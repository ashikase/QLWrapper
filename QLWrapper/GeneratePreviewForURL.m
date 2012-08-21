#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import <Foundation/Foundation.h>

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    @autoreleasepool {
        // Determine name of generator script
        // NOTE: Script name is of format "(uti)-(extension)";
        //       if file has no extension, then it will be simply "(uti)".
        //       Ex.: "Readme.unk" -> "public.data-unk"
        //       (unless .unk has been registered with a more-specific UTI)
        // NOTE: Treat dynamic UTIs as "public.data".
        NSString *scriptName = (__bridge NSString *)(contentTypeUTI);
        if ([scriptName hasPrefix:@"dyn."]) {
           scriptName = @"public.data";
        }

        NSString *filePath = [(__bridge NSURL *)url path];
        NSString *ext = [filePath pathExtension];
        if ([ext length] != 0) {
            scriptName = [scriptName stringByAppendingFormat:@"-%@", ext];
        }

        // Check that the generator scripts exists
        NSString *scriptPath = [@"~/Library/QuickLook/Scripts" stringByAppendingPathComponent:scriptName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:scriptPath]) {
            // FIXME: Fallback to just displaying the text/hex content?
            return noErr;
        }

        // Create the task
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:scriptPath];

        // Pass the "preview flag" and the path to the file to preview
        NSArray *arguments = [NSArray arrayWithObjects: @"-p", filePath, nil];
        [task setArguments:arguments];

        // Create a pipe to collect the output
        NSPipe *pipe = [NSPipe pipe];
        [task setStandardOutput: pipe];

        // Launch the task and wait for it to finish
        [task launch];
        [task waitUntilExit];

        // Collect the output
        NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        // Parse output, retrieving any preview properties
        // NOTE: Output of generator script should be well-formed HTML;
        //       HTML must begin with a doctype tag.
        // NOTE: A JSON object containing preview settings (width, height)
        //       may be included before the doctype tag.
        id json = nil;
        NSRange range = [string rangeOfString:@"<!doctype" options:NSCaseInsensitiveSearch];
        if (range.location != NSNotFound && range.location != 0) {
            // Parse JSON data
            NSData *data = [[string substringToIndex:range.location] dataUsingEncoding:NSUTF8StringEncoding];
            json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (![json isKindOfClass:[NSDictionary class]]) {
                // Not valid JSON; ignore
                // NOTE: Do not strip from HTML, as it may have some unknown importance.
                NSLog(@"Output from generator script contains invalid JSON object");
                json = nil;
            } else {
                // Remove JSON data from HTML string
                string = [string substringFromIndex:range.location];
            }
        }

        // Create properties for the preview
        NSMutableDictionary *props = [[NSMutableDictionary alloc] init];
        [props setObject:@"UTF-8" forKey:(__bridge NSString *)kQLPreviewPropertyTextEncodingNameKey];
        [props setObject:@"text/html" forKey:(__bridge NSString *)kQLPreviewPropertyMIMETypeKey];

        if (json != nil) {
            id obj = [json objectForKey:@"width"];
            if ([obj isKindOfClass:[NSNumber class]]) {
                [props setObject:obj forKey:(__bridge NSString *)kQLPreviewPropertyWidthKey];
            }
            obj = [json objectForKey:@"height"];
            if ([obj isKindOfClass:[NSNumber class]]) {
                [props setObject:obj forKey:(__bridge NSString *)kQLPreviewPropertyHeightKey];
            }
        }

        // Set the data (HTML) and properties for the preview
        QLPreviewRequestSetDataRepresentation(
                preview,
                (CFDataRef)CFBridgingRetain([string dataUsingEncoding:NSUTF8StringEncoding]),
                kUTTypeHTML,
                (CFDictionaryRef)CFBridgingRetain(props));
    }

    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}

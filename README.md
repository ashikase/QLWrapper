About
=====

QLWrapper is a simple Quick Look plug-in that utilizes user-provided scripts to
generate the preview and thumbnail for a given filetype.

By providing a script (and modifying the plug-in's Info.plist, if necessary),
any filetype can be supported.

(NOTE: Thumbnail generation is currently not supported.)

Usage
=====

By default, the plug-in only supports the "public.data" UTI. To support other
UTI values, the value must be added to the LSItemContentTypes array in the
plug-in's Info.plist file.

Generator scripts should be placed in ~/Library/QuickLook/Scripts.

Scripts should be named using the filetype's UTI and extension; the name
should be formatted as "(uti)-(extension)"; if a filetype has no extension,
the script should be named simply "(uti)". For example, given a file named
"SomeFile.unk", if the UTI is "public.data", the name for the script would be
"public.data-unk".

Scripts can be written in any language, even a compiled language.

A script must:

1. Be executable.
2. Accept two command-line parameters:
    a. A generation type flag ("-p" or "-t")
    b. Absolute path to file to generate preview/thumbnail for.
3. Output result to standard out (STDOUT).

The output for previews must be in HTML; the HTML *must* begin with a doctype
tag. The HTML can be preceeded with a JSON object containing settings for the
width and height of the Quick Look preview window. For example:

    { "width": 300, "height": 200 }<!DOCTYPE ...

The output for thumbnails is not yet decided.

Warranty
========

This plug-in was created for the developer's personal use. It may contain
bugs, it may not work properly, etc.

Use at your own risk.

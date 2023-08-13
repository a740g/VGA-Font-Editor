'-----------------------------------------------------------------------------------------------------------------------
' Tiny tool to convert raw VGA character ROM to PSF1 (PC Screen Font v1) format
' See https://github.com/spacerace/romfont to learn more about VGA ROM fonts or character ROM
' See https://www.win.tue.nl/~aeb/linux/kbd/font-formats-1.html to learn about the PSF format
'
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$INCLUDE:'include/VGAFont.bi'
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' METACOMMANDS
'-----------------------------------------------------------------------------------------------------------------------
$NOPREFIX
$CONSOLE:ONLY
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT
'-----------------------------------------------------------------------------------------------------------------------
' Change to the directory specified by the environment
CHDIR STARTDIR$

' If there are no command line parameters just show some info and exit
IF COMMANDCOUNT < 1 THEN
    PRINT
    PRINT "Bin2PSF: Converts raw VGA ROM fonts to PSF1 (PC Screen Font v1)"
    PRINT
    PRINT "Copyright (c) 2023 Samuel Gomes"
    PRINT
    PRINT "https://github.com/a740g"
    PRINT
    PRINT "Usage: bin2psf [filespec]"
    PRINT
    PRINT "Note:"
    PRINT " * This will create filespec.psf"
    PRINT " * Bulk convert files using wildcards"
    PRINT " * If filespec.psf already exists, then it will not be overwritten"
    PRINT
    SYSTEM
END IF

DIM AS LONG i, h

PRINT
' Convert all files requested
FOR i = 1 TO COMMANDCOUNT
    PRINT "Attempting to convert "; COMMAND$(i); " ... ";
    h = ConvertBin2PSF(COMMAND$(i), COMMAND$(i) + ".psf")
    IF h > 0 THEN
        PRINT "8 x"; h; "done!"
    ELSE
        PRINT "failed!"
    END IF
NEXT

SYSTEM
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' FUNCTIONS AND SUBROUTINES
'-----------------------------------------------------------------------------------------------------------------------
FUNCTION ConvertBin2PSF& (sBinFileName AS STRING, sPSFFileName AS STRING)
    ' Assume failure
    ConvertBin2PSF = 0

    IF FILEEXISTS(sBinFileName) AND NOT FILEEXISTS(sPSFFileName) THEN
        ' Open the raw ROM font file
        DIM binFileHandle AS LONG
        binFileHandle = FREEFILE
        OPEN sBinFileName FOR BINARY ACCESS READ AS binFileHandle

        DIM h AS LONG

        ' Get and store the raw file size
        h = LOF(binFileHandle)

        ' Basic check: The raw font should be completely divisible by 256
        IF h MOD 256 <> 0 OR h = 0 THEN
            CLOSE binFileHandle
            EXIT FUNCTION
        END IF

        ' Open the PSF file
        DIM psfFilehandle AS LONG
        psfFilehandle = FREEFILE
        OPEN sPSFFileName FOR BINARY ACCESS WRITE AS psfFilehandle

        ' Calculate font height
        h = h \ 256

        DIM buffer AS STRING

        ' Write the magic ID
        buffer = CHR$(__PSF1_MAGIC0) + CHR$(__PSF1_MAGIC1)
        PUT psfFilehandle, , buffer

        ' Write mode (just a NULL)
        buffer = CHR$(NULL)
        PUT psfFilehandle, , buffer

        ' Write charsize
        buffer = CHR$(h)
        PUT psfFilehandle, , buffer

        ' Read the font data
        buffer = INPUT$(h * 256, binFileHandle)

        ' Write the font data
        PUT psfFilehandle, , buffer

        ' Close all files
        CLOSE psfFilehandle, binFileHandle

        ' Return the font height
        ConvertBin2PSF = h
    END IF
END FUNCTION
'-----------------------------------------------------------------------------------------------------------------------
'-----------------------------------------------------------------------------------------------------------------------

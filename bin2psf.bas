'-----------------------------------------------------------------------------------------------------
'
' Tiny tool to convert raw VGA character ROM to PSF1 (PC Screen Font v1) format
' See https://github.com/spacerace/romfont to learn more about VGA ROM fonts or character ROM
' See https://www.win.tue.nl/~aeb/linux/kbd/font-formats-1.html to learn about PSF format
'
' Copyright (c) Samuel Gomes (a740g), 2022.
' All rights reserved.
'
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------
'$Include:'./include/VGAFont.bi'
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' METACOMMANDS
'-----------------------------------------------------------------------------------------------------
$Console:Only
$ScreenHide
'-----------------------------------------------------------------------------------------------------

' Set output destination to the console
Dest Console
' Change to the directory specified by the environment
ChDir StartDir$

' If there are no command line parameters just show some info and exit
If CommandCount < 1 Then
    Print
    Print "Bin2PSF: Converts raw VGA ROM fonts to PSF1 (PC Screen Font v1)"
    Print
    Print "Copyright (c) Samuel Gomes, 2022."
    Print "All rights reserved."
    Print
    Print "https://github.com/a740g"
    Print
    Print "Usage: bin2psf [filespec]"
    Print
    Print "Note:"
    Print " This will create filespec.psf"
    Print " Bulk convert files using wildcards"
    Print " If filespec.psf already exists, then it will not be overwritten"
    System
End If

Dim As Long i, h

Print
' Convert all files requested
For i = 1 To CommandCount
    Print "Attempting to convert "; Command$(i); " ... ";
    h = ConvertBin2PSF(Command$(i), Command$(i) + ".psf")
    If h > 0 Then
        Print "8 x"; h; "done!"
    Else
        Print "failed!"
    End If
Next

System


Function ConvertBin2PSF& (sBinFileName As String, sPSFFileName As String)
    ' Assume failure
    ConvertBin2PSF = NULL

    If FileExists(sBinFileName) And Not FileExists(sPSFFileName) Then
        ' Open the raw ROM font file
        Dim binFileHandle As Long
        binFileHandle = FreeFile
        Open sBinFileName For Binary Access Read As binFileHandle

        Dim h As Long

        ' Get and store the raw file size
        h = LOF(binFileHandle)

        ' Basic check: The raw font should be completely divisible by 256
        If h Mod 256 <> 0 Or h = 0 Then
            Close binFileHandle
            Exit Function
        End If

        ' Open the PSF file
        Dim psfFilehandle As Long
        psfFilehandle = FreeFile
        Open sPSFFileName For Binary Access Write As psfFilehandle

        ' Calculate font height
        h = h \ 256

        Dim buffer As String

        ' Write the magic ID
        buffer = Chr$(PSF1_MAGIC0) + Chr$(PSF1_MAGIC1)
        Put psfFilehandle, , buffer

        ' Write mode (just a NULL)
        buffer = Chr$(NULL)
        Put psfFilehandle, , buffer

        ' Write charsize
        buffer = Chr$(h)
        Put psfFilehandle, , buffer

        ' Read the font data
        buffer = Input$(h * 256, binFileHandle)

        ' Write the font data
        Put psfFilehandle, , buffer

        ' Close all files
        Close psfFilehandle, binFileHandle

        ' Return the font height
        ConvertBin2PSF = h
    End If
End Function


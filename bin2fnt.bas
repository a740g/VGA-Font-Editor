'-----------------------------------------------------------------------------------------------------
'
' Quick and dirty tool to convert raw VGA character ROM to our format
' See https://github.com/spacerace/romfont to learn more about VGA ROM fonts or character ROM
'
' Copyright (c) Samuel Gomes (a740g), 2022.
' All rights reserved.
'
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' These are some metacommands and compiler options for QB64 to write modern type-strict code
'-----------------------------------------------------------------------------------------------------
' This will disable prefixing all modern QB64 calls using a underscore prefix.
$NoPrefix
' Whatever indentifiers are not defined, should default to signed longs (ex. constants and functions).
DefLng A-Z
' All variables must be defined.
Option Explicit
' All arrays must be defined.
Option ExplicitArray
' Array lower bounds should always start from 1 unless explicitly specified.
' This allows a(4) as integer to have 4 members with index 1-4.
Option Base 1
' All arrays should be allocated dynamically by default. This allows us to easily resize arrays.
'$DYNAMIC
' For text mode programs, uncomment the three lines below.
$Console
$ScreenHide
Dest Console
'-----------------------------------------------------------------------------------------------------

ChDir StartDir$

If CommandCount < 1 Then
    Print
    Print "bin2fnt"
    Print
    Print "Copyright (c) Samuel Gomes, 2022."
    Print "All rights reserved."
    Print
    Print "https://github.com/a740g"
    Print
    Print "Usage: bin2fnt [InFile]"
    Print
    Print "This will create Infile.fnt"
    System 0
End If

Dim binfilename As String
binfilename = Command$(1)

If Not FileExists(binfilename) Then
    Print
    Print binfilename; " does not exist! Specify a valid filename."
    System 1
End If

Dim binfilehandle As Long
binfilehandle = FreeFile
Open binfilename For Binary Access Read As binfilehandle

If LOF(binfilehandle) Mod 256 <> 0 Then
    Print
    Print binfilename; " is probably not a VGA ROM font! Please check."

    Close binfilehandle
    System 1
End If

Dim fntfilename As String
fntfilename = binfilename + ".fnt"

If FileExists(fntfilename) Then
    Print
    Print fntfilename; " already exists! Will not overwite."

    Close binfilehandle
    System 1
End If

Dim fntfilehandle As Long
fntfilehandle = FreeFile
Open fntfilename For Binary Access Write As fntfilehandle

Dim buffer As String

Print "Creating 8 x"; LOF(binfilehandle) / 256; "font: "; fntfilename; "...";

buffer = "FONT"
Put fntfilehandle, , buffer

buffer = Chr$(LOF(binfilehandle) / 256)
Put fntfilehandle, , buffer

buffer = Space$(LOF(binfilehandle))

Get binfilehandle, , buffer
Put fntfilehandle, , buffer

Close fntfilehandle, binfilehandle

Print "done!"

System 0


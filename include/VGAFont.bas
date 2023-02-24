'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' VGA Font Library
' Copyright (c) 2023 Samuel Gomes
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
'$Include:'./VGAFont.bi'
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

$If VGAFONT_BAS = UNDEFINED Then
    $Let VGAFONT_BAS = TRUE
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' Draws a single character at x, y using the active font
    Sub DrawCharacter (cp As Unsigned Byte, x As Long, y As Long)
        $Checking:Off
        Shared __CurPSF As PSFType
        Dim As Long uy, r, t, p, bc, pm

        r = x + __CurPSF.size.x - 1 ' calculate right just once

        bc = BackgroundColor
        pm = PrintMode

        ' Go through the scan line one at a time
        For uy = 1 To __CurPSF.size.y
            ' Get the scan line and pepare it
            p = Asc(__CurPSF.bitmap, __CurPSF.size.y * cp + uy)
            p = 256 * (p + (256 * (p > 127)))
            ' Draw the line
            t = y + uy - 1
            If pm = 3 Then Line (x, t)-(r, t), bc
            Line (x, t)-(r, t), , , p
        Next
        $Checking:On
    End Sub


    ' Draws a string at x, y using the active font
    Sub DrawString (text As String, x As Long, y As Long)
        $Checking:Off
        Shared __CurPSF As PSFType
        Dim As Long uy, l, r, t, p, cidx, bc, pm, cp

        bc = BackgroundColor
        pm = PrintMode

        ' We will iterate through the whole text
        For cidx = 1 To Len(text)
            cp = Asc(text, cidx) ' find the character to draw
            l = x + (cidx - 1) * __CurPSF.size.x ' calculate the starting x position for this character
            r = l + __CurPSF.size.x - 1 ' calculate right
            ' Next go through each scan line and draw those
            For uy = 1 To __CurPSF.size.y
                ' Get the scan line and prepare it
                p = Asc(__CurPSF.bitmap, __CurPSF.size.y * cp + uy)
                p = 256 * (p + (256 * (p > 127)))
                ' Draw the scan line
                t = y + uy - 1
                If pm = 3 Then Line (l, t)-(r, t), bc
                Line (l, t)-(r, t), , , p
            Next
        Next
        $Checking:On
    End Sub


    ' Returns the current font width
    Function GetFontWidth~%%
        $Checking:Off
        Shared __CurPSF As PSFType
        GetFontWidth = __CurPSF.size.x
        $Checking:On
    End Function


    ' Returns the current font height
    Function GetFontHeight~%%
        $Checking:Off
        Shared __CurPSF As PSFType
        GetFontHeight = __CurPSF.size.y
        $Checking:On
    End Function


    ' Return the onsreen length of a string in pixels
    Function GetDrawStringWidth& (text As String)
        $Checking:Off
        Shared __CurPSF As PSFType
        GetDrawStringWidth = Len(text) * __CurPSF.size.x
        $Checking:On
    End Function


    ' Set the active font
    Sub SetCurrentFont (psf As PSFType)
        $Checking:Off
        Shared __CurPSF As PSFType
        __CurPSF = psf
        $Checking:On
    End Sub


    ' Loads a font file from disk
    Function ReadFont%% (sFile As String, ignoreMode As Byte, psf As PSFType)
        If FileExists(sFile) Then
            Dim As Long hFile

            ' Open the file for reading
            hFile = FreeFile
            Open sFile For Binary Access Read As hFile

            ' Check font magic id
            If Input$(2, hFile) <> Chr$(PSF1_MAGIC0) + Chr$(PSF1_MAGIC1) Then
                Close hFile
                Exit Function
            End If

            Dim i As Long

            ' Read special mode value and ignore only if specified
            i = Asc(Input$(1, hFile))
            If Not ignoreMode And i <> 0 Then
                Close hFile
                Exit Function
            End If

            ' Check font height
            i = Asc(Input$(1, hFile))
            If i = 0 Then
                Close hFile
                Exit Function
            End If

            psf.size.x = 8 ' the width is always 8 for PSFv1
            psf.size.y = i ' change the font height
            psf.bitmap = Input$(256 * psf.size.y, hFile) ' the bitmap data in one go

            Close hFile

            ReadFont = TRUE
        End If
    End Function


    ' Changes the font height of the active font
    ' This will wipe out whatever bitmap the font already has
    Sub SetFontHeight (h As Unsigned Byte)
        Shared __CurPSF As PSFType
        __CurPSF.size.x = 8 ' the width is always 8 for PSFv1
        __CurPSF.size.y = h ' change the font height
        __CurPSF.bitmap = String$(256 * __CurPSF.size.y, NULL) ' just allocate enough space for the bitmap

        ' Load default glyphs
        Dim i As Long
        For i = 0 To 255
            SetGlyphDefaultBitmap i
        Next
    End Sub


    ' Returns the entire bitmap of a glyph in a string
    Function GetGlyphBitmap$ (cp As Unsigned Byte)
        Shared __CurPSF As PSFType
        GetGlyphBitmap = Mid$(__CurPSF.bitmap, 1 + __CurPSF.size.y * cp, __CurPSF.size.y)
    End Function


    ' Sets the entire bitmap of a glyph with bmp
    Sub SetGlyphBitmap (cp As Unsigned Byte, bmp As String)
        Shared __CurPSF As PSFType
        Mid$(__CurPSF.bitmap, 1 + __CurPSF.size.y * cp, __CurPSF.size.y) = bmp
    End Sub


    ' Set the glyph's bitmap to QB64's current font glyph
    Sub SetGlyphDefaultBitmap (cp As Unsigned Byte)
        Shared __CurPSF As PSFType

        Dim img As Long: img = NewImage(FontWidth, FontHeight, 32)
        If img >= -1 Then Exit Sub ' leave if we failed to allocate the image

        Dim dst As Long: dst = Dest ' save dest
        Dest img ' set img as dest

        Dim f As Long: f = Font ' save the current font

        ' Select the best builtin font to use
        Select Case __CurPSF.size.y
            Case Is > 15
                Font 16

            Case Is > 13
                Font 14

            Case Else
                Font 8
        End Select

        PrintString (0, 0), Chr$(cp) ' render the glyph to our image

        ' Find the starting x, y on the font bitmap where we should start to render
        Dim sx As Long: sx = __CurPSF.size.x \ 2 - FontWidth \ 2
        Dim sy As Long: sy = __CurPSF.size.y \ 2 - FontHeight \ 2

        Dim src As Long: src = Source ' save the old source
        Source img ' change source to img

        ' Copy the QB64 glyph
        Dim As Long x, y
        For y = 0 To FontHeight - 1
            For x = 0 To FontWidth - 1
                SetGlyphPixel cp, sx + x, sy + y, Point(x, y) <> Black
            Next
        Next

        Source src ' restore source
        Font f ' restore font
        Dest dst
        FreeImage img ' free img
    End Sub


    ' Return true if the pixel-bit at the glyphs x, y is set
    Function GetGlyphPixel%% (cp As Unsigned Byte, x As Long, y As Long)
        Shared __CurPSF As PSFType

        If x < 0 Or x >= __CurPSF.size.x Or y < 0 Or y >= __CurPSF.size.y Then Exit Function

        GetGlyphPixel = ReadBit(Asc(__CurPSF.bitmap, __CurPSF.size.y * cp + y + 1), __CurPSF.size.x - x - 1)
    End Function


    ' Sets or unsets pixel at the glyphs x, y
    Sub SetGlyphPixel (cp As Unsigned Byte, x As Long, y As Long, b As Byte)
        Shared __CurPSF As PSFType

        If x < 0 Or x >= __CurPSF.size.x Or y < 0 Or y >= __CurPSF.size.y Then Exit Sub

        If Not b Then
            Asc(__CurPSF.bitmap, __CurPSF.size.y * cp + y + 1) = ResetBit(Asc(__CurPSF.bitmap, __CurPSF.size.y * cp + y + 1), __CurPSF.size.x - x - 1)
        Else
            Asc(__CurPSF.bitmap, __CurPSF.size.y * cp + y + 1) = SetBit(Asc(__CurPSF.bitmap, __CurPSF.size.y * cp + y + 1), __CurPSF.size.x - x - 1)
        End If
    End Sub


    ' Saves the current font to disk in PSF v1 format
    ' This does not check if the file exists or whatever and will happily overwrite it
    ' It is the caller's resposibility to check this stuff
    Function WriteFont%% (sFile As String)
        Shared __CurPSF As PSFType

        If __CurPSF.size.x > 0 And __CurPSF.size.y > 0 And Len(__CurPSF.bitmap) = 256 * __CurPSF.size.y Then ' check if the font is valid
            Dim As Long hFile

            ' Open the file for writing
            hFile = FreeFile
            Open sFile For Binary Access Write As hFile

            Dim buffer As String

            ' Write font id
            buffer = Chr$(PSF1_MAGIC0) + Chr$(PSF1_MAGIC1)
            Put hFile, , buffer

            ' Write mode as zero
            buffer = Chr$(NULL)
            Put hFile, , buffer

            ' Write font height
            buffer = Chr$(__CurPSF.size.y)
            Put hFile, , buffer

            Put hFile, , __CurPSF.bitmap ' write the font data

            Close hFile

            WriteFont = TRUE
        End If
    End Function
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------------------------------------------------------------


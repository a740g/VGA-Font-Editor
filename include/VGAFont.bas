'---------------------------------------------------------------------------------------------------------
' VGA Font Library
' Copyright (c) 2022 Samuel Gomes
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------
'$Include:'VGAFont.bi'
'---------------------------------------------------------------------------------------------------------

$If VGAFONT_BAS = UNDEFINED Then
    $Let VGAFONT_BAS = TRUE

    '-----------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-----------------------------------------------------------------------------------------------------
    ' Changes the font height in memory
    ' This can be used by an editor
    ' This will crop the font if a font is loaded!
    Sub SetFontHeight (nHeight As Unsigned Byte)
        Dim i As Long

        ' Change the global font height
        VGAFont.glyphSize.y = nHeight
        VGAFont.glyphSize.x = 8 ' Our width is always 8

        ' Now change the main font array height
        For i = 0 To 255
            FontData(i) = Left$(FontData(i) + String$(nHeight, NULL), nHeight)
        Next
    End Sub


    ' This will clear the font glyphs
    Sub ResetFont
        Dim i As Long

        For i = 0 To 255
            FontData(i) = String$(VGAFont.glyphSize.y, NULL)
        Next
    End Sub


    ' Draws a single character at x, y
    ' Colors are picked up from the VGAFont
    Sub DrawCharacter (nChar As Unsigned Byte, x As Long, y As Long)
        Dim As Long uy, p, r, t

        ' Calculate right just once
        r = x + VGAFont.glyphSize.x - 1

        ' Go through the scan line one at a time
        For uy = 1 To VGAFont.glyphSize.y
            ' Get the scan line and pepare it
            p = Asc(FontData(nChar), uy)
            p = 256 * (p + (256 * (p > 127)))
            ' Draw the line
            t = y + uy - 1
            Line (x, t)-(r, t), VGAFont.bgColor
            Line (x, t)-(r, t), VGAFont.fgColor, , p
        Next
    End Sub


    ' Draws a string at x, y
    ' Colors are picked up from the VGAFont
    Sub DrawString (sText As String, x As Long, y As Long)
        Dim As Long uy, p, l, r, t, cidx
        Dim ch As Unsigned Byte

        ' We will iterate through the whole text
        For cidx = 1 To Len(sText)
            ' Find the character to draw
            ch = Asc(sText, cidx)
            ' Calculate the starting x position for this character
            l = x + (cidx - 1) * VGAFont.glyphSize.x
            ' Calculate right
            r = l + VGAFont.glyphSize.x - 1
            ' Next go through each scan line and draw those
            For uy = 1 To VGAFont.glyphSize.y
                ' Get the scan line and prepare it
                p = Asc(FontData(ch), uy)
                p = 256 * (p + (256 * (p > 127)))
                ' Draw the scan line
                t = y + uy - 1
                Line (l, t)-(r, t), VGAFont.bgColor
                Line (l, t)-(r, t), VGAFont.fgColor, , p
            Next
        Next
    End Sub


    ' Return the onsreen length of a string in pixels
    ' Just a convenience function
    Function GetDrawStringWidth& (sText As String)
        GetDrawStringWidth = Len(sText) * VGAFont.glyphSize.x
    End Function


    ' Loads a font file from disk
    ' This also sets the default foreground and background colors
    Function ReadFont%% (sFile As String, ignoreMode As Byte)
        ' Assume failure
        ReadFont = FALSE

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

            ' Set the height
            ' This also sets the array
            SetFontHeight i

            For i = 0 To 255
                Get hFile, , FontData(i)
            Next

            Close hFile

            ' Set default colors
            VGAFont.fgColor = White
            VGAFont.bgColor = Black

            ReadFont = TRUE
        End If
    End Function

    ' Saves the font file to disk in PSF v1 format
    ' This does not check if the file exists or whatever and will happily overwrite it
    ' It is the caller's resposibility to check this stuff
    Function WriteFont%% (sFile As String)
        ' Assume failure
        WriteFont = FALSE

        If VGAFont.glyphSize.x > 0 And VGAFont.glyphSize.y > 0 Then
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
            buffer = Chr$(VGAFont.glyphSize.y)
            Put hFile, , buffer

            Dim i As Long

            ' Write the font data
            For i = 0 To 255
                Put hFile, , FontData(i)
            Next

            Close hFile

            WriteFont = TRUE
        End If
    End Function
    '---------------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------


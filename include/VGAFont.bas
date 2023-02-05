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
    ' Changes the font height in memory
    ' This can be used by an editor
    ' This will crop the font if a font is loaded!
    Sub SetFontHeight (nHeight As Unsigned Byte)
        Shared FontSize As Vector2DType
        Shared FontData() As String
        Dim i As Long

        ' Change the global font height
        FontSize.y = nHeight
        FontSize.x = 8 ' Our width is always 8

        ' Now change the main font array height
        For i = 0 To 255
            FontData(i) = Left$(FontData(i) + String$(nHeight, NULL), nHeight)
        Next
    End Sub


    ' This will clear the font glyphs
    Sub ResetFont
        Shared FontSize As Vector2DType
        Shared FontData() As String
        Dim i As Long

        For i = 0 To 255
            FontData(i) = String$(FontSize.y, NULL)
        Next
    End Sub


    ' Draws a single character at x, y
    Sub DrawCharacter (nChar As Unsigned Byte, x As Long, y As Long)
        $Checking:Off
        Shared FontSize As Vector2DType
        Shared FontData() As String
        Dim As Long uy, r, t, p, fc, bc

        ' Calculate right just once
        r = x + FontSize.x - 1

        fc = DefaultColor
        bc = BackgroundColor

        ' Go through the scan line one at a time
        For uy = 1 To FontSize.y
            ' Get the scan line and pepare it
            p = Asc(FontData(nChar), uy)
            p = 256 * (p + (256 * (p > 127)))
            ' Draw the line
            t = y + uy - 1
            Line (x, t)-(r, t), bc
            Line (x, t)-(r, t), fc, , p
        Next
        $Checking:On
    End Sub


    ' Draws a string at x, y
    Sub DrawString (sText As String, x As Long, y As Long)
        $Checking:Off
        Shared FontSize As Vector2DType
        Shared FontData() As String
        Dim As Long uy, l, r, t, p, cidx, fc, bc
        Dim ch As Unsigned Byte

        fc = DefaultColor
        bc = BackgroundColor

        ' We will iterate through the whole text
        For cidx = 1 To Len(sText)
            ' Find the character to draw
            ch = Asc(sText, cidx)
            ' Calculate the starting x position for this character
            l = x + (cidx - 1) * FontSize.x
            ' Calculate right
            r = l + FontSize.x - 1
            ' Next go through each scan line and draw those
            For uy = 1 To FontSize.y
                ' Get the scan line and prepare it
                p = Asc(FontData(ch), uy)
                p = 256 * (p + (256 * (p > 127)))
                ' Draw the scan line
                t = y + uy - 1
                Line (l, t)-(r, t), bc
                Line (l, t)-(r, t), fc, , p
            Next
        Next
        $Checking:On
    End Sub


    ' Return the onsreen length of a string in pixels
    ' Just a convenience function
    Function GetDrawStringWidth& (sText As String)
        $Checking:Off
        Shared FontSize As Vector2DType

        GetDrawStringWidth = Len(sText) * FontSize.x
        $Checking:On
    End Function


    ' Loads a font file from disk
    Function ReadFont%% (sFile As String, ignoreMode As Byte)
        Shared FontData() As String

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

            ReadFont = TRUE
        End If
    End Function


    ' Saves the font file to disk in PSF v1 format
    ' This does not check if the file exists or whatever and will happily overwrite it
    ' It is the caller's resposibility to check this stuff
    Function WriteFont%% (sFile As String)
        Shared FontSize As Vector2DType
        Shared FontData() As String

        ' Assume failure
        WriteFont = FALSE

        If FontSize.x > 0 And FontSize.y > 0 Then
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
            buffer = Chr$(FontSize.y)
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
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------------------------------------------------------------


'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' QB64 Base64 Encoder and Decoder library
' Copyright (c) 2023 Samuel Gomes
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
'$Include:'./Base64.bi'
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

$If BASE64_BAS = UNDEFINED Then
    $Let BASE64_BAS = TRUE

    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' Convert a normal string to a base64 string
    Function EncodeBase64$ (s As String)
        Dim As String buffer, result
        Dim As Unsigned Long i

        For i = 1 To Len(s)
            buffer = buffer + Chr$(Asc(s, i))
            If Len(buffer) = 3 Then
                result = result + Chr$(Asc(BASE64_CHARACTERS, 1 + (ShR(Asc(buffer, 1), 2))))
                result = result + Chr$(Asc(BASE64_CHARACTERS, 1 + (ShL((Asc(buffer, 1) And 3), 4) Or ShR(Asc(buffer, 2), 4))))
                result = result + Chr$(Asc(BASE64_CHARACTERS, 1 + (ShL((Asc(buffer, 2) And 15), 2) Or ShR(Asc(buffer, 3), 6))))
                result = result + Chr$(Asc(BASE64_CHARACTERS, 1 + (Asc(buffer, 3) And 63)))
                buffer = NULLSTRING
            End If
        Next

        ' Add padding
        If Len(buffer) > 0 Then
            result = result + Chr$(Asc(BASE64_CHARACTERS, 1 + (ShR(Asc(buffer, 1), 2))))
            If Len(buffer) = 1 Then
                result = result + Chr$(Asc(BASE64_CHARACTERS, 1 + (ShL(Asc(buffer, 1) And 3, 4))))
                result = result + "=="
            Else
                result = result + Chr$(Asc(BASE64_CHARACTERS, 1 + (ShL((Asc(buffer, 1) And 3), 4) Or ShR(Asc(buffer, 2), 4))))
                result = result + Chr$(Asc(BASE64_CHARACTERS, 1 + (ShL(Asc(buffer, 2) And 15, 2))))
                result = result + "="
            End If
        End If

        EncodeBase64 = result
    End Function


    ' Convert a base64 string to a normal string
    Function DecodeBase64$ (s As String)
        Dim As String buffer, result
        Dim As Unsigned Long i
        Dim As Unsigned Byte char1, char2, char3, char4

        For i = 1 To Len(s) Step 4
            char1 = InStr(BASE64_CHARACTERS, Chr$(Asc(s, i))) - 1
            char2 = InStr(BASE64_CHARACTERS, Chr$(Asc(s, i + 1))) - 1
            char3 = InStr(BASE64_CHARACTERS, Chr$(Asc(s, i + 2))) - 1
            char4 = InStr(BASE64_CHARACTERS, Chr$(Asc(s, i + 3))) - 1
            buffer = Chr$(ShL(char1, 2) Or ShR(char2, 4)) + Chr$(ShL(char2 And 15, 4) Or ShR(char3, 2)) + Chr$(ShL(char3 And 3, 6) Or char4)

            result = result + buffer
        Next

        ' Remove padding
        If Right$(s, 2) = "==" Then
            result = Left$(result, Len(result) - 2)
        ElseIf Right$(s, 1) = "=" Then
            result = Left$(result, Len(result) - 1)
        End If

        DecodeBase64 = result
    End Function


    ' Loads a binary file encoded with Bin2Data
    ' Usage:
    '   1. Encode the binary file with Bin2Data
    '   2. Include the file or it's contents
    '   3. Load the file like so:
    '       Restore label_generated_by_bin2data
    '       Dim buffer As String
    '       buffer = LoadResource   ' buffer will now hold the contents of the file
    Function LoadResource$
        Dim As Unsigned Long ogSize, resSize
        Dim As Byte isCompressed

        Read ogSize, resSize, isCompressed ' read the header

        Dim As String buffer, result

        ' Read the whole resource data
        Do While Len(result) < resSize
            Read buffer
            result = result + buffer
        Loop

        ' Decode the data
        buffer = DecodeBase64(result)

        ' Expand the data if needed
        If isCompressed Then
            result = Inflate$(buffer, ogSize)
        Else
            result = buffer
        End If

        LoadResource = result
    End Function
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------------------------------------------------------------


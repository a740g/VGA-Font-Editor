'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' VGA font editor
' Copyright (c) 2023 Samuel Gomes
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
'$Include:'./include/Base64.bi'
'$Include:'./include/ANSIPrint.bi'
'$Include:'./include/VGAFont.bi'
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' METACOMMANDS
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
$ExeIcon:'.\VGAFontEditor.ico'
$VersionInfo:CompanyName=Samuel Gomes
$VersionInfo:FileDescription=VGA Font Editor executable
$VersionInfo:InternalName=VGAFontEditor
$VersionInfo:LegalCopyright=Copyright (c) 2023 Samuel Gomes
$VersionInfo:LegalTrademarks=All trademarks are property of their respective owners
$VersionInfo:OriginalFilename=VGAFontEditor.exe
$VersionInfo:ProductName=VGA Font Editor
$VersionInfo:Web=https://github.com/a740g
$VersionInfo:Comments=https://github.com/a740g
$VersionInfo:FILEVERSION#=4,1,0,0
$VersionInfo:ProductVersion=4,0,0,0
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' CONSTANTS
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
Const APP_NAME = "VGA Font Editor"
' Program events
Const EVENT_NONE = 0
Const EVENT_QUIT = 1
Const EVENT_COMMAND = 2
Const EVENT_NEW = 3
Const EVENT_LOAD = 4
Const EVENT_CHOOSE = 5
Const EVENT_EDIT = 6
Const EVENT_PREVIEW = 7
Const EVENT_SAVE = 8
' Screen properties
Const SCREEN_WIDTH = 640
Const SCREEN_HEIGHT = 480
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' GLOBAL VARIABLES
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
Dim Shared sFontFile As String ' the name of the font file we are viewing / editing
Dim Shared ubFontCharacter As Unsigned Byte ' the glyph we are editing
Dim Shared bFontChanged As Byte ' has the font changed?
Dim Shared sClipboard As String ' our clipboard that holds a single glyph
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
ChDir StartDir$ ' change to the directory specifed by the environment
ControlChr Off ' turn off control characters
Screen NewImage(SCREEN_WIDTH, SCREEN_HEIGHT, 32) ' switch to graphics mode
Title APP_NAME + " " + OS$ ' set app title
AllowFullScreen SquarePixels , Smooth ' Allow the program window to run fullscreen with Alt+Enter

Dim event As Byte: event = EVENT_COMMAND ' default's to command line event on program entry

' Event loop
Do
    Select Case event
        Case EVENT_COMMAND
            event = DoCommandLine

        Case EVENT_NEW
            event = DoNewFont

        Case EVENT_LOAD
            event = DoLoadFont

        Case EVENT_SAVE
            event = DoSaveFont

        Case EVENT_CHOOSE
            event = DoChooseCharacter

        Case EVENT_EDIT
            event = DoEditCharacter

        Case EVENT_PREVIEW
            event = DoShowPreview

        Case EVENT_QUIT
            If bFontChanged Then
                ' Attempt to save the changes
                event = DoSaveFont

                ' Check the user really wants to quit
                If MessageBox(APP_NAME, "Are you sure you want to quit?", "yesno", "question") = 1 Then
                    Exit Do
                End If
            Else
                Exit Do
            End If

        Case Else
            event = DoWelcomeScreen
    End Select
Loop

System
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' FUNCTIONS AND SUBROUTINES
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
Function DoWelcomeScreen%%
    ' Save the current destination
    Dim As Long oldDest: oldDest = Dest

    ' Now create a new image
    Dim As Long img: img = NewImage(80 * 8, 31 * 16, 32) ' we'll allocate some extra height to avoid any scrolling

    ' Change destination and render the ANSI art
    Dest img
    Restore Data_vga_font_editor_logo_3_ans_3737
    Dim As String buffer: buffer = LoadResource
    PrintANSI buffer, 0

    ' Capture rendered image to another image
    Dim As Long imgANSI: imgANSI = NewImage(80 * 8, 30 * 16, 32)
    PutImage (0, 0), img, imgANSI ' any excess height will simply get clipped
    ClearColor Black, imgANSI ' set all black pixels to be transparent

    ' Render the menu
    Cls , Black
    Color , Black
    Color Lime: Print "F1";: Color Gray: Print " ............";: Color Yellow: Print " LOAD"
    Color Lime: Print "F2";: Color Gray: Print " .............";: Color Yellow: Print " NEW"
    Color Lime: Print "ENTER";: Color Gray: Print " .......";: Color Yellow: Print " CHOOSE"
    Color Lime: Print "ESC";: Color Gray: Print " ...........";: Color Yellow: Print " QUIT"

    ' Capture the rendered image
    Dim As Long imgMenu: imgMenu = NewImage(20 * 8, 4 * 16, 32)
    PutImage (0, 0), img, imgMenu ' all excess stuff will get clipped
    ClearColor Black, imgMenu ' set all black pixels to be transparent

    ' Do some cleanup
    Dest oldDest
    FreeImage img

    Shared FontSize As Vector2DType ' needed to check if a font is loaded

    Const STAR_COUNT = 1024 ' the maximum stars that we can show
    Dim As Single starX(1 To STAR_COUNT), starY(1 To STAR_COUNT), starZ(1 To STAR_COUNT)
    Dim As Unsigned Long starC(1 To STAR_COUNT)
    Dim As Long i, k
    Dim As Byte e

    Do
        Cls , Black ' clear the page

        For i = 1 To STAR_COUNT
            If starX(i) < 1 Or starX(i) >= Width Or starY(i) < 1 Or starY(i) >= Height Then
                starX(i) = RandomBetween(0, Width - 1)
                starY(i) = RandomBetween(0, Height - 1)
                starZ(i) = 4096
                starC(i) = RGB32(RandomBetween(64, 255), RandomBetween(64, 255), RandomBetween(64, 255))
            End If

            PSet (starX(i), starY(i)), starC(i)

            starZ(i) = starZ(i) + 0.25
            starX(i) = ((starX(i) - (Width / 2)) * (starZ(i) / 4096)) + (Width / 2)
            starY(i) = ((starY(i) - (Height / 2)) * (starZ(i) / 4096)) + (Height / 2)
        Next

        PutImage (0, 0), imgANSI
        PutImage (SCREEN_WIDTH \ 2 - Width(imgMenu) \ 2, SCREEN_HEIGHT \ 2 - Height(imgMenu) \ 2), imgMenu

        Limit 60
        Display

        k = KeyHit

        Select Case k
            Case KEY_F1
                e = EVENT_LOAD

            Case KEY_F2
                e = EVENT_NEW

            Case KEY_ENTER
                If FontSize.y > 0 Then e = EVENT_CHOOSE

            Case KEY_ESCAPE
                e = EVENT_QUIT

            Case Else
                e = EVENT_NONE
        End Select
    Loop While e = EVENT_NONE

    AutoDisplay

    ' Do some cleanup
    FreeImage imgMenu
    FreeImage imgANSI

    DoWelcomeScreen = e

    Data_vga_font_editor_logo_3_ans_3737:
    Data 3737,1064,-1
    Data eJyVV91t4zAMfi/QCfKi28Cpk/Yho2SAAgd4N0fr0LZWOYmk+CPZMU4BKomkyI9/knt5DtPnR7BjvjzH
    Data 4XH7mWJe/DxuwxT+Z/THnX7Lvj7GPEcAuDzFSiFnNiA1n4ZMW/IqS0IdyFhUKSC/cGIsqk4woJFJDpEZ
    Data D6HlMgRwg2CYg/5kPfv5YUXEyXGctiwwqqsr8joiVAKpSzgaIuvVs3K8WkeTX1ONNSNw22vH3THS0XaR
    Data 7MPznoHfssQOCtjxgBL63gshlLBcfZx7ElSKg6xja/hefmW/96AXrGfx5k1uCIUNHmPYw+hFoBB8/RdN
    Data XRO32FvfUPHwsKAOKqRNxqFPzL9jMu428h2B8N19bzY+3cvMx2y9B1Unvnhtazh1TxJ25E2e7ta3vPgm
    Data KIH+Yingwl4YQpTZK2qNNJDOUPCR72kTi6tBgtdGGXkOm8VFYhiSAzQUkWPjebo5KMZn465d+rsUWh3H
    Data kZFQvLOPpFEisfLlobnna3LBwfVTRVhg42DVwK2NxG36/fuHTFo0zVujiRn0Zq5QysFhSk0sKh+ZbFlO
    Data EHUTuZ3nxZos7fA1cTNgC9TdWiWTFzEp2TRvnLH1yJy4mNXcpNliLxedAD8geydEkBiHhs9GeZTn+dJ/
    Data 6dSx8DfHooPvEnzKeXO0lg1+C1w1S6jRPm1s4swb/IiAmOrACLFys6LHpjedEya2B/yLziVOL/KSY72F
    Data RIpJngzThWRCdXUB4QrWAEHcAwowm1KLrfEK7X0ikrOrH4gxvrL2Jf+ylRhSDyBHqUQ2YHmndJ4OJURY
    Data 0pIJdNT5ymIOldlYK67YXIQxW0lTNIXKtJJlieVht5IYUUNhSmgShTX7S20HOktXHZi8zCGTTJrmNss+
    Data zyGEpqxU9CAIZDsCoSvZiJiTF3/SVw1BXq4QeRXn2lBsBDtF2yPOvaGKYzF9Cfwe53yGQEvKLGhgIdkN
    Data F40a00KFtG9Uy940UpBOKrsFI99AAC5q7uq+Z41H9uaKr1d1H2+/18s7Dnqu7uU9Tj72kfFgZQP/kBTl
    Data cTRjr5G6DnozIv+79A8QGpjU
End Function


' Creates an empty font file
Function DoNewFont%%
    Shared FontSize As Vector2DType
    Dim ubFontHeight As Long

    ' Attempt to save the font if there is one
    DoNewFont = DoSaveFont

    ubFontHeight = Val(InputBox$(APP_NAME, "Enter new font height in pixels (8 - 32):", Str$(ubFontHeight)))

    If ubFontHeight < 8 Or ubFontHeight > 32 Then
        MessageBox APP_NAME, "Enter a valid font height!", "error"

        If FontSize.y <= 0 Then DoNewFont = EVENT_NONE
        Exit Function
    End If

    sFontFile = NULLSTRING
    Title APP_NAME + " - UNTITLED"
    SetFontHeight ubFontHeight
    ResizeClipboard
    bFontChanged = TRUE
End Function


' Handles and command line parameters
Function DoCommandLine%%
    ' Default to no event
    DoCommandLine = EVENT_NONE

    ' Check if any help is needed
    If Command$(1) = "/?" Or Command$(1) = "-?" Then
        MessageBox APP_NAME, APP_NAME + Chr$(13) + "Syntax: EDITFONT [fontfile.psf]" + Chr$(13) + "    /?: Shows this message" + String$(2, 13) + "Copyright (c) 1998-2022, Samuel Gomes" + String$(2, 13) + "https://github.com/a740g/", "info"
        DoCommandLine = EVENT_QUIT
        Exit Function ' Exit the function and allow the main loop to handle the quit event
    End If

    ' Fetch the file name from the command line
    sFontFile = Command$(1)

    If sFontFile <> NULLSTRING Then
        If FileExists(sFontFile) Then
            ' Read in the font
            If ReadFont(sFontFile, TRUE) Then
                Title APP_NAME + " - " + GetFileNameFromPath(sFontFile)
                ResizeClipboard
            Else
                MessageBox APP_NAME, "Failed to load " + sFontFile + "!", "error"
                sFontFile = NULLSTRING
            End If
        Else
            ' If this is a new file ask use for specs
            DoCommandLine = DoNewFont
        End If
    End If
End Function


' This is called when a font has to be loaded
Function DoLoadFont%%
    Shared FontSize As Vector2DType
    Dim tmpFilename As String

    ' Attempt to save the font if there is one
    DoLoadFont = DoSaveFont

    ' Get an existing font file name from the user
    tmpFilename = OpenFileDialog$(APP_NAME + ": Open", "", "*.psf|*.PSF|*.Psf", "PC Screen Font files")

    ' Exit if user canceled
    If tmpFilename = NULLSTRING Then
        If FontSize.y <= 0 Then DoLoadFont = EVENT_NONE ' Do nothing if no font file is loaded
        Exit Function
    End If

    ' Read in the font
    If ReadFont(tmpFilename, TRUE) Then
        sFontFile = tmpFilename
        Title APP_NAME + " - " + GetFileNameFromPath(sFontFile)
        ResizeClipboard
        bFontChanged = FALSE
    Else
        MessageBox APP_NAME, "Failed to load " + tmpFilename + "!", "error"
        DoLoadFont = EVENT_NONE
    End If
End Function


' This is called when the file should be saved
Function DoSaveFont%%
    ' Default to the character choose event
    DoSaveFont = EVENT_CHOOSE

    ' Only attempt to save if the font has changed
    If bFontChanged Then
        If sFontFile = NULLSTRING Then
            Dim tmpFilename As String

            ' Get a font file name from the user
            tmpFilename = SaveFileDialog$(APP_NAME + ": Save", "", "*.psf|*.PSF|*.Psf", "Font files")

            ' Exit if user canceled
            If tmpFilename = NULLSTRING Then Exit Function

            sFontFile = tmpFilename ' set the font filename
        Else
            ' Ask the user if they want to overwrite the current file
            If MessageBox(APP_NAME, "Font " + sFontFile + " has changed. Save it now?", "yesno", "question") = 0 Then Exit Function
        End If

        ' Save the font
        If WriteFont(sFontFile) Then
            bFontChanged = FALSE ' clear the font changed flag now
        Else
            MessageBox APP_NAME, "Failed to save " + sFontFile + "!", "error"
        End If
    End If
End Function


' This is the character selector routine
Function DoChooseCharacter%%
    Shared FontSize As Vector2DType
    Static xp As Long, yp As Long
    Dim refTime As Single, blinkState As Byte

    ' Save the current time
    refTime = Timer

    Cls , Black

    ' Show some info
    Color Aqua, Navy
    DrawTextBox 43, 1, 80, 30, "Controls"
    Color , Navy
    Locate 3, 47: Color Lime: Print "Left Arrow";: Color Gray: Print " ......... ";: Color White: Print "Move left";
    Locate 5, 47: Color Lime: Print "Right Arrow";: Color Gray: Print " ....... ";: Color White: Print "Move right";
    Locate 7, 47: Color Lime: Print "Up Arrow";: Color Gray: Print " ............. ";: Color White: Print "Move up";
    Locate 9, 47: Color Lime: Print "Down Arrow";: Color Gray: Print " ......... ";: Color White: Print "Move down";
    Locate 11, 47: Color Lime: Print "Mouse Pointer";: Color Gray: Print " ......... ";: Color White: Print "Select";
    Locate 13, 47: Color Lime: Print "Left Button";: Color Gray: Print " ... ";: Color White: Print "Edit character";
    Locate 15, 47: Color Lime: Print "Right Button";: Color Gray: Print " .. ";: Color White: Print "Edit character";
    Locate 17, 47: Color Lime: Print "Enter";: Color Gray: Print " ......... ";: Color White: Print "Edit character";
    Locate 19, 47: Color Lime: Print "F1";: Color Gray: Print " ................. ";: Color White: Print "Load font";
    Locate 21, 47: Color Lime: Print "F2";: Color Gray: Print " .................. ";: Color White: Print "New font";
    Locate 23, 47: Color Lime: Print "F9";: Color Gray: Print " ................. ";: Color White: Print "Save font";
    Locate 25, 47: Color Lime: Print "F5";: Color Gray: Print " .............. ";: Color White: Print "Show preview";
    Locate 27, 47: Color Lime: Print "Escape";: Color Gray: Print " ............. ";: Color White: Print "Main menu";

    ' Draw the main character set area
    Color White, Gray
    DrawTextBox 1, 1, 42, 30, "Select a character to edit"

    Dim As Long x, y

    ' Draw the characters
    Color Yellow, Navy
    For y = 0 To 7
        For x = 0 To 31
            DrawCharacter 32 * y + x, 9 + x * (FontSize.x + 2), 32 + y * (FontSize.y + 2)
        Next
    Next

    Dim in As Long

    ' Clear keyboard and mouse
    ClearInput

    Do
        If MouseInput Then
            If GetMouseOverCharPosiion(x, y) Then
                ' Turn off the current highlight
                DrawCharSelector xp, yp, Gray
                xp = x
                yp = y
                DrawCharSelector xp, yp, White

                ' Also check for mouse click
                If MouseButton(1) Or MouseButton(2) Then
                    ubFontCharacter = 32 * yp + xp
                    DoChooseCharacter = EVENT_EDIT
                    Exit Do
                End If
            End If
        Else
            Delay 0.01
        End If

        in = KeyHit

        Select Case in
            Case KEY_LEFT_ARROW
                DrawCharSelector xp, yp, Gray
                xp = xp - 1
                If xp < 0 Then xp = 31
                DrawCharSelector xp, yp, White

            Case KEY_RIGHT_ARROW
                DrawCharSelector xp, yp, Gray
                xp = xp + 1
                If xp > 31 Then xp = 0
                DrawCharSelector xp, yp, White

            Case KEY_UP_ARROW
                DrawCharSelector xp, yp, Gray
                yp = yp - 1
                If yp < 0 Then yp = 7
                DrawCharSelector xp, yp, White

            Case KEY_DOWN_ARROW
                DrawCharSelector xp, yp, Gray
                yp = yp + 1
                If yp > 7 Then yp = 0
                DrawCharSelector xp, yp, White

            Case KEY_ENTER
                ubFontCharacter = 32 * yp + xp
                DoChooseCharacter = EVENT_EDIT
                Exit Do

            Case KEY_F9
                DoChooseCharacter = EVENT_SAVE
                Exit Do

            Case KEY_F1
                DoChooseCharacter = EVENT_LOAD
                Exit Do

            Case KEY_F2
                DoChooseCharacter = EVENT_NEW
                Exit Do

            Case KEY_F5
                DoChooseCharacter = EVENT_PREVIEW
                Exit Do

            Case KEY_ESCAPE
                Dim e As Byte

                e = DoSaveFont
                DoChooseCharacter = EVENT_NONE
                Exit Do

            Case Else
                ' Blink the selector at regular intervals
                If Abs(Timer - refTime) > .3 Then
                    refTime = Timer
                    blinkState = Not blinkState

                    If blinkState Then
                        DrawCharSelector xp, yp, White
                    Else
                        DrawCharSelector xp, yp, Gray
                    End If
                End If
        End Select
    Loop
End Function


' This is font bitmap editor routine
Function DoEditCharacter%%
    Shared FontSize As Vector2DType
    Shared FontData() As String
    Dim refTime As Single, blinkState As Byte

    ' Save the current time
    refTime = Timer

    Cls , Black

    ' Show some info
    Color OrangeRed, Navy
    DrawTextBox 43, 1, 80, 30, "Controls"
    Color , Navy
    Locate 4, 47: Color Lime: Print "Left Arrow";: Color Gray: Print " ......... ";: Color White: Print "Move left"
    Locate 5, 47: Color Lime: Print "Right Arrow";: Color Gray: Print " ....... ";: Color White: Print "Move right"
    Locate 6, 47: Color Lime: Print "Up Arrow";: Color Gray: Print " ............. ";: Color White: Print "Move up"
    Locate 7, 47: Color Lime: Print "Down Arrow";: Color Gray: Print " ......... ";: Color White: Print "Move down"
    Locate 8, 47: Color Lime: Print "Mouse Pointer";: Color Gray: Print " ......... ";: Color White: Print "Select"
    Locate 9, 47: Color Lime: Print "Left Button";: Color Gray: Print " ......... ";: Color White: Print "Pixel on"
    Locate 10, 47: Color Lime: Print "Right Button";: Color Gray: Print " ....... ";: Color White: Print "Pixel off"
    Locate 11, 47: Color Lime: Print "Spacebar";: Color Gray: Print " ........ ";: Color White: Print "Toggle pixel"
    Locate 12, 47: Color Lime: Print "Delete";: Color Gray: Print " ................. ";: Color White: Print "Clear"
    Locate 13, 47: Color Lime: Print "Insert";: Color Gray: Print " .................. ";: Color White: Print "Fill"
    Locate 14, 47: Color Lime: Print "X";: Color Gray: Print " ........................ ";: Color White: Print "Cut"
    Locate 15, 47: Color Lime: Print "C";: Color Gray: Print " ....................... ";: Color White: Print "Copy"
    Locate 16, 47: Color Lime: Print "P";: Color Gray: Print " ...................... ";: Color White: Print "Paste"
    Locate 17, 47: Color Lime: Print "H";: Color Gray: Print " ............ ";: Color White: Print "Flip horizontal"
    Locate 18, 47: Color Lime: Print "V";: Color Gray: Print " .............. ";: Color White: Print "Flip vertical"
    Locate 19, 47: Color Lime: Print "I";: Color Gray: Print " ..................... ";: Color White: Print "Invert"
    Locate 20, 47: Color Lime: Print "A";: Color Gray: Print " ............ ";: Color White: Print "Horizontal line"
    Locate 21, 47: Color Lime: Print "W";: Color Gray: Print " .............. ";: Color White: Print "Vertical line"
    Locate 22, 47: Color Lime: Print "Home";: Color Gray: Print " .............. ";: Color White: Print "Slide left"
    Locate 23, 47: Color Lime: Print "End";: Color Gray: Print " .............. ";: Color White: Print "Slide right"
    Locate 24, 47: Color Lime: Print "Page Up";: Color Gray: Print " ............. ";: Color White: Print "Slide up"
    Locate 25, 47: Color Lime: Print "Page Down";: Color Gray: Print " ......... ";: Color White: Print "Slide down"
    Locate 26, 47: Color Lime: Print "Enter";: Color Gray: Print " .......... ";: Color White: Print "Save & return"
    Locate 27, 47: Color Lime: Print "Escape";: Color Gray: Print " ....... ";: Color White: Print "Cancel & return"

    ' Draw the main character set area
    Color White, Gray
    DrawTextBox 1, 1, 42, 30, Trim$(Str$(ubFontCharacter) + ": " + Chr$(ubFontCharacter))
    Locate 2, 27: Color Navy, Yellow: Print "Demonstration:";

    Dim cpy As String

    ' Save a copy of this character
    cpy = FontData(ubFontCharacter)

    ' Draw the initial bitmap
    DrawCharBitmap ubFontCharacter
    DrawDemo

    Dim As Long xp, yp, x, y
    Dim tmp As String, sl As Unsigned Byte
    Dim in As Long

    ' Clear keyboard and mouse
    ClearInput

    Do
        If MouseInput Then
            If GetMouseOverCellPosition(x, y) Then
                ' Turn off the current highlight
                DrawCellSelector xp, yp, Gray
                xp = x
                yp = y
                DrawCellSelector xp, yp, White

                ' Also check for mouse click
                If MouseButton(1) Then
                    ' Flag font changed
                    bFontChanged = TRUE

                    Asc(FontData(ubFontCharacter), yp + 1) = SetBit(Asc(FontData(ubFontCharacter), yp + 1), FontSize.x - xp - 1)
                End If

                If MouseButton(2) Then
                    ' Flag font changed
                    bFontChanged = TRUE

                    Asc(FontData(ubFontCharacter), yp + 1) = ResetBit(Asc(FontData(ubFontCharacter), yp + 1), FontSize.x - xp - 1)
                End If

                DrawCharBit ubFontCharacter, xp, yp
                DrawDemo
            End If
        Else
            Delay 0.01
        End If

        in = KeyHit

        Select Case in
            Case KEY_LEFT_ARROW ' Move left
                DrawCellSelector xp, yp, Gray
                xp = xp - 1
                If xp < 0 Then xp = FontSize.x - 1
                DrawCellSelector xp, yp, White

            Case KEY_RIGHT_ARROW ' Move right
                DrawCellSelector xp, yp, Gray
                xp = xp + 1
                If xp >= FontSize.x Then xp = 0
                DrawCellSelector xp, yp, White

            Case KEY_UP_ARROW ' Move up
                DrawCellSelector xp, yp, Gray
                yp = yp - 1
                If yp < 0 Then yp = FontSize.y - 1
                DrawCellSelector xp, yp, White

            Case KEY_DOWN_ARROW ' Move down
                DrawCellSelector xp, yp, Gray
                yp = yp + 1
                If yp >= FontSize.y Then yp = 0
                DrawCellSelector xp, yp, White

            Case KEY_SPACE_BAR ' Toggle pixel
                ' Flag font changed
                bFontChanged = TRUE

                Asc(FontData(ubFontCharacter), yp + 1) = ToggleBit(Asc(FontData(ubFontCharacter), yp + 1), FontSize.x - xp - 1)

                DrawCharBit ubFontCharacter, xp, yp
                DrawDemo

            Case KEY_DELETE ' Clear bitmap
                ' Flag font changed
                bFontChanged = TRUE

                FontData(ubFontCharacter) = String$(FontSize.y, NULL)

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KEY_INSERT ' Fill bitmap
                ' Flag font changed
                bFontChanged = TRUE

                FontData(ubFontCharacter) = String$(FontSize.y, 255)

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KEY_LOWER_X, KEY_UPPER_X ' Cut
                ' Flag font changed
                bFontChanged = TRUE

                sClipboard = FontData(ubFontCharacter)
                FontData(ubFontCharacter) = String$(FontSize.y, NULL)

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KEY_LOWER_C, KEY_UPPER_C ' Copy
                sClipboard = FontData(ubFontCharacter)

            Case KEY_LOWER_P, KEY_UPPER_P ' Paste
                ' Flag font changed
                bFontChanged = TRUE

                FontData(ubFontCharacter) = sClipboard

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KEY_LOWER_H, KEY_UPPER_H ' Horizontal flip
                ' Flag font changed
                bFontChanged = TRUE

                tmp = String$(FontSize.y, NULL)

                For y = 0 To FontSize.y - 1
                    For x = 0 To FontSize.x - 1
                        If ReadBit(Asc(FontData(ubFontCharacter), y + 1), FontSize.x - x - 1) Then
                            Asc(tmp, y + 1) = Asc(tmp, y + 1) + (2 ^ x)
                        End If
                    Next
                Next

                FontData(ubFontCharacter) = tmp

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KEY_LOWER_V, KEY_UPPER_V ' Vertical flip
                ' Flag font changed
                bFontChanged = TRUE

                tmp = FontData(ubFontCharacter)

                For y = 0 To FontSize.y - 1
                    Asc(FontData(ubFontCharacter), y + 1) = Asc(tmp, FontSize.y - y)
                Next

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KEY_LOWER_I, KEY_UPPER_I ' Invert
                ' Flag font changed
                bFontChanged = TRUE

                tmp = FontData(ubFontCharacter)

                For y = 0 To FontSize.y - 1
                    Asc(FontData(ubFontCharacter), y + 1) = 255 - Asc(tmp, y + 1)
                Next

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KEY_LOWER_A, KEY_UPPER_A ' Horizontal line
                ' Flag font changed
                bFontChanged = TRUE

                Asc(FontData(ubFontCharacter), yp + 1) = 255

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KEY_LOWER_L, KEY_UPPER_U ' Vertical line
                ' Flag font changed
                bFontChanged = TRUE

                For y = 0 To FontSize.y - 1
                    Asc(FontData(ubFontCharacter), y + 1) = SetBit(Asc(FontData(ubFontCharacter), y + 1), FontSize.x - xp - 1)
                Next

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KEY_HOME ' Slide left
                ' Flag font changed
                bFontChanged = TRUE

                For y = 0 To FontSize.y - 1
                    sl = Asc(FontData(ubFontCharacter), y + 1)
                    Asc(FontData(ubFontCharacter), y + 1) = RoL(sl, 1)
                Next

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KEY_END ' Slide right
                ' Flag font changed
                bFontChanged = TRUE

                For y = 0 To FontSize.y - 1
                    sl = Asc(FontData(ubFontCharacter), y + 1)
                    Asc(FontData(ubFontCharacter), y + 1) = RoR(sl, 1)
                Next

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KEY_PAGE_UP ' Slide up
                ' Flag font changed
                bFontChanged = TRUE

                tmp = FontData(ubFontCharacter)

                ' Shift scanlines up
                For y = 0 To FontSize.y - 2
                    Asc(tmp, y + 1) = Asc(tmp, y + 2)
                Next

                ' Set the last line
                Asc(tmp, FontSize.y) = Asc(FontData(ubFontCharacter), 1)

                FontData(ubFontCharacter) = tmp

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KEY_PAGE_DOWN ' Slide down
                ' Flag font changed
                bFontChanged = TRUE

                tmp = FontData(ubFontCharacter)

                ' Shift scanlines down
                For y = FontSize.y - 1 To 1 Step -1
                    Asc(tmp, y + 1) = Asc(tmp, y)
                Next

                ' Set the last line
                Asc(tmp, 1) = Asc(FontData(ubFontCharacter), FontSize.y)

                FontData(ubFontCharacter) = tmp

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KEY_ENTER ' Save & return
                DoEditCharacter = EVENT_CHOOSE

                Exit Do

            Case KEY_ESCAPE ' Cancel & return
                FontData(ubFontCharacter) = cpy

                DoEditCharacter = EVENT_CHOOSE

                Exit Do

            Case Else
                ' Blink the selector at regular intervals
                If Abs(Timer - refTime) > .3 Then
                    refTime = Timer
                    blinkState = Not blinkState

                    If blinkState Then
                        DrawCellSelector xp, yp, White
                    Else
                        DrawCellSelector xp, yp, Gray
                    End If
                End If
        End Select
    Loop
End Function


' Draws a preview screen using the loaded font
Function DoShowPreview%%
    Shared FontSize As Vector2DType

    Cls , Black

    ClearInput

    ' Draw a box on the screen
    Color Aqua, Navy
    DrawTextBox 1, 1, 80, 30, "Preview"

    ' Draw the body
    Color White, Navy
    DrawString "This Fox has a longing for grapes:", FontSize.x * 2, FontSize.y * 3
    DrawString "He jumps, but the bunch still escapes.", FontSize.x * 2, FontSize.y * 4
    DrawString "So he goes away sour;", FontSize.x * 2, FontSize.y * 5
    DrawString "And, 'tis said, to this hour", FontSize.x * 2, FontSize.y * 6
    DrawString "Declares that he's no taste for grapes.", FontSize.x * 2, FontSize.y * 7
    DrawString "     /\                   ,'|", FontSize.x * 45, FontSize.y * 3
    DrawString " o--'O `.                /  /", FontSize.x * 45, FontSize.y * 4
    DrawString "  `--.   `-----------._,' ,'", FontSize.x * 45, FontSize.y * 5
    DrawString "      \              ,---'", FontSize.x * 45, FontSize.y * 6
    DrawString "       ) )    _,--(  |", FontSize.x * 45, FontSize.y * 7
    DrawString "      /,^.---'     )/\\", FontSize.x * 45, FontSize.y * 8
    DrawString "     ((   \\      ((  \\", FontSize.x * 45, FontSize.y * 9
    DrawString "      \)   \)      \) (/", FontSize.x * 45, FontSize.y * 10

    WaitInput

    DoShowPreview = EVENT_CHOOSE
End Function


' Resizes the clipboard to match the font height
Sub ResizeClipboard
    Shared FontSize As Vector2DType

    sClipboard = Left$(sClipboard + String$(FontSize.y, NULL), FontSize.y)
End Sub


' Return true if mouse is over any character
' Updates mxp & myp with position
' This is used by the character chooser
Function GetMouseOverCharPosiion%% (mxp As Long, myp As Long)
    Shared FontSize As Vector2DType
    Dim As Long x, y

    GetMouseOverCharPosiion = FALSE

    For y = 0 To 7
        For x = 0 To 31
            If PointCollidesWithRect(MouseX, MouseY, 8 + x * (FontSize.x + 2), 31 + y * (FontSize.y + 2), 9 + FontSize.x + x * (FontSize.x + 2), 32 + FontSize.y + y * (FontSize.y + 2)) Then
                mxp = x
                myp = y
                GetMouseOverCharPosiion = TRUE
                Exit Function
            End If
        Next
    Next
End Function


' Draw the character selector using color c at xp, yp
Sub DrawCharSelector (xp As Long, yp As Long, c As Unsigned Long)
    Shared FontSize As Vector2DType

    Line (8 + xp * (FontSize.x + 2), 31 + yp * (FontSize.y + 2))-(9 + FontSize.x + xp * (FontSize.x + 2), 32 + FontSize.y + yp * (FontSize.y + 2)), c, B
End Sub


' Return true if mouse is over any cell
' Updates mxp & myp with position
' This is used by the bitmap editor
Function GetMouseOverCellPosition%% (mxp As Long, myp As Long)
    Shared FontSize As Vector2DType
    Dim As Long x, y

    GetMouseOverCellPosition = FALSE

    For y = 0 To FontSize.y - 1
        For x = 0 To FontSize.x - 1
            If PointCollidesWithRect(MouseX, MouseY, 8 + x * 14, 19 + y * 14, 22 + x * 14, 33 + y * 14) Then
                mxp = x
                myp = y
                GetMouseOverCellPosition = TRUE
                Exit Function
            End If
        Next
    Next
End Function


' Draw the character cell selector using color c at xe, ye
Sub DrawCellSelector (x As Long, y As Long, c As Unsigned Long)
    Line (8 + x * 14, 19 + y * 14)-(22 + x * 14, 33 + y * 14), c, B
End Sub


' This draws a single character pixel block
Sub DrawCharBit (ch As Unsigned Byte, x As Long, y As Long)
    Shared FontSize As Vector2DType
    Shared FontData() As String
    Dim As Long xp, yp

    xp = 9 + x * 14
    yp = 20 + y * 14
    If ReadBit(Asc(FontData(ch), y + 1), FontSize.x - x - 1) Then
        Line (xp, yp)-(xp + 12, yp + 12), Yellow, BF
    Else
        Line (xp, yp)-(xp + 12, yp + 12), Navy, BF
    End If
End Sub


' Draw the character bitmap for editing
Sub DrawCharBitmap (ch As Unsigned Byte)
    Shared FontSize As Vector2DType
    Dim As Long x, y

    For y = 0 To FontSize.y - 1
        For x = 0 To FontSize.x - 1
            DrawCharBit ch, x, y
        Next
    Next
End Sub


' This draws a grid of the same character for demo purpose on the edit screen
Sub DrawDemo
    Shared FontSize As Vector2DType
    Dim As Long x, y

    Color White, Black

    ' Draw the character on the right side using the font rending code
    For y = 32 To 32 + 12 * FontSize.y Step FontSize.y
        For x = 208 To 208 + 13 * FontSize.x Step FontSize.x
            DrawCharacter ubFontCharacter, x, y
        Next
    Next
End Sub


' Draw a box using box drawing characters and optionally puts a caption
Sub DrawTextBox (l As Long, t As Long, r As Long, b As Long, sCaption As String)
    Dim As Long i, inBoxWidth

    ' Calculate the "internal" box width
    inBoxWidth = r - l - 1

    ' Draw the top line
    Locate t, l: Print Chr$(218); String$(inBoxWidth, 196); Chr$(191);

    ' Draw the sides
    For i = t + 1 To b - 1
        Locate i, l: Print Chr$(179); Space$(inBoxWidth); Chr$(179);
    Next

    ' Draw the bottom line
    Locate b, l: Print Chr$(192); String$(inBoxWidth, 196); Chr$(217);

    ' Set the caption if specified
    If sCaption <> NULLSTRING Then
        Color BackgroundColor, DefaultColor
        Locate t, l + inBoxWidth \ 2 - Len(sCaption) \ 2
        Print " "; sCaption; " ";
        Color BackgroundColor, DefaultColor
    End If
End Sub


' Point & box collision test for mouse
Function PointCollidesWithRect%% (x As Long, y As Long, l As Long, t As Long, r As Long, b As Long)
    PointCollidesWithRect = (x >= l And x <= r And y >= t And y <= b)
End Function


' Sleeps until some keys or buttons are pressed
Sub WaitInput
    Do
        While MouseInput
            If MouseButton(1) Or MouseButton(2) Or MouseButton(3) Then Exit Do
        Wend
        Delay 0.01
    Loop While KeyHit <= NULL
End Sub


' Chear mouse and keyboard events
Sub ClearInput
    While MouseInput
    Wend
    KeyClear
End Sub


' Gets the filename portion from a file path
Function GetFileNameFromPath$ (pathName As String)
    Dim i As Unsigned Long

    ' Retrieve the position of the first / or \ in the parameter from the
    For i = Len(pathName) To 1 Step -1
        If Asc(pathName, i) = 47 Or Asc(pathName, i) = 92 Then Exit For
    Next

    ' Return the full string if pathsep was not found
    If i = 0 Then
        GetFileNameFromPath = pathName
    Else
        GetFileNameFromPath = Right$(pathName, Len(pathName) - i)
    End If
End Function

' Generates a random number between lo & hi
Function RandomBetween& (lo As Long, hi As Long)
    RandomBetween = lo + Rnd * (hi - lo)
End Function
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' MODULE FILES
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
'$Include:'./include/Base64.bas'
'$Include:'./include/ANSIPrint.bas'
'$Include:'./include/VGAFont.bas'
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
'---------------------------------------------------------------------------------------------------------------------------------------------------------------


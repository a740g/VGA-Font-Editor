'-----------------------------------------------------------------------------------------------------
'
' VGA font editor
' Copyright (c) 1998-2022, Samuel Gomes
' Compiles with QB64 for Windows
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
$ExeIcon:'.\VGAFontEditor.ico'
$VersionInfo:CompanyName='Samuel Gomes'
$VersionInfo:FileDescription='VGA Font Editor executable'
$VersionInfo:InternalName='VGAFontEditor'
$VersionInfo:LegalCopyright='Copyright (c) 1998-2022, Samuel Gomes'
$VersionInfo:LegalTrademarks='All trademarks are property of their respective owners'
$VersionInfo:OriginalFilename='VGAFontEditor.exe'
$VersionInfo:ProductName='VGA Font Editor'
$VersionInfo:Web='https://github.com/a740g'
$VersionInfo:Comments='https://github.com/a740g'
$VersionInfo:FILEVERSION#=4,0,0,0
$VersionInfo:ProductVersion=4,0,0,0
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' CONSTANTS
'-----------------------------------------------------------------------------------------------------
' App name
Const APP_NAME = "VGA Font Editor"

'MessageBox Constant values as defined by Microsoft (MBType)
Const MB_OK = 0 'OK button only
Const MB_OKCANCEL = 1 'OK & Cancel
Const MB_ABORTRETRYIGNORE = 2 'Abort, Retry & Ignore
Const MB_YESNOCANCEL = 3 'Yes, No & Cancel
Const MB_YESNO = 4 'Yes & No
Const MB_RETRYCANCEL = 5 'Retry & Cancel
Const MB_CANCELTRYCONTINUE = 6 'Cancel, Try Again & Continue
Const MB_ICONSTOP = 16 'Error stop sign icon
Const MB_ICONQUESTION = 32 'Question-mark icon
Const MB_ICONEXCLAMATION = 48 'Exclamation-point icon
Const MB_ICONINFORMATION = 64 'Letter i in a circle icon
Const MB_DEFBUTTON1 = 0 '1st button default(left)
Const MB_DEFBUTTON2 = 256 '2nd button default
Const MB_DEFBUTTON3 = 512 '3rd button default(right)
Const MB_APPLMODAL = 0 'Message box applies to application only
Const MB_SYSTEMMODAL = 4096 'Message box on top of all other windows
Const MB_SETFOCUS = 65536 'Set message box as focus

' Return values from MessageBox
Const ID_OK = 1 'OK button pressed
Const ID_CANCEL = 2 'Cancel button pressed
Const ID_ABORT = 3 'Abort button pressed
Const ID_RETRY = 4 'Retry button pressed
Const ID_IGNORE = 5 'Ignore button pressed
Const ID_YES = 6 'Yes button pressed
Const ID_NO = 7 'No button pressed
Const ID_TRYAGAIN = 10 'Try again button pressed
Const ID_CONTINUE = 1 'Continue button pressed

' Dialog flag constants (use + or OR to use more than 1 flag value)
Const OFN_ALLOWMULTISELECT = &H200 ' Allows the user to select more than one file, not recommended!
Const OFN_CREATEPROMPT = &H2000 ' Prompts if a file not found should be created(GetOpenFileName only).
Const OFN_EXTENSIONDIFFERENT = &H400 ' Allows user to specify file extension other than default extension.
Const OFN_FILEMUSTEXIST = &H1000 ' Chechs File name exists(GetOpenFileName only).
Const OFN_HIDEREADONLY = &H4 ' Hides read-only checkbox(GetOpenFileName only)
Const OFN_NOCHANGEDIR = &H8 ' Restores the current directory to original value if user changed
Const OFN_NODEREFERENCELINKS = &H100000 ' Returns path and file name of selected shortcut(.LNK) file instead of file referenced.
Const OFN_NONETWORKBUTTON = &H20000 ' Hides and disables the Network button.
Const OFN_NOREADONLYRETURN = &H8000 ' Prevents selection of read-only files, or files in read-only subdirectory.
Const OFN_NOVALIDATE = &H100 ' Allows invalid file name characters.
Const OFN_OVERWRITEPROMPT = &H2 ' Prompts if file already exists(GetSaveFileName only)
Const OFN_PATHMUSTEXIST = &H800 ' Checks Path name exists (set with OFN_FILEMUSTEXIST).
Const OFN_READONLY = &H1 ' Checks read-only checkbox. Returns if checkbox is checked
Const OFN_SHAREAWARE = &H4000 ' Ignores sharing violations in networking
Const OFN_SHOWHELP = &H10 ' Shows the help button (useless!)

Const MAX_PATH = 4096 ' Max path name size

' Keyboard codes
Const KB_ESC = 27
Const KB_ENTER = 13
Const KB_SPACE = 32
Const KB_DELETE = 21248
Const KB_INSERT = 20992
Const KB_HOME = 18176
Const KB_END = 20224
Const KB_PAGEUP = 18688
Const KB_PAGEDOWN = 20736
Const KB_F1 = 15104
Const KB_F5 = 16128
Const KB_F9 = 17152
Const KB_UP = 18432
Const KB_DOWN = 20480
Const KB_LEFT = 19200
Const KB_RIGHT = 19712
Const KB_XL = 120
Const KB_XU = 88
Const KB_CL = 99
Const KB_CU = 67
Const KB_PL = 112
Const KB_PU = 80
Const KB_HL = 104
Const KB_HU = 72
Const KB_VL = 118
Const KB_VU = 86
Const KB_IL = 105
Const KB_IU = 73
Const KB_WL = 119
Const KB_WU = 87
Const KB_AL = 97
Const KB_AU = 65

' Program events
Const EVENT_QUIT = 0
Const EVENT_SAVE = 1
Const EVENT_LOAD = 2
Const EVENT_CHOOSE = 3
Const EVENT_EDIT = 4
Const EVENT_PREVIEW = 5
Const EVENT_COMMAND = 6
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' USER DEFINED TYPES
'-----------------------------------------------------------------------------------------------------
Type FileDialogType
    lStructSize As Offset '      For the DLL call
    hwndOwner As Offset '        Dialog will hide behind window when not set correctly
    hInstance As Offset '        Handle to a module that contains a dialog box template.
    lpstrFilter As Offset '      Pointer of the string of file filters
    lpstrCustFilter As Long
    nMaxCustFilter As Long
    nFilterIndex As Integer64 '  One based starting filter index to use when dialog is called
    lpstrFile As Offset '        String full of 0's for the selected file name
    nMaxFile As Offset '         Maximum length of the string stuffed with 0's minus 1
    lpstrFileTitle As Offset '   Same as lpstrFile
    nMaxFileTitle As Offset '    Same as nMaxFile
    lpstrInitialDir As Offset '  Starting directory
    lpstrTitle As Offset '       Dialog title
    flags As Integer64 '         Dialog flags
    nFileOffset As Integer64 '   Zero-based offset from path beginning to file name string pointed to by lpstrFile
    nFileExtension As Integer64 'Zero-based offset from path beginning to file extension string pointed to by lpstrFile.
    lpstrDefExt As Offset '      Default/selected file extension
    lCustData As Integer64
    lpfnHook As Integer64
    lpTemplateName As Offset
End Type
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' LIBRARY FUCTIONS
'-----------------------------------------------------------------------------------------------------
Declare Dynamic Library "user32"
    Function MessageBoxA& (ByVal oHWnd As Offset, sMessage As String, sTitle As String, Byval ulMBType As Unsigned Long)
End Declare

Declare Dynamic Library "comdlg32"
    Function GetOpenFileNameA& (DialogParams As FileDialogType)
    Function GetSaveFileNameA& (DialogParams As FileDialogType)
End Declare
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' GLOBAL VARIABLES
'-----------------------------------------------------------------------------------------------------
Dim Shared sFontFile As String ' The name of the font file we are viewing / editing
Dim Shared ubFontCharacter As Unsigned Byte ' The glyph we are editing
Dim Shared bFontChanged As Byte ' Has the font changed
Dim Shared sClipboard As String ' The is the clipboard
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT
'-----------------------------------------------------------------------------------------------------
ChDir StartDir$ ' Change to the directory specifed by the environment
ControlChr Off ' Turn off control characters
Screen 12 ' Change to graphics mode
Title APP_NAME ' Set app title
AllowFullScreen SquarePixels , Smooth ' Allow the program window to run fullscreen with Alt+Enter

Dim Event As Byte

' Default's to command line event on program entry
Event = EVENT_COMMAND

' Event loop
Do
    Select Case Event
        Case EVENT_COMMAND
            Event = DoCommandLine

        Case EVENT_LOAD
            Event = LoadVGAFont

        Case EVENT_SAVE
            Event = SaveVGAFont

        Case EVENT_CHOOSE
            Event = ChooseCharacter

        Case EVENT_EDIT
            Event = EditCharacter

        Case EVENT_PREVIEW
            Event = ShowPreview

        Case EVENT_QUIT
            If bFontChanged Then
                ' Attempt to save the changes
                Event = SaveVGAFont

                ' Check the user really wants to quit
                If MsgBox("Are you sure you want to quit?", APP_NAME, MB_YESNO Or MB_DEFBUTTON2 Or MB_APPLMODAL Or MB_SETFOCUS) = ID_YES Then
                    Exit Do
                End If
            Else
                Exit Do
            End If

        Case Else
            ShowCriticalMsgBox "Unhandled program event!"
            Exit Do
    End Select
Loop

System
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' FUNCTIONS AND SUBROUTINES
'-----------------------------------------------------------------------------------------------------
' Handles and command line parameters
Function DoCommandLine%%
    Dim i As Long

    ' Default to the character choose event
    DoCommandLine = EVENT_CHOOSE

    ' Check if any help is needed
    If ArgVPresent("?", 1) Then
        i = MsgBox(APP_NAME + Chr$(13) + "Syntax: EDITFONT [fontfile.psf]" + Chr$(13) + "    /?: Shows this message" + String$(2, 13) + "Copyright (c) 1998-2022, Samuel Gomes" + String$(2, 13) + "https://github.com/a740g/", APP_NAME, MB_OK Or MB_ICONINFORMATION Or MB_SETFOCUS Or MB_APPLMODAL)
        DoCommandLine = EVENT_QUIT
        Exit Function ' Exit the function and allow the main loop to handle the quit event
    End If

    ' Fetch the file name from the command line
    sFontFile = Command$(1)

    If sFontFile = NULLSTRING Then
        ' Trigger the load event if no file name was specified
        DoCommandLine = EVENT_LOAD
    Else
        If FileExists(sFontFile) Then
            ' Read in the font
            If ReadFont(sFontFile, TRUE) Then
                Title APP_NAME + " - " + GetFileNameFromPath(sFontFile)
                ResizeClipboard
            Else
                ShowCriticalMsgBox "Failed to load " + sFontFile + "!"
                sFontFile = NULLSTRING
                ' Trigger the load event if no file name was specified
                DoCommandLine = EVENT_LOAD
            End If
        Else
            ' If this is a new file ask use for specs
            Dim ubFontHeight As Long
            Do
                Print
                Input ; "Enter new font height in pixels (8 - 32): ", ubFontHeight
            Loop While ubFontHeight < 8 Or ubFontHeight > 32
            SetFontHeight ubFontHeight
        End If
    End If
End Function


' This is called when a font has to loaded
Function LoadVGAFont%%
    Dim tmpFilename As String

    ' Default to the character choose event
    LoadVGAFont = EVENT_CHOOSE

    ' Get an existing font file name from the user
    tmpFilename = GetFileNameDialog(FALSE, NULLSTRING, NULLSTRING, "Font files (*.psf)|*.PSF|All files (*.*)|*.*", 1, OFN_FILEMUSTEXIST)

    ' Exit if user canceled
    If tmpFilename = NULLSTRING Then
        If FontSize.y <= 0 Then LoadVGAFont = EVENT_QUIT ' Exit if 1st time
        Exit Function
    End If

    ' Read in the font
    If ReadFont(tmpFilename, TRUE) Then
        sFontFile = tmpFilename
        Title APP_NAME + " - " + GetFileNameFromPath(sFontFile)
        ResizeClipboard
        bFontChanged = FALSE
    Else
        ShowCriticalMsgBox "Failed to load " + tmpFilename + "!"
        LoadVGAFont = EVENT_LOAD
    End If
End Function


' This is called when the file should be saved
Function SaveVGAFont%%
    Dim tmpFilename As String

    ' Default to the charcter choose event
    SaveVGAFont = EVENT_CHOOSE

    If sFontFile = NULLSTRING Then
        ' Get a font file name from the user
        tmpFilename = GetFileNameDialog(TRUE, NULLSTRING, NULLSTRING, "Font files (*.psf)|*.PSF|All files (*.*)|*.*", 1, OFN_OVERWRITEPROMPT)

        ' Exit if user canceled
        If tmpFilename = NULLSTRING Then Exit Function
    Else
        ' Ask the user if they want to overwrite the current file
        If MsgBox("Font " + sFontFile + " has changed. Save it now?", APP_NAME, MB_YESNO Or MB_DEFBUTTON1 Or MB_APPLMODAL Or MB_SETFOCUS) = ID_YES Then
            tmpFilename = sFontFile
        Else
            Exit Function
        End If
    End If

    ' Save the font
    If WriteFont(tmpFilename) Then
        sFontFile = tmpFilename
        bFontChanged = FALSE
    Else
        ShowCriticalMsgBox "Failed to save " + tmpFilename + "!"
    End If
End Function


' This is the character selector routine
Function ChooseCharacter%%
    Static xp As Long, yp As Long
    Dim refTime As Single, blinkState As Byte

    ' Save the current time
    refTime = Timer

    Cls

    ' Show some info
    Color 11, 1
    DrawFancyBox 43, 1, 80, 30, " Controls ", FALSE
    Color , 1
    Locate 4, 47: Color 10: Print "Left Arrow";: Color 8: Print " ......... ";: Color 15: Print "Move left";
    Locate 6, 47: Color 10: Print "Right Arrow";: Color 8: Print " ....... ";: Color 15: Print "Move right";
    Locate 8, 47: Color 10: Print "Up Arrow";: Color 8: Print " ............. ";: Color 15: Print "Move up";
    Locate 10, 47: Color 10: Print "Down Arrow";: Color 8: Print " ......... ";: Color 15: Print "Move down";
    Locate 12, 47: Color 10: Print "Mouse Pointer";: Color 8: Print " ......... ";: Color 15: Print "Select";
    Locate 14, 47: Color 10: Print "Left Button";: Color 8: Print " ... ";: Color 15: Print "Edit character";
    Locate 16, 47: Color 10: Print "Right Button";: Color 8: Print " .. ";: Color 15: Print "Edit character";
    Locate 18, 47: Color 10: Print "Enter";: Color 8: Print " ......... ";: Color 15: Print "Edit character";
    Locate 20, 47: Color 10: Print "F1";: Color 8: Print " ................. ";: Color 15: Print "Load font";
    Locate 22, 47: Color 10: Print "F9";: Color 8: Print " ................. ";: Color 15: Print "Save font";
    Locate 24, 47: Color 10: Print "F5";: Color 8: Print " .............. ";: Color 15: Print "Show preview";
    Locate 26, 47: Color 10: Print "Escape";: Color 8: Print " .................. ";: Color 15: Print "Quit";

    ' Draw the main character set area
    Color 15, 8
    DrawFancyBox 1, 1, 42, 30, " Select a character to edit ", FALSE

    Dim As Long x, y

    ' Draw the characters
    Color 14, 1
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
                DrawCharSelector xp, yp, 8
                xp = x
                yp = y
                DrawCharSelector xp, yp, 15

                ' Also check for mouse click
                If MouseButton(1) Or MouseButton(2) Then
                    ubFontCharacter = 32 * yp + xp
                    ChooseCharacter = EVENT_EDIT
                    Exit Do
                End If
            End If
        Else
            Delay 0.01
        End If

        in = KeyHit

        Select Case in
            Case KB_LEFT
                DrawCharSelector xp, yp, 8
                xp = xp - 1
                If xp < 0 Then xp = 31
                DrawCharSelector xp, yp, 15

            Case KB_RIGHT
                DrawCharSelector xp, yp, 8
                xp = xp + 1
                If xp > 31 Then xp = 0
                DrawCharSelector xp, yp, 15

            Case KB_UP
                DrawCharSelector xp, yp, 8
                yp = yp - 1
                If yp < 0 Then yp = 7
                DrawCharSelector xp, yp, 15

            Case KB_DOWN
                DrawCharSelector xp, yp, 8
                yp = yp + 1
                If yp > 7 Then yp = 0
                DrawCharSelector xp, yp, 15

            Case KB_ENTER
                ubFontCharacter = 32 * yp + xp
                ChooseCharacter = EVENT_EDIT
                Exit Do

            Case KB_F9
                ChooseCharacter = EVENT_SAVE
                Exit Do

            Case KB_F1
                ChooseCharacter = EVENT_LOAD
                Exit Do

            Case KB_F5
                ChooseCharacter = EVENT_PREVIEW
                Exit Do

            Case KB_ESC
                ChooseCharacter = EVENT_QUIT
                Exit Do

            Case Else
                ' Blink the selector at regular intervals
                If Abs(Timer - refTime) > .3 Then
                    refTime = Timer
                    blinkState = Not blinkState

                    If blinkState Then
                        DrawCharSelector xp, yp, 15
                    Else
                        DrawCharSelector xp, yp, 8
                    End If
                End If
        End Select
    Loop
End Function


' This is font bitmap editor routine
Function EditCharacter%%
    Dim refTime As Single, blinkState As Byte

    ' Save the current time
    refTime = Timer

    Cls

    ' Show some info
    Color 11, 1
    DrawFancyBox 43, 1, 80, 30, " Controls ", FALSE
    Color , 1
    Locate 4, 47: Color 10: Print "Left Arrow";: Color 8: Print " ......... ";: Color 15: Print "Move left"
    Locate 5, 47: Color 10: Print "Right Arrow";: Color 8: Print " ....... ";: Color 15: Print "Move right"
    Locate 6, 47: Color 10: Print "Up Arrow";: Color 8: Print " ............. ";: Color 15: Print "Move up"
    Locate 7, 47: Color 10: Print "Down Arrow";: Color 8: Print " ......... ";: Color 15: Print "Move down"
    Locate 8, 47: Color 10: Print "Mouse Pointer";: Color 8: Print " ......... ";: Color 15: Print "Select"
    Locate 9, 47: Color 10: Print "Left Button";: Color 8: Print " ......... ";: Color 15: Print "Pixel on"
    Locate 10, 47: Color 10: Print "Right Button";: Color 8: Print " ....... ";: Color 15: Print "Pixel off"
    Locate 11, 47: Color 10: Print "Spacebar";: Color 8: Print " ........ ";: Color 15: Print "Toggle pixel"
    Locate 12, 47: Color 10: Print "Delete";: Color 8: Print " ................. ";: Color 15: Print "Clear"
    Locate 13, 47: Color 10: Print "Insert";: Color 8: Print " .................. ";: Color 15: Print "Fill"
    Locate 14, 47: Color 10: Print "X";: Color 8: Print " ........................ ";: Color 15: Print "Cut"
    Locate 15, 47: Color 10: Print "C";: Color 8: Print " ....................... ";: Color 15: Print "Copy"
    Locate 16, 47: Color 10: Print "P";: Color 8: Print " ...................... ";: Color 15: Print "Paste"
    Locate 17, 47: Color 10: Print "H";: Color 8: Print " ............ ";: Color 15: Print "Flip horizontal"
    Locate 18, 47: Color 10: Print "V";: Color 8: Print " .............. ";: Color 15: Print "Flip vertical"
    Locate 19, 47: Color 10: Print "I";: Color 8: Print " ..................... ";: Color 15: Print "Invert"
    Locate 20, 47: Color 10: Print "A";: Color 8: Print " ............ ";: Color 15: Print "Horizontal line"
    Locate 21, 47: Color 10: Print "W";: Color 8: Print " .............. ";: Color 15: Print "Vertical line"
    Locate 22, 47: Color 10: Print "Home";: Color 8: Print " .............. ";: Color 15: Print "Slide left"
    Locate 23, 47: Color 10: Print "End";: Color 8: Print " .............. ";: Color 15: Print "Slide right"
    Locate 24, 47: Color 10: Print "Page Up";: Color 8: Print " ............. ";: Color 15: Print "Slide up"
    Locate 25, 47: Color 10: Print "Page Down";: Color 8: Print " ......... ";: Color 15: Print "Slide down"
    Locate 26, 47: Color 10: Print "Enter";: Color 8: Print " .......... ";: Color 15: Print "Save & return"
    Locate 27, 47: Color 10: Print "Escape";: Color 8: Print " ....... ";: Color 15: Print "Cancel & return"

    ' Draw the main character set area
    Color 15, 8
    DrawFancyBox 1, 1, 42, 30, Str$(ubFontCharacter) + ": " + Chr$(ubFontCharacter) + " ", FALSE
    Locate 2, 27: Color 1, 14: Print "Demonstration:";

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
                DrawCellSelector xp, yp, 8
                xp = x
                yp = y
                DrawCellSelector xp, yp, 15

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
            Case KB_LEFT ' Move left
                DrawCellSelector xp, yp, 8
                xp = xp - 1
                If xp < 0 Then xp = FontSize.x - 1
                DrawCellSelector xp, yp, 15

            Case KB_RIGHT ' Move right
                DrawCellSelector xp, yp, 8
                xp = xp + 1
                If xp >= FontSize.x Then xp = 0
                DrawCellSelector xp, yp, 15

            Case KB_UP ' Move up
                DrawCellSelector xp, yp, 8
                yp = yp - 1
                If yp < 0 Then yp = FontSize.y - 1
                DrawCellSelector xp, yp, 15

            Case KB_DOWN ' Move down
                DrawCellSelector xp, yp, 8
                yp = yp + 1
                If yp >= FontSize.y Then yp = 0
                DrawCellSelector xp, yp, 15

            Case KB_SPACE ' Toggle pixel
                ' Flag font changed
                bFontChanged = TRUE

                Asc(FontData(ubFontCharacter), yp + 1) = ToggleBit(Asc(FontData(ubFontCharacter), yp + 1), FontSize.x - xp - 1)

                DrawCharBit ubFontCharacter, xp, yp
                DrawDemo

            Case KB_DELETE ' Clear bitmap
                ' Flag font changed
                bFontChanged = TRUE

                FontData(ubFontCharacter) = String$(FontSize.y, NULL)

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KB_INSERT ' Fill bitmap
                ' Flag font changed
                bFontChanged = TRUE

                FontData(ubFontCharacter) = String$(FontSize.y, 255)

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KB_XL, KB_XU ' Cut
                ' Flag font changed
                bFontChanged = TRUE

                sClipboard = FontData(ubFontCharacter)
                FontData(ubFontCharacter) = String$(FontSize.y, NULL)

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KB_CL, KB_CU ' Copy
                sClipboard = FontData(ubFontCharacter)

            Case KB_PL, KB_PU ' Paste
                ' Flag font changed
                bFontChanged = TRUE

                FontData(ubFontCharacter) = sClipboard

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KB_HL, KB_HU ' Horizontal flip
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

            Case KB_VL, KB_VU ' Vertical flip
                ' Flag font changed
                bFontChanged = TRUE

                tmp = FontData(ubFontCharacter)

                For y = 0 To FontSize.y - 1
                    Asc(FontData(ubFontCharacter), y + 1) = Asc(tmp, FontSize.y - y)
                Next

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KB_IL, KB_IU ' Invert
                ' Flag font changed
                bFontChanged = TRUE

                tmp = FontData(ubFontCharacter)

                For y = 0 To FontSize.y - 1
                    Asc(FontData(ubFontCharacter), y + 1) = 255 - Asc(tmp, y + 1)
                Next

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KB_AL, KB_AU ' Horizontal line
                ' Flag font changed
                bFontChanged = TRUE

                Asc(FontData(ubFontCharacter), yp + 1) = 255

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KB_WL, KB_WU ' Vertical line
                ' Flag font changed
                bFontChanged = TRUE

                For y = 0 To FontSize.y - 1
                    Asc(FontData(ubFontCharacter), y + 1) = SetBit(Asc(FontData(ubFontCharacter), y + 1), FontSize.x - xp - 1)
                Next

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KB_HOME ' Slide left
                ' Flag font changed
                bFontChanged = TRUE

                For y = 0 To FontSize.y - 1
                    sl = Asc(FontData(ubFontCharacter), y + 1)
                    sl = SHL(sl, 1) Or SHR(sl, 7)
                    Asc(FontData(ubFontCharacter), y + 1) = sl
                Next

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KB_END ' Slide right
                ' Flag font changed
                bFontChanged = TRUE

                For y = 0 To FontSize.y - 1
                    sl = Asc(FontData(ubFontCharacter), y + 1)
                    sl = SHR(sl, 1) Or SHL(sl, 7)
                    Asc(FontData(ubFontCharacter), y + 1) = sl
                Next

                DrawCharBitmap ubFontCharacter
                DrawDemo

            Case KB_PAGEUP ' Slide up
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

            Case KB_PAGEDOWN ' Slide down
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

            Case KB_ENTER ' Save & return
                EditCharacter = EVENT_CHOOSE

                Exit Do

            Case KB_ESC ' Cancel & return
                FontData(ubFontCharacter) = cpy

                EditCharacter = EVENT_CHOOSE

                Exit Do

            Case Else
                ' Blink the selector at regular intervals
                If Abs(Timer - refTime) > .3 Then
                    refTime = Timer
                    blinkState = Not blinkState

                    If blinkState Then
                        DrawCellSelector xp, yp, 15
                    Else
                        DrawCellSelector xp, yp, 8
                    End If
                End If
        End Select
    Loop
End Function


' Draws a preview screen using the loaded font
Function ShowPreview%%
    Cls

    ClearInput

    ' Draw a box on the screen
    Color 11, 1
    DrawFancyBox 1, 1, 80, 30, " FONT  DEMO ", FALSE

    ' Draw the body
    Color 15, 1
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

    ShowPreview = EVENT_CHOOSE
End Function


' Resizes the clipboard to match the font height
Sub ResizeClipboard
    sClipboard = Left$(sClipboard + String$(FontSize.y, NULL), FontSize.y)
End Sub


' Return true if mouse is over any character
' Updates mxp & myp with position
' This is used by the character chooser
Function GetMouseOverCharPosiion%% (mxp As Long, myp As Long)
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
    Line (8 + xp * (FontSize.x + 2), 31 + yp * (FontSize.y + 2))-(9 + FontSize.x + xp * (FontSize.x + 2), 32 + FontSize.y + yp * (FontSize.y + 2)), c, B
End Sub


' Return true if mouse is over any cell
' Updates mxp & myp with position
' This is used by the bitmap editor
Function GetMouseOverCellPosition%% (mxp As Long, myp As Long)
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
    Dim As Long xp, yp

    xp = 9 + x * 14
    yp = 20 + y * 14
    If ReadBit(Asc(FontData(ch), y + 1), FontSize.x - x - 1) Then
        Line (xp, yp)-(xp + 12, yp + 12), 14, BF
    Else
        Line (xp, yp)-(xp + 12, yp + 12), 1, BF
    End If
End Sub


' Draw the character bitmap for editing
Sub DrawCharBitmap (ch As Unsigned Byte)
    Dim As Long x, y

    For y = 0 To FontSize.y - 1
        For x = 0 To FontSize.x - 1
            DrawCharBit ch, x, y
        Next
    Next
End Sub


Sub DrawDemo
    Dim As Long x, y

    Color 15, 0

    ' Draw the character on the right side using the font rending code
    For y = 32 To 32 + 12 * FontSize.y Step FontSize.y
        For x = 208 To 208 + 13 * FontSize.x Step FontSize.x
            DrawCharacter ubFontCharacter, x, y
        Next
    Next
End Sub

' Draw a box using box drawing characters and optionally puts a caption
Sub DrawFancyBox (l As Long, t As Long, r As Long, b As Long, sCaption As String, noBorders As Byte)
    Dim i As Long, buffer As String

    If noBorders Then
        ' Calculate and create the border as string
        buffer = String$(1 + r - l, 32)

        ' Draw the whole box from top to bottom
        For i = t To b
            Locate i, l: Print buffer;
        Next
    Else
        ' Calculate and create the border as string
        buffer = String$(r - l - 1, 196)

        ' Draw the top & bottom borders
        Locate t, l + 1: Print buffer;
        Locate b, l + 1: Print buffer;

        ' Calculate and create the space in between the left & right edge
        buffer = String$(r - l - 1, 32)

        ' Draw the left border, right border & space in between
        For i = t + 1 To b - 1
            Locate i, l: Print Chr$(179); buffer; Chr$(179);
        Next

        ' Now draw the edges
        Locate t, l: Print Chr$(218);
        Locate t, r: Print Chr$(191);
        Locate b, l: Print Chr$(192);
        Locate b, r: Print Chr$(217);
    End If

    ' Set the caption if specified
    If sCaption <> NULLSTRING Then
        Color BackgroundColor, DefaultColor
        Locate t, l + (1 + r - l) / 2 - Len(sCaption) / 2
        Print sCaption;
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


' Check if an argument is present in the command line
Function ArgVPresent%% (argv As String, start As Long)
    Dim argc As Long
    Dim As String a, b

    argc = start
    b = UCase$(argv)
    Do
        a = UCase$(Command$(argc))
        If Len(a) = 0 Then Exit Do

        If a = "/" + b Or a = "-" + b Then
            ArgVPresent = TRUE
            Exit Function
        End If

        argc = argc + 1
    Loop

    ArgVPresent = FALSE
End Function


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


' Returns a BASIC string (bstring) from zero terminated C string (cstring)
Function CStrToBStr$ (cStr As String)
    Dim zeroPos As Long

    CStrToBStr = cStr
    zeroPos = InStr(cStr, Chr$(NULL))
    If zeroPos > 0 Then CStrToBStr = Left$(cStr, zeroPos - 1)
End Function


' Critical message box. This does not terminate the program!
Sub ShowCriticalMsgBox (sMessage As String)
    Dim i As Long
    i = MsgBox(sMessage, APP_NAME, MB_OK Or MB_ICONSTOP Or MB_SETFOCUS Or MB_APPLMODAL)
End Sub


' Shows the shadard windows message box
Function MsgBox& (sMessage As String, sTitle As String, BoxType As Long)
    MsgBox = MessageBoxA(WindowHandle, sMessage + Chr$(NULL), sTitle + Chr$(NULL), BoxType)
End Function


'  sTitle       - The dialog title
'  sInitialDir  - If this left blank, it will use the directory where the last opened file is located. Specify ".\" if you want to always use the current directory
'  sFilter      - File filters separated by pipes (|) in the same format as VB6 common dialogs
'  lFilterIndex - The initial file filter to use. Will be altered by user during the call
'  llFlags      - Dialog flags. Will be altered by the user during the call
'
' Returns: Blank when cancel is clicked, otherwise the file name selected by the user
' lFilterIndex and llFlags will be changed depending on the user's selections
Function GetFileNameDialog$ (isSave As Byte, sTitle As String, sInitialDir As String, sFilter As String, lFilterIndex As Integer64, llFlags As Integer64)
    Dim OSFN As FileDialogType

    ' Set the struct size
    OSFN.lStructSize = Len(OSFN)

    ' Set the parent window
    OSFN.hwndOwner = WindowHandle

    ' Set the file filters
    Dim fFilter As String
    If sFilter <> NULLSTRING Then
        fFilter = sFilter + Chr$(NULL)
        ' Replace the pipes with character zero and then zero terminate filter string
        Dim r As Unsigned Long
        For r = 1 To Len(fFilter)
            If 124 = Asc(fFilter, r) Then Asc(fFilter, r) = NULL
        Next
        OSFN.lpstrFilter = Offset(fFilter)
    End If

    ' Set the filter index
    OSFN.nFilterIndex = lFilterIndex

    ' Allocate space for returned file name
    Dim lpstrFile As String
    lpstrFile = String$(MAX_PATH, NULL)
    OSFN.lpstrFile = Offset(lpstrFile)
    OSFN.nMaxFile = Len(lpstrFile) - 1

    OSFN.lpstrFileTitle = OSFN.lpstrFile
    OSFN.nMaxFileTitle = OSFN.nMaxFile

    ' Set the initial directory
    Dim fInitialDir As String
    If sInitialDir <> NULLSTRING Then
        fInitialDir = sInitialDir + Chr$(NULL)
        OSFN.lpstrInitialDir = Offset(fInitialDir)
    End If

    ' Zero terminate the title
    Dim dTitle As String
    If sTitle <> NULLSTRING Then
        dTitle = sTitle + Chr$(NULL)
        OSFN.lpstrTitle = Offset(dTitle)
    End If

    ' Extension will not be added when this is not specified
    Dim lpstrDefExt As String
    lpstrDefExt = String$(10, NULL)
    OSFN.lpstrDefExt = Offset(lpstrDefExt)

    OSFN.flags = llFlags

    ' Call the dialog fuction
    Dim result As Long
    If isSave Then
        result = GetSaveFileNameA(OSFN)
    Else
        result = GetOpenFileNameA(OSFN)
    End If

    If result Then
        ' Trim the remaining zeros
        GetFileNameDialog = CStrToBStr(lpstrFile)
        llFlags = OSFN.flags
        lFilterIndex = OSFN.nFilterIndex
    End If
End Function
'-----------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' MODULE FILES
'---------------------------------------------------------------------------------------------------------
'$Include:'./include/VGAFont.bas'
'---------------------------------------------------------------------------------------------------------


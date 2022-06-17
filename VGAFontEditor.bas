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
$VersionInfo:InternalName='EditFont'
$VersionInfo:LegalCopyright='Copyright (c) 1998-2022, Samuel Gomes'
$VersionInfo:LegalTrademarks='All trademarks are property of their respective owners'
$VersionInfo:OriginalFilename='EditFont.exe'
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

' Keyboard codes
Const KB_ESC = 27
Const KB_ENTER = 13
Const KB_F1 = 15104
Const KB_F2 = 15360
Const KB_F3 = 15616
Const KB_F5 = 16128
Const KB_UP = 18432
Const KB_DOWN = 20480
Const KB_LEFT = 19200
Const KB_RIGHT = 19712
Const KB_DELETE = 21248
Const KB_C = 99
Const KB_H = 104
Const KB_I = 105
Const KB_P = 112
Const KB_V = 118
Const KB_LCTRL = 100306
Const KB_RCTRL = 100305
Const KB_SPACEBAR = 32

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
Type FILEDIALOGTYPE
    $If 32BIT Then
        lStructSize As Long '        For the DLL call
        hwndOwner As Long '          Dialog will hide behind window when not set correctly
        hInstance As Long '          Handle to a module that contains a dialog box template.
        lpstrFilter As Offset '     Pointer of the string of file filters
        lpstrCustFilter As Offset
        nMaxCustFilter As Long
        nFilterIndex As Long '       One based starting filter index to use when dialog is called
        lpstrFile As Offset '       String full of 0's for the selected file name
        nMaxFile As Long '           Maximum length of the string stuffed with 0's minus 1
        lpstrFileTitle As Offset '  Same as lpstrFile
        nMaxFileTitle As Long '      Same as nMaxFile
        lpstrInitialDir As Offset ' Starting directory
        lpstrTitle As Offset '      Dialog title
        flags As Long '              Dialog flags
        nFileOffset As Integer '     Zero-based offset from path beginning to file name string pointed to by lpstrFile
        nFileExtension As Integer '  Zero-based offset from path beginning to file extension string pointed to by lpstrFile.
        lpstrDefExt As Offset '     Default/selected file extension
        lCustData As Long
        lpfnHook As Long
        lpTemplateName As Offset
    $Else
        lStructSize As Integer64 '           For the DLL call
        hwndOwner As Integer64 '          Dialog will hide behind window when not set correctly
        hInstance As Integer64 '          Handle to a module that contains a dialog box template.
        lpstrFilter As Offset '        Pointer of the string of file filters
        lpstrCustFilter As Offset
        nMaxCustFilter As Long '       LONG tu a o radek niz => je vyber pripony
        nFilterIndex As Long '         One based starting filter index to use when dialog is called    TOTO nefunguje
        lpstrFile As Offset '          String full of 0's for the selected file name
        nMaxFile As Integer64 '              Maximum length of the string stuffed with 0's minus 1       zmena z offset
        lpstrFileTitle As Offset '     Same as lpstrFile
        nMaxFileTitle As Integer64 '      Same as nMaxFile
        lpstrInitialDir As Offset '    Starting directory
        lpstrTitle As Offset '         Dialog title
        flags As Integer64 '                 Dialog flags
        nFileOffset As Integer64 '     Zero-based offset from path beginning to file name string pointed to by lpstrFile
        nFileExtension As Integer64 '  Zero-based offset from path beginning to file extension string pointed to by lpstrFile.
        lpstrDefExt As Offset '        Default/selected file extension
        lCustData As Integer64
        lpfnHook As Integer64
        lpTemplateName As Offset
    $End If
End Type
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' LIBRARY FUCTIONS
'-----------------------------------------------------------------------------------------------------
Declare Dynamic Library "user32"
    Function MessageBoxA& (ByVal oHWnd As Offset, sMessage As String, sTitle As String, Byval ulMBType As Unsigned Long)
End Declare

Declare Dynamic Library "comdlg32"
    Function GetOpenFileNameA& (DIALOGPARAMS As FILEDIALOGTYPE)
    Function GetSaveFileNameA& (DIALOGPARAMS As FILEDIALOGTYPE)
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
' Change to the directory specified by the environment
ChDir StartDir$

' Change to graphics mode 320x200
Screen 7
Title APP_NAME

' Allow the program window to run fullscreen with Alt+Enter
AllowFullScreen SquarePixels , Smooth

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
                Select Case MsgBox("The font has changed. Save it now?", APP_NAME, MB_YESNOCANCEL Or MB_DEFBUTTON1 Or MB_APPLMODAL Or MB_SETFOCUS)
                    Case ID_YES
                        Event = SaveVGAFont
                        Exit Do

                    Case ID_NO
                        Exit Do

                    Case Else
                        Event = EVENT_CHOOSE
                End Select
            Else
                Exit Do
            End If

        Case Else
            ShowAbortMsgBox "Unhandled program event!"
            Exit Do
    End Select
Loop

System 0 ' Exit immediately with errorlevel 0
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' FUNCTIONS AND SUBROUTINES
'-----------------------------------------------------------------------------------------------------
' This is the character selector routine
Function ChooseCharacter%%
    Static xp As Integer, yp As Integer
    Dim refTime As Single, blinkState As Integer

    ' Save the current time
    refTime = Timer

    Cls

    ' Show some info
    Color 4
    Print "Select a character to edit:"
    Locate 25, 1
    Print "Press 'F1' for help.";

    ' Draw the selector at the initial position
    If xp = 0 Or yp = 0 Then
        xp = 1
        yp = 1
    End If
    DrawCharSelector xp, yp, 15

    VGAFont.fgColor = 14
    VGAFont.bgColor = 1

    Dim x As Integer, y As Integer

    ' Draw the characters
    For y = 1 To 8
        For x = 1 To 32
            DrawCharacter 32 * (y - 1) + x - 1, 1 + (x - 1) * 10, 1 + y * 20
        Next
    Next

    ' Also draw the help text on a different page
    Screen , , 1, 0
    Cls
    Color 4
    Print "Quick help:"
    Print
    Color 15
    Print "Controls:"
    Print " Left          - Move left"
    Print " Right         - Move right"
    Print " Up            - Move up"
    Print " Down          - Move down"
    Print " Mouse Pointer - Select"
    Print " Left Button   - Edit character"
    Print " Right Button  - Edit character"
    Print " Enter         - Edit character"
    Print " F1            - Show help"
    Print " F2            - Save font"
    Print " F3            - Load font"
    Print " F5            - Show preview"
    Print " ESC           - Quit"
    Print
    Color 4
    Print "Press any key to continue..."
    Screen , , 0, 0

    Dim As Integer mx, my
    Dim in As Long

    ' Clear the mouse event queue
    While MouseInput
    Wend

    Do
        If MouseInput Then
            If GetMouseOverCharPosiion(mx, my) Then
                ' Turn off the current highlight
                DrawCharSelector xp, yp, 0
                xp = mx
                yp = my
                DrawCharSelector xp, yp, 15

                ' Also check for mouse click
                If MouseButton(1) Or MouseButton(2) Then
                    ubFontCharacter = (xp - 1) + (32 * (yp - 1))
                    ChooseCharacter = EVENT_EDIT
                    Exit Do
                End If
            End If
        Else
            Delay 0.01
        End If

        in = KeyHit

        Select Case in
            Case KB_F1
                Screen , , 1, 1
                WaitKeyPress
                Screen , , 0, 0

            Case KB_LEFT
                DrawCharSelector xp, yp, 0
                xp = xp - 1
                If xp < 1 Then xp = 32
                DrawCharSelector xp, yp, 15

            Case KB_RIGHT
                DrawCharSelector xp, yp, 0
                xp = xp + 1
                If xp > 32 Then xp = 1
                DrawCharSelector xp, yp, 15

            Case KB_UP
                DrawCharSelector xp, yp, 0
                yp = yp - 1
                If yp < 1 Then yp = 8
                DrawCharSelector xp, yp, 15

            Case KB_DOWN
                DrawCharSelector xp, yp, 0
                yp = yp + 1
                If yp > 8 Then yp = 1
                DrawCharSelector xp, yp, 15

            Case KB_ENTER
                ubFontCharacter = (xp - 1) + (32 * (yp - 1))
                ChooseCharacter = EVENT_EDIT
                Exit Do

            Case KB_F2
                ChooseCharacter = EVENT_SAVE
                Exit Do

            Case KB_F3
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
                If Timer - refTime > .3 Then
                    refTime = Timer
                    blinkState = Not blinkState

                    If blinkState Then
                        DrawCharSelector xp, yp, 15
                    Else
                        DrawCharSelector xp, yp, 0
                    End If
                End If
        End Select
    Loop
End Function


' Handles and command line parameters
Function DoCommandLine%%
    Dim i As Long

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
        If Not FileExists(sFontFile) Then
            ' If this is a new file ask use for specs
            Dim ubFontHeight As Long
            ubFontHeight = 16
            Do
                Print
                Input ; "Enter new font height in pixels (8 - 16): ", ubFontHeight
            Loop While (ubFontHeight < 8 Or ubFontHeight > 16)
            SetFontHeight ubFontHeight
        Else
            ' Else read in the font
            If ReadFont(sFontFile, TRUE) Then
                Title APP_NAME + " - " + GetFileNameFromPath(sFontFile)
                ResizeClipboard
                ' Trigger the choose event
                DoCommandLine = EVENT_CHOOSE
            Else
                ShowAbortMsgBox "Failed to load " + sFontFile + "!"
                sFontFile = NULLSTRING
                ' Trigger the load event if no file name was specified
                DoCommandLine = EVENT_LOAD
            End If
        End If
    End If
End Function


' Draw the character cell selector using color c at xe, ye
Sub DrawBmpSelector (xe As Integer, ye As Integer, c As Integer)
    Line (7 + (xe - 1) * 10, 7 + (ye - 1) * 10)-(17 + (xe - 1) * 10, 17 + (ye - 1) * 10), c, B
End Sub


' Draw the character bitmap for editing
Sub DrawCharBitmap (ch As Unsigned Byte)
    Dim x As Integer, y As Integer
    Dim xs As Integer, ys As Integer

    For y = 1 To VGAFont.glyphSize.y
        For x = 1 To VGAFont.glyphSize.x
            xs = 8 + (x - 1) * 10
            ys = 8 + (y - 1) * 10
            If GetFontXY(ch, x, y) Then
                Line (xs, ys)-(xs + 8, ys + 8), 14, BF
            Else
                Line (xs, ys)-(xs + 8, ys + 8), 1, BF
            End If
        Next
    Next
End Sub


' Draw the character selector using color c at xp, yp
Sub DrawCharSelector (xp As Integer, yp As Integer, c As Integer)
    Line ((xp - 1) * 10, (yp * 20))-(9 + (xp - 1) * 10, VGAFont.glyphSize.y + 1 + (yp * 20)), c, B
End Sub


' Point & box collision test for mouse
Function PointCollidesWithRect%% (x As Integer, y As Integer, l As Integer, t As Integer, r As Integer, b As Integer)
    PointCollidesWithRect = (x >= l And x <= r And y >= t And y <= b)
End Function


' Return true if mouse is over any character
' Updates mxp & myp with position
Function GetMouseOverCharPosiion%% (mxp As Integer, myp As Integer)
    Dim As Integer x, y

    GetMouseOverCharPosiion = FALSE

    For y = 1 To 8
        For x = 1 To 32
            If PointCollidesWithRect(MouseX, MouseY, (x - 1) * 10, y * 20, 9 + (x - 1) * 10, VGAFont.glyphSize.y + 1 + y * 20) Then
                mxp = x
                myp = y
                GetMouseOverCharPosiion = TRUE
                Exit Function
            End If
        Next
    Next
End Function


' Return true if mouse is over any cell
' Updates mxp & myp with position
Function GetMouseOverCellPosition%% (mxp As Integer, myp As Integer)
    Dim As Integer x, y

    GetMouseOverCellPosition = FALSE

    For y = 1 To VGAFont.glyphSize.y
        For x = 1 To 8
            If PointCollidesWithRect(MouseX, MouseY, 8 + (x - 1) * 10, 8 + (y - 1) * 10, 16 + (x - 1) * 10, 16 + (y - 1) * 10) Then
                mxp = x
                myp = y
                GetMouseOverCellPosition = TRUE
                Exit Function
            End If
        Next
    Next
End Function


' This is font bitmap editor routine
Function EditCharacter%%
    Dim refTime As Single, blinkState As Integer

    ' Save the current time
    refTime = Timer

    Cls

    ' Display some help
    Color 4
    Locate 2, 13: Print "Controls:"
    Color 15
    Locate 3, 13: Print " Move left       - Left"
    Locate 4, 13: Print " Move right      - Right"
    Locate 5, 13: Print " Move up         - Up"
    Locate 6, 13: Print " Move down       - Down"
    Locate 7, 13: Print " Move selector   - Mouse"
    Locate 8, 13: Print " Toggle pixel    - Space"
    Locate 9, 13: Print " Pixel on        - Btn Left"
    Locate 10, 13: Print " Pixel off       - Btn Right"
    Locate 11, 13: Print " Save & return   - Enter"
    Locate 12, 13: Print " Cancel & return - Esc"
    Locate 13, 13: Print " Flip horizontal - Ctrl+H"
    Locate 14, 13: Print " Flip vertical   - Ctrl+V"
    Locate 15, 13: Print " Invert          - Ctrl+I"
    Locate 16, 13: Print " Copy            - Ctrl+C"
    Locate 17, 13: Print " Paste           - Ctrl+P"
    Locate 18, 13: Print " Clear           - Del"

    Dim cpy As String

    ' Save a copy of this character
    cpy = FontData(ubFontCharacter)

    ' Draw the initial bitmap
    DrawCharBitmap ubFontCharacter

    Dim xe As Integer, ye As Integer

    xe = 1
    ye = 1
    DrawBmpSelector xe, ye, 15

    Dim x As Integer, y As Integer
    Dim xs As Integer, ys As Integer
    Dim v As String, n As Integer
    Dim As Integer mx, my
    Dim in As Long

    ' Clear the mouse event queue
    While MouseInput
    Wend

    Do
        If MouseInput Then
            If GetMouseOverCellPosition(mx, my) Then
                ' Turn off the current highlight
                DrawBmpSelector xe, ye, 0
                xe = mx
                ye = my
                DrawBmpSelector xe, ye, 15

                ' Also check for mouse click
                If MouseButton(1) Then
                    ' Flag font changed
                    bFontChanged = TRUE

                    Asc(FontData(ubFontCharacter), ye) = Asc(FontData(ubFontCharacter), ye) Or (2 ^ (8 - xe))
                End If

                If MouseButton(2) Then
                    ' Flag font changed
                    bFontChanged = TRUE

                    Asc(FontData(ubFontCharacter), ye) = Asc(FontData(ubFontCharacter), ye) And Not (2 ^ (8 - xe))
                End If

                xs = 8 + (xe - 1) * 10
                ys = 8 + (ye - 1) * 10
                If GetFontXY(ubFontCharacter, xe, ye) Then
                    Line (xs, ys)-(xs + 8, ys + 8), 14, BF
                Else
                    Line (xs, ys)-(xs + 8, ys + 8), 1, BF
                End If
            End If
        Else
            Delay 0.01
        End If

        in = KeyHit

        Select Case in
            Case KB_LEFT
                DrawBmpSelector xe, ye, 0
                xe = xe - 1
                If xe < 1 Then xe = 8
                DrawBmpSelector xe, ye, 15

            Case KB_RIGHT
                DrawBmpSelector xe, ye, 0
                xe = xe + 1
                If xe > 8 Then xe = 1
                DrawBmpSelector xe, ye, 15

            Case KB_UP
                DrawBmpSelector xe, ye, 0
                ye = ye - 1
                If ye < 1 Then ye = VGAFont.glyphSize.y
                DrawBmpSelector xe, ye, 15

            Case KB_DOWN
                DrawBmpSelector xe, ye, 0
                ye = ye + 1
                If ye > VGAFont.glyphSize.y Then ye = 1
                DrawBmpSelector xe, ye, 15

            Case KB_SPACEBAR
                ' Flag font changed
                bFontChanged = TRUE

                If GetFontXY(ubFontCharacter, xe, ye) Then
                    Asc(FontData(ubFontCharacter), ye) = Asc(FontData(ubFontCharacter), ye) And Not (2 ^ (8 - xe))
                Else
                    Asc(FontData(ubFontCharacter), ye) = Asc(FontData(ubFontCharacter), ye) Or (2 ^ (8 - xe))
                End If

                xs = 8 + (xe - 1) * 10
                ys = 8 + (ye - 1) * 10
                If GetFontXY(ubFontCharacter, xe, ye) Then
                    Line (xs, ys)-(xs + 8, ys + 8), 14, BF
                Else
                    Line (xs, ys)-(xs + 8, ys + 8), 1, BF
                End If

            Case KB_V
                If KeyDown(KB_LCTRL) Or KeyDown(KB_RCTRL) Then
                    ' Flag font changed
                    bFontChanged = TRUE

                    v = FontData(ubFontCharacter)
                    For n = 1 To VGAFont.glyphSize.y
                        Asc(FontData(ubFontCharacter), n) = Asc(v, 1 + VGAFont.glyphSize.y - n)
                    Next
                    DrawCharBitmap ubFontCharacter
                End If

            Case KB_H
                If KeyDown(KB_LCTRL) Or KeyDown(KB_RCTRL) Then
                    ' Flag font changed
                    bFontChanged = TRUE

                    v = String$(VGAFont.glyphSize.y, NULL)
                    For y = 1 To VGAFont.glyphSize.y
                        For x = 1 To 8
                            If GetFontXY(ubFontCharacter, x, y) Then
                                Asc(v, y) = Asc(v, y) + (2 ^ (x - 1))
                            End If
                        Next
                    Next
                    FontData(ubFontCharacter) = v
                    DrawCharBitmap ubFontCharacter
                End If

            Case KB_I
                If KeyDown(KB_LCTRL) Or KeyDown(KB_RCTRL) Then
                    ' Flag font changed
                    bFontChanged = TRUE

                    v = FontData(ubFontCharacter)
                    For n = 1 To VGAFont.glyphSize.y
                        Asc(FontData(ubFontCharacter), n) = 255 - Asc(v, n)
                    Next
                    DrawCharBitmap ubFontCharacter
                End If

            Case KB_C
                If KeyDown(KB_LCTRL) Or KeyDown(KB_RCTRL) Then
                    sClipboard = FontData(ubFontCharacter)
                End If

            Case KB_P
                If KeyDown(KB_LCTRL) Or KeyDown(KB_RCTRL) Then
                    ' Flag font changed
                    bFontChanged = TRUE

                    FontData(ubFontCharacter) = sClipboard
                    DrawCharBitmap ubFontCharacter
                End If

            Case KB_DELETE
                ' Flag font changed
                bFontChanged = TRUE

                FontData(ubFontCharacter) = String$(VGAFont.glyphSize.y, NULL)
                DrawCharBitmap ubFontCharacter

            Case KB_ESC
                FontData(ubFontCharacter) = cpy
                EditCharacter = EVENT_CHOOSE
                Exit Do

            Case KB_ENTER
                EditCharacter = EVENT_CHOOSE
                Exit Do

            Case Else
                ' Blink the selector at regular intervals
                If Timer - refTime > .3 Then
                    refTime = Timer
                    blinkState = Not blinkState

                    If blinkState Then
                        DrawBmpSelector xe, ye, 15
                    Else
                        DrawBmpSelector xe, ye, 0
                    End If
                End If
        End Select
    Loop
End Function


Function GetFontXY% (ch As Unsigned Byte, x As Integer, y As Integer)
    GetFontXY = Sgn(Asc(FontData(ch), y) And (2 ^ (8 - x)))
End Function


' Resizes the clipboard to match the font height
Sub ResizeClipboard
    sClipboard = Left$(sClipboard + String$(VGAFont.glyphSize.y, NULL), VGAFont.glyphSize.y)
End Sub


' This is called when a font has to loaded
Function LoadVGAFont%%
    ' Get an existing font file name from the user
    Dim flags As Integer64, tmpFilename As String

    flags = OFN_FILEMUSTEXIST
    tmpFilename = GetOpenFileName(APP_NAME, NULLSTRING, "Font files (*.psf)|*.PSF|All files (*.*)|*.*", 1, flags)

    ' Exit if user canceled
    If tmpFilename = NULLSTRING Then
        ' Exit if 1st time
        If VGAFont.glyphSize.y = 0 Then
            LoadVGAFont = EVENT_QUIT
        Else
            LoadVGAFont = EVENT_CHOOSE
        End If
        Exit Function
    End If

    ' Read in the font
    If ReadFont(tmpFilename, TRUE) Then
        sFontFile = tmpFilename
        Title APP_NAME + " - " + GetFileNameFromPath(sFontFile)
        ResizeClipboard
        bFontChanged = FALSE
        LoadVGAFont = EVENT_CHOOSE
    Else
        ShowAbortMsgBox "Failed to load " + tmpFilename + "!"
        LoadVGAFont = EVENT_LOAD
    End If
End Function


' This is called when the file should be saved
Function SaveVGAFont%%
    ' Get an existing font file name from the user
    Dim flags As Integer64, tmpFilename As String

    flags = OFN_OVERWRITEPROMPT
    tmpFilename = GetOpenFileName(APP_NAME, NULLSTRING, "Font files (*.psf)|*.PSF|All files (*.*)|*.*", 1, flags)

    SaveVGAFont = EVENT_CHOOSE

    ' Exit if user canceled
    If tmpFilename = NULLSTRING Then Exit Function

    ' Save the font
    If WriteFont(tmpFilename) Then
        sFontFile = tmpFilename
        bFontChanged = FALSE
    Else
        ShowAbortMsgBox "Failed to save " + tmpFilename + "!"
    End If
End Function


' Shows the shadard windows message box
Function MsgBox& (sMessage As String, sTitle As String, BoxType As Long)
    MsgBox = MessageBoxA(WindowHandle, sMessage + Chr$(NULL), sTitle + Chr$(NULL), BoxType)
End Function


' Abort message box
' This does not terminate the program
Sub ShowAbortMsgBox (sMessage As String)
    Dim i As Long

    i = MsgBox(sMessage, APP_NAME, MB_OK Or MB_ICONSTOP Or MB_SETFOCUS Or MB_APPLMODAL)
End Sub


' Sleeps until the user presses a key on the keyboard
Sub WaitKeyPress
    Do
        Sleep
    Loop Until KeyHit <> NULL
End Sub


' Check if an argument is present in the command line
Function ArgVPresent%% (argv As String, start As Integer)
    Dim argc As Integer
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


' Draws a preview screen using the loaded font
Function ShowPreview%%
    Cls

    ' Draw a box on the screen
    ' First draw top and bottom edges
    VGAFont.fgColor = 12
    VGAFont.bgColor = 0
    DrawString String$(40, Chr$(205)), 0, 0
    DrawString String$(40, Chr$(205)), 0, 199 - VGAFont.glyphSize.y

    Dim i As Integer

    ' Next draw the side edges
    For i = 0 To 199 - VGAFont.glyphSize.y Step VGAFont.glyphSize.y
        DrawCharacter 186, 0, i
        DrawCharacter 186, 312, i
    Next

    ' Next draw the four corners
    DrawCharacter 201, 0, 0
    DrawCharacter 187, 312, 0
    DrawCharacter 200, 0, 199 - VGAFont.glyphSize.y
    DrawCharacter 188, 312, 199 - VGAFont.glyphSize.y

    ' Draw the title bar border
    DrawString String$(40, 196), 0, VGAFont.glyphSize.y * 2
    DrawCharacter 199, 0, VGAFont.glyphSize.y * 2
    DrawCharacter 182, 312, VGAFont.glyphSize.y * 2

    ' Draw the title
    VGAFont.fgColor = 14
    DrawString "FONT  DEMO", 8 * 14, VGAFont.glyphSize.y * 1

    ' Draw the body
    VGAFont.fgColor = 10
    DrawString "This Fox has a longing for grapes:", 8, VGAFont.glyphSize.y * 3
    DrawString "He jumps, but the bunch still escapes.", 8, VGAFont.glyphSize.y * 4
    DrawString "So he goes away sour;", 8, VGAFont.glyphSize.y * 5
    DrawString "And, 'tis said, to this hour", 8, VGAFont.glyphSize.y * 6
    DrawString "Declares that he's no taste for", 8, VGAFont.glyphSize.y * 7
    DrawString "grapes.", 8, VGAFont.glyphSize.y * 8

    WaitKeyPress

    ShowPreview = EVENT_CHOOSE
End Function


' Gets the filename portion from a file path
Function GetFileNameFromPath$ (pathName As String)
    Dim i As Unsigned Long

    ' Retrieve the position of the first / or \ in the parameter from the
    For i = Len(pathName) To 1 Step -1
        If Asc(pathName, i) = Asc("/") Or Asc(pathName, i) = Asc("\") Then Exit For
    Next

    ' Return the full string if pathsep was not found
    If i = 0 Then
        GetFileNameFromPath = pathName
    Else
        GetFileNameFromPath = Right$(pathName, Len(pathName) - i)
    End If
End Function


'  sTitle       - The dialog title.
'  sInitialDir  - If this left blank, it will use the directory where the last opened file is located. Specify ".\" if you want to always use the current directory.
'  sFilter      - File filters separated by pipes (|) in the same format as using VB6 common dialogs.
'  lFilterIndex - The initial file filter to use. Will be altered by user during the call.
'  llFlags      - Dialog flags. Will be altered by the user during the call.
'
' Returns: Blank when cancel is clicked, otherwise the file name selected by the user.
' lFilterIndex and llFlags will be changed depending on the user's selections.
Function GetOpenFileName$ (sTitle As String, sInitialDir As String, sFilter As String, lFilterIndex As Long, llFlags As Integer64)
    ' Zero terminate the title
    Dim dTitle As String
    dTitle = sTitle + Chr$(NULL)

    ' Zero terminate the initial directory
    Dim fInitialDir As String
    fInitialDir = sInitialDir + Chr$(NULL)

    ' Replace the pipes with character zero and then zero terminate filter string
    Dim fFilter As String
    fFilter = sFilter + Chr$(NULL)
    Dim r As Unsigned Long
    For r = 1 To Len(fFilter$)
        If 124 = Asc(fFilter$, r) Then Asc(fFilter$, r) = NULL
    Next

    ' Allocate space for returned file name
    Dim lpstrFile As String
    lpstrFile = String$(2048, NULL) ' For the returned file name

    ' Extension will not be added when this is not specified
    Dim lpstrDefExt As String
    lpstrDefExt$ = String$(10, NULL)

    ' Needed for dialog call
    Dim OpenCall As FILEDIALOGTYPE
    OpenCall.lStructSize = Len(OpenCall)
    OpenCall.hwndOwner = WindowHandle
    OpenCall.lpstrFilter = Offset(fFilter$)
    OpenCall.nFilterIndex = lFilterIndex
    OpenCall.lpstrFile = Offset(lpstrFile$)
    OpenCall.nMaxFile = Len(lpstrFile$) - 1
    OpenCall.lpstrFileTitle = OpenCall.lpstrFile
    OpenCall.nMaxFileTitle = OpenCall.nMaxFile
    OpenCall.lpstrInitialDir = Offset(fInitialDir)
    OpenCall.lpstrTitle = Offset(dTitle)
    OpenCall.lpstrDefExt = Offset(lpstrDefExt)
    OpenCall.flags = llFlags

    ' Do Open File dialog call!
    Dim result As Long
    result = GetOpenFileNameA(OpenCall)

    If result Then
        ' Trim the remaining zeros
        GetOpenFileName$ = Left$(lpstrFile, InStr(lpstrFile, Chr$(NULL)) - 1)
        llFlags = OpenCall.flags
        lFilterIndex = OpenCall.nFilterIndex
    End If
End Function


'  sTitle       - The dialog title.
'  sInitialDir  - If this left blank, it will use the directory where the last opened file is located. Specify ".\" if you want to always use the current directory.
'  sFilter      - File filters separated by pipes (|) in the same format as VB6 common dialogs.
'  lFilterIndex - The initial file filter to use. Will be altered by user during the call.
'  llFlags      - Dialog flags. Will be altered by the user during the call.
'
' Returns: Blank when cancel is clicked otherwise, the file name entered by the user.
' lFilterIndex and llFlags will be changed depending on the user's selections.
Function GetSaveFileName$ (sTitle As String, sInitialDir As String, sFilter As String, lFilterIndex As Long, llFlags As Integer64)
    ' Zero terminate the title
    Dim dTitle As String
    dTitle = sTitle + Chr$(NULL)

    ' Zero terminate the initial directory
    Dim fInitialDir As String
    fInitialDir = sInitialDir + Chr$(NULL)

    ' Replace the pipes with character zero and then zero terminate filter string
    Dim fFilter As String
    fFilter = sFilter + Chr$(NULL)
    Dim r As Unsigned Long
    For r = 1 To Len(fFilter$)
        If 124 = Asc(fFilter$, r) Then Asc(fFilter$, r) = NULL
    Next

    ' Allocate space for returned file name
    Dim lpstrFile As String
    lpstrFile = String$(2048, NULL) ' For the returned file name

    ' Extension will not be added when this is not specified
    Dim lpstrDefExt As String
    lpstrDefExt$ = String$(10, NULL)

    Dim SaveCall As FILEDIALOGTYPE ' Needed for dialog call
    SaveCall.lStructSize = Len(SaveCall)
    SaveCall.hwndOwner = WindowHandle
    SaveCall.lpstrFilter = Offset(fFilter)
    SaveCall.nFilterIndex = lFilterIndex
    SaveCall.lpstrFile = Offset(lpstrFile)
    SaveCall.nMaxFile = Len(lpstrFile) - 1
    SaveCall.lpstrFileTitle = SaveCall.lpstrFile
    SaveCall.nMaxFileTitle = SaveCall.nMaxFile
    SaveCall.lpstrInitialDir = Offset(fInitialDir)
    SaveCall.lpstrTitle = Offset(dTitle)
    SaveCall.lpstrDefExt = Offset(lpstrDefExt)
    SaveCall.flags = llFlags

    ' Do save file dialog call!
    Dim result As Long
    result = GetSaveFileNameA(SaveCall)

    If result Then
        ' Trim the remaining zeros
        GetSaveFileName = Left$(lpstrFile, InStr(lpstrFile, Chr$(NULL)) - 1)
        llFlags = SaveCall.flags
        lFilterIndex = SaveCall.nFilterIndex
    End If
End Function
'-----------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' MODULE FILES
'---------------------------------------------------------------------------------------------------------
'$Include:'./include/VGAFont.bas'
'---------------------------------------------------------------------------------------------------------


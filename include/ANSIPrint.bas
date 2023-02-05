'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' QB64-PE ANSI Escape Sequence Emulator
' Copyright (c) 2023 Samuel Gomes
'
' TODO:
'   https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#screen-colors
'   https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#window-title
'   https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#soft-reset
'   https://github.com/a740g/ANSIPrint/blob/master/docs/ansimtech.txt
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
'$Include:'./ANSIPrint.bi'
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

$If ANSIPRINT_BAS = UNDEFINED Then
    $Let ANSIPRINT_BAS = TRUE
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    '$Debug
    'Screen NewImage(8 * 80, 16 * 25, 32)
    'Font 16

    'Do
    '    Dim ansFile As String: ansFile = OpenFileDialog$("Open", "", "*.ans|*.asc|*.diz|*.nfo|*.txt", "ANSI Art Files")
    '    If Not FileExists(ansFile) Then Exit Do

    '    Dim fh As Long: fh = FreeFile
    '    Open ansFile For Binary Access Read As fh
    '    Color DarkGray, Black
    '    Cls
    '    PrintANSI Input$(LOF(fh), fh), -1 ' put a -ve number here for superfast rendering
    '    Close fh
    '    Title "Press any key to open another file...": Sleep 3600
    'Loop

    'End
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' sANSI - the ANSI stream to render
    ' nCPS - characters / second (bigger numbers means faster; -ve number to disable)
    Sub PrintANSI (sANSI As String, nCPS As Long)
        Static colorLUTInitialized As Long ' if this is true then the legacy color table has been initialized

        Dim As Long state ' the current parser state
        Dim As Long i, ch ' the current character index and the character
        ReDim arg(1 To ANSI_ARG_COUNT) As Long ' CSI argument list
        Dim As Long argIndex ' the current CSI argument index & count; 0 means no arguments
        'Dim As Long leadInPrefix ' the type of lead-in prefix that was specified; this can help diffrentiate what the argument will be used for
        Dim As Long isBold, isBlink, isInvert ' text attributes
        Dim As Long x, y, z ' temp variables used in many places (usually as counter / index)
        Dim As Unsigned Long fc, bc ' foreground and background colors
        Dim As Long savedDECX, savedDECY ' DEC saved cursor position
        Dim As Long savedSCOX, savedSCOY ' SCO saved cursor position
        Dim As Long oldControlChr ' to save old ContolChr

        ' We only support rendering to 32bpp images
        If PixelSize < 4 Then Error ERROR_FEATURE_UNAVAILABLE

        ' Setup legacy color LUT if needed
        If Not colorLUTInitialized Then
            InitializeANSIColorLUT
            colorLUTInitialized = TRUE
        End If

        ' Save the old ControlChr state
        oldControlChr = ControlChr
        ControlChr On ' get assist from QB64's control character handling (only for tabs; we are pretty much doing the rest ourselves)

        ' Get the current cursor position
        savedDECX = Pos(0)
        savedDECY = CsrLin
        savedSCOX = savedDECX
        savedSCOY = savedDECY

        ' Reset the foreground and background color
        fc = ANSI_DEFAULT_COLOR_FOREGROUND
        SetTextCanvasColor fc, FALSE, TRUE
        bc = ANSI_DEFAULT_COLOR_BACKGROUND
        SetTextCanvasColor bc, TRUE, TRUE

        state = ANSI_STATE_TEXT ' we will start parsing regular text by default

        For i = 1 To Len(sANSI)
            ch = Asc(sANSI, i)

            Select Case state
                Case ANSI_STATE_TEXT ' handle normal characters (including some control characters)
                    Select Case ch
                        Case ANSI_SUB ' stop processing and exit loop on EOF (usually put by SAUCE blocks)
                            state = ANSI_STATE_END

                        Case ANSI_BEL ' handle Bell - because QB64 does not (even with ControlChr On)
                            Beep

                        Case ANSI_BS ' handle Backspace - because QB64 does not (even with ControlChr On)
                            x = Pos(0) - 1
                            If x > 0 Then Locate , x ' move to the left only if we are not on the edge

                        Case ANSI_LF ' handle Line Feed because QB64 screws this up and moves the cursor to the beginning of the next line
                            x = Pos(0) ' save old x pos
                            Print Chr$(ch); ' use QB64 to handle the LF and then correct the mistake
                            Locate , x ' set the cursor to the old x pos

                        Case ANSI_FF ' handle Form Feed - because QB64 does not (even with ControlChr On)
                            Locate 1, 1

                        Case ANSI_CR ' handle Carriage Return because QB64 screws this up and moves the cursor to the beginning of the next line
                            Locate , 1

                            'Case ANSI_DEL ' TODO: Check what to do with this

                        Case ANSI_ESC ' handle escape character
                            state = ANSI_STATE_BEGIN ' beginning a new escape sequence

                        Case Else ' print the character
                            Print Chr$(ch);
                            If nCPS > 0 Then Limit nCPS ' limit the loop speed if char/sec is a positive value

                    End Select

                Case ANSI_STATE_BEGIN ' handle escape sequence
                    Select Case ch
                        Case Is < ANSI_SP ' handle escaped character
                            ControlChr Off
                            Print Chr$(ch); ' print escaped ESC character
                            ControlChr On
                            If nCPS > 0 Then Limit nCPS ' limit the loop speed if char/sec is a positive value
                            state = ANSI_STATE_TEXT

                        Case ANSI_ESC_DECSC ' Save Cursor Position in Memory
                            savedDECX = Pos(0)
                            savedDECY = CsrLin
                            state = ANSI_STATE_TEXT

                        Case ANSI_ESC_DECSR ' Restore Cursor Position from Memory
                            Locate savedDECY, savedDECX
                            state = ANSI_STATE_TEXT

                        Case ANSI_ESC_RI ' Reverse Index
                            y = CsrLin - 1
                            If y > 0 Then Locate y
                            state = ANSI_STATE_TEXT

                        Case ANSI_ESC_CSI ' handle CSI
                            ReDim arg(1 To ANSI_ARG_COUNT) As Long ' reset the control sequence arguments
                            argIndex = 0 ' reset argument index
                            'leadInPrefix = 0 ' reset lead-in prefix
                            state = ANSI_STATE_SEQUENCE

                        Case Else ' throw an error for stuff we are not handling
                            Error ERROR_FEATURE_UNAVAILABLE

                    End Select

                Case ANSI_STATE_SEQUENCE ' handle CSI sequence
                    Select Case ch
                        Case ANSI_0 To ANSI_QUESTION_MARK ' argument bytes
                            If argIndex < 1 Then argIndex = 1 ' set the argument index to one if this is the first time

                            Select Case ch
                                Case ANSI_0 To ANSI_9 ' handle sequence numeric arguments
                                    arg(argIndex) = arg(argIndex) * 10 + ch - ANSI_0

                                Case ANSI_SEMICOLON ' handle sequence argument seperators
                                    argIndex = argIndex + 1 ' increment the argument index

                                Case ANSI_EQUALS_SIGN, ANSI_GREATER_THAN_SIGN, ANSI_QUESTION_MARK ' handle lead-in prefix
                                    ' NOP: leadInPrefix = ch ' just save the prefix type

                                Case Else ' throw an error for stuff we are not handling
                                    Error ERROR_FEATURE_UNAVAILABLE

                            End Select

                        Case ANSI_SP To ANSI_SLASH ' intermediate bytes
                            Select Case ch
                                Case ANSI_SP ' ignore spaces
                                    ' NOP

                                Case Else ' throw an error for stuff we are not handling
                                    Error ERROR_FEATURE_UNAVAILABLE

                            End Select

                        Case ANSI_AT_SIGN To ANSI_TILDE ' final byte
                            Select Case ch
                                Case ANSI_ESC_CSI_SM, ANSI_ESC_CSI_RM ' Set and reset screen mode
                                    If argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                    Select Case arg(1)
                                        Case 0 To 6, 14 To 18 ' all mode changes are ignored. the screen type must be set by the caller
                                            ' NOP

                                        Case 7 ' Enable / disable line wrapping
                                            ' NOP: QB64 does line wrapping by default
                                            If ANSI_ESC_CSI_RM = ch Then ' ANSI_ESC_CSI_RM disable line wrapping unsupported
                                                Error ERROR_FEATURE_UNAVAILABLE
                                            End If

                                        Case 12 ' Text Cursor Enable / Disable Blinking
                                            ' NOP

                                        Case 25 ' make cursor visible / invisible
                                            If ANSI_ESC_CSI_SM = ch Then ' ANSI_ESC_CSI_SM make cursor visible
                                                Locate , , 1
                                            Else ' ANSI_ESC_CSI_RM make cursor invisible
                                                Locate , , 0
                                            End If

                                        Case Else ' throw an error for stuff we are not handling
                                            Error ERROR_FEATURE_UNAVAILABLE

                                    End Select

                                Case ANSI_ESC_CSI_ED ' Erase in Display
                                    If argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                    Select Case arg(1)
                                        Case 0 ' clear from cursor to end of screen
                                            ClearTextCanvasArea Pos(0), CsrLin, TextCanvasWidth, CsrLin ' first clear till the end of the line starting from the cursor
                                            ClearTextCanvasArea 1, CsrLin + 1, TextCanvasWidth, TextCanvasHeight ' next clear the whole canvas below the cursor

                                        Case 1 ' clear from cursor to beginning of the screen
                                            ClearTextCanvasArea 1, CsrLin, Pos(0), CsrLin ' first clear from the beginning of the line till the cursor
                                            ClearTextCanvasArea 1, 1, TextCanvasWidth, CsrLin - 1 ' next clear the whole canvas above the cursor

                                        Case 2 ' clear entire screen (and moves cursor to upper left like ANSI.SYS)
                                            Cls

                                        Case 3 ' clear entire screen and delete all lines saved in the scrollback buffer (scrollback stuff not supported)
                                            ClearTextCanvasArea 1, 1, TextCanvasWidth, TextCanvasHeight

                                        Case Else ' throw an error for stuff we are not handling
                                            Error ERROR_FEATURE_UNAVAILABLE

                                    End Select

                                Case ANSI_ESC_CSI_EL ' Erase in Line
                                    If argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                    Select Case arg(1)
                                        Case 0 ' erase from cursor to end of line
                                            ClearTextCanvasArea Pos(0), CsrLin, TextCanvasWidth, CsrLin

                                        Case 1 ' erase start of line to the cursor
                                            ClearTextCanvasArea 1, CsrLin, Pos(0), CsrLin

                                        Case 2 ' erase the entire line
                                            ClearTextCanvasArea 1, CsrLin, TextCanvasWidth, CsrLin

                                        Case Else ' throw an error for stuff we are not handling
                                            Error ERROR_FEATURE_UNAVAILABLE

                                    End Select

                                Case ANSI_ESC_CSI_SGR ' Select Graphic Rendition
                                    x = 1 ' start with the first argument
                                    If argIndex < 1 Then argIndex = 1 ' this allows '[m' to be treated as [0m
                                    Do While x <= argIndex ' loop through the argument list and process each argument
                                        Select Case arg(x)
                                            Case 0 ' reset all modes (styles and colors)
                                                fc = ANSI_DEFAULT_COLOR_FOREGROUND
                                                bc = ANSI_DEFAULT_COLOR_BACKGROUND
                                                isBold = FALSE
                                                isBlink = FALSE
                                                isInvert = FALSE
                                                SetTextCanvasColor fc, isInvert, TRUE
                                                SetTextCanvasColor bc, Not isInvert, TRUE

                                            Case 1 ' enable high intensity colors
                                                If fc < 8 Then fc = fc + 8
                                                isBold = TRUE
                                                SetTextCanvasColor fc, isInvert, TRUE

                                            Case 2, 22 ' enable low intensity, disable high intensity colors
                                                If fc > 7 Then fc = fc - 8
                                                isBold = FALSE
                                                SetTextCanvasColor fc, isInvert, TRUE

                                            Case 3, 4, 23, 24 ' set / reset italic & underline mode ignored
                                                ' NOP: This can be used if we load monospaced TTF fonts using 'italics', 'underline' properties

                                            Case 5, 6 ' turn blinking on
                                                If bc < 8 Then bc = bc + 8
                                                isBlink = TRUE
                                                SetTextCanvasColor bc, Not isInvert, TRUE

                                            Case 7 ' enable reverse video
                                                If Not isInvert Then
                                                    isInvert = TRUE
                                                    SetTextCanvasColor fc, isInvert, TRUE
                                                    SetTextCanvasColor bc, Not isInvert, TRUE
                                                End If

                                            Case 25 ' turn blinking off
                                                If bc > 7 Then bc = bc - 8
                                                isBlink = FALSE
                                                SetTextCanvasColor bc, Not isInvert, TRUE

                                            Case 27 ' disable reverse video
                                                If isInvert Then
                                                    isInvert = FALSE
                                                    SetTextCanvasColor fc, isInvert, TRUE
                                                    SetTextCanvasColor bc, Not isInvert, TRUE
                                                End If

                                            Case 30 To 37 ' set foreground color
                                                fc = arg(x) - 30
                                                If isBold Then fc = fc + 8
                                                SetTextCanvasColor fc, isInvert, TRUE

                                            Case 38 ' set 8-bit 256 or 24-bit RGB foreground color
                                                z = argIndex - x ' get the number of arguments remaining

                                                If arg(x + 1) = 2 And z >= 4 Then ' 32bpp color with 5 arguments
                                                    fc = RGB32(arg(x + 2) And &HFF, arg(x + 3) And &HFF, arg(x + 4) And &HFF)
                                                    SetTextCanvasColor fc, isInvert, FALSE

                                                    x = x + 4 ' skip to last used arg

                                                ElseIf arg(x + 1) = 5 And z >= 2 Then ' 256 color with 3 arguments
                                                    fc = arg(x + 2)
                                                    SetTextCanvasColor fc, isInvert, TRUE

                                                    x = x + 2 ' skip to last used arg

                                                Else
                                                    Error ERROR_CANNOT_CONTINUE

                                                End If

                                            Case 39 ' set default foreground color
                                                fc = ANSI_DEFAULT_COLOR_FOREGROUND
                                                SetTextCanvasColor fc, isInvert, TRUE

                                            Case 40 To 47 ' set background color
                                                bc = arg(x) - 40
                                                If isBlink Then bc = bc + 8
                                                SetTextCanvasColor bc, Not isInvert, TRUE

                                            Case 48 ' set 8-bit 256 or 24-bit RGB background color
                                                z = argIndex - x ' get the number of arguments remaining

                                                If arg(x + 1) = 2 And z >= 4 Then ' 32bpp color with 5 arguments
                                                    bc = RGB32(arg(x + 2) And &HFF, arg(x + 3) And &HFF, arg(x + 4) And &HFF)
                                                    SetTextCanvasColor bc, Not isInvert, FALSE

                                                    x = x + 4 ' skip to last used arg

                                                ElseIf arg(x + 1) = 5 And z >= 2 Then ' 256 color with 3 arguments
                                                    bc = arg(x + 2)
                                                    SetTextCanvasColor bc, Not isInvert, TRUE

                                                    x = x + 2 ' skip to last used arg

                                                Else
                                                    Error ERROR_CANNOT_CONTINUE

                                                End If

                                            Case 49 ' set default background color
                                                bc = ANSI_DEFAULT_COLOR_BACKGROUND
                                                SetTextCanvasColor bc, Not isInvert, TRUE

                                            Case 90 To 97 ' set high intensity foreground color
                                                fc = 8 + arg(x) - 90
                                                SetTextCanvasColor fc, isInvert, TRUE

                                            Case 100 To 107 ' set high intensity background color
                                                bc = 8 + arg(x) - 100
                                                SetTextCanvasColor bc, Not isInvert, TRUE

                                            Case Else ' throw an error for stuff we are not handling
                                                Error ERROR_FEATURE_UNAVAILABLE

                                        End Select

                                        x = x + 1 ' move to the next argument
                                    Loop

                                Case ANSI_ESC_CSI_SCP ' Save Current Cursor Position (SCO)
                                    If argIndex > 0 Then Error ERROR_CANNOT_CONTINUE ' was not expecting args

                                    savedSCOX = Pos(0)
                                    savedSCOY = CsrLin

                                Case ANSI_ESC_CSI_RCP ' Restore Saved Cursor Position (SCO)
                                    If argIndex > 0 Then Error ERROR_CANNOT_CONTINUE ' was not expecting args

                                    Locate savedSCOY, savedSCOX

                                Case ANSI_ESC_CSI_PABLODRAW_24BPP ' PabloDraw 24-bit ANSI sequences
                                    If argIndex <> 4 Then Error ERROR_CANNOT_CONTINUE ' we need 4 arguments

                                    SetTextCanvasColor RGB32(arg(2) And &HFF, arg(3) And &HFF, arg(4) And &HFF), arg(1) = FALSE, FALSE

                                Case ANSI_ESC_CSI_CUP, ANSI_ESC_CSI_HVP ' Cursor position or Horizontal and vertical position
                                    If argIndex > 2 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 2 args

                                    y = TextCanvasHeight
                                    If arg(1) < 1 Then
                                        arg(1) = 1
                                    ElseIf arg(1) > y Then
                                        arg(1) = y
                                    End If

                                    x = TextCanvasWidth
                                    If arg(2) < 1 Then
                                        arg(2) = 1
                                    ElseIf arg(2) > x Then
                                        arg(2) = x
                                    End If

                                    Locate arg(1), arg(2) ' line #, column #

                                Case ANSI_ESC_CSI_CUU ' Cursor up
                                    If argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                    If arg(1) < 1 Then arg(1) = 1
                                    y = CsrLin - arg(1)
                                    If y < 1 Then arg(1) = 1
                                    Locate y

                                Case ANSI_ESC_CSI_CUD ' Cursor down
                                    If argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                    If arg(1) < 1 Then arg(1) = 1
                                    y = CsrLin + arg(1)
                                    z = TextCanvasHeight
                                    If y > z Then y = z
                                    Locate y

                                Case ANSI_ESC_CSI_CUF ' Cursor forward
                                    If argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                    If arg(1) < 1 Then arg(1) = 1
                                    x = Pos(0) + arg(1)
                                    z = TextCanvasWidth
                                    If x > z Then x = z
                                    Locate , x

                                Case ANSI_ESC_CSI_CUB ' Cursor back
                                    If argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                    If arg(1) < 1 Then arg(1) = 1
                                    x = Pos(0) - arg(1)
                                    If x < 1 Then x = 1
                                    Locate , x

                                Case ANSI_ESC_CSI_CNL ' Cursor Next Line
                                    If argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                    If arg(1) < 1 Then arg(1) = 1
                                    y = CsrLin + arg(1)
                                    z = TextCanvasHeight
                                    If y > z Then y = z
                                    Locate y, 1

                                Case ANSI_ESC_CSI_CPL ' Cursor Previous Line
                                    If argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                    If arg(1) < 1 Then arg(1) = 1
                                    y = CsrLin - arg(1)
                                    If y < 1 Then y = 1
                                    Locate y, 1

                                Case ANSI_ESC_CSI_CHA ' Cursor Horizontal Absolute
                                    If argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                    x = TextCanvasWidth
                                    If arg(1) < 1 Then
                                        arg(1) = 1
                                    ElseIf arg(1) > x Then
                                        arg(1) = x
                                    End If
                                    Locate , arg(1)

                                Case ANSI_ESC_CSI_VPA ' Vertical Line Position Absolute
                                    If argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                    y = TextCanvasHeight
                                    If arg(1) < 1 Then
                                        arg(1) = 1
                                    ElseIf arg(1) > y Then
                                        arg(1) = y
                                    End If
                                    Locate arg(1)

                                Case ANSI_ESC_CSI_DECSCUSR
                                    If argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                    Select Case arg(1)
                                        Case 0, 3, 4 ' Default, Blinking & Steady underline cursor shape
                                            Locate , , , 29, 31 ' this should give a nice underline cursor

                                        Case 1, 2 ' Blinking & Steady block cursor shape
                                            Locate , , , 0, 31 ' this should give a full block cursor

                                        Case 5, 6 ' Blinking & Steady bar cursor shape
                                            Locate , , , 16, 31 ' since we cannot get a bar cursor in QB64, we'll just use a half-block cursor

                                        Case Else ' throw an error for stuff we are not handling
                                            Error ERROR_FEATURE_UNAVAILABLE

                                    End Select

                                Case Else ' throw an error for stuff we are not handling
                                    Error ERROR_FEATURE_UNAVAILABLE

                            End Select

                            ' End of sequence
                            state = ANSI_STATE_TEXT

                        Case Else ' throw an error for stuff we are not handling
                            Error ERROR_FEATURE_UNAVAILABLE

                    End Select

                Case ANSI_STATE_END ' exit loop if end state was set
                    Exit For

                Case Else ' this should never happen
                    Error ERROR_CANNOT_CONTINUE

            End Select
        Next

        ' Set ControlChr the way we found it
        If oldControlChr Then
            ControlChr Off
        Else
            ControlChr On
        End If
    End Sub


    ' Set the foreground or background color
    Sub SetTextCanvasColor (c As Unsigned Long, isBackground As Long, isLegacy As Long)
        Shared ANSIColorLUT() As Unsigned Long

        Dim nRGB As Unsigned Long

        If isLegacy Then
            nRGB = ANSIColorLUT(c)
        Else
            nRGB = c
        End If

        If isBackground Then
            ' Echo "Background color" + Str$(c) + " (" + Hex$(nRGB) + ")"
            Color , nRGB
        Else
            ' Echo "Foreground color" + Str$(c) + " (" + Hex$(nRGB) + ")"
            Color nRGB
        End If
    End Sub


    ' Returns the number of characters per line
    Function TextCanvasWidth&
        TextCanvasWidth = Width \ FontWidth ' this will cause a divide by zero if a variable width font is used; use monospaced fonts to avoid this
    End Function


    ' Returns the number of lines
    Function TextCanvasHeight&
        TextCanvasHeight = Height \ FontHeight
    End Function


    ' Clears a given portion of screen without disturbing the cursor location and screen colors
    Sub ClearTextCanvasArea (l As Long, t As Long, r As Long, b As Long)
        Dim As Long i, w, x, y
        Dim As Unsigned Long fc, bc

        w = 1 + r - l ' calculate width

        If w > 0 And t <= b Then ' only proceed is width is > 0 and height is > 0
            ' Save some stuff
            fc = DefaultColor
            bc = BackgroundColor
            x = Pos(0)
            y = CsrLin

            Color Black, Black ' lights out

            For i = t To b
                Locate i, l: Print Space$(w); ' fill with SPACE
            Next

            ' Restore saved stuff
            Color fc, bc
            Locate y, x
        End If
    End Sub


    ' Initializes the ANSI legacy color LUT
    Sub InitializeANSIColorLUT
        Shared ANSIColorLUT() As Unsigned Long

        Dim As Long c, i, r, g, b

        ' The first 16 are the standard 16 ANSI colors (VGA style)
        ANSIColorLUT(0) = Black ' exact match
        ANSIColorLUT(1) = RGB32(170, 0, 0) '  1 red
        ANSIColorLUT(2) = RGB32(0, 170, 0) '  2 green
        ANSIColorLUT(3) = RGB32(170, 85, 0) '  3 yellow (not really yellow; oh well)
        ANSIColorLUT(4) = RGB32(0, 0, 170) '  4 blue
        ANSIColorLUT(5) = RGB32(170, 0, 170) '  5 magenta
        ANSIColorLUT(6) = RGB32(0, 170, 170) '  6 cyan
        ANSIColorLUT(7) = DarkGray ' white (well VGA defines this as (170, 170, 170); darkgray is (169, 169, 169); so we are super close)
        ANSIColorLUT(8) = RGB32(85, 85, 85) '  8 grey
        ANSIColorLUT(9) = RGB32(255, 85, 85) '  9 bright red
        ANSIColorLUT(10) = RGB32(85, 255, 85) ' 10 bright green
        ANSIColorLUT(11) = RGB32(255, 255, 85) ' 11 bright yellow
        ANSIColorLUT(12) = RGB32(85, 85, 255) ' 12 bright blue
        ANSIColorLUT(13) = RGB32(255, 85, 255) ' 13 bright magenta
        ANSIColorLUT(14) = RGB32(85, 255, 255) ' 14 bright cyan
        ANSIColorLUT(15) = White ' exact match

        ' The next 216 colors (16-231) are formed by a 3bpc RGB value offset by 16, packed into a single value
        For c = 16 To 231
            i = ((c - 16) \ 36) Mod 6
            If i = 0 Then r = 0 Else r = (14135 + 10280 * i) \ 256

            i = ((c - 16) \ 6) Mod 6
            If i = 0 Then g = 0 Else g = (14135 + 10280 * i) \ 256

            i = ((c - 16) \ 1) Mod 6
            If i = 0 Then b = 0 Else b = (14135 + 10280 * i) \ 256

            ANSIColorLUT(c) = RGB32(r, g, b)
        Next

        ' The final 24 colors (232-255) are grayscale starting from a shade slighly lighter than black, ranging up to shade slightly darker than white
        For c = 232 To 255
            g = (2056 + 2570 * (c - 232)) \ 256
            ANSIColorLUT(c) = RGB32(g, g, g)
        Next
    End Sub
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------------------------------------------------------------


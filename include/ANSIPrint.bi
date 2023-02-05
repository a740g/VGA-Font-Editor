'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' QB64-PE ANSI Escape Sequence Emulator
' Copyright (c) 2023 Samuel Gomes
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
'$Include:'./Common.bi'
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

$If ANSIPRINT_BI = UNDEFINED Then
    $Let ANSIPRINT_BI = TRUE
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' CONSTANTS
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' ANSI constants (not an exhaustive list)
    Const ANSI_NUL = 0 ' Null
    Const ANSI_SOH = 1 ' Start of Heading
    Const ANSI_STX = 2 ' Start of Text
    Const ANSI_ETX = 3 ' End of Text
    Const ANSI_EOT = 4 ' End of Transmission
    Const ANSI_ENQ = 5 ' Enquiry
    Const ANSI_ACK = 6 ' Acknowledgement
    Const ANSI_BEL = 7 ' Bell
    Const ANSI_BS = 8 ' Backspace
    Const ANSI_HT = 9 ' Horizontal Tab
    Const ANSI_LF = 10 ' Line Feed
    Const ANSI_VT = 11 ' Vertical Tab
    Const ANSI_FF = 12 ' Form Feed
    Const ANSI_CR = 13 ' Carriage Return
    Const ANSI_SO = 14 ' Shift Out
    Const ANSI_SI = 15 ' Shift In
    Const ANSI_DLE = 16 ' Data Link Escape
    Const ANSI_DC1 = 17 ' Device Control 1
    Const ANSI_DC2 = 18 ' Device Control 2
    Const ANSI_DC3 = 19 ' Device Control 3
    Const ANSI_DC4 = 20 ' Device Control 4
    Const ANSI_NAK = 21 ' Negative Acknowledgement
    Const ANSI_SYN = 22 ' Synchronous Idle
    Const ANSI_ETB = 23 ' End of Transmission Block
    Const ANSI_CAN = 24 ' Cancel
    Const ANSI_EM = 25 ' End of Medium
    Const ANSI_SUB = 26 ' Substitute
    Const ANSI_ESC = 27 ' Escape
    Const ANSI_FS = 28 ' File Separator
    Const ANSI_GS = 29 ' Group Separator
    Const ANSI_RS = 30 ' Record Separator
    Const ANSI_US = 31 ' Unit Separator
    Const ANSI_SP = 32 ' Space
    Const ANSI_SLASH = 47 ' /
    Const ANSI_0 = 48 ' 0
    Const ANSI_ESC_DECSC = 55 ' Save Cursor Position in Memory
    Const ANSI_ESC_DECSR = 56 ' Restore Cursor Position from Memory
    Const ANSI_9 = 57 ' 9
    Const ANSI_COLON = 58 ' :
    Const ANSI_SEMICOLON = 59 ' ;
    Const ANSI_LESS_THAN_SIGN = 60 ' <
    Const ANSI_EQUALS_SIGN = 61 ' =
    Const ANSI_GREATER_THAN_SIGN = 62 ' >
    Const ANSI_QUESTION_MARK = 63 ' ?
    Const ANSI_AT_SIGN = 64 ' @
    Const ANSI_ESC_CSI_CUU = 65 ' Cursor Up
    Const ANSI_ESC_CSI_CUD = 66 ' Cursor Down
    Const ANSI_ESC_CSI_CUF = 67 ' Cursor Forward/Right
    Const ANSI_ESC_CSI_CUB = 68 ' Cursor Back/Left
    Const ANSI_ESC_CSI_CNL = 69 ' Cursor Next Line
    Const ANSI_ESC_CSI_CPL = 70 ' Cursor Previous Line
    Const ANSI_ESC_CSI_CHA = 71 ' Cursor Horizontal Absolute
    Const ANSI_ESC_CSI_CUP = 72 ' Cursor Position
    Const ANSI_ESC_CSI_ED = 74 ' Erase in Display
    Const ANSI_ESC_CSI_EL = 75 ' Erase in Line
    Const ANSI_ESC_CSI_IL = 76 ' ANSI.SYS: Insert line
    Const ANSI_ESC_CSI_DL = 77 ' ANSI.SYS: Delete line
    Const ANSI_ESC_RI = 77 ' Reverse Index
    Const ANSI_ESC_SS2 = 78 ' Single Shift Two
    Const ANSI_ESC_SS3 = 79 ' Single Shift Three
    Const ANSI_ESC_DCS = 80 ' Device Control String
    Const ANSI_ESC_CSI_SU = 83 ' Scroll Up
    Const ANSI_ESC_CSI_SD = 84 ' Scroll Down
    Const ANSI_ESC_SOS = 88 ' Start of String
    Const ANSI_ESC_CSI = 91 ' Control Sequence Introducer
    Const ANSI_ESC_ST = 92 ' String Terminator
    Const ANSI_ESC_OSC = 93 ' Operating System Command
    Const ANSI_ESC_PM = 94 ' Privacy Message
    Const ANSI_ESC_APC = 95 ' Application Program Command
    Const ANSI_ESC_CSI_VPA = 100 ' Vertical Line Position Absolute
    Const ANSI_ESC_CSI_HVP = 102 ' Horizontal Vertical Position
    Const ANSI_ESC_CSI_SM = 104 ' ANSI.SYS: Set screen mode
    Const ANSI_ESC_CSI_RM = 108 ' ANSI.SYS: Reset screen mode
    Const ANSI_ESC_CSI_SGR = 109 ' Select Graphic Rendition
    Const ANSI_ESC_CSI_DSR = 110 ' Device status report
    Const ANSI_ESC_CSI_DECSCUSR = 113 ' Cursor Shape
    Const ANSI_ESC_CSI_SCP = 115 ' Save Current Cursor Position
    Const ANSI_ESC_CSI_PABLODRAW_24BPP = 116 ' PabloDraw 24-bit ANSI sequences
    Const ANSI_ESC_CSI_RCP = 117 ' Restore Saved Cursor Position
    Const ANSI_TILDE = 126 ' ~
    Const ANSI_DEL = 127 ' Delete
    ' Parser state
    Const ANSI_STATE_TEXT = 0 ' when parsing regular text & control characters
    Const ANSI_STATE_BEGIN = 1 ' when beginning an escape sequence
    Const ANSI_STATE_SEQUENCE = 2 ' when parsing a control sequence introducer
    Const ANSI_STATE_END = 3 ' when the end of the character stream has been reached
    ' Parser limits
    Const ANSI_ARG_COUNT = 10 ' max number of arguments that we can parse at a time
    ' Some defaults
    Const ANSI_DEFAULT_COLOR_FOREGROUND = 7
    Const ANSI_DEFAULT_COLOR_BACKGROUND = 0
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' GLOBAL VARIABLES
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    Dim ANSIColorLUT(0 To 255) As Unsigned Long ' this table is used to get the RGB for legacy ANSI colors
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------------------------------------------------------------


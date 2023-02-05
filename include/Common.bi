'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' Common header
' Copyright (c) 2023 Samuel Gomes
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

$If COMMON_BI = UNDEFINED Then
    $Let COMMON_BI = TRUE

    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' METACOMMANDS
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    $If VERSION < 3.5 Then
            $Error This requires the latest version of QB64-PE from https://github.com/QB64-Phoenix-Edition/QB64pe/releases
    $End If

    ' We don't want an underscore prefix when writing new code. Leading underscores are ugly
    $NoPrefix

    ' All identifiers must default to long (32-bits). This results in fastest code execution on x86 & x64
    DefLng A-Z

    ' Force all arrays to be defined
    Option ExplicitArray

    ' Force all variables to be defined
    Option Explicit

    ' All arrays should be static. If dynamic arrays are required use "ReDim"
    '$Static

    ' Start array lower bound from 1. If 0 is required this should be explicitly specified as (0 To X)
    Option Base 1

    ' We want our window to be resizeable. "Smooth" is a personal preference. Use "Stretch" if preferred
    $Resize:Smooth

    ' We want all 32bpp color constants
    $Color:32
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' CONSTANTS
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' Some common and useful constants
    Const FALSE = 0, TRUE = Not FALSE
    Const NULL = 0
    Const NULLSTRING = ""
    ' Common keyboard key codes
    Const KEY_BACKSPACE = 8
    Const KEY_TAB = 9
    Const KEY_ENTER = 13
    Const KEY_ESCAPE = 27
    Const KEY_SPACE_BAR = 32
    Const KEY_OPEN_PARENTHESIS = 40
    Const KEY_CLOSE_PARENTHESIS = 41
    Const KEY_PLUS = 43
    Const KEY_MINUS = 45
    Const KEY_SLASH = 47
    Const KEY_0 = 48
    Const KEY_1 = 49
    Const KEY_2 = 50
    Const KEY_3 = 51
    Const KEY_4 = 52
    Const KEY_5 = 53
    Const KEY_6 = 54
    Const KEY_7 = 55
    Const KEY_8 = 56
    Const KEY_9 = 57
    Const KEY_COLON = 58
    Const KEY_SEMICOLON = 59
    Const KEY_EQUALS = 61
    Const KEY_UPPER_A = 65
    Const KEY_UPPER_B = 66
    Const KEY_UPPER_C = 67
    Const KEY_UPPER_D = 68
    Const KEY_UPPER_E = 69
    Const KEY_UPPER_F = 70
    Const KEY_UPPER_G = 71
    Const KEY_UPPER_H = 72
    Const KEY_UPPER_I = 73
    Const KEY_UPPER_J = 74
    Const KEY_UPPER_K = 75
    Const KEY_UPPER_L = 76
    Const KEY_UPPER_M = 77
    Const KEY_UPPER_N = 78
    Const KEY_UPPER_O = 79
    Const KEY_UPPER_P = 80
    Const KEY_UPPER_Q = 81
    Const KEY_UPPER_R = 82
    Const KEY_UPPER_S = 83
    Const KEY_UPPER_T = 84
    Const KEY_UPPER_U = 85
    Const KEY_UPPER_V = 86
    Const KEY_UPPER_W = 87
    Const KEY_UPPER_X = 88
    Const KEY_UPPER_Y = 89
    Const KEY_UPPER_Z = 90
    Const KEY_OPEN_BRACKET = 91
    Const KEY_BACKSLASH = 92
    Const KEY_CLOSE_BRACKET = 93
    Const KEY_UNDERSCORE = 95
    Const KEY_LOWER_A = 97
    Const KEY_LOWER_B = 98
    Const KEY_LOWER_C = 99
    Const KEY_LOWER_D = 100
    Const KEY_LOWER_E = 101
    Const KEY_LOWER_F = 102
    Const KEY_LOWER_G = 103
    Const KEY_LOWER_H = 104
    Const KEY_LOWER_I = 105
    Const KEY_LOWER_J = 106
    Const KEY_LOWER_K = 107
    Const KEY_LOWER_L = 108
    Const KEY_LOWER_M = 109
    Const KEY_LOWER_N = 110
    Const KEY_LOWER_O = 111
    Const KEY_LOWER_P = 112
    Const KEY_LOWER_Q = 113
    Const KEY_LOWER_R = 114
    Const KEY_LOWER_S = 115
    Const KEY_LOWER_T = 116
    Const KEY_LOWER_U = 117
    Const KEY_LOWER_V = 118
    Const KEY_LOWER_W = 119
    Const KEY_LOWER_X = 120
    Const KEY_LOWER_Y = 121
    Const KEY_LOWER_Z = 122
    Const KEY_OPEN_BRACE = 123
    Const KEY_CLOSE_BRACE = 125
    Const KEY_TILDE = 126
    Const KEY_F1 = 15104
    Const KEY_F2 = 15360
    Const KEY_F3 = 15616
    Const KEY_F4 = 15872
    Const KEY_F5 = 16128
    Const KEY_F6 = 16384
    Const KEY_F7 = 16640
    Const KEY_F8 = 16896
    Const KEY_F9 = 17152
    Const KEY_F10 = 17408
    Const KEY_HOME = 18176
    Const KEY_UP_ARROW = 18432
    Const KEY_PAGE_UP = 18688
    Const KEY_LEFT_ARROW = 19200
    Const KEY_RIGHT_ARROW = 19712
    Const KEY_END = 20224
    Const KEY_DOWN_ARROW = 20480
    Const KEY_PAGE_DOWN = 20736
    Const KEY_INSERT = 20992
    Const KEY_DELETE = 21248
    Const KEY_F11 = 34048
    Const KEY_F12 = 34304
    Const KEY_RIGHT_CONTROL = 100305
    Const KEY_LEFT_CONTROL = 100306
    Const KEY_RIGHT_ALT = 100306
    Const KEY_LEFT_ALT = 100308
    ' QB64 errors that we can throw if something bad happens
    Const ERROR_CANNOT_CONTINUE = 17
    Const ERROR_INTERNAL_ERROR = 51
    Const ERROR_FEATURE_UNAVAILABLE = 73
    Const ERROR_INVALID_HANDLE = 258
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------------------------------------------------------------


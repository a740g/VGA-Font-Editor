'-----------------------------------------------------------------------------------------------------------------------
' VGA font editor
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$INCLUDE:'include/BitwiseOps.bi'
'$INCLUDE:'include/MathOps.bi'
'$INCLUDE:'include/StringOps.bi'
'$INCLUDE:'include/FileOps.bi'
'$INCLUDE:'include/TimeOps.bi'
'$INCLUDE:'include/Base64.bi'
'$INCLUDE:'include/ANSIPrint.bi'
'$INCLUDE:'include/VGAFont.bi'
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' METACOMMANDS
'-----------------------------------------------------------------------------------------------------------------------
$NOPREFIX
$RESIZE:SMOOTH
$COLOR:32
$EXEICON:'.\VGAFontEditor.ico'
$VERSIONINFO:CompanyName=Samuel Gomes
$VERSIONINFO:FileDescription=VGA Font Editor executable
$VERSIONINFO:InternalName=VGAFontEditor
$VERSIONINFO:LegalCopyright=Copyright (c) 2023 Samuel Gomes
$VERSIONINFO:LegalTrademarks=All trademarks are property of their respective owners
$VERSIONINFO:OriginalFilename=VGAFontEditor.exe
$VERSIONINFO:ProductName=VGA Font Editor
$VERSIONINFO:Web=https://github.com/a740g
$VERSIONINFO:Comments=https://github.com/a740g
$VERSIONINFO:FILEVERSION#=4,2,0,0
$VERSIONINFO:ProductVersion=4,2,0,0
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' CONSTANTS
'-----------------------------------------------------------------------------------------------------------------------
CONST APP_NAME = "VGA Font Editor"
' Program events
CONST EVENT_NONE = 0
CONST EVENT_QUIT = 1
CONST EVENT_COMMAND = 2
CONST EVENT_NEW = 3
CONST EVENT_LOAD = 4
CONST EVENT_CHOOSE = 5
CONST EVENT_EDIT = 6
CONST EVENT_PREVIEW = 7
CONST EVENT_SAVE = 8
CONST EVENT_IMPORT = 9
' Font metric limits
CONST FONT_WIDTH = 8
CONST FONT_HEIGHT_MIN = 8
CONST FONT_HEIGHT_MAX = 32
' Screen properties
CONST SCREEN_WIDTH = 640
CONST SCREEN_HEIGHT = 480
' FPS
CONST UPDATES_PER_SECOND = 30
' Blinky stuff
CONST BLINK_TICKS = 300
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' GLOBAL VARIABLES
'-----------------------------------------------------------------------------------------------------------------------
DIM SHARED sFontFile AS STRING ' the name of the font file we are viewing / editing
DIM SHARED ubFontCharacter AS UNSIGNED BYTE ' the glyph we are editing
DIM SHARED bFontChanged AS BYTE ' has the font changed?
DIM SHARED sClipboard AS STRING ' our clipboard that holds a single glyph
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT
'-----------------------------------------------------------------------------------------------------------------------
CHDIR STARTDIR$ ' change to the directory specifed by the environment
CONTROLCHR OFF ' turn off control characters
SCREEN NEWIMAGE(SCREEN_WIDTH, SCREEN_HEIGHT, 32) ' switch to graphics mode
SetWindowTitle ' set app title
ALLOWFULLSCREEN SQUAREPIXELS , SMOOTH ' allow the program window to run fullscreen with Alt+Enter
SetRandomSeed TIMER ' seed randomizer

DIM event AS BYTE: event = EVENT_COMMAND ' default's to command line event on program entry

' Event loop
DO
    SELECT CASE event
        CASE EVENT_COMMAND
            event = OnCommandLine

        CASE EVENT_NEW
            event = OnNewFont

        CASE EVENT_IMPORT
            event = OnImportAtlas

        CASE EVENT_LOAD
            event = OnLoadFont

        CASE EVENT_SAVE
            event = OnSaveFont

        CASE EVENT_CHOOSE
            event = OnChooseCharacter

        CASE EVENT_EDIT
            event = OnEditCharacter

        CASE EVENT_PREVIEW
            event = OnShowPreview

        CASE EVENT_QUIT
            IF bFontChanged THEN
                ' Attempt to save the changes
                event = OnSaveFont

                ' Check the user really wants to quit
                IF MESSAGEBOX(APP_NAME, "Are you sure you want to quit?", "yesno", "question") = 1 THEN
                    EXIT DO
                END IF
            ELSE
                EXIT DO
            END IF

        CASE ELSE
            event = OnWelcomeScreen
    END SELECT
LOOP

SYSTEM
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' FUNCTIONS AND SUBROUTINES
'-----------------------------------------------------------------------------------------------------------------------
FUNCTION OnWelcomeScreen%%
    ' Save the current destination
    DIM oldDest AS LONG: oldDest = DEST

    ' Save the old print mode
    DIM oldPM AS LONG: oldPM = PRINTMODE

    ' Now create a new image
    DIM img AS LONG: img = NEWIMAGE(80 * FONT_WIDTH, 31 * 16, 32) ' we'll allocate some extra height to avoid any scrolling

    ' Change destination and render the ANSI art
    DEST img
    RESTORE Data_vga_font_editor_logo_3_ans_3737
    DIM buffer AS STRING: buffer = LoadResource
    PrintANSI buffer

    ' Capture rendered image to another image
    DIM imgANSI AS LONG: imgANSI = NEWIMAGE(80 * FONT_WIDTH, 30 * 16, 32)
    PUTIMAGE (0, 0), img, imgANSI ' any excess height will simply get clipped
    CLEARCOLOR Black, imgANSI ' set all black pixels to be transparent

    ' Render the menu
    CLS , RGBA32(255, 255, 255, 102) ' clear the image to a translucent white
    PRINTMODE KEEPBACKGROUND
    COLOR , Black
    COLOR Lime: PRINT "F1";: COLOR LightGray: PRINT " ............";: COLOR Yellow: PRINT " LOAD"
    COLOR Lime: PRINT "F2";: COLOR LightGray: PRINT " .............";: COLOR Yellow: PRINT " NEW"
    COLOR Lime: PRINT "F3";: COLOR LightGray: PRINT " ..........";: COLOR Yellow: PRINT " IMPORT"
    COLOR Lime: PRINT "ENTER";: COLOR LightGray: PRINT " .......";: COLOR Yellow: PRINT " CHOOSE"
    COLOR Lime: PRINT "ESC";: COLOR LightGray: PRINT " ...........";: COLOR Yellow: PRINT " QUIT"

    ' Capture the rendered image
    DIM imgMenu AS LONG: imgMenu = NEWIMAGE(20 * FONT_WIDTH, 5 * 16, 32)
    PUTIMAGE (0, 0), img, imgMenu ' all excess stuff will get clipped

    ' Do some cleanup
    SELECT CASE oldPM
        CASE 1
            PRINTMODE KEEPBACKGROUND
        CASE 2
            PRINTMODE ONLYBACKGROUND
        CASE ELSE
            PRINTMODE FILLBACKGROUND
    END SELECT
    DEST oldDest
    FREEIMAGE img

    CONST STAR_COUNT = 1024 ' the maximum stars that we can show
    DIM starP(1 TO STAR_COUNT) AS Vector3FType
    DIM starC(1 TO STAR_COUNT) AS UNSIGNED LONG
    DIM AS LONG i, k
    DIM e AS BYTE

    FOR i = 1 TO STAR_COUNT
        starP(i).x = -1! ' this will let the below logic to kick-in
    NEXT

    ' No need to calculate this again and again
    CONST SCREEN_HALF_WIDTH = SCREEN_WIDTH / 2
    CONST SCREEN_HALF_HEIGHT = SCREEN_HEIGHT / 2

    DO
        CLS , Black ' clear the page

        FOR i = 1 TO STAR_COUNT
            IF starP(i).x < 0 OR starP(i).x >= SCREEN_WIDTH OR starP(i).y < 0 OR starP(i).y >= SCREEN_HEIGHT THEN
                starP(i).x = GetRandomBetween(0, SCREEN_WIDTH - 1)
                starP(i).y = GetRandomBetween(0, SCREEN_HEIGHT - 1)
                starP(i).z = 4096!
                starC(i) = RGB32(GetRandomBetween(64, 255), GetRandomBetween(64, 255), GetRandomBetween(64, 255))
            END IF

            PSET (starP(i).x, starP(i).y), starC(i)

            starP(i).z = starP(i).z + 0.5!
            starP(i).x = ((starP(i).x - SCREEN_HALF_WIDTH) * (starP(i).z / 4096!)) + SCREEN_HALF_WIDTH
            starP(i).y = ((starP(i).y - SCREEN_HALF_HEIGHT) * (starP(i).z / 4096!)) + SCREEN_HALF_HEIGHT
        NEXT

        PUTIMAGE (0, 0), imgANSI
        PUTIMAGE (SCREEN_HALF_WIDTH - WIDTH(imgMenu) \ 2, SCREEN_HALF_HEIGHT - HEIGHT(imgMenu) \ 2), imgMenu

        LIMIT UPDATES_PER_SECOND
        DISPLAY

        k = KEYHIT

        SELECT CASE k
            CASE KEY_F1
                e = EVENT_LOAD

            CASE KEY_F2
                e = EVENT_NEW

            CASE KEY_F3
                e = EVENT_IMPORT

            CASE KEY_ENTER
                IF PSF1_GetFontHeight > 0 THEN e = EVENT_CHOOSE

            CASE KEY_ESCAPE
                e = EVENT_QUIT

            CASE ELSE
                e = EVENT_NONE
        END SELECT

        IF EXIT > 0 THEN e = EVENT_QUIT
    LOOP WHILE e = EVENT_NONE

    AUTODISPLAY

    ' Do some cleanup
    FREEIMAGE imgMenu
    FREEIMAGE imgANSI

    OnWelcomeScreen = e

    Data_vga_font_editor_logo_3_ans_3737:
    DATA 3737,1064,-1
    DATA eJyVV91t4zAMfi/QCfKi28Cpk/Yho2SAAgd4N0fr0LZWOYmk+CPZMU4BKomkyI9/knt5DtPnR7BjvjzH
    DATA 4XH7mWJe/DxuwxT+Z/THnX7Lvj7GPEcAuDzFSiFnNiA1n4ZMW/IqS0IdyFhUKSC/cGIsqk4woJFJDpEZ
    DATA D6HlMgRwg2CYg/5kPfv5YUXEyXGctiwwqqsr8joiVAKpSzgaIuvVs3K8WkeTX1ONNSNw22vH3THS0XaR
    DATA 7MPznoHfssQOCtjxgBL63gshlLBcfZx7ElSKg6xja/hefmW/96AXrGfx5k1uCIUNHmPYw+hFoBB8/RdN
    DATA XRO32FvfUPHwsKAOKqRNxqFPzL9jMu428h2B8N19bzY+3cvMx2y9B1Unvnhtazh1TxJ25E2e7ta3vPgm
    DATA KIH+Yingwl4YQpTZK2qNNJDOUPCR72kTi6tBgtdGGXkOm8VFYhiSAzQUkWPjebo5KMZn465d+rsUWh3H
    DATA kZFQvLOPpFEisfLlobnna3LBwfVTRVhg42DVwK2NxG36/fuHTFo0zVujiRn0Zq5QysFhSk0sKh+ZbFlO
    DATA EHUTuZ3nxZos7fA1cTNgC9TdWiWTFzEp2TRvnLH1yJy4mNXcpNliLxedAD8geydEkBiHhs9GeZTn+dJ/
    DATA 6dSx8DfHooPvEnzKeXO0lg1+C1w1S6jRPm1s4swb/IiAmOrACLFys6LHpjedEya2B/yLziVOL/KSY72F
    DATA RIpJngzThWRCdXUB4QrWAEHcAwowm1KLrfEK7X0ikrOrH4gxvrL2Jf+ylRhSDyBHqUQ2YHmndJ4OJURY
    DATA 0pIJdNT5ymIOldlYK67YXIQxW0lTNIXKtJJlieVht5IYUUNhSmgShTX7S20HOktXHZi8zCGTTJrmNss+
    DATA zyGEpqxU9CAIZDsCoSvZiJiTF3/SVw1BXq4QeRXn2lBsBDtF2yPOvaGKYzF9Cfwe53yGQEvKLGhgIdkN
    DATA F40a00KFtG9Uy940UpBOKrsFI99AAC5q7uq+Z41H9uaKr1d1H2+/18s7Dnqu7uU9Tj72kfFgZQP/kBTl
    DATA cTRjr5G6DnozIv+79A8QGpjU
END FUNCTION


' Creates an empty font file
FUNCTION OnNewFont%%
    DIM ubFontHeight AS LONG

    ' Attempt to save the font if there is one
    OnNewFont = OnSaveFont

    ubFontHeight = VAL(INPUTBOX$(APP_NAME, "Enter new font height in pixels (8 - 32):", STR$(ubFontHeight)))

    IF ubFontHeight < FONT_HEIGHT_MIN OR ubFontHeight > FONT_HEIGHT_MAX THEN
        IF PSF1_GetFontHeight <= 0 THEN
            OnNewFont = EVENT_NONE
        ELSE
            MESSAGEBOX APP_NAME, "Enter a valid font height!", "error"
        END IF

        EXIT FUNCTION
    END IF

    sFontFile = EMPTY_STRING
    bFontChanged = TRUE
    PSF1_SetFontHeight ubFontHeight
    ResizeClipboard
    SetWindowTitle
END FUNCTION


' Imports a font from a raw VGA font dump (like bin2psf.bas)
FUNCTION ImportRaw%% (fileName AS STRING)
    DIM h AS LONG: h = GetFileSize(fileName) ' get the file size

    DIM buffer AS STRING: buffer = LoadFile(fileName) ' load the whole file into memory

    ' Set the font data. This also does basic size check and sets the font height
    IF NOT PSF1_SetFont(buffer) THEN EXIT FUNCTION

    ResizeClipboard
    sFontFile = EMPTY_STRING
    bFontChanged = TRUE
    SetWindowTitle

    ImportRaw = TRUE
END FUNCTION


' Imports a font from a font atlas (image)
' The image format must be supported by QB64
FUNCTION OnImportAtlas%%
    ' Attempt to save the font if there is one
    OnImportAtlas = OnSaveFont

    DIM imgFileName AS STRING: imgFileName = OPENFILEDIALOG$(APP_NAME + ": Import")
    IF LEN(imgFileName) = NULL THEN
        IF PSF1_GetFontHeight <= 0 THEN OnImportAtlas = EVENT_NONE ' do nothing if no font file is loaded
        EXIT FUNCTION
    END IF

    DIM img AS LONG: img = LOADIMAGE(imgFileName, 256) ' load as 8bpp image
    IF img >= -1 THEN
        ' Loading image failed, assume it is a raw ROM font dump and import it
        IF NOT ImportRaw(imgFileName) THEN
            MESSAGEBOX APP_NAME, "Failed to load image / raw font dump: " + imgFileName, "error"
        END IF

        IF PSF1_GetFontHeight <= 0 THEN OnImportAtlas = EVENT_NONE ' do nothing if no font file is loaded
        EXIT FUNCTION
    END IF

    ' Calculate the optimal font height (font width is always 8)
    DIM fntHeight AS LONG: fntHeight = (HEIGHT(img) * FONT_WIDTH) / WIDTH(img)

    ' Check for insane values
    IF fntHeight < FONT_HEIGHT_MIN OR fntHeight > FONT_HEIGHT_MAX THEN
        MESSAGEBOX APP_NAME, "Font height too large or small!", "error"
        FREEIMAGE img ' free the image
        IF PSF1_GetFontHeight <= 0 THEN OnImportAtlas = EVENT_NONE ' Do nothing if no font file is loaded
        EXIT FUNCTION ' leave if we failed to load the image
    END IF

    ' Create the atlas where we can copy from
    DIM atlas AS LONG: atlas = NEWIMAGE(FONT_WIDTH * 16, fntHeight * 16, 256)
    IF atlas >= -1 THEN
        MESSAGEBOX APP_NAME, "Failed to create font atlas image!", "error"
        FREEIMAGE img ' free the image
        IF PSF1_GetFontHeight <= 0 THEN OnImportAtlas = EVENT_NONE ' Do nothing if no font file is loaded
        EXIT FUNCTION ' leave if we failed to load the image
    END IF

    DIM src AS LONG: src = SOURCE ' save the old source

    ' Check if the atlas has some weird color-key and if so change it to black
    SOURCE img ' set img as the source for POINT to work
    CLEARCOLOR POINT(WIDTH(img) - 1, HEIGHT(img) - 1), img ' change the color we get from the last pixel to transparent

    PUTIMAGE , img, atlas ' stretch blit the image on the atlas

    PSF1_SetFontHeight fntHeight
    ResizeClipboard

    SOURCE atlas ' change source to atlas

    ' Now copy all 256 characters
    DIM AS LONG c, sx, sy, x, y
    FOR c = 0 TO 255
        sx = (c MOD 16) * FONT_WIDTH ' starting x of char c
        sy = (c \ 16) * fntHeight ' starting y of char c
        FOR y = 0 TO fntHeight - 1
            FOR x = 0 TO FONT_WIDTH - 1
                PSF1_SetGlyphPixel c, x, y, POINT(sx + x, sy + y) <> 0
            NEXT
        NEXT
    NEXT

    SOURCE src ' restore source
    FREEIMAGE atlas
    FREEIMAGE img

    sFontFile = EMPTY_STRING
    bFontChanged = TRUE
    SetWindowTitle
END FUNCTION


' Handles and command line parameters
FUNCTION OnCommandLine%%
    OnCommandLine = EVENT_NONE ' Default to no event

    ' Check if any help is needed
    IF COMMAND$(1) = "/?" OR COMMAND$(1) = "-?" THEN
        MESSAGEBOX APP_NAME, APP_NAME + CHR$(13) + "Syntax: EDITFONT [fontfile.psf]" _
            + CHR$(13) + "    /?: Shows this message" _
            + STRING$(2, 13) + "Copyright (c) 1998-2022, Samuel Gomes" _
            + STRING$(2, 13) + "https://github.com/a740g/", "info"
        OnCommandLine = EVENT_QUIT
        EXIT FUNCTION ' Exit the function and allow the main loop to handle the quit event
    END IF

    ' Fetch the file name from the command line
    sFontFile = COMMAND$(1)

    IF LEN(sFontFile) <> NULL THEN
        IF FILEEXISTS(sFontFile) THEN
            ' Read in the font
            DIM psf AS PSF1Type
            IF PSF1_LoadFontFromFile(sFontFile, psf) THEN
                PSF1_SetCurrentFont psf
                ResizeClipboard
                SetWindowTitle
            ELSE
                MESSAGEBOX APP_NAME, "Failed to load " + sFontFile + "!", "error"
                sFontFile = EMPTY_STRING
            END IF
        ELSE
            ' If this is a new file ask use for specs
            OnCommandLine = OnNewFont
        END IF
    END IF
END FUNCTION


' This is called when a font has to be loaded
FUNCTION OnLoadFont%%
    DIM tmpFilename AS STRING

    ' Attempt to save the font if there is one
    OnLoadFont = OnSaveFont

    ' Get an existing font file name from the user
    tmpFilename = OPENFILEDIALOG$(APP_NAME + ": Open", , "*.psf|*.PSF|*.Psf", "PC Screen Font files")

    ' Exit if user canceled
    IF LEN(tmpFilename) = NULL THEN
        IF PSF1_GetFontHeight <= 0 THEN OnLoadFont = EVENT_NONE ' Do nothing if no font file is loaded
        EXIT FUNCTION
    END IF

    ' Read in the font
    DIM psf AS PSF1Type
    IF PSF1_LoadFontFromFile(tmpFilename, psf) THEN
        PSF1_SetCurrentFont psf
        ResizeClipboard
        sFontFile = tmpFilename
        bFontChanged = FALSE
        SetWindowTitle
    ELSE
        MESSAGEBOX APP_NAME, "Failed to load " + tmpFilename + "!", "error"
        OnLoadFont = EVENT_NONE
    END IF
END FUNCTION


' This is called when the file should be saved
FUNCTION OnSaveFont%%
    OnSaveFont = EVENT_CHOOSE ' default to the character choose event

    ' Only attempt to save if the font has changed
    IF bFontChanged THEN
        IF LEN(sFontFile) = NULL THEN
            ' Check if the user wants to save the new font
            IF MESSAGEBOX(APP_NAME, "Do you want to save the new font?", "yesno", "question") = 0 THEN EXIT FUNCTION

            ' Get a font file name from the user
            DIM tmpFilename AS STRING: tmpFilename = SAVEFILEDIALOG$(APP_NAME + ": Save", , "*.psf|*.PSF|*.Psf", "Font files")

            ' Exit if user canceled
            IF LEN(tmpFilename) = NULL THEN EXIT FUNCTION

            sFontFile = tmpFilename ' set the font filename
        ELSE
            ' Ask the user if they want to overwrite the current file
            IF MESSAGEBOX(APP_NAME, "Font " + sFontFile + " has changed. Save it now?", "yesno", "question") = 0 THEN EXIT FUNCTION
        END IF

        ' Save the font
        IF PSF1_SaveFont(sFontFile) THEN
            bFontChanged = FALSE ' clear the font changed flag now
            SetWindowTitle ' update the window title
        ELSE
            MESSAGEBOX APP_NAME, "Failed to save " + sFontFile + "!", "error"
        END IF
    END IF
END FUNCTION


' This is the character selector routine
FUNCTION OnChooseCharacter%%
    STATIC AS LONG xp, yp
    DIM ticks AS UNSIGNED INTEGER64, blinkState AS BYTE

    ' Save the current tick
    ticks = GetTicks

    CLS , Black

    ' Show some info
    COLOR Aqua, Navy
    DrawTextBox 43, 1, 80, 30, "Controls"
    COLOR , Navy
    LOCATE 3, 47: COLOR Lime: PRINT "Left Arrow";: COLOR DimGray: PRINT " ......... ";: COLOR White: PRINT "Move left";
    LOCATE 5, 47: COLOR Lime: PRINT "Right Arrow";: COLOR DimGray: PRINT " ....... ";: COLOR White: PRINT "Move right";
    LOCATE 7, 47: COLOR Lime: PRINT "Up Arrow";: COLOR DimGray: PRINT " ............. ";: COLOR White: PRINT "Move up";
    LOCATE 9, 47: COLOR Lime: PRINT "Down Arrow";: COLOR DimGray: PRINT " ......... ";: COLOR White: PRINT "Move down";
    LOCATE 11, 47: COLOR Lime: PRINT "Mouse Pointer";: COLOR DimGray: PRINT " ......... ";: COLOR White: PRINT "Select";
    LOCATE 13, 47: COLOR Lime: PRINT "Left Button";: COLOR DimGray: PRINT " ... ";: COLOR White: PRINT "Edit character";
    LOCATE 15, 47: COLOR Lime: PRINT "Right Button";: COLOR DimGray: PRINT " .. ";: COLOR White: PRINT "Edit character";
    LOCATE 17, 47: COLOR Lime: PRINT "Enter";: COLOR DimGray: PRINT " ......... ";: COLOR White: PRINT "Edit character";
    LOCATE 19, 47: COLOR Lime: PRINT "F1";: COLOR DimGray: PRINT " ................. ";: COLOR White: PRINT "Load font";
    LOCATE 21, 47: COLOR Lime: PRINT "F2";: COLOR DimGray: PRINT " .................. ";: COLOR White: PRINT "New font";
    LOCATE 23, 47: COLOR Lime: PRINT "F9";: COLOR DimGray: PRINT " ................. ";: COLOR White: PRINT "Save font";
    LOCATE 25, 47: COLOR Lime: PRINT "F5";: COLOR DimGray: PRINT " .............. ";: COLOR White: PRINT "Show preview";
    LOCATE 27, 47: COLOR Lime: PRINT "Escape";: COLOR DimGray: PRINT " ............. ";: COLOR White: PRINT "Main menu";

    ' Draw the main character set area
    COLOR White, DimGray
    DrawTextBox 1, 1, 42, 30, "Select a character to edit"

    DIM AS LONG x, y

    ' Draw the characters
    COLOR Yellow, Navy
    FOR y = 0 TO 7
        FOR x = 0 TO 31
            PSF1_DrawCharacter 32 * y + x, 9 + x * (PSF1_GetFontWidth + 2), 32 + y * (PSF1_GetFontHeight + 2)
        NEXT
    NEXT

    DIM in AS LONG

    ' Clear keyboard and mouse
    ClearInput

    DO
        IF MOUSEINPUT THEN
            IF GetMouseOverCharPosiion(x, y) THEN
                ' Turn off the current highlight
                DrawCharSelector xp, yp, DimGray
                xp = x
                yp = y
                DrawCharSelector xp, yp, White

                ' Also check for mouse click
                IF MOUSEBUTTON(1) OR MOUSEBUTTON(2) THEN
                    ubFontCharacter = 32 * yp + xp
                    OnChooseCharacter = EVENT_EDIT
                    EXIT DO
                END IF
            END IF
        ELSE
            LIMIT UPDATES_PER_SECOND
        END IF

        in = KEYHIT

        SELECT CASE in
            CASE KEY_LEFT_ARROW
                DrawCharSelector xp, yp, DimGray
                xp = xp - 1
                IF xp < 0 THEN xp = 31
                DrawCharSelector xp, yp, White

            CASE KEY_RIGHT_ARROW
                DrawCharSelector xp, yp, DimGray
                xp = xp + 1
                IF xp > 31 THEN xp = 0
                DrawCharSelector xp, yp, White

            CASE KEY_UP_ARROW
                DrawCharSelector xp, yp, DimGray
                yp = yp - 1
                IF yp < 0 THEN yp = 7
                DrawCharSelector xp, yp, White

            CASE KEY_DOWN_ARROW
                DrawCharSelector xp, yp, DimGray
                yp = yp + 1
                IF yp > 7 THEN yp = 0
                DrawCharSelector xp, yp, White

            CASE KEY_ENTER
                ubFontCharacter = 32 * yp + xp
                OnChooseCharacter = EVENT_EDIT
                EXIT DO

            CASE KEY_F9
                OnChooseCharacter = EVENT_SAVE
                EXIT DO

            CASE KEY_F1
                OnChooseCharacter = EVENT_LOAD
                EXIT DO

            CASE KEY_F2
                OnChooseCharacter = EVENT_NEW
                EXIT DO

            CASE KEY_F5
                OnChooseCharacter = EVENT_PREVIEW
                EXIT DO

            CASE KEY_ESCAPE
                OnChooseCharacter = EVENT_NONE
                EXIT DO

            CASE ELSE
                ' Blink the selector at regular intervals
                IF GetTicks - ticks > BLINK_TICKS THEN
                    ticks = GetTicks
                    blinkState = NOT blinkState

                    IF blinkState THEN
                        DrawCharSelector xp, yp, White
                    ELSE
                        DrawCharSelector xp, yp, DimGray
                    END IF
                END IF
        END SELECT

        IF EXIT > 0 THEN
            OnChooseCharacter = EVENT_QUIT
            EXIT DO
        END IF
    LOOP
END FUNCTION


' This is font bitmap editor routine
FUNCTION OnEditCharacter%%
    DIM ticks AS UNSIGNED INTEGER64, blinkState AS BYTE

    ' Save the current tick
    ticks = GetTicks

    CLS , Black

    ' Show some info
    COLOR Aqua, Navy
    DrawTextBox 43, 1, 80, 30, "Controls"
    COLOR , Navy
    LOCATE 4, 47: COLOR Lime: PRINT "Left Arrow";: COLOR DimGray: PRINT " ......... ";: COLOR White: PRINT "Move left"
    LOCATE 5, 47: COLOR Lime: PRINT "Right Arrow";: COLOR DimGray: PRINT " ....... ";: COLOR White: PRINT "Move right"
    LOCATE 6, 47: COLOR Lime: PRINT "Up Arrow";: COLOR DimGray: PRINT " ............. ";: COLOR White: PRINT "Move up"
    LOCATE 7, 47: COLOR Lime: PRINT "Down Arrow";: COLOR DimGray: PRINT " ......... ";: COLOR White: PRINT "Move down"
    LOCATE 8, 47: COLOR Lime: PRINT "Mouse Pointer";: COLOR DimGray: PRINT " ......... ";: COLOR White: PRINT "Select"
    LOCATE 9, 47: COLOR Lime: PRINT "Left Button";: COLOR DimGray: PRINT " ......... ";: COLOR White: PRINT "Pixel on"
    LOCATE 10, 47: COLOR Lime: PRINT "Right Button";: COLOR DimGray: PRINT " ....... ";: COLOR White: PRINT "Pixel off"
    LOCATE 11, 47: COLOR Lime: PRINT "Spacebar";: COLOR DimGray: PRINT " ........ ";: COLOR White: PRINT "Toggle pixel"
    LOCATE 12, 47: COLOR Lime: PRINT "Delete";: COLOR DimGray: PRINT " ................. ";: COLOR White: PRINT "Clear"
    LOCATE 13, 47: COLOR Lime: PRINT "Insert";: COLOR DimGray: PRINT " .................. ";: COLOR White: PRINT "Fill"
    LOCATE 14, 47: COLOR Lime: PRINT "X";: COLOR DimGray: PRINT " ........................ ";: COLOR White: PRINT "Cut"
    LOCATE 15, 47: COLOR Lime: PRINT "C";: COLOR DimGray: PRINT " ....................... ";: COLOR White: PRINT "Copy"
    LOCATE 16, 47: COLOR Lime: PRINT "P";: COLOR DimGray: PRINT " ...................... ";: COLOR White: PRINT "Paste"
    LOCATE 17, 47: COLOR Lime: PRINT "H";: COLOR DimGray: PRINT " ............ ";: COLOR White: PRINT "Flip horizontal"
    LOCATE 18, 47: COLOR Lime: PRINT "V";: COLOR DimGray: PRINT " .............. ";: COLOR White: PRINT "Flip vertical"
    LOCATE 19, 47: COLOR Lime: PRINT "I";: COLOR DimGray: PRINT " ..................... ";: COLOR White: PRINT "Invert"
    LOCATE 20, 47: COLOR Lime: PRINT "A";: COLOR DimGray: PRINT " ............ ";: COLOR White: PRINT "Horizontal line"
    LOCATE 21, 47: COLOR Lime: PRINT "W";: COLOR DimGray: PRINT " .............. ";: COLOR White: PRINT "Vertical line"
    LOCATE 22, 47: COLOR Lime: PRINT "Home";: COLOR DimGray: PRINT " .............. ";: COLOR White: PRINT "Slide left"
    LOCATE 23, 47: COLOR Lime: PRINT "End";: COLOR DimGray: PRINT " .............. ";: COLOR White: PRINT "Slide right"
    LOCATE 24, 47: COLOR Lime: PRINT "Page Up";: COLOR DimGray: PRINT " ............. ";: COLOR White: PRINT "Slide up"
    LOCATE 25, 47: COLOR Lime: PRINT "Page Down";: COLOR DimGray: PRINT " ......... ";: COLOR White: PRINT "Slide down"
    LOCATE 26, 47: COLOR Lime: PRINT "Enter";: COLOR DimGray: PRINT " .......... ";: COLOR White: PRINT "Save & return"
    LOCATE 27, 47: COLOR Lime: PRINT "Escape";: COLOR DimGray: PRINT " ....... ";: COLOR White: PRINT "Cancel & return"

    ' Draw the main character set area
    COLOR White, DimGray
    DrawTextBox 1, 1, 42, 30, TRIM$(STR$(ubFontCharacter) + ": " + CHR$(ubFontCharacter))
    LOCATE 2, 27: COLOR Navy, Yellow: PRINT "Demonstration:";

    ' Save a copy of this character
    DIM cpy AS STRING: cpy = PSF1_GetGlyphBitmap(ubFontCharacter)

    ' Draw the initial bitmap
    DrawCharBitmap ubFontCharacter
    DrawDemo

    DIM AS LONG xp, yp, x, y, in
    DIM tmp AS STRING, sl AS UNSIGNED BYTE

    ' Clear keyboard and mouse
    ClearInput

    DO
        IF MOUSEINPUT THEN
            IF GetMouseOverCellPosition(x, y) THEN
                ' Turn off the current highlight
                DrawCellSelector xp, yp, DimGray
                xp = x
                yp = y
                DrawCellSelector xp, yp, White

                ' Also check for mouse click
                IF MOUSEBUTTON(1) THEN
                    ' Flag font changed
                    bFontChanged = TRUE
                    PSF1_SetGlyphPixel ubFontCharacter, xp, yp, TRUE
                    DrawCharBit ubFontCharacter, xp, yp
                    DrawDemo
                ELSEIF MOUSEBUTTON(2) THEN
                    ' Flag font changed
                    bFontChanged = TRUE
                    PSF1_SetGlyphPixel ubFontCharacter, xp, yp, FALSE
                    DrawCharBit ubFontCharacter, xp, yp
                    DrawDemo
                END IF
            END IF
        ELSE
            LIMIT UPDATES_PER_SECOND
        END IF

        in = KEYHIT

        SELECT CASE in
            CASE KEY_LEFT_ARROW ' Move left
                DrawCellSelector xp, yp, DimGray
                xp = xp - 1
                IF xp < 0 THEN xp = PSF1_GetFontWidth - 1
                DrawCellSelector xp, yp, White

            CASE KEY_RIGHT_ARROW ' Move right
                DrawCellSelector xp, yp, DimGray
                xp = xp + 1
                IF xp >= PSF1_GetFontWidth THEN xp = 0
                DrawCellSelector xp, yp, White

            CASE KEY_UP_ARROW ' Move up
                DrawCellSelector xp, yp, DimGray
                yp = yp - 1
                IF yp < 0 THEN yp = PSF1_GetFontHeight - 1
                DrawCellSelector xp, yp, White

            CASE KEY_DOWN_ARROW ' Move down
                DrawCellSelector xp, yp, DimGray
                yp = yp + 1
                IF yp >= PSF1_GetFontHeight THEN yp = 0
                DrawCellSelector xp, yp, White

            CASE KEY_SPACE ' Toggle pixel
                ' Flag font changed
                bFontChanged = TRUE

                PSF1_SetGlyphPixel ubFontCharacter, xp, yp, NOT PSF1_GetGlyphPixel(ubFontCharacter, xp, yp)
                DrawCharBit ubFontCharacter, xp, yp
                DrawDemo

            CASE KEY_DELETE ' Clear bitmap
                ' Flag font changed
                bFontChanged = TRUE

                PSF1_SetGlyphBitmap ubFontCharacter, STRING$(PSF1_GetFontHeight, NULL)
                DrawCharBitmap ubFontCharacter
                DrawDemo

            CASE KEY_INSERT ' Fill bitmap
                ' Flag font changed
                bFontChanged = TRUE

                PSF1_SetGlyphBitmap ubFontCharacter, STRING$(PSF1_GetFontHeight, 255)
                DrawCharBitmap ubFontCharacter
                DrawDemo

            CASE KEY_LOWER_X, KEY_UPPER_X ' Cut
                ' Flag font changed
                bFontChanged = TRUE

                sClipboard = PSF1_GetGlyphBitmap(ubFontCharacter)
                PSF1_SetGlyphBitmap ubFontCharacter, STRING$(PSF1_GetFontHeight, NULL)
                DrawCharBitmap ubFontCharacter
                DrawDemo

            CASE KEY_LOWER_C, KEY_UPPER_C ' Copy
                sClipboard = PSF1_GetGlyphBitmap(ubFontCharacter)

            CASE KEY_LOWER_P, KEY_UPPER_P ' Paste
                ' Flag font changed
                bFontChanged = TRUE

                PSF1_SetGlyphBitmap ubFontCharacter, sClipboard
                DrawCharBitmap ubFontCharacter
                DrawDemo

            CASE KEY_LOWER_H, KEY_UPPER_H ' Horizontal flip
                ' Flag font changed
                bFontChanged = TRUE

                tmp = PSF1_GetGlyphBitmap(ubFontCharacter)
                FOR y = 1 TO PSF1_GetFontHeight
                    ASC(tmp, y) = ReverseBitsByte(ASC(tmp, y))
                NEXT
                PSF1_SetGlyphBitmap ubFontCharacter, tmp
                DrawCharBitmap ubFontCharacter
                DrawDemo

            CASE KEY_LOWER_V, KEY_UPPER_V ' Vertical flip
                ' Flag font changed
                bFontChanged = TRUE

                PSF1_SetGlyphBitmap ubFontCharacter, ReverseString(PSF1_GetGlyphBitmap(ubFontCharacter))
                DrawCharBitmap ubFontCharacter
                DrawDemo

            CASE KEY_LOWER_I, KEY_UPPER_I ' Invert
                ' Flag font changed
                bFontChanged = TRUE

                tmp = PSF1_GetGlyphBitmap(ubFontCharacter)
                FOR y = 1 TO PSF1_GetFontHeight
                    ASC(tmp, y) = 255 - ASC(tmp, y)
                NEXT
                PSF1_SetGlyphBitmap ubFontCharacter, tmp
                DrawCharBitmap ubFontCharacter
                DrawDemo

            CASE KEY_LOWER_A, KEY_UPPER_A ' Horizontal line
                ' Flag font changed
                bFontChanged = TRUE

                tmp = PSF1_GetGlyphBitmap(ubFontCharacter)
                ASC(tmp, yp + 1) = 255
                PSF1_SetGlyphBitmap ubFontCharacter, tmp
                DrawCharBitmap ubFontCharacter
                DrawDemo

            CASE KEY_LOWER_W, KEY_UPPER_W ' Vertical line
                ' Flag font changed
                bFontChanged = TRUE

                FOR y = 0 TO PSF1_GetFontHeight - 1
                    PSF1_SetGlyphPixel ubFontCharacter, xp, y, TRUE
                NEXT
                DrawCharBitmap ubFontCharacter
                DrawDemo

            CASE KEY_HOME ' Slide left
                ' Flag font changed
                bFontChanged = TRUE

                tmp = PSF1_GetGlyphBitmap(ubFontCharacter)
                FOR y = 1 TO PSF1_GetFontHeight
                    sl = ASC(tmp, y) ' Asc() returns integer instead of byte :(
                    ASC(tmp, y) = ROL(sl, 1)
                NEXT
                PSF1_SetGlyphBitmap ubFontCharacter, tmp
                DrawCharBitmap ubFontCharacter
                DrawDemo

            CASE KEY_END ' Slide right
                ' Flag font changed
                bFontChanged = TRUE

                tmp = PSF1_GetGlyphBitmap(ubFontCharacter)
                FOR y = 1 TO PSF1_GetFontHeight
                    sl = ASC(tmp, y) ' Asc() returns integer instead of byte :(
                    ASC(tmp, y) = ROR(sl, 1)
                NEXT
                PSF1_SetGlyphBitmap ubFontCharacter, tmp
                DrawCharBitmap ubFontCharacter
                DrawDemo

            CASE KEY_PAGE_UP ' Slide up
                ' Flag font changed
                bFontChanged = TRUE

                tmp = PSF1_GetGlyphBitmap(ubFontCharacter)
                sl = ASC(tmp, 1)
                FOR y = 1 TO PSF1_GetFontHeight - 1
                    ASC(tmp, y) = ASC(tmp, y + 1)
                NEXT
                ASC(tmp, PSF1_GetFontHeight) = sl
                PSF1_SetGlyphBitmap ubFontCharacter, tmp
                DrawCharBitmap ubFontCharacter
                DrawDemo

            CASE KEY_PAGE_DOWN ' Slide down
                ' Flag font changed
                bFontChanged = TRUE

                tmp = PSF1_GetGlyphBitmap(ubFontCharacter)
                sl = ASC(tmp, PSF1_GetFontHeight)
                FOR y = PSF1_GetFontHeight - 1 TO 1 STEP -1
                    ASC(tmp, y + 1) = ASC(tmp, y)
                NEXT
                ASC(tmp, 1) = sl
                PSF1_SetGlyphBitmap ubFontCharacter, tmp
                DrawCharBitmap ubFontCharacter
                DrawDemo

            CASE KEY_ENTER ' Save & return
                OnEditCharacter = EVENT_CHOOSE

                EXIT DO

            CASE KEY_ESCAPE ' Cancel & return
                PSF1_SetGlyphBitmap ubFontCharacter, cpy

                OnEditCharacter = EVENT_CHOOSE

                EXIT DO

            CASE ELSE
                ' Blink the selector at regular intervals
                IF GetTicks - ticks > BLINK_TICKS THEN
                    ticks = GetTicks
                    blinkState = NOT blinkState

                    IF blinkState THEN
                        DrawCellSelector xp, yp, White
                        IF bFontChanged THEN SetWindowTitle ' update the title only if the user changed the glyph
                    ELSE
                        DrawCellSelector xp, yp, DimGray
                    END IF
                END IF
        END SELECT

        IF EXIT > 0 THEN
            OnEditCharacter = EVENT_QUIT
            EXIT DO
        END IF
    LOOP
END FUNCTION


' Draws a preview screen using the loaded font
FUNCTION OnShowPreview%%
    CLS , Black

    ClearInput

    ' Draw a box on the screen
    COLOR Aqua, Navy
    DrawTextBox 1, 1, 80, 30, "Preview"

    ' Draw the body
    COLOR White, Navy
    PSF1_DrawString "This Fox has a longing for grapes:", PSF1_GetFontWidth * 2, PSF1_GetFontHeight * 3
    PSF1_DrawString "He jumps, but the bunch still escapes.", PSF1_GetFontWidth * 2, PSF1_GetFontHeight * 4
    PSF1_DrawString "So he goes away sour;", PSF1_GetFontWidth * 2, PSF1_GetFontHeight * 5
    PSF1_DrawString "And, 'tis said, to this hour", PSF1_GetFontWidth * 2, PSF1_GetFontHeight * 6
    PSF1_DrawString "Declares that he's no taste for grapes.", PSF1_GetFontWidth * 2, PSF1_GetFontHeight * 7
    PSF1_DrawString "     /\                   ,'|", PSF1_GetFontWidth * 45, PSF1_GetFontHeight * 3
    PSF1_DrawString " o--'O `.                /  /", PSF1_GetFontWidth * 45, PSF1_GetFontHeight * 4
    PSF1_DrawString "  `--.   `-----------._,' ,'", PSF1_GetFontWidth * 45, PSF1_GetFontHeight * 5
    PSF1_DrawString "      \              ,---'", PSF1_GetFontWidth * 45, PSF1_GetFontHeight * 6
    PSF1_DrawString "       ) )    _,--(  |", PSF1_GetFontWidth * 45, PSF1_GetFontHeight * 7
    PSF1_DrawString "      /,^.---'     )/\\", PSF1_GetFontWidth * 45, PSF1_GetFontHeight * 8
    PSF1_DrawString "     ((   \\      ((  \\", PSF1_GetFontWidth * 45, PSF1_GetFontHeight * 9
    PSF1_DrawString "      \)   \)      \) (/", PSF1_GetFontWidth * 45, PSF1_GetFontHeight * 10

    WaitInput

    IF EXIT > 0 THEN OnShowPreview = EVENT_QUIT ELSE OnShowPreview = EVENT_CHOOSE
END FUNCTION


' This sets up the Window tile based on several things
SUB SetWindowTitle
    $CHECKING:OFF
    DIM windowTitle AS STRING

    ' First check if we have loaded a font file
    IF LEN(sFontFile) <> NULL THEN ' loaded from disk
        windowTitle = GetFileNameFromPathOrURL(sFontFile)
    ELSEIF bFontChanged AND LEN(sFontFile) = NULL THEN ' creating new
        windowTitle = "UNTITLED"
    END IF

    ' Add an asterisk if the font file has changed
    IF bFontChanged THEN windowTitle = windowTitle + "*"

    ' Finally add the application name
    IF LEN(windowTitle) <> NULL THEN
        windowTitle = windowTitle + " - " + APP_NAME
    ELSE
        windowTitle = APP_NAME + " " + OS$
    END IF

    TITLE windowTitle
    $CHECKING:ON
END SUB


' Resizes the clipboard to match the font height
SUB ResizeClipboard
    sClipboard = LEFT$(sClipboard + STRING$(PSF1_GetFontHeight, NULL), PSF1_GetFontHeight)
END SUB


' Return true if mouse is over any character
' Updates mxp & myp with position
' This is used by the character chooser
FUNCTION GetMouseOverCharPosiion%% (mxp AS LONG, myp AS LONG)
    $CHECKING:OFF
    DIM AS LONG x, y, fw, fh
    fw = PSF1_GetFontWidth
    fh = PSF1_GetFontHeight
    FOR y = 0 TO 7
        FOR x = 0 TO 31
            IF PointCollidesWithRect(MOUSEX, MOUSEY, 8 + x * (fw + 2), 31 + y * (fh + 2), 9 + fw + x * (fw + 2), 32 + fh + y * (fh + 2)) THEN
                mxp = x
                myp = y
                GetMouseOverCharPosiion = TRUE
                EXIT FUNCTION
            END IF
        NEXT
    NEXT
    $CHECKING:ON
END FUNCTION


' Draw the character selector using color c at xp, yp
SUB DrawCharSelector (xp AS LONG, yp AS LONG, c AS UNSIGNED LONG)
    $CHECKING:OFF
    DIM fw AS LONG: fw = PSF1_GetFontWidth
    DIM fh AS LONG: fh = PSF1_GetFontHeight
    LINE (8 + xp * (fw + 2), 31 + yp * (fh + 2))-(9 + fw + xp * (fw + 2), 32 + fh + yp * (fh + 2)), c, B
    $CHECKING:ON
END SUB


' Return true if mouse is over any cell
' Updates mxp & myp with position
' This is used by the bitmap editor
FUNCTION GetMouseOverCellPosition%% (mxp AS LONG, myp AS LONG)
    $CHECKING:OFF
    DIM AS LONG x, y, w, h, w1, h1
    w = PSF1_GetFontWidth
    h = PSF1_GetFontHeight
    WHILE y < h
        h1 = y * 14
        x = 0
        WHILE x < w
            w1 = x * 14
            IF PointCollidesWithRect(MOUSEX, MOUSEY, 8 + w1, 19 + h1, 22 + w1, 33 + h1) THEN
                mxp = x
                myp = y
                GetMouseOverCellPosition = TRUE
                EXIT FUNCTION
            END IF
            x = x + 1
        WEND
        y = y + 1
    WEND
    $CHECKING:ON
END FUNCTION


' Draw the character cell selector using color c at (x, y)
SUB DrawCellSelector (x AS LONG, y AS LONG, c AS UNSIGNED LONG)
    $CHECKING:OFF
    DIM w AS LONG: w = x * 14
    DIM h AS LONG: h = y * 14
    LINE (8 + w, 19 + h)-(22 + w, 33 + h), c, B
    $CHECKING:ON
END SUB


' This draws a single character pixel block
SUB DrawCharBit (ch AS UNSIGNED BYTE, x AS LONG, y AS LONG)
    $CHECKING:OFF
    DIM xp AS LONG: xp = 9 + x * 14
    DIM yp AS LONG: yp = 20 + y * 14
    IF PSF1_GetGlyphPixel(ch, x, y) THEN
        LINE (xp, yp)-(xp + 12, yp + 12), Yellow, BF
    ELSE
        LINE (xp, yp)-(xp + 12, yp + 12), Navy, BF
    END IF
    $CHECKING:ON
END SUB


' Draw the character bitmap for editing
SUB DrawCharBitmap (ch AS UNSIGNED BYTE)
    $CHECKING:OFF
    DIM AS LONG x, y, w, h
    w = PSF1_GetFontWidth
    h = PSF1_GetFontHeight
    WHILE y < h
        x = 0
        WHILE x < w
            DrawCharBit ch, x, y
            x = x + 1
        WEND
        y = y + 1
    WEND
    $CHECKING:ON
END SUB


' This draws a grid of the same character for demo purpose on the edit screen
SUB DrawDemo
    $CHECKING:OFF
    DIM AS LONG x, y, w, h
    w = PSF1_GetFontWidth
    h = PSF1_GetFontHeight
    COLOR White, Black
    ' Draw the character on the right side using the font rending code
    FOR y = 32 TO 32 + 12 * h STEP h
        FOR x = 208 TO 208 + 13 * w STEP w
            PSF1_DrawCharacter ubFontCharacter, x, y
        NEXT
    NEXT
    $CHECKING:ON
END SUB


' Draw a box using box drawing characters and optionally puts a caption
SUB DrawTextBox (l AS LONG, t AS LONG, r AS LONG, b AS LONG, sCaption AS STRING)
    DIM AS LONG i, inBoxWidth

    ' Calculate the "internal" box width
    inBoxWidth = r - l - 1

    ' Draw the top line
    LOCATE t, l: PRINT CHR$(218); STRING$(inBoxWidth, 196); CHR$(191);

    ' Draw the sides
    FOR i = t + 1 TO b - 1
        LOCATE i, l: PRINT CHR$(179); SPACE$(inBoxWidth); CHR$(179);
    NEXT

    ' Draw the bottom line
    LOCATE b, l: PRINT CHR$(192); STRING$(inBoxWidth, 196); CHR$(217);

    ' Set the caption if specified
    IF LEN(sCaption) <> NULL THEN
        COLOR BACKGROUNDCOLOR, DEFAULTCOLOR
        LOCATE t, l + inBoxWidth \ 2 - LEN(sCaption) \ 2
        PRINT " "; sCaption; " ";
        COLOR BACKGROUNDCOLOR, DEFAULTCOLOR
    END IF
END SUB


' Point & box collision test for mouse
FUNCTION PointCollidesWithRect%% (x AS LONG, y AS LONG, l AS LONG, t AS LONG, r AS LONG, b AS LONG)
    $CHECKING:OFF
    PointCollidesWithRect = (x >= l AND x <= r AND y >= t AND y <= b)
    $CHECKING:ON
END FUNCTION


' Sleeps until some keys or buttons are pressed
SUB WaitInput
    DO
        WHILE MOUSEINPUT
            IF MOUSEBUTTON(1) OR MOUSEBUTTON(2) OR MOUSEBUTTON(3) THEN EXIT DO
        WEND
        LIMIT UPDATES_PER_SECOND
    LOOP WHILE KEYHIT <= NULL
END SUB


' Chear mouse and keyboard events
SUB ClearInput
    WHILE MOUSEINPUT
    WEND
    KEYCLEAR
END SUB
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' MODULE FILES
'-----------------------------------------------------------------------------------------------------------------------
'$INCLUDE:'include/StringOps.bas'
'$INCLUDE:'include/FileOps.bas'
'$INCLUDE:'include/TimeOps.bas'
'$INCLUDE:'include/Base64.bas'
'$INCLUDE:'include/ANSIPrint.bas'
'$INCLUDE:'include/VGAFont.bas'
'-----------------------------------------------------------------------------------------------------------------------
'-----------------------------------------------------------------------------------------------------------------------

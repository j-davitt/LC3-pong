;*****************************************************************************
; Author: Joe Davitt
; Date: 5-4-2025
; Revision: 1.0
;
; Description:
;  LC-3 recreation of a brick / pong game.
;
; Notes:
; 
;
; Register Usage:
; R0 used by traps to display
; R1 game condition
; R2 used in subroutines
; R3 used in subroutines
; R4 stores brick spacer count
; R5 stores time for sleep
; R6 stack address
; R7 jsr return
;****************************************************************************
.ORIG x3000

    LD R6, STACK
    
    ;clear R4 and initialize to 8
    AND R4, R4, #0
    ADD R4, R4, #8
    
    ;initialize ball starting location
    AND R3, R3, #0
    ADD R3, R3, #2
    ST R3, BALL_X
    ST R3, BALL_Y
    ;initialize direction 1
    ADD R3, R3, #-1
    ST R3, BALL_DIR

    JSR enable_int
LOOP    
        JSR CLEAR
        JSR PRINT_SCREEN
        JSR PRINT_BLOCK
        ;write subroutine here to update ball location, return -1 if game over
        JSR CHECK_GAME
        ADD R1, R1, #0
        BRn GAME_OVER
        JSR UPDATE_BALL
        
        ;sleep
        LD R5 TIME
SLEEP   ADD R5, R5, #-1
        BRzp SLEEP
        BR LOOP
        
GAME_OVER
        LEA R0, GO_PROMPT
        PUTS

        
    HALT
    
TIME    .FILL 30000
GO_PROMPT   .STRINGZ "\n\nGAME OVER\n\n"  

BALL_X  .BLKW 3
BALL_Y  .BLKW 3
BALL_DIR .BLKW 3

STACK .FILL xFE00


;********************enable_int*********************
;Enables keyboard interrupts by setting 14th bit for PSR and for KBSR
;
;R1 = PSR
;R2 KBSR
;R3 = mask = not x4000 = xBFFF
;R6 stack
;R7 reserved for the return address
;***************************************************
enable_int:
        ;save registers
        ADD R6, R6, #-1
        STR R1, R6, #0
        ADD R6, R6, #-1
        STR R2, R6, #0
        ADD R6, R6, #-1
        STR R3, R6, #0
        
        ;set interrupt bit on PSR
        LDI R1, PSR
        LD R3, MASK
        ;PSR OR x4000
        NOT R1, R1
        AND R1, R1, R3
        NOT R1, R1
        ;store PSR with unable bit
        STI R1, PSR
        
        ;set interrupt bit on keyboard
        ;KBSR OR x4000
        LDI R2, KBSR
        NOT R2, R2
        AND R2, R2, R3
        NOT R2, R2
        ;store KBSR with unable bit
        STI R2,KBSR
        
        ;restore registers
        LDR R3, R6, #0
        ADD R6, R6, #1
        LDR R2, R6, #0
        ADD R6, R6, #1
        LDR R1, R6, #0
        ADD R6, R6, #1
        RET
 
PSR     .FILL xFFFC  
MASK    .FILL xBFFF
KBSR    .FILL xFE00 ; Address of KBSR


;********************PRINT_SCREEN*********************
;Displays the box for the animation
;
;R0 - used for trap
;R1 - used for loop counter x
;R2 - used for loop counter y
;R3 - temp
;R5 - row counter
;***************************************************
PRINT_SCREEN
    ADD R6, R6, #-1
    STR R1, R6, #0
    ADD R6, R6, #-1
    STR R2, R6, #0
    ADD R6, R6, #-1
    STR R3, R6, #0
    ADD R6, R6, #-1
    STR R5, R6, #0
    
    LEA R0, LINE
    PUTS
    LD R5, NUM_ROWS
ROW_LOOP
    ;display left wall
    LEA R0, WALL
    PUTS
    ;check if ball is in current row
    LD R3, BALL_Y
    NOT R3, R3
    ADD R3, R3, #1
    ADD R3, R3, R5 ;if zero, ball is in current row
    BRz BALL_ROW
    
    LD R3, BLANK_COUNT
    LEA R0, BLANK
BLANK_LOOP
    PUTS
    ADD R3, R3, #-1
    BRp BLANK_LOOP
    BRnzp ROW_EXIT
    
BALL_ROW
    LD R1, BALL_X ;spacer before ball
    LD R3, BLANK_COUNT
    ADD R2, R1, #0
    NOT R2, R2
    ADD R2, R2, #1
    ADD R2, R3, R2 ;This is the spacer after the ball
    ADD R2, R2, #-1
    LEA R0, BLANK
BEFORE_SPACER
    PUTS
    ADD R1, R1, #-1
    BRp BEFORE_SPACER
    
    LEA R0, BALL
    PUTS
    
    LEA R0, BLANK
AFTER_SPACER
    PUTS
    ADD R2, R2, #-1
    BRp AFTER_SPACER
    
ROW_EXIT
    LEA R0, WALL ;display right wall
    PUTS
    LEA R0, NEWLINE
    PUTS
    ADD R5, R5, #-1 ;decrement row counter
    BRp ROW_LOOP


    

    LDR R5, R6, #0
    ADD R6, R6, #1
    LDR R3, R6, #0
    ADD R6, R6, #1
    LDR R2, R6, #0
    ADD R6, R6, #1
    LDR R1, R6, #0
    ADD R6, R6, #1

    RET
LINE    .STRINGZ " ========================\n"
BAR     .STRINGZ "|                        |\n"
WALL    .STRINGZ "|"
BLANK   .STRINGZ " "
NEWLINE .STRINGZ "\n"
BALL    .STRINGZ "o"
SCORE_PROMPT   .STRINGZ "SCORE: "

BLANK_COUNT .FILL #24
NUM_ROWS .FILL #9

;********************UPDATE_BALL*********************
;Moves the ball
;
;R0 - 
;R1 - 
;R2 - ball direction
;R3 - temp
;R4 - temp
;R5 - temp
;
;***************************************************
UPDATE_BALL
    ADD R6, R6, #-1
    STR R1, R6, #0
    ADD R6, R6, #-1
    STR R2, R6, #0
    ADD R6, R6, #-1
    STR R3, R6, #0
    ADD R6, R6, #-1
    STR R4, R6, #0
    ADD R6, R6, #-1
    STR R4, R6, #0
    
    LD R2, BALL_DIR;grab ball direction
    ;if at top bound and moving up, subtract 3 to get correct direction
    ;1-up right
    ;2-up left
    ;-1 down left
    ;-2 down right
    
    ;check bounds
    LD R3, BALL_Y
    ADD R3, R3, #-1
    BRz HIT_BOTTOM
    ADD R3, R3, #-8
    BRz HIT_TOP
    LD R3, BALL_X
    ADD R3, R3, #-1
    BRz HIT_LEFT
    LD R1, RIGHT_CHECK
    ADD R3, R3, R1
    BRz HIT_RIGHT
    BRnzp UPDATE_DIR
    
    
HIT_TOP
    ADD R2, R2, #-3
    ST R2, BALL_DIR
    BRnzp UPDATE_DIR
    
HIT_BOTTOM
    ADD R2, R2, #3
    ST R2, BALL_DIR
    BRnzp UPDATE_DIR
    
HIT_LEFT
    ADD R2, R2, #-1
    ST R2, BALL_DIR
    BRnzp UPDATE_DIR

HIT_RIGHT
    ADD R2, R2, #1
    ST R2, BALL_DIR
    
UPDATE_DIR
    LD R3, BALL_X
    LD R1, BALL_Y
    ;update according to direction
    ADD R5, R2, #-1
    BRz UP_RIGHT
    BRp UP_LEFT
    ADD R5, R2, #1
    BRz DOWN_LEFT
    BRn DOWN_RIGHT
    
UP_LEFT
    ADD R3, R3, #-1
    ADD R1, R1, #1
    BRnzp UPDATE_EXIT

UP_RIGHT
    ADD R3, R3, #1
    ADD R1, R1, #1
    BRnzp UPDATE_EXIT

DOWN_LEFT
    ADD R3, R3, #-1
    ADD R1, R1, #-1
    BRnzp UPDATE_EXIT

DOWN_RIGHT
    ADD R3, R3, #1
    ADD R1, R1, #-1
    BRnzp UPDATE_EXIT

UPDATE_EXIT
    ST R3, BALL_X
    ST R1, BALL_Y
    
    LDR R5, R6, #0
    ADD R6, R6, #1
    LDR R4, R6, #0
    ADD R6, R6, #1
    LDR R3, R6, #0
    ADD R6, R6, #1
    LDR R2, R6, #0
    ADD R6, R6, #1
    LDR R1, R6, #0
    ADD R6, R6, #1

    RET
    
RIGHT_CHECK .FILL #-21

;********************CHECK_GAME*********************
;Checks game over condition
;
;R1 - the ball x,y value
;R2 - score
;
;***************************************************
CHECK_GAME

    
    LD R1, BALL_Y 
    ADD R1, R1, #-1
    BRp EXIT_CHECK


    LD R1, BALL_X ;check if brick is in location
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R4, R1 ;if negative, check right brick bound
    BRp FLAG
    ADD R1, R1, #5 ; add brick width
    BRzp EXIT_CHECK
    
FLAG
    AND R1, R1, #0
    ADD R1, R1, #-1
    
EXIT_CHECK   
    ;update score
    
    RET


;********************CLEAR*********************
;Clears screen
;
;R0 - used for trap
;
;***************************************************
CLEAR
    LEA R0, BREAK
    PUTS
    PUTS

    RET
BREAK    .STRINGZ "\n\n\n\n\n\n\n\n\n"

;********************PRINT_BLOCK*********************
;Displays the block for the animation
;
;R0 - used for trap
;R1- used for loop counter
;R4 - spacer value
;***************************************************
PRINT_BLOCK
    ADD R6, R6, #-1
    STR R1, R6, #0
    
    ADD R1, R4, #0 ; initialize loop counter
    
    LEA R0, SPACER
    SPACER_LOOP
    PUTS
    ADD R1, R1, #-1
    BRp SPACER_LOOP
    
    LEA R0, BLOCK
    PUTS

    LDR R1, R6, #0
    ADD R6, R6, #1

    RET
BLOCK    .STRINGZ "[~~~]\n"
SPACER     .STRINGZ " "


.END
;**************************************************************
; store value of the keyboard interrupt in the interrupt vector
;**************************************************************
.ORIG x0180
    INPUT .FILL x0415; starting address of keyboard interrupt
.END 
   
;**************************************************************
; Keyboard interrupt
;R0 - used for traps
;R1 - used to check key pressed
;*************************************************************
.ORIG x0415
    ;stack
    ADD R6, R6, #-1
    STR R7, R6, #0
    ADD R6, R6, #-1
    STR R0, R6, #0
    ADD R6, R6, #-1
    STR R1, R6, #0
    
    ;LEA R0, INT_MSG
    ;PUTS
    ; no need to check KBSR since it triggers the interrupt
    LDI R0, KBDR
    LD R1, A
    ADD R1, R1, R0
    BRz INT_A
    
    LD R1, D
    ADD R1, R1, R0
    BRz INT_D
    BRnzp INT_EXIT
    
INT_A
    ;LEA R0, LEFT
    ;PUTS
    JSR BLOCK_LEFT
    BRnzp INT_EXIT

INT_D
    ;LEA R0, RIGHT
    ;PUTS
    JSR BLOCK_RIGHT
    BRnzp INT_EXIT
    
INT_EXIT
    ;stack
    LDR R1, R6, #0
    ADD R6, R6, #1
    LDR R0, R6, #0
    ADD R6, R6, #1
    LDR R7, R6, #0
    ADD R6, R6, #1
    RTI

KBDR    .FILL xFE02 ; Address of KBDR    
INT_MSG .STRINGZ "User pressed: "   
LEFT    .STRINGZ "LEFT"
RIGHT   .STRINGZ "RIGHT"
A       .FILL #-97
D       .FILL #-100

;********************BLOCK_LEFT*********************
;Moves block to the left
;
;R0 - used for trap
;R1 - used to check current location
;R4 - spacer value for block
;***************************************************
BLOCK_LEFT
    ADD R6, R6, #-1
    STR R7, R6, #0
    ADD R6, R6, #-1
    STR R0, R6, #0
    ADD R6, R6, #-1
    STR R1, R6, #0
    
    ;check if already zero otherwise subtract one
    ADD R1, R4, #-1
    BRn LEFT_EXIT
    ADD R4, R4, #-1
    
    LEFT_EXIT
    LDR R1, R6, #0
    ADD R6, R6, #1
    LDR R0, R6, #0
    ADD R6, R6, #1
    LDR R7, R6, #0
    ADD R6, R6, #1

    RET
    
    ;********************BLOCK_RIGHT*********************
;Moves block to the right
;
;R0 - used for trap
;R1 - used to check current location
;R4 - spacer value for block
;***************************************************
BLOCK_RIGHT
    ADD R6, R6, #-1
    STR R7, R6, #0
    ADD R6, R6, #-1
    STR R0, R6, #0
    ADD R6, R6, #-1
    STR R1, R6, #0
    
    ;check if above limit otherwise add one
    LD R1, RIGHT_LIMIT
    ADD R1, R4, R1
    BRp RIGHT_EXIT
    ADD R4, R4, #1
    
    RIGHT_EXIT
    LDR R1, R6, #0
    ADD R6, R6, #1
    LDR R0, R6, #0
    ADD R6, R6, #1
    LDR R7, R6, #0
    ADD R6, R6, #1

    RET

RIGHT_LIMIT     .FILL #-20
    
    .END   

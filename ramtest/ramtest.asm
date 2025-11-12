
;
; Xerox-820 DRAM Diagnostic (rev1.1: don't stop on first fault)
;

CRTPAG   EQU    30H                ; Where video RAM lives
CRTRAM   EQU    3000H              ; ..

RAM_LOW  EQU    03C00H             ; DRAM low test address (4K)
RAM_TOP  EQU    0FFFFH             ; DRAM top test address (64K)

; I/O ports

BRG.A    EQU    000H               ; Baud rate generator for channel A
BRG.C    EQU    000H               ; Baud rate generator for channel A
BRG.B    EQU    00CH               ; Baud rate generator for channel B

SIO.AD   EQU    004H               ; SIO channel A, Data port
SIO.CD   EQU    004H               ; SIO channel A, Data port
SIO.BD   EQU    005H               ; SIO channel B, Data port
SIO.AS   EQU    006H               ; SIO channel A, Status port
SIO.CS   EQU    006H               ; SIO channel A, Status port
SIO.BS   EQU    007H               ; SIO channel B, Status port
PIO.AD   EQU    008H               ; PIO channel A, Data port
PIO.AS   EQU    009H               ; PIO channel A, Sts/Ctrl port
PIO.BD   EQU    00AH               ; PIO channel B, Data port
PIO.BS   EQU    00BH               ; PIO channel B, Sts/Ctrl port
FDC.CS   EQU    010H               ; 1771 Floppy Controller: Ctrl/Status
FDC.CY   EQU    011H               ; 1771 Floppy Controller: Cylinder/track
FDC.SE   EQU    012H               ; 1771 Floppy Controller: Sector
FDC.DA   EQU    013H               ; 1771 Floppy disc Controller: Data
CRT.SC   EQU    014H               ; CRT Scroll control register
CTC.C0   EQU    018H               ; Counter/Timer Chip Channel 0
CTC.C1   EQU    019H               ; Counter/Timer Chip Channel 1
CTC.C2   EQU    01AH               ; Counter/Timer Chip Channel 2
CTC.C3   EQU    01BH               ; Counter/Timer Chip Channel 3
PIO.SD   EQU    01CH               ; Data port of system PIO
PIO.SC   EQU    01DH               ; Control port of system PIO
PIO.KD   EQU    01EH               ; Keyboard data port of PIO
PIO.KC   EQU    01FH               ; Keyboard control port of PIO

; ASCII characters

CH.EOT   EQU    004H               ; String terminator
CH.BEL   EQU    007H               ; Bell
CH.BS    EQU    008H               ; Backspace
CH.HT    EQU    009H               ; Horizontal Tab
CH.LF    EQU    00AH               ; Linefeed
CH.FF    EQU    00CH               ; Formfeed
CH.CR    EQU    00DH               ; carriage return
CH.CAN   EQU    018H               ; Cancel, Control X
CH.SUB   EQU    01AH               ; SUB, Control Z
CH.ESC   EQU    01BH               ; Escape
CH.CTL   EQU    020H               ; Control group less than this
CH.SPC   EQU    020H               ; Space character

; Bit numbers for BIT, RES and SET instructions

B0       EQU    0
B1       EQU    1
B2       EQU    2
B3       EQU    3
B4       EQU    4
B5       EQU    5
B6       EQU    6
B7       EQU    7

; video RAM line addresses

LINE1    EQU    CRTRAM + 0000H
LINE2    EQU    CRTRAM + 0080H
LINE3    EQU    CRTRAM + 0100H
LINE4    EQU    CRTRAM + 0180H
LINE5    EQU    CRTRAM + 0200H
LINE6    EQU    CRTRAM + 0280H

SP_TOP   EQU    0CFFFH             ; the stack is not used
VRAM_SZ  EQU    00C00H             ; VRAM size = 3K

; end of definitions

         ORG     0000H

START:   DI                        ; disable interrupts
         LD      SP, SP_TOP        ; initial stack pointer

         ; init system PIO port A
         LD      A, 0CFH           ; bit mode
         OUT     (PIO.SC), A
         LD      A, 018H           ; bits 3 and 4 are inputs
         OUT     (PIO.SC), A
         LD      A, 080H           ; disable interrupts
         OUT     (PIO.SC), A

         ; load the scroll register
         LD      A, 23             ; top display line
         OUT     (CRT.SC), A

         ; clear video RAM
         LD      A, CH.SPC         ; load the fill character (space)
         LD      HL, CRTRAM        ; set HL to start of VRAM
         LD      (HL), A           ; write to the first location
         LD      DE, CRTRAM + 1    ; set DE to the second VRAM location
         LD      BC, VRAM_SZ-1     ; iteration counter
         LDIR                      ; block copy

         ; write message to video line #1
         LD      HL, MSG1          ; set HL to message start
         LD      DE, LINE1         ; set DE to VRAM address
         LD      BC, LEN1          ; message length
         LDIR                      ; block copy

         ; clear alternate registers
         EX AF, AF'
         EXX
         XOR A                     ; A' = 0
         LD D, A                   ; D' = 0
         LD E, A                   ; E' = 0
         LD H, A                   ; H' = 0
         LD L, A                   ; L' = 0
         EXX
         EX AF, AF'                ; switch back

         ; start of DRAM diagnostics

; -----------------------------------------------------------------------------
; TEST_55 -- Write/Verify/ID for pattern 55h
; -----------------------------------------------------------------------------
TEST_55:
         LD A, 55h
         LD D, A                 ; D = expected pattern
         LD B, A                 ; B = expected pattern
         LD HL, RAM_LOW

WRITE_55:
         LD (HL), D              ; write the pattern
         INC HL
         ; check if HL > RAM_TOP
         LD A, H
         CP 0                    ; compare H with FFh+1 (00h)
         JR NZ, WRITE_55
         LD A, L
         CP 0                    ; compare L with FFh+1 (00h)
         JR NZ, WRITE_55

         ; verify-pattern loop
         LD HL, RAM_LOW          ; reset address pointer
CHK_55:  LD A, B                 ; A = expected pattern
         CP (HL)                 ; compare expected with actual
         JR NZ, FAULT            ; jump on mismatch

         ; check for verify-pattern loop termination
CHK_5X:  INC HL
         LD A, H
         CP 0                    ; compare H with FFh+1 (00h)
         JR NZ, CHK_55
         LD A, L
         CP 0                    ; compare L with FFh+1 (00h)
         JR NZ, CHK_55

; -----------------------------------------------------------------------------
; TEST_AA -- Write/Verify/ID for pattern AAh
; -----------------------------------------------------------------------------
TEST_AA:
         LD A, 0AAh
         LD D, A                 ; D = expected pattern
         LD B, A                 ; B = expected pattern
         LD HL, RAM_LOW

WRITE_AA:
         LD (HL), D              ; write the pattern
         INC HL
         ; check if HL > RAM_TOP
         LD A, H
         CP 0                    ; compare H with FFh+1 (00h)
         JR NZ, WRITE_AA
         LD A, L
         CP 0                    ; compare L with FFh+1 (00h)
         JR NZ, WRITE_AA

         ; verify-pattern loop
         LD HL, RAM_LOW          ; reset address pointer
CHK_AA:  LD A, B                 ; A = expected pattern
         CP (HL)                 ; compare expected with actual
         JR NZ, FAULT            ; jump on mismatch

         ; check for verify-pattern loop termination
CHK_AX:  INC HL
         LD A, H
         CP 0                    ; compare H with FFh+1 (00h)
         JR NZ, CHK_AA
         LD A, L
         CP 0                    ; compare L with FFh+1 (00h)
         JR NZ, CHK_AA

         JP REPORT               ; test complete jump to reporting

; -----------------------------------------------------------------------------
; FAULT -- found a fault
; State on entry: HL = failing address, A = expected (55h), B = 55h
; -----------------------------------------------------------------------------
FAULT:   LD A, (HL)              ; A = actual data
         XOR B                   ; A = actual XOR expected
         LD C, A                 ; C = error mask
         LD E,7

COL_LP:  LD A, C
         CP 0                    ; check if done
         JR Z, COL_XX
         SLA A
         LD C, A
         JR C, GOT_COL
         DEC E                   ; E = failing DRAM column
         JR COL_LP

COL_XX:  LD A, B
         CP 055h
         JR Z, CHK_5X            ; continue test with 55 pattern
         JR CHK_AX               ; continue test with AA pattern

GOT_COL: LD A, H                 ; A = high byte of failing address
         AND 80h                 ; check A15 (bit 7)
         JR Z, ROW_10

ROW_32:  LD D, 2                 ; A15 is set (row 3 or 2)
         BIT 6, H                ; check A14 (bit 6 of H)
         JR Z, WBMAP             ; if A14 is clear, it's row 2 (80h-BFh)
         INC D                   ; row 3
         JR WBMAP

ROW_10:  LD D, 0                 ; A15 is clear (row 2 or 0)
         BIT 6, H                ; check A14
         JR Z, WBMAP             ; if A14 is clear, it's row 0 (00h-3Fh)
         INC D                   ; row 1

         ; start of RAM fault bitmap section

         ; write to 32-bit bitmap of faulting chips in DE',HL'
         ; D = failing row (0-3)  E = failing column (0-7)
WBMAP:   LD A, D
         EXX
         LD B, A                 ; B' = D
         EXX
         LD A, E
         EXX
         LD C, A                 ; C' = E

         EX      AF, AF'         ; switch to alternate AF
         LD      A, 0FFh         ; set error flag
         EX      AF, AF'         ; switch back

         ; BC' has the failing row and col
         ; Calculate the 5-bit chip index (0-31) = (row * 8) + col
         LD A, B                 ; A = row
         SLA A                   ; A = row * 2
         SLA A                   ; A = row * 4
         SLA A                   ; A = row * 8
         ADD A, C                ; A = chip index (0-31)
         LD B, A                 ; B' holds the chip index (0-31)

         ; Binary Split Logic (max 4 comparisons)

WBX1:    LD A, B                 ; A = chip index (0-31)
         CP 16                   ; split 0-31 into 0-15 and 16-31
         JR C, WBX3

         ; range 16-31
         CP 24                   ; split 16-31 into 16-23 and 24-31
         JR C, WBX2

         ; range 24-31
         CP 28                   ; split 24-31 into 24-27 and 28-31
         JP C, WBP24             ; jump to WBP24 for range 24-27
         JP WBP28                ; jump to WBP28 for range 28-31

WBX2:    ; range 16-23
         CP 20                   ; split 16-23 into 16-19 and 20-23
         JP C, WBP16             ; jump to WBP16 for range 16-19
         JP WBP20                ; jump to WBP20 for range 20-23

         ; range 0-15
WBX3:    CP 8                    ; split 0-15 into 0-7 and 8-15
         JR C, WBX4

         ; range 8-15
         CP 12                   ; split 8-15 into 8-11 and 12-15
         JR C, WBP8              ; jump to WBP8 for range 8-11
         JP WBP12                ; jump to WBP12 for range 12-15

         ; range 0-7
WBX4:    CP 4                    ; split 0-7 into 0-3 and 4-7
         JR C, WBP0              ; jump to WBP0 for range 0-3
         JP WBP4                 ; jump to WBP4 for range 4-7

; Range 0-3

WBP0:    LD A, B
         CP 0
         JR NZ, WBP1
         LD A, L
         OR 01h                  ; bit 0
         LD L, A
         JP WBPXX

WBP1:    CP 1
         JR NZ, WBP2
         LD A, L
         OR 02h                  ; bit 1
         LD L, A
         JP WBPXX

WBP2:    CP 2
         JR NZ, WBP3
         LD A, L
         OR 04h                  ; bit 2
         LD L, A
         JP WBPXX

WBP3:    LD A, L
         OR 08h                  ; bit 3
         LD L, A
         JP WBPXX

; Range 4-7

WBP4:    LD A, B
         CP 4
         JR NZ, WBP5
         LD A, L
         OR 10h                  ; bit 4
         LD L, A
         JP WBPXX

WBP5:    CP 5
         JR NZ, WBP6
         LD A, L
         OR 20h                  ; bit 5
         LD L, A
         JP WBPXX

WBP6:    CP 6
         JR NZ, WBP7
         LD A, L
         OR 40h                  ; bit 6
         LD L, A
         JP WBPXX

WBP7:    LD A, L
         OR 80h                  ; bit 7
         LD L, A
         JP WBPXX

; Range 8-11

WBP8:    LD A, B
         CP 8
         JR NZ, WBP9
         LD A, H
         OR 01h                  ; bit 8
         LD H, A
         JP WBPXX

WBP9:    CP 9
         JR NZ, WBP10
         LD A, H
         OR 02h                  ; bit 9
         LD H, A
         JP WBPXX

WBP10:   CP 10
         JR NZ, WBP11
         LD A, H
         OR 04h                  ; bit 10
         LD H, A
         JP WBPXX

WBP11:   LD A, H                 ; B must be 11
         OR 08h                  ; bit 11
         LD H, A
         JP WBPXX

; Range 12-15

WBP12:   LD A, B
         CP 12
         JR NZ, WBP13
         LD A, H
         OR 10h                  ; bit 12
         LD H, A
         JP WBPXX

WBP13:   CP 13
         JR NZ, WBP14
         LD A, H
         OR 20h                  ; bit 13
         LD H, A
         JP WBPXX

WBP14:   CP 14
         JR NZ, WBP15
         LD A, H
         OR 40h                  ; bit 14
         LD H, A
         JP WBPXX

WBP15:   LD A, H                 ; B must be 15
         OR 80h                  ; bit 15
         LD H, A
         JP WBPXX

; Range 16-19

WBP16:   LD A, B
         CP 16
         JR NZ, WBP17
         LD A, E
         OR 01h                  ; bit 16
         LD E, A
         JP WBPXX

WBP17:   CP 17
         JR NZ, WBP18
         LD A, E
         OR 02h                  ; bit 17
         LD E, A
         JP WBPXX

WBP18:   CP 18
         JR NZ, WBP19
         LD A, E
         OR 04h                  ; bit 18
         LD E, A
         JP WBPXX

WBP19:   LD A, E                 ; B must be 19
         OR 08h                  ; bit 19
         LD E, A
         JP WBPXX

; Range 20-23

WBP20:   LD A, B
         CP 20
         JR NZ, WBP21
         LD A, E
         OR 10h                  ; bit 20
         LD E, A
         JP WBPXX

WBP21:   CP 21
         JR NZ, WBP22
         LD A, E
         OR 20h                  ; bit 21
         LD E, A
         JP WBPXX

WBP22:   CP 22
         JR NZ, WBP23
         LD A, E
         OR 40h                  ; bit 22
         LD E, A
         JP WBPXX

WBP23:   LD A, E                 ; B must be 23
         OR 80h                  ; bit 23
         LD E, A
         JP WBPXX

; Range 24-27

WBP24:   LD A, B
         CP 24
         JR NZ, WBP25
         LD A, D
         OR 01h                  ; bit 24
         LD D, A
         JP WBPXX

WBP25:   CP 25
         JR NZ, WBP26
         LD A, D
         OR 02h                  ; bit 25
         LD D, A
         JP WBPXX

WBP26:   CP 26
         JR NZ, WBP27
         LD A, D
         OR 04h                  ; bit 26
         LD D, A
         JP WBPXX

WBP27:   LD A, D                 ; B must be 27
         OR 08h                  ; bit 27
         LD D, A
         JP WBPXX

; Range 28-31

WBP28:   LD A, B
         CP 28
         JR NZ, WBP29
         LD A, D
         OR 10h                  ; bit 28
         LD D, A
         JP WBPXX

WBP29:   CP 29
         JR NZ, WBP30
         LD A, D
         OR 20h                  ; bit 29
         LD D, A
         JP WBPXX

WBP30:   CP 30
         JR NZ, WBP31
         LD A, D
         OR 40h                  ; bit 30
         LD D, A
         JP WBPXX

WBP31:   LD A, D                 ; B must be 31
         OR 80h                  ; bit 31
         LD D, A
         JP WBPXX

         ; end of RAM fault bitmap section

WBPXX:   EXX                     ; Swap back
         DEC E                   ; E = failing DRAM column
         JP COL_LP               ; continue searching columns

; -----------------------------------------------------------------------------
; REPORT -- use DE' HL' bitmap to generate a final report
; -----------------------------------------------------------------------------
REPORT:  EX AF, AF'              ; check A'
         OR A                    ; check if A' is zero (no error)
         JP Z, SUCCESS           ; the test passed if A'=0

         EX AF, AF'              ; restore AF
FNL3X:   EXX
         LD A, D
         EXX
         LD DE, LINE2            ; DE = VRAM destination (start of line 2)

FNL37:   BIT 7, A
         JR Z, FNL36
         LD HL, MSG_37           ; HL = pointer to message
         LD BC, 2                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL36:   BIT 6, A
         JR Z, FNL35
         LD HL, MSG_36           ; HL = pointer to message
         LD BC, 2                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL35:   BIT 5, A
         JR Z, FNL34
         LD HL, MSG_35           ; HL = pointer to message
         LD BC, 2                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL34:   BIT 4, A
         JR Z, FNL33
         LD HL, MSG_34           ; HL = pointer to message
         LD BC, 2                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL33:   BIT 3, A
         JR Z, FNL32
         LD HL, MSG_33           ; HL = pointer to message
         LD BC, 2                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL32:   BIT 2, A
         JR Z, FNL31
         LD HL, MSG_32           ; HL = pointer to message
         LD BC, 2                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL31:   BIT 1, A
         JR Z, FNL30
         LD HL, MSG_31           ; HL = pointer to message
         LD BC, 2                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL30:   BIT 0, A
         JR Z, FNL2X
         LD HL, MSG_30           ; HL = pointer to message
         LD BC, 2                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL2X:   EXX
         LD A, E
         EXX

FNL27:   BIT 7, A
         JR Z, FNL26
         LD HL, MSG_27           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL26:   BIT 6, A
         JR Z, FNL25
         LD HL, MSG_26           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL25:   BIT 5, A
         JR Z, FNL24
         LD HL, MSG_25           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL24:   BIT 4, A
         JR Z, FNL23
         LD HL, MSG_24           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL23:   BIT 3, A
         JR Z, FNL22
         LD HL, MSG_23           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL22:   BIT 2, A
         JR Z, FNL21
         LD HL, MSG_22           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL21:   BIT 1, A
         JR Z, FNL20
         LD HL, MSG_21           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL20:   BIT 0, A
         JR Z, FNL1X
         LD HL, MSG_20           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL1X:   EXX
         LD A, H
         EXX

FNL17:   BIT 7, A
         JR Z, FNL16
         LD HL, MSG_17           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL16:   BIT 6, A
         JR Z, FNL15
         LD HL, MSG_16           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL15:   BIT 5, A
         JR Z, FNL14
         LD HL, MSG_15           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL14:   BIT 4, A
         JR Z, FNL13
         LD HL, MSG_14           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL13:   BIT 3, A
         JR Z, FNL12
         LD HL, MSG_13           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL12:   BIT 2, A
         JR Z, FNL11
         LD HL, MSG_12           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL11:   BIT 1, A
         JR Z, FNL10
         LD HL, MSG_11           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL10:   BIT 0, A
         JR Z, FNL0X
         LD HL, MSG_10           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL0X:   EXX
         LD A, L
         EXX

FNL07:   BIT 7, A
         JR Z, FNL06
         LD HL, MSG_07           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL06:   BIT 6, A
         JR Z, FNL05
         LD HL, MSG_06           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL05:   BIT 5, A
         JR Z, FNL04
         LD HL, MSG_05           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL04:   BIT 4, A
         JR Z, FNL03
         LD HL, MSG_04           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL03:   BIT 3, A
         JR Z, FNL02
         LD HL, MSG_03           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL02:   BIT 2, A
         JR Z, FNL01
         LD HL, MSG_02           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL01:   BIT 1, A
         JR Z, FNL00
         LD HL, MSG_01           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNL00:   BIT 0, A
         JR Z, FNLXX
         LD HL, MSG_00           ; HL = pointer to message
         LD BC, 3                ; BC = message length
         LDIR                    ; block copy: (HL) to (DE)
         INC DE

FNLXX:   LD HL, MSG_ERR          ; set HL to message start
         LD  DE, LINE1+23        ; set DE to VRAM address
         LD BC, LEN_ERR          ; message length
         LDIR                    ; block copy
         JP $                    ; null loop

SUCCESS:
         EX AF, AF'              ; restore AF
         LD  HL, MSG_OK          ; set HL to message start
         LD  DE, LINE1+23        ; set DE to VRAM address
         LD  BC, LEN_OK          ; message length
         LDIR                    ; block copy
         JP $                    ; null loop

         ; end of program

; -----------------------------------------------------------------------------
; MESSAGE DATA
; -----------------------------------------------------------------------------

MSG1:    DB      'XEROX-820 -- DRAM TEST'
LEN1     EQU     $ - MSG1

MSG_OK:  DB      'PASSED'
LEN_OK   EQU     $ - MSG_OK

MSG_ERR: DB      'ERROR'
LEN_ERR  EQU     $ - MSG_ERR

; -----------------------------------------------------------------------------
;                    Xerox-820 DRAM Chip Map
;
; Bit#   7     6     5     4     3     2     1     0          Range
;       ---   ---   ---   ---   ---   ---   ---   ---     --------------
;       U1    U2    U3    U4    U5    U6    U7    U8      C000h -> FFFFh
;       U17   U18   U19   U20   U21   U22   U23   U24     8000h -> BFFFh
;       U37   U38   U39   U40   U41   U42   U43   U44     4000h -> 7FFFh
;       U54   U55   U56   U57   U58   U59   U60   U61     0000h -> 3FFFh
;
; -----------------------------------------------------------------------------

; Message table ordered by row and column

MSG_ADDR_TABLE:
         DW MSG_00, MSG_01, MSG_02, MSG_03, MSG_04, MSG_05, MSG_06, MSG_07
         DW MSG_10, MSG_11, MSG_12, MSG_13, MSG_14, MSG_15, MSG_16, MSG_17
         DW MSG_20, MSG_21, MSG_22, MSG_23, MSG_24, MSG_25, MSG_26, MSG_27
         DW MSG_30, MSG_31, MSG_32, MSG_33, MSG_34, MSG_35, MSG_36, MSG_37

; DRAM chip IDs for range C000h -> FFFFh

MSG_30:  DB      'U8 '
MSG_31:  DB      'U7 '
MSG_32:  DB      'U6 '
MSG_33:  DB      'U5 '
MSG_34:  DB      'U4 '
MSG_35:  DB      'U3 '
MSG_36:  DB      'U2 '
MSG_37:  DB      'U1 '

; DRAM chip IDs for range 8000h -> BFFFh

MSG_20:  DB      'U24'
MSG_21:  DB      'U23'
MSG_22:  DB      'U22'
MSG_23:  DB      'U21'
MSG_24:  DB      'U20'
MSG_25:  DB      'U19'
MSG_26:  DB      'U18'
MSG_27:  DB      'U17'

; DRAM chip IDs for range 4000h -> 7FFFh

MSG_10:  DB      'U44'
MSG_11:  DB      'U43'
MSG_12:  DB      'U42'
MSG_13:  DB      'U41'
MSG_14:  DB      'U40'
MSG_15:  DB      'U39'
MSG_16:  DB      'U38'
MSG_17:  DB      'U37'

; DRAM chip IDs for range 0000h -> 3FFFh

MSG_00:  DB      'U61'
MSG_01:  DB      'U60'
MSG_02:  DB      'U59'
MSG_03:  DB      'U58'
MSG_04:  DB      'U57'
MSG_05:  DB      'U56'
MSG_06:  DB      'U55'
MSG_07:  DB      'U54'

         ; end of messages

         END


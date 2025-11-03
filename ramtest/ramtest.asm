
;
; Xerox-820 DRAM Diagnostic
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

         ; verify pattern
         LD HL, RAM_LOW          ; reset address pointer

CHECK_55:
         LD A, B                 ; A = expected pattern
         CP (HL)                 ; compare expected with actual
         JR NZ, FAULT_55         ; jump on mismatch
         INC HL
    
         ; check termination
         LD A, H
         CP 0                    ; compare H with FFh+1 (00h)
         JR NZ, CHECK_55
         LD A, L
         CP 0                    ; compare L with FFh+1 (00h)
         JR NZ, CHECK_55

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

         ; verify pattern
         LD HL, RAM_LOW          ; reset address pointer

CHECK_AA:
         LD A, B                 ; A = expected pattern
         CP (HL)                 ; compare expected with actual
         JR NZ, FAULT_AA         ; jump on mismatch
         INC HL
    
         ; check termination
         LD A, H
         CP 0                    ; compare H with FFh+1 (00h)
         JR NZ, CHECK_AA
         LD A, L
         CP 0                    ; compare L with FFh+1 (00h)
         JR NZ, CHECK_AA

         ; success path
         JP SUCCESS_HALT         ; all tests passed

; -----------------------------------------------------------------------------
; FAULT_55
; State on entry: HL = failing address, A = expected (55h), B = 55h
; -----------------------------------------------------------------------------
FAULT_55:
         ; Calculate the Error Mask
         LD A, (HL)              ; A = actual data
         XOR B                   ; A = actual XOR expected
         LD C, A                 ; C = error mask
         LD E,7
LOOP_55: RL A                    ; find the failing DRAM column
         JR C, COLUMN_FOUND_55
         DEC E                   ; E = failing DRAM column
         JR LOOP_55

COLUMN_FOUND_55:
         ; check A15 (bit 7)
         LD A, H                 ; A = high byte of failing address
         AND 80h                 
         JR Z, CHECK_A14_55

         ; A15 is set (row 3 or 2)
         LD D, 2
         BIT 6, H                ; check A14 (bit 6 of H)
         JR Z, ROW_FOUND_55      ; if A14 is clear, it's row 2 (80h-BFh)
         INC D                   ; row 3
         JR ROW_FOUND_55

CHECK_A14_55:
         ; A15 is clear (row 0 or 1)
         LD D, 0
         BIT 6, H                ; check A14
         JR Z, ROW_FOUND_55      ; if A14 is clear, it's row 0 (00h-3Fh)
         INC D                   ; row 1

ROW_FOUND_55:
         ; D now contains the failing row (0-3)
         ; final reporting
         LD A, (HL)              ; A = actual data
         JP ERROR_HALT           ; jump to final halt location

; -----------------------------------------------------------------------------
; FAULT_AA
; State on entry: HL = failing address, A = expected (AAh), B = AAh
; -----------------------------------------------------------------------------
FAULT_AA:
         ; Calculate the Error Mask
         LD A, (HL)              ; A = actual data
         XOR B                   ; A = actual XOR expected
         LD C, A                 ; C = error mask
         LD E,7
LOOP_AA: RL A                    ; find the failing DRAM column
         JR C, COLUMN_FOUND_AA
         DEC E                   ; E = failing DRAM column
         JR LOOP_AA

COLUMN_FOUND_AA:
         ; check A15 (bit 7)
         LD A, H                 ; A = high byte of failing address
         AND 80h                 
         JR Z, CHECK_A14_AA

         ; A15 is set (row 3 or 2)
         LD D, 2
         BIT 6, H                ; check A14 (bit 6 of H)
         JR Z, ROW_FOUND_AA      ; if A14 is clear, it's row 2 (80h-BFh)
         INC D                   ; row 3
         JR ROW_FOUND_AA

CHECK_A14_AA:
         ; A15 is clear (row 0 or 1)
         LD D, 0
         BIT 6, H                ; check A14
         JR Z, ROW_FOUND_AA      ; if A14 is clear, it's row 0 (00h-3Fh)
         INC D                   ; row 1

ROW_FOUND_AA:
         ; D now contains the failing row (0-3)
         ; final reporting
         LD A, (HL)              ; A = actual data

ERROR_HALT:

; -----------------------------------------------------------------------------
;        Register Values on HALT
;
;        HL = failing memory address
;        A  = actual data read (failing value)
;        B  = expected data (the pattern being verified)
;        D  = failing DRAM row (0-3)
;        E  = failing DRAM column (0-7, corresponds to D0-D7)
;        C  = error mask (expected XOR actual)
;
; -----------------------------------------------------------------------------

         ; calculate the chip ID message index
         LD A, D                 ; A = row
         SLA A
         SLA A
         SLA A                   ; A = row * 8
         ADD A, E                ; A = (row * 8) + col

         ; lookup the chip ID message address
         LD L, A                 ; L = Index
         LD H, 0                 ; HL = Index (16-bit index value)
         SLA L                   ; L = Index * 2
         RL H                    ; HL = Index * 2 (word index offset)
         
         LD DE, MSG_ADDR_TABLE   ; DE = pointer to address table
         ADD HL, DE              ; HL = address table address + Index*2
         
         ; load HL with the chip ID message address
         LD E, (HL)              ; E = low byte of message address
         INC HL
         LD D, (HL)              ; D = high byte of message address
         EX DE, HL               ; HL = message address
         
         ; write chip ID message to VRAM
         LD BC, 3                ; BC = 3 (fixed message length)
         LD DE, LINE2            ; DE = VRAM destination (start of line 2)
         LDIR                    ; block copy: (HL) to (DE), length BC.

         ; write ERROR message to VRAM
         LD      HL, MSG_ERR     ; set HL to message start
         LD      DE, LINE2+5     ; set DE to VRAM address
         LD      BC, LEN_ERR     ; message length
         LDIR                    ; block copy
         JP      $               ; null loop

SUCCESS_HALT:
         ; write PASSED message to VRAM
         LD      HL, MSG_OK      ; set HL to message start
         LD      DE, LINE2       ; set DE to VRAM address
         LD      BC, LEN_OK      ; message length
         LDIR                    ; block copy
         JP      $               ; null loop

         ; end of program

         ; start of messages

MSG1:    DB      'XEROX-820 -- DRAM TEST'
LEN1     EQU     $ - MSG1

MSG_OK:  DB      'TEST PASSED'
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
LEN_30   EQU     $ - MSG_30

MSG_31:  DB      'U7 '
LEN_31   EQU     $ - MSG_31

MSG_32:  DB      'U6 '
LEN_32   EQU     $ - MSG_32

MSG_33:  DB      'U5 '
LEN_33   EQU     $ - MSG_33

MSG_34:  DB      'U4 '
LEN_34   EQU     $ - MSG_34

MSG_35:  DB      'U3 '
LEN_35   EQU     $ - MSG_35

MSG_36:  DB      'U2 '
LEN_36   EQU     $ - MSG_36

MSG_37:  DB      'U1 '
LEN_37   EQU     $ - MSG_37

; DRAM chip IDs for range 8000h -> BFFFh

MSG_20:  DB      'U24'
LEN_20   EQU     $ - MSG_20

MSG_21:  DB      'U23'
LEN_21   EQU     $ - MSG_21

MSG_22:  DB      'U22'
LEN_22   EQU     $ - MSG_22

MSG_23:  DB      'U21'
LEN_23   EQU     $ - MSG_23

MSG_24:  DB      'U20'
LEN_24   EQU     $ - MSG_24

MSG_25:  DB      'U19'
LEN_25   EQU     $ - MSG_25

MSG_26:  DB      'U18'
LEN_26   EQU     $ - MSG_26

MSG_27:  DB      'U17'
LEN_27   EQU     $ - MSG_27

; DRAM chip IDs for range 4000h -> 7FFFh

MSG_10:  DB      'U44'
LEN_10   EQU     $ - MSG_10

MSG_11:  DB      'U43'
LEN_11   EQU     $ - MSG_11

MSG_12:  DB      'U42'
LEN_12   EQU     $ - MSG_12

MSG_13:  DB      'U41'
LEN_13   EQU     $ - MSG_13

MSG_14:  DB      'U40'
LEN_14   EQU     $ - MSG_14

MSG_15:  DB      'U39'
LEN_15   EQU     $ - MSG_15

MSG_16:  DB      'U38'
LEN_16   EQU     $ - MSG_16

MSG_17:  DB      'U37'
LEN_17   EQU     $ - MSG_17

; DRAM chip IDs for range 0000h -> 3FFFh

MSG_00:  DB      'U61'
LEN_00   EQU     $ - MSG_00

MSG_01:  DB      'U60'
LEN_01   EQU     $ - MSG_01

MSG_02:  DB      'U59'
LEN_02   EQU     $ - MSG_02

MSG_03:  DB      'U58'
LEN_03   EQU     $ - MSG_03

MSG_04:  DB      'U57'
LEN_04   EQU     $ - MSG_04

MSG_05:  DB      'U56'
LEN_05   EQU     $ - MSG_05

MSG_06:  DB      'U55'
LEN_06   EQU     $ - MSG_06

MSG_07:  DB      'U54'
LEN_07   EQU     $ - MSG_07

         ; end of messages

         END


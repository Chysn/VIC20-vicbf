; Brainf**k Interpreter for Commodore VIC-20
; (c)2020, Jason Justian
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;

; Before executing, two configuration settings need to be done:
; (1) The starting address of the code is placed in $033C/$033D
; (2) The starting address of the data is placed in $033E/$033F
;
; SU_SRC/SU_DST are one less than the first setup location, because the
; copy is 1-indexed
SU_SRC = $033B
SU_DST = $FA
DATA_L = $033E
DATA_H = $033F

; This code is fully-relocatable. You can put it anywhere in memory and it will work.
* = $1800

; Working memory locations 
W_IP   = $FB
W_IPH  = $FC
W_DP   = $FD
W_DPH  = $FE
HI_DP  = $A3
HI_DPH = $A4

; Brainf**k Commands
C_IP_D = $3C ; <
C_IP_I = $3E ; >
C_DP_D = $2D ; -
C_DP_I = $2B ; +
C_OUT  = $2E ; .
C_IN   = $2C ; ,
C_LP_S = $5B ; [
A_LP_S = $1B ; [ (alias for screen RAM)
C_LP_E = $5D ; ]
A_LP_E = $1D ; ] (alias for screen RAM)

; VICBF Pseudo-Command
PC_END = $2A ; *
 
; Copy the starting instruction and data pointers to working memory.
; This is copied so that the BF program can be run multiple times, with
; the state always restored.
INIT    LDX #$04
COPY    LDA SU_SRC,X
        STA SU_DST,X
        DEX
        BNE COPY
        
; Copy the starting data pointer to the high data pointer location, set the
; first memory cell to 0, then increment the high memory location. The high
; data pointer is used to set each memory cell to 0 the first time it's used.
        LDA #$00
        STA (W_DP,X)
        LDA DATA_L
        STA HI_DP
        LDA DATA_H
        STA HI_DPH
        INC HI_DP
        BNE GETCMD
        INC HI_DPH
      
; Load the Accumulator with the character at the instruction pointer      
GETCMD  LDY #$00
        LDA (W_IP),Y

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Handle the data pointer decrement command '<'
;
PTRDEC  CMP #C_IP_D
        BNE PTRINC      ; Nope, check the next possibility
        DEC W_DP
        CMP #$FF
        BNE TOADV 
        DEC W_DPH
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Handle the data pointer increment command '>'
;
PTRINC  CMP #C_IP_I
        BNE MEMDEC      ; Nope, check the next possibility
        INC W_DP
        BNE CHKMEM
        INC W_DPH
        
; See if the newly-incremented data pointer has gone into new territory
; by advancing to the high data pointer location.        
CHKMEM  LDA W_DP
        CMP HI_DP
        BNE TOADV
        LDA W_DPH
        CMP HI_DPH
        BNE TOADV
; If the data pointer has broken a record, initialize (set to 0) the cell value,
; then advance the high data pointer.
        LDA #$00
        STA (HI_DP),Y
        INC HI_DP
        BNE TOADV
        INC HI_DPH
        SEC
        BCS TOADV

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Handle the data decrement command '-'
;
MEMDEC  CMP #C_DP_D
        BNE MEMINC      ; Nope, check the next possibility
        LDA (W_DP),Y
        TAX
        DEX
        TXA
        STA (W_DP),Y
        SEC
        BCS TOADV
TOCMD   SEC
        BCS GETCMD

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Handle the data increment command '+'       
;
MEMINC  CMP #C_DP_I
        BNE OUTPUT      ; Nope, check the next possibility
        LDA (W_DP),Y
        TAX
        INX
        TXA
        STA (W_DP),Y
        SEC
        BCS TOADV

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Handle the output command '.'  
;      
OUTPUT  CMP #C_OUT
        BNE INPUT       ; Nope, check the next possibility
        LDA (W_DP),Y
        JSR $FFD2

; TOADV is a target for relative branches above, that are too far away from ADV
TOADV   SEC
        BCS ADV
; TOGET is a target for relative branches below, that are too far away from GETCMD
TOGET   SEC
        BCS GETCMD

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Handle the input command ','
;
INPUT   CMP #C_IN
        BNE SLOOP       ; Nope, check the next possibility
        JSR $FFCF
        LDY #$00
        STA (W_DP),Y
        SEC
        BCS ADV

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Handle the start loop command '['
;
SLOOP   CMP #C_LP_S
        BEQ STARTL
        CMP #A_LP_S     ; Alias for '[' for programs running in screen memory
        BNE ELOOP       ; Nope, check the next possibility
STARTL  LDA (W_DP),Y      ; Get the data in the current cell
        BNE NLOOP       ; If it's not zero, enter a new loop

; If the data is 0, the task at hand is to skip the loop by finding
; the matching ']' for this '['. We do this by stepping through the
; code looking for ']'. But not any old ']' will do! Every time a
; '[' is found during the search, the X register is incremented so
; that we know which ']' matches the '[' that we're interested in.
        LDX #$01        ; X is the loop level
NEXTLC  INC W_IP       ; Increase the instruction pointer
        BNE CHKCMD
        INC W_IPH
CHKCMD  LDA (W_IP),Y    ; and look at its command
        CMP #PC_END    
        BEQ BYE         ; If the program is done, end
CHKLS   CMP #C_LP_S     ; Is it another, inner, '['?
        BEQ FOUNDS
        CMP #A_LP_S     ; Alias for '[' for programs running in screen memory
        BNE CHKLE
FOUNDS  INX             ; If so, increment the loop counter
CHKLE   CMP #C_LP_E     ; Is it a ']'?
        BEQ FOUNDE
        CMP #A_LP_E     ; Alias for ']' for programs running in screen memory
        BNE NEXTLC      ; If not, keep looking
FOUNDE  DEX             ; Is this the ']' that matches the original '['?
        BEQ ADV         ; Yes! Go to the next command
        BNE NEXTLC      ; No, it matches an inner '[', so keep looking
        
; Enter a new loop by pushing the instruction pointer onto the stack. When the
; end-of-loop command ']' is reached, the instruction pointer will be popped
; off the stack to bring the program back to the start of the loop.        
NLOOP   LDA W_IP
        PHA
        LDA W_IPH
        PHA
        SEC
        BCS ADV

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Handle the end loop command ']'
;
; Pop the start address of this loop off the stack, which takes us back to the
; beginning. After this, jump back to GETCMD without advancing the intruction
; pointer, because we want to make sure the '[' is handled again based on the
; current cell value.
ELOOP   CMP #C_LP_E
        BEQ ENDL
        CMP #A_LP_E     ; Alias for ']' for programs running in screen memory
        BNE EXIT        ; Nope, check the next possibility
ENDL    PLA
        STA W_IPH
        PLA
        STA W_IP
        SEC
        BCS TOGET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; The BF program ends when a 2A value is reached. This is a sort of "pseudo-command",
; because it's not part of the BF specification. But the program needs to end somehow. 
; (Note that, on the VIC-20, this is an asterisk)  
;                 
EXIT    CMP #PC_END
        BNE ADV
BYE     RTS

; Now that the command has been processed, or not processed, advance the instruction
; pointer and go back to GETCMD
ADV     INC W_IP
        BNE TOGET
        INC W_IPH
        SEC
        BCS TOGET

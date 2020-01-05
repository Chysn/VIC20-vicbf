_VICBF is a Brainfuck interpreter for Commodore VIC-20_

## Implementation Details
    
* The interpreter will begin executing BF code at a memory location specified by
  a pointer at $033C (828)
* The interpreter will use a data "tape" at memory specified by a pointer at
  $033E (830)
* The program code can be any length that will fit in your VIC-20
* The data tape can likewise be any length that will fit in your VIC-20
* The data tape cells are one byte (eight bits) in length. Subtracting 1 from 0 will
  result in 255, and adding 1 to 255 will result in 0.
* The interpreter does no range checking, so it will allow you to move to memory
  lower than the tape starting address. It does not "circle back" like some
  implementations do, because it does not limit the size of the tape, and thus
  has no way of knowing the "end" of the tape.
* The > command checks to see whether it's moving to the highest data tape memory
  location for the current run. If it is, it will initialize the cell with 0. The
  < command does not perfom such a check for the lowest location. The provided
  address is assumed to be the lowest end of the tape.
* Each loop ([...]) takes two bytes of stack space, so the levels of nesting
  are limited by available stack space.
* The end of VICBF code is indicated by an asterisk (* ($2A)) pseudo-command
* THE VICBF interpreter allows code to be run from any memory location, including
  screen RAM. This requires that the [ and ] commands each have two codes, a PETASCII
  code ($5B and $5D) and a screen RAM code ($1B and $1D). Fortunately, the rest of
  the commands, and the code-ending pseudo-command, have the same code for PETASCII
  and screen RAM.
  
  If the code location pointer ($033C) is set to 7680 (on an unexpanded VIC), you can
  thus write BF code directly at the top of the screen, then execute it with
  SYS6144. Make sure to end such programs (and all VICBF programs) with *.
  
* The . and , commands use KERNEL routines $FFD2 (CHROUT) and $FFCF (CHRIN),
  respectively
* VICBF is probably fully-compatible with the Commodore 64, with the exception of
  memory location updates in the sample code. VICBF is probably widely compatible with
  Commodore 8-bit machines, but the VIC-20 is obviously the best of these.

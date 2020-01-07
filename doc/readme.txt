Files:
    Files in the vic/ directory can be loaded via SDIEC
    Files in the src/ directory are source code files, readable by a modern OS
    
    BF-LOADER
        This is the loader for the machine lanauge BF interpreter. When it's run,
        it asks which memory location you'd like to install to. The interpreter
        can be installed anywhere 229 bytes are available. If you don't choose a
        location, it will be installed at 6144.
        
    BF-HELLO
        This is a Hello World program. It demonstrates one method of loading a BF
        program into memory. It sets the following variables:
            
            C is the location of the BF code in memroy
            D is the location of the data "tape"
            
        And then it reads DATA lines and POKEs each character into memory, starting
        at C. After this is done, you may run the Hello World program with the BF
        interpreter with SYS6144 (provided you previously ran BF-LOADER). If you
        changed the default location with BF-LOADER, change the SYS argument
        accordingly.
        
    BF-CODER
        This is a blank template for loading your own BF programs into memory. Just
        add DATA statements. See BF-HELLO for a working example.
        
    BF-SCREEN
        This sets up your VIC-20 to run BF programs from screen memory.
        
    VICBF
        This is the VICBF interpreter, assembled. It can be loaded with
        
        LOAD"VICBF",8,1
        
        and it will be installed at $1800, or 6144.
        
Additional files in src/
    VICBF.asm is the assembly language source code, with license and comments
    VICBF.obj is the machine language object code, as a series of hex bytes
    VICBF.dis is the assembly language code with opcodes and addresses from $1800
    


IMPLEMENTATION DETAILS

    VICBF is a Brainfuck interpreter for Commodore VIC-20. Note the following:
    
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
  are limited by available stack space. VICBF does not check for stack overflow
  nor stack overread, so pay attention to this.
  
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

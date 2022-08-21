***********************************************************************
*
* Title:          Interrupt based clock and Calculator 
*
* Objective:      CMPEN 472 Homework 9, in-class-room demonstration
*                 program
*
* Revision:       V3.2  for CodeWarrior 5.2 Debugger Simulation
*
* Date:	          Oct. 28, 2020
*
* Programmer:    Yonathan Daniel
*
* Company:        The Pennsylvania State University
*                 Department of Computer Science and Engineering
*
* Program:        Simple SCI Serial Port I/O and Demonstration
*                 Typewriter program and 7-Segment display, at PORTB
*                 
*
* Algorithm:      Simple Serial I/O use, typewriter
*
* Register use:	  A: Serial port data
*                 X,Y: Delay loop counters
*
* Memory use:     RAM Locations from $3000 for data, 
*                 RAM Locations from $3100 for program
*
* Output:         
*                 PORTB bit 7 to bit 4, 7-segment MSB
*                 PORTB bit 3 to bit 0, 7-segment LSB
*
* Observation:    This is a typewriter program that displays ASCII
*                 data on PORTB - 7-segment displays.
*
***********************************************************************
* Parameter Declearation Section
*
* Export Symbols
            XDEF        pstart       ; export 'pstart' symbol
            ABSENTRY    pstart       ; for assembly entry point
  
* Symbols and Macros
PORTB       EQU         $0001        ; i/o port B addresses
DDRB        EQU         $0003

PORTA       EQU         $0000        ; i/o port A addresses
DDRA        EQU         $0002
;** started with working hw9
;*** hw 11 portion interupts
;
ATDCTL2     EQU  $0082            ; Analog-to-Digital Converter (ADC) registers
ATDCTL3     EQU  $0083
ATDCTL4     EQU  $0084
ATDCTL5     EQU  $0085
ATDSTAT0    EQU  $0086
ATDDR0H     EQU  $0090
ATDDR0L     EQU  $0091
ATDDR7H     EQU  $009e
ATDDR7L     EQU  $009f

TIOS        EQU         $0040        ; Timer Input Capture (IC) or Output Compare (OC) select
TIE         EQU         $004C        ; Timer interrupt enable register
TCNTH       EQU         $0044        ; Timer free runing main counter
TSCR1       EQU         $0046        ; Timer system control 1
TSCR2       EQU         $004D        ; Timer system control 2
TFLG1       EQU         $004E        ; Timer interrupt flag 1
TC2H        EQU         $0054        ; Timer channel 2 register
;***
SCIBDH      EQU         $00C8        ; Serial port (SCI) Baud Register H
SCIBDL      EQU         $00C9        ; Serial port (SCI) Baud Register L
SCICR2      EQU         $00CB        ; Serial port (SCI) Control Register 2
SCISR1      EQU         $00CC        ; Serial port (SCI) Status Register 1
SCIDRL      EQU         $00CF        ; Serial port (SCI) Data Register

CRGFLG      EQU         $0037        ; Clock and Reset Generator Flags
CRGINT      EQU         $0038        ; Clock and Reset Generator Interrupts
RTICTL      EQU         $003B        ; Real Time Interrupt Control

CR          equ         $0d          ; carriage return, ASCII 'Return' key
LF          equ         $0a          ; line feed, ASCII 'next line' character
PLUS      	EQU        	$2B
MINUS     	EQU        	$2D
MULT      	EQU       	$2A
DIV       	EQU     	  $2F
***********************************************************************
* Data Section: address used [ $3000 to $30FF ] RAM memory
*
            ORG         $3000        ; Reserved RAM memory starting address 
                                   ;   for Data for CMPEN 472 class
;SCISR1    	EQU    	$0203        	; Serial port (SCI) Status Register 1
;SCIDRL    	EQU    	$0204        	; Serial port (SCI) Data Register
;;;;;;;;;;;;;;interupts;;;;;;;;;;;;;;;;;;;;;;;;;
ctr2p5m     DS.W   1                 ; interrupt counter for 2.5 mSec. of time
times       DS.B   1
;temp        DS.B   1; for clokc function
;timem       DS.B   1
;timeh       DS.B   1
;Buffer   	  DS.B    	5            	; buffer to store input
;CCOUNT    	DS.B    	1             ;keeps track of buffer size
val1        DS.B      1             ;stores clock input first ascii
val2        DS.B      1             ;stores second ascii
result      DS.B      1             ; stores total value from clock input   
;;;;;;;;;;;caclulator;;;;;;;;;;;;;;;;;;;;;
;;storage for ascii val
Buffer   	  DS.B    	10            	; buffer to store input
CCOUNT    	DS.B    	1             ;keeps track of buffer size
NUM1      	DS.B    	6               ;stores values
operand   	DS.B    	1               ; stores the result of the operation (+-/*)
NUM2      	DS.B    	6               ;stores values
NUM1COUNT 	DS.B    	1             	; number values in NUM1
NUM1COUNT2	DS.B    	1             	; copy of NUM1COUNT for use later
NUM2COUNT 	DS.B    	1
NUM2COUNT2	DS.B    	1               ;count2's are incase I needed it later if I did something to value
NUM1SUM   	DS.B    	2               ;total of num1
NUM2SUM   	DS.B    	2               ;total of num2
final     	DS.B    	2               ; final value or result
output      DS.B      5               ; was for outputting but at this point couldnt
outCount    DS.B      1
temp        DS.B      2 ;for putting d into x but for now to display output
sign        DS.B      2 ; if neg or not for subtract 
         	; buffer to store input
;Counter1    DC.W        $008F        ; X register count number for time delay
                                   ;   inner loop for msec
;Counter2    DC.W        $000C        ; Y register count number for time delay
                                     ;   outer loop for sec
;hw 11 stuff
;***
ATDdone     DS.B  1               ; ADC finish indicator, 1 = ATD finished

ctr125u     DS.W    1                ; 16bit interrupt counter for 125 uSec. of time 
ret         DS.B    3                ; for decimal ascii in pdeci sub routine  
count       DS.B    1                                   
;;***
prompt        DC.B        'Tclac>', $00
;*******************************************************
; interrupt vector section
            ORG    $FFF0             ; RTI interrupt vector setup for the simulator
;            ORG    $3FF0             ; RTI interrupt vector setup for the CSM-12C128 board
            DC.W   rtiisr
            ;            ORG     $3FEA            ; Timer channel 2 interrupt vector setup, HC12 board
            ORG     $FFEA            ; Timer channel 2 interrupt vector setup, simulator
            DC.W    oc2isr
;*******************************************************
*
***********************************************************************
* Program Section: address used [ $3100 to $3FFF ] RAM memory
*
            ORG        $3100        ; Program start address, in RAM
pstart      LDS        #$3100       ; initialize the stack pointer

            LDAA       #%11111111   ; Set PORTB bit 0,1,2,3,4,5,6,7
            STAA       DDRB         ; as output

            LDAA       #%00000000
            STAA       PORTB        ; clear all bits of PORTB

            ; just need PORTA for SW0 tbh  
            LDAA   #%00000001   ; Set PORTA bit 0,1,2,3,4,5,6,7
            STAA   DDRA         ; as output
            
            STAA   PORTA        ; set all bits of PORTA, initialize
            
            ldaa    #%00000000
            staa    PORTA   
          

            ldaa       #$0C         ; Enable SCI port Tx and Rx units
            staa       SCICR2       ; disable SCI interrupts

            ldd        #$0002       ; Set SCI Baud Register = $0002 => 1M baud at 24MHz
;            ldd        #$000D       ; Set SCI Baud Register = $000D => 115200 baud at 24MHz
;            ldd        #$009C       ; Set SCI Baud Register = $009C => 9600 baud at 24MHz
            std        SCIBDH       ; SCI port baud rate change

            bset   RTICTL,%00011001 ; set RTI: dev=10*(2**10)=2.555msec for C128 board
                                    ;      4MHz quartz oscillator clock
            bset   CRGINT,%10000000 ; enable RTI interrupt
            bset   CRGFLG,%10000000 ; clear RTI IF (Interrupt Flag)


            ldx    #0
            stx    ctr2p5m          ; initialize interrupt counter with 0.
            cli                     ; enable interrupt, global
            
            ; ATD initialization
            LDAA  #%11000000       ; Turn ON ADC, clear flags, Disable ATD interrupt
            STAA  ATDCTL2
            LDAA  #%00001000       ; Single conversion per sequence, no FIFO
            STAA  ATDCTL3
            LDAA  #%10000111       ; 8bit, ADCLK=24MHz/16=1.5MHz, sampling time=2*(1/ADCLK)
            STAA  ATDCTL4          ; for SIMULATION
            
            ldaa #0
            staa val1
            staa val2
            staa result                     
            staa times   
           
           ldx     	#msg1
           jsr     	printmsg
         
           ; bra reset 

reset 
        ;;reset variables
        ;; jump to loop below  
           	clr     	Buffer
          	clr       Buffer+1
          	clr       Buffer+2
          	clr       Buffer+3
          	clr       Buffer+4
          	clr       Buffer+5
          	clr       Buffer+6
          	clr       Buffer+7
          	clr       Buffer+8
          	clr       Buffer+9
          	clr      	CCOUNT
          	clr      	NUM1
          	clr      	NUM2
          	clr     	NUM1COUNT
          	clr      	NUM2COUNT
            clr      	NUM1COUNT2
            clr      	NUM2COUNT2
            clr      operand
          	clr       output 
          	clr       outCount 
          	clr       final
          	clr        sign
          	
          	jsr nextline 
          	ldx #inst
          	jsr printmsg
          	jsr nextline
          	ldx #inst2
          	jsr printmsg
          	jsr nextline
          	ldx #inst3
          	jsr printmsg
          	jsr nextline
          	ldx #inst4
          	jsr printmsg
          	jsr nextline
          	ldx #inst5
          	jsr printmsg
          	jsr nextline   
          	ldx #inst6
          	jsr printmsg
          	jsr nextline 
          	
          	ldx     	#prompt
          	jsr     	printmsg
          	ldy     	#Buffer   	   ; Jump to start of buffer
            ;bra hw9

hw9         
           jsr   clock 
            
            jsr   getchar            ; type writer - check the key board
            cmpa  #$00               ;  if nothing typed, keep checking
            beq   hw9
            
            jsr     	putchar
          	staa    	0,y
          	iny
          	
          	inc     	CCOUNT
          	ldab    	CCOUNT
          	cmpb    	#9        	; test if CCOUNT = 9, if so, not a valid input
          	bne     	lessThan9
          	lbra    	Error1
         	 
lessThan9 	cmpa    	#CR       	; user hit return
          	beq     	returned
          	bra     	hw9
   	 
returned 	 
            ;;check if only enter then jump to atd or buffer size less than 9
            ldab CCOUNT
            cmpb #1 
            lbeq  hw11 
            ldx #Buffer                         
            lbra bitone               

;****************************************************************************
; has to be a digit to be valid 
bitone    ldaa    	1,X+
          ;check if valid for clock
          cmpa   #$73                   ;checsk for s
          lbeq   SetClock
          cmpa  #$71                    ; checks for q
          lbeq Quit
          ;if not then must be an error or calc prompt 
          cmpa    	#CR       	 
          lbeq    	EarlyEnter  
          cmpa    	#$39
          lbhi    	MustBeDigit
          cmpa    	#$30
          lblo    	MustBeDigit
          suba      #$30
          staa    	NUM1+1
          inc     	NUM1COUNT
          inc     	NUM1COUNT2

;* Check if second bit is between 0 and 9 or an operand (+-*/),
;* if it's an operand character, store it and branch to second number        	 
bittwo
          	ldaa    	1,X+
          	cmpa    	#CR        	; If 2nd digit of buffer is CR, then only one number was entered	ex: 1
          	lbeq    	EarlyEnter  
          	cmpa    	#PLUS     	 
          	bne     	IFMINUS
          	staa    	operand
          	lbra    	secondNum                                           	 
IFMINUS    	cmpa    	#MINUS
          	bne     	IFMULT 	 
          	staa    operand
          	lbra    	secondNum
IFMULT 	    cmpa    	#MULT
          	bne     	IFDIV
          	staa    operand
          	lbra    	secondNum
IFDIV     	cmpa    	#DIV
          	bne     	IFDigit
          	staa    operand
            lbra    	secondNum
IFDigit	    cmpa    	#$39
          	lbhi    	Error1     	; check if higher than 9
          	cmpa    	#$30
          	lblo    	Error1     	; check if lower than 0
          	suba      #$30
          	staa    	NUM1+3
          	inc     	NUM1COUNT
          	inc     	NUM1COUNT2
;*******************************************************************************        	 
         	 
BitThreeFirstNum
          	ldaa    	1,X+
          	cmpa    	#CR        	 
          	lbeq    	EarlyEnter 	; ex: 12'CR'
          	cmpa    	#PLUS      	 
          	bne    	  IFMINUS2
          	staa    operand
          	bra     	secondNum                                           	 
IFMINUS2    cmpa    	#MINUS
          	bne     	IFMULT2 	 
          	staa    operand
          	bra     	secondNum
IFMULT2	    cmpa    	#MULT
          	bne     	IFDIV2
          	staa    	operand
          	bra     	secondNum
IFDIV2 	    cmpa    	#DIV
          	bne     	IFDigit2    
          	staa    operand
          	bra     	secondNum  
   
IFDigit2    cmpa    	#$39
          	lbhi    	Error1     	; check if higher than 9
          	cmpa    	#$30
          	lblo    	Error1     	; check if lower than 0
          	suba      #$30
          	staa   	  NUM1+5
          	inc     	NUM1COUNT
          	inc     	NUM1COUNT2
;*******************************************************************************
;to get to this case no operand must have been inputted prior to this
BitFour
          	ldaa     	1,X+
          	cmpa    	#CR     	 
          	lbeq    	EarlyEnter
          	cmpa    	#PLUS      	 
          	bne     	IFMINUS3
          	staa    	operand
          	bra     	secondNum   
                                                      	 
IFMINUS3    cmpa    	#MINUS
          	bne     	IFMULT3 	 
          	staa    operand
          	bra     	secondNum
         	 
IFMULT3	    cmpa    	#MULT
          	bne     	IFDIV3
          	staa    	operand
          	bra     	secondNum
         	 
IFDIV3 	    cmpa    	    #DIV
          	lbne    	MissingChar    	; if the fourth bit is not a character and no characters have been previously entered
          	                          ;then the input is invalid
          	staa    operand
          	bra     	secondNum         	 

;*******************************************************************************

secondNum 	 
          	 
          	 
num2bitOne
          	ldaa    	1,X+
          	cmpa    	#CR            	; If first mem location in second num is CR, theninput is invalid like 123+
          	lbeq     	EarlyEnter
          	cmpa    	#$39
          	lbhi    	MustBeDigit    	;  if higher than 9
          	cmpa    	#$30
          	lblo    	MustBeDigit    	; if lower than 0
            suba      #$30
          	staa    	NUM2+1
       	 
          	inc     	NUM2COUNT
          	inc     	NUM2COUNT2
num2bitTwo
          	ldaa    	1,X+
          	cmpa    	#CR        	 
          	lbeq    NUM1Total;Conversion      	; ex: 123+1 or 1+1
          	cmpa    	#$39
          	lbhi    	MustBeDigit     	; check if higher than 9
          	cmpa    	#$30
          	lblo    	MustBeDigit     	; check if lower than 0
          	suba      #$30
          	staa    	NUM2+3
            	 
          	inc     	NUM2COUNT
          	inc     	NUM2COUNT2
         	 
num2bitThree
          	ldaa    	X               	 
          	cmpa    	#CR        	 
          	beq     	NUM1Total
          	cmpa    	#$39
          	lbhi    	MustBeDigit     	; check if higher than 9
          	cmpa    	#$30
          	lblo    	MustBeDigit     	; check if lower than 0
          	suba      #$30
          	staa    	NUM2+5
         	 
          	inc     	NUM2COUNT
          	inc     	NUM2COUNT2
         	 
;*********************************************************************************
;* Converting num1 and num2 to a single value 
;*********************************************************************************
          	 
                        	 
NUM1Total
         	 
           
          	ldab    	NUM1COUNT2
          	cmpb    	#3                  	; check if num1 has 3 numbers
          	beq     	num1Has3
          	cmpb    	#2
          	beq     	num1Has2
          	cmpb    	#1
          	beq     	num1Has1
          	ldaa   	NUM1COUNT2
          	jsr     	nextline
          	ldaa    	NUM1COUNT2        	
          	jsr     	putchar
          	jsr     	nextline
          
                                            	 
num1Has3
          ;	LDAA    	NUM1
          ;	LDAB    	#100
          ;	MUL                             	; 100*first digit of num1 = B
          ;	STAB    	NUM1SUM            	; stores 100*first digit of num1 into the byte designated by NUM1SUM
          ;	LDAA    	NUM1+1
          ;	LDAB    	#10
          ;	MUL                             	; 10*second digit of num1 = B
          ;	ADDB    	NUM1SUM             	; 100*first digit of num1 + 10*second digit of num1 =  B
          ;	ADDB    	NUM1+2              
          ;	STAB    	NUM1SUM           	 
          clra
          clrb
          ;clear D
          ldd  NUM1
          ldy  #100
          emul
          std  NUM1SUM; have lower 16 bits in D
          ldy  #10
          ldd NUM1+2
          emul	
          addd NUM1SUM
          addd NUM1+4
          std  NUM1SUM	
          	BRA     	NUM2total

num1Has2
          	;LDAB    	#10
          	;MUL                             	; 10*first digit of num1 = B         	 
          	;ADDB    	NUM1+1         	 
          	;STAB    	NUM1SUM            	 
          	clra
            clrb
          	;cleaar D
          	;ldab     NUM1
          	ldd       NUM1
          	ldy       #10
          	emul
          	addd      NUM1+2
          	std       NUM1SUM
          	BRA     	NUM2total
         	 


num1Has1  	
           clra
           clrb
            ;clear D
            LDD    	NUM1
          	STD    	NUM1SUM
          	BRA     	NUM2total
 
          	 

NUM2total
          	LDAB    	NUM2COUNT2  
          	CMPB    	#3                  	; check if num1 has 3 numbers
          	BEQ     	num2Has3
          	CMPB    	#2
          	BEQ     	num2Has2
          	CMPB    	#1
          	BEQ     	num2Has1
          
                                            	 
num2Has3
          	;LDAA    	NUM2
          	;LDAB    	#100
          	;MUL                             	; 100*first num2 digit = B
          	;STAB    	NUM2SUM             	; put 100*first digit of num2 into the byte specified by NUM2SUM
          	;LDAA    	NUM2+1
          	;LDAB    	#10
          	;MUL                             	; 10*second num2 digit = B
          	;ADDB    	NUM2SUM             	; 100*first digit of num2 + 10*second digit of num2 = B
          	;ADDB    	NUM2+2              	; no need to load 1 into B for MUL, just  add the third digit
          	;STAB    	NUM2SUM           	 
             clra
             clrb
          	 ;; clear D
          ;ldab NUM2
          	ldd  NUM2
            ldy  #100
            emul
            std  NUM2SUM; have lower 16 bits in D
            ldy  #10
            ldd NUM2+2
            emul	
            addd NUM2SUM
            addd NUM2+4
            std  NUM2SUM	
          	
          	
          	BRA     	Operation

num2Has2
          	;LDAB    	#10
          	;MUL                             	; 10*first num2 digit =  B         	 
          	;ADDB    	NUM2+1         	 
          	;STAB    	NUM2SUM            	 
          	 clra
             clrb
          	 ;;clear D 
           ;ldab NUM2+1
            ldd       NUM2
          	ldy       #10
          	emul
          	addd      NUM2+2
          	std     NUM2SUM
          	BRA     	Operation
         	 
num2Has1  	
            clra
            clrb
            ; clear D
            LDD     	NUM2
          	STD      	NUM2SUM; to get into second byte
          	BRA     	Operation       	 
       	 
                    	 
;****************************************************************************
 ; decide what operation is needed
Operation              	 
            ldaa     operand 
          	cmpa     	#PLUS
          	bne      	subtract
          	bra      	addFunct
subtract 	 
          	cmpa     	#MINUS
          	bne      	multiply        	 
          	bra      	subtractFunct
multiply 	 
          	cmpa     	#MULT
          	bne      	divide
          	bra      	multiplyFunct
divide   	 
          	cmpa     	#DIV
          	lbne      	Error1
          	bra      	divideFunct	 
   
addFunct  	;ldaa     	NUM1SUM
          	;jsr      	nextLine
          	;jsr      	putchar
          	
          	ldd      	NUM1SUM
          	addd     	NUM2SUM
          	std      	final
          
            bra out          	 
 	                      
subtractFunct
            ldd      	NUM1SUM
          	subd     	NUM2SUM
;; need way to track negatives 
            lbmi negative        ;branch if negative   
            bpl positive         ;branch if positive      
negative 
            ;subd #$ffff ; ones complement
            ;addd #$0001 ; two complement
            coma 
            comb
            addd #$0001
            std final
            inc sign 
            bra out
positive                 	
          	std      	final
            bra out 

multiplyFunct
             ldd      	NUM1SUM
          	 ldy     	NUM2SUM
          	 emul
          	 std      final
             
             cpy #$0001
             lbhs Error2
             blo out

divideFunct
         ldd      	NUM1SUM
         ldx     	  NUM2SUM
         idiv
         stx       final
         
         bra out         
 ;; displaying output	 
out
     ;ldx temp
     ;ldd temp 
     clra
     clrb
     ;std temp 
     
     ldx final                                                      
     ;stx temp
     ;ldx #couldnt
     ;jsr printmsg
     ;jsr nextLine
     ;lbra reset
     
     ldd final
     ldx #10
     idiv 
     ldy #output
     stab y
     iny
     inc  outCount 
     clra
     clrb
     cpx #0 ;;is quotient 0
     beq out2 ;;only 1 
     stx temp
     bra outloop
outloop
         ldx #10
         ldd temp
         idiv 
         stab y
         iny
         inc  outCount 
         clra
         clrb
        stx temp
          
        ldd temp
     ; do not uncomment this  ;ldaa outCount 
        cpd #0
        bne outloop
        beq out2 
out2
    LDX  #prompt
    JSR   printmsg
    ;ldx #Buffer
    ;jsr nextLine
    ldx #Buffer
outloop1
    ;jsr nextLine
    ldaa 1,X+
    cmpa #$0D
    bne outloop1
   ; bne putchar
null
    ldaa $00
    dex ;just for now
    staa x
    ldx #Buffer
    jsr printmsg
;    jmp out2
outloop2
    ldaa #$3D      ;ascii value  for equal
    ;cmpa #$3D
    ;beq putchar
    jsr putchar
    ldx sign 
    cpx #0
    beq  normal 
    bne  negsign 
negsign    
    ldd final 
    cpd #0 
    beq normal
    ldaa #MINUS
    jsr putchar
normal     
    ldy #output
    ldab outCount
    aby
    dey
    ;sty temp; offset for what part of buffer to start at 
    ; clear
    clra
    clrb
    ;ldy temp 
outloop3 
      ldaa y
      adda #$30; just for now 
      ;cmpa #30
      ;bhs putchar
      jsr putchar
      dey
      dec outCount 
      ldaa outCount
      cmpa #0
      lbeq outDone 
      bne outloop3
outDone
    jsr nextline
    lbra reset
                  
;subroutine section below


; for quit command  
looop       jsr    LEDtoggle        ; if 0.5 second is up, toggle the LED 

            jsr    getchar          ; type writer - check the key board
            tsta                    ;  if nothing typed, keep checking
            beq    looop
                                    ;  otherwise - what is typed on key board
            jsr    putchar          ; is displayed on the terminal window
            cmpa   #CR
            bne    looop            ; if Enter/Return key is pressed, move the
            ldaa   #LF              ; cursor to next line
            jsr    putchar
            bra    looop
;*************************
SetClock
        ldaa 1,X+
        cmpa #$20  ;;check for space                                           
        lbne Error
        ldab CCOUNT
        cmpb #4 ;4 byte buffer means one digit input under current assumptions
        beq OneDigit
        cmpb #5
        beq TwoDigit
        lbne Error  

OneDigit
         ldaa     1,X+
         cmpa    	#$39
         lbhi    	Error     	; check if higher than 9
         cmpa    	#$30
         lblo    	Error     	; check if lower than 0
         suba     #$30
         staa     val1         ; first digit
         ldaa     #00
         staa     val2         ; set second digit to zero
         ldaa     1,X+
         cmpa      #CR
         beq     NewTime 
         lbne      Error
TwoDigit
         ldaa 1,X+
         cmpa    	#$35
         lbhi    	Error     	; check if higher than 5
         cmpa    	#$30
         lblo    	Error     	; check if lower than 0
         suba     #$30
         staa     val2
         ;;second digit below
         ldaa     1,X+
         cmpa    	#$39
         lbhi    	Error     	; check if higher than 9
         cmpa    	#$30
         lblo    	Error     	; check if lower than 0
         suba     #$30
         staa     val1
         ;; return check
         ldaa     1,X+
         cmpa      #CR
         beq      NewTime 
         lbne      Error
;;;;probably compute value         
NewTime         
        ldaa val2 
        ldab #10
        mul         ; 
        ;stab result
        ldaa val1
        aba    ; A+B=A                 
        staa result ; result = hex input
        staa times
        jsr clock  
        lbra reset 

;***************************
Quit     ;;if q entered
        ldab 1,X+
        cmpb #CR
        ldx #quitting
        JSR   	printmsg
        lbra looop
;***************************
;Clock subroutine 
clock
          psha
          pshx
          pshb
          
        
          ldx    ctr2p5m          ; check for 0.5 sec
;         cpx    #200             ; 2.5msec * 200 = 0.5 sec
          cpx    #80           ; 2.5msec * 200 = 0.5 sec
          lblo    clockdone 
          ldx    #0               ; 0.5sec is up,
          stx    ctr2p5m          ;     clear counter to restart
          
          ;ldx    ctr2p5m          ; check for 0.5 sec
    ;     cpx    #200             ; 2.5msec * 200 = 0.5 sec
          ;cpx    #40             ; 2.5msec * 200 = 0.5 sec
          ;blo    clockcont 
          ;ldx    #0               ; 0.5sec is up,
          ;stx    ctr2p5m          ;     clear counter to restart
          ;; can update clock now 
          ldaa times
          ldab #%00000000
          stab PORTB
          
          cmpa #9
          bls time9
          cmpa #19
          bls time19
          cmpa #29
          bls time29
          cmpa #39
          bls time39
          cmpa #49
          bls time49
          cmpa #59
          bls time59
          cmpa #60
          bhs over60
          ;; problem if it doesnt branch here    

time9   ;0-9
         ldaa times ;just checking
         staa PORTB ;$0X x is hex value 0-9
         inca 
         staa times
         ;ldaa PORTB
         ;inca
         ;daa
         ;staa PORTB
         bra clockdone 
time19   ;10-19
         ldaa times
         suba  #10
         adda #$10  ; # A = $1X x = 0-9
         staa PORTB ; loads new value into portb
         inca
         staa times
         ;ldaa PORTB
         ;inca
         ;daa
         ;staa PORTB
         bra clockdone 
time29   ;20-29
         ldaa times
         suba  #20
         adda #$20
         staa PORTB ; loads new value into portb
        inca
        staa times
        ;ldaa PORTB
         ;inca
        ; daa
        ; staa PORTB
        bra clockdone 
time39   ;30-39
         ldaa times
         suba  #30
         adda #$30
         staa PORTB ; loads new value into portb
        inca
        staa times
        ;ldaa PORTB
         ;inca
         ;daa
         ;staa PORTB
        bra clockdone 
time49   ;41-49
         ldaa times
         suba  #40
         adda #$40
         ldab PORTB 
        ; clrb
        ; stab PORTB ;; clears portb
        ; coma ;just checking
         staa PORTB ; loads new value into portb
        inca
        staa times   
        ;ldaa PORTB
        ; inca
         ;daa
        ; staa PORTB
        bra clockdone 
time59   ;50-59       
         ldaa times
         suba  #50
         adda #$50
         staa PORTB ; loads new value into port
         inca
         staa times
         ;ldaa PORTB
         ;inca
         ;daa
         ;staa PORTB
clockdone 
         ldx times
         cpx #60
         beq over60
         bne actuallyDone 
over60           
          ldaa #0
          staa times 
          ;staa PORTB
actuallyDone
          pulx
          pula
          pulb
          ;lbra clock
          rts
;***************************

;hw 11 actual loops
hw11     
            jsr   nextline
            ldx   #msg3           ; print the sixth message, more instruction
            jsr   printmsg
            jsr   nextline
            ldx   #msg4           ; print the sixth message, more instruction
            jsr   printmsg
            jsr   nextline
            ldx   #msg5           ; print the sixth message, more instruction
            jsr   printmsg
            jsr   nextline
            
hw11p2            
            ; add a bunch of messages 
            ldaa PORTA   ;ready for switch
            anda  #%00000001   ; check the bit 0 only
            beq hw11p2  ;keep looping until user pushes SW0
            jsr StartTimer2oc

loop1024    ldx  ctr125u
            cpx  #1024
            ble  loop1024
            ;bne loop1024
            ;;;;;;;;;  
            sei      ;enable/disable masked interuprts (set I bit)
            ldx #0
            stx ctr125u
            ;;;;;;;; 
            jsr   nextline
            ldx   #msg6           ; print the sixth message, more instruction
            jsr   printmsg
            jsr   nextline
            ldx   #msg7            ; print the seventh message, more instruction
            jsr   printmsg
            jsr   nextline
            ldx   #msg8            ; print the eighth message, more instruction
            jsr   printmsg
            jsr   nextline
            jsr   nextline
         
loop2onlyON 
            ldaa  PORTA
            anda  #%00000001
            ;bne   loop2onlyON ;sw0 pressed again?
            ;bra   hw11p2       ;here we go again
            lbra   reset   
;end 

;***********RTI interrupt service routine***************
rtiisr      
            
            bset   CRGFLG,%10000000 ; clear RTI Interrupt Flag - for the next one
            ldx    ctr2p5m          ; every time the RTI occur, increase
            inx                     ;    the 16bit interrupt count
            stx    ctr2p5m
rtidone     RTI
;***********end of RTI interrupt service routine********

;***************LEDtoggle**********************
;* Program: toggle LED if 0.5 second is up
;* Input:   ctr2p5m variable
;* Output:  ctr2p5m variable and LED1
;* Registers modified: CCR
;* Algorithm:
;    Check for 0.5 second passed
;      if not 0.5 second yet, just pass
;      if 0.5 second has reached, then toggle LED and reset ctr2p5m
;**********************************************
LEDtoggle   psha
            pshx

            ldx    ctr2p5m          ; check for 0.5 sec
;           cpx    #200             ; 2.5msec * 200 = 0.5 sec
            cpx    #40             ; 2.5msec * 200 = 0.5 sec
            blo    doneLED          ; NOT yet

            ldx    #0               ; 0.5sec is up,
            stx    ctr2p5m          ;     clear counter to restart

            LDAA   PORTB
            EORA   #%00000001       ; Toggle the PORTB bit 4, LED1
            STAA   PORTB

            ldaa   #'*'             ; also print a '*' on the screen
            jsr    putchar

doneLED     pulx
            pula
            rts        

;hw 11 subroutines here
;***********Timer OC2 interrupt service routine***************
oc2isr
            jsr go2ADC               ;call every interupt
            ldd   #3000              ; 125usec with (24MHz/1 clock)
            addd  TC2H               ;    for next interrupt
            std   TC2H               ; 
            bset  TFLG1,%00000100    ; clear timer CH2 interrupt flag, not needed if fast clear enabled
            ldx   ctr125u            ; 125uSec => 8.000KHz rate
            inx
            stx   ctr125u            ; every time the RTI occur, increase interrupt count
oc2done     RTI
;***********end of Timer OC2 interrupt service routine********

;***************StartTimer2oc************************
;* Program: Start the timer interrupt, timer channel 2 output compare
;* Input:   Constants - channel 2 output compare, 125usec at 24MHz
;* Output:  None, only the timer interrupt
;* Registers modified: D used and CCR modified
;* Algorithm:
;             initialize TIOS, TIE, TSCR1, TSCR2, TC2H, and TFLG1
;**********************************************
StartTimer2oc
            PSHD
            LDAA   #%00000100
            STAA   TIOS              ; set CH2 Output Compare
            STAA   TIE               ; set CH2 interrupt Enable
            LDAA   #%10000000        ; enable timer, Fast Flag Clear not set
            STAA   TSCR1
            LDAA   #%00000000        ; TOI Off, TCRE Off, TCLK = BCLK/1
            STAA   TSCR2             ;   not needed if started from reset

            LDD     #3000            ; 125usec with (24MHz/1 clock)
            ADDD    TCNTH            ;    for first interrupt
            STD     TC2H             ; 

            PULD
            BSET   TFLG1,%00000100   ; initial Timer CH2 interrupt flag Clear, not needed if fast clear set
            CLI                      ; enable interrupt
            RTS
;***************end of StartTimer2oc***************** 

;***********single AD conversiton*********************
; This is a sample, non-interrupt, busy wait method
;
go2ADC
            PSHA                   ; Start ATD conversion
            LDAA  #%10000111       ; right justified, unsigned, single conversion,
            STAA  ATDCTL5          ; single channel, CHANNEL 7, start the conversion

adcwait     ldaa  ATDSTAT0         ; Wait until ATD conversion finish
            anda  #%10000000       ; check SCF bit, wait for ATD conversion to finish
            beq   adcwait

            ;ldaa  #'$'             ; print the ATD result, in hex
            ;jsr   putchar

            ldaa  ATDDR0L          ; for SIMULATOR, pick up the lower 8bit result
            ;turn this subroutine into printDeci (below)
            ;jsr   printHx          ; print the ATD result
            jsr     pdeci           ; print the ATD result
            jsr   nextline

            PULA
            RTS
;***********end of AD conversiton**************        
;************* pdeci ********************************
;**prints decimal value to terminal 
;Input accumulatro A
;no specific reg output but terminal displays orginal accumulator A value in ascii
pdeci
                pshd                   ;Save registers
                pshx
                pshy
                clr     count          ; clear count for the 8 bit number
                clr     ret            ; convert 8bit to 16bit, clear upper byte of 
                staa    ret+1          ; a 16bit number
                ldd     ret
                ldy     #ret
pdeci1          ldx     #10
                idiv
                beq     pdeci2
                stab    1,y+
                inc     count
                tfr     x,d
                bra     pdeci1
pdeci2          stab    1,y+
                inc     count                        

pdeci3          ldaa    #$30                
                adda    1,-y
                jsr     putchar
                dec     count
                bne     pdeci3
                puly
                pulx
                puld
                rts
;************** end of pdeci ******************
;end of hw 11 sub's
;***************************
Error 
       jsr ErrorDisp 
       lbra reset        
;***********printmsg***************************
;* Program: Output character string to SCI port, print message
;* Input:   Register X points to ASCII characters in memory
;* Output:  message printed on the terminal connected to SCI port
;* 
;* Registers modified: CCR
;* Algorithm:
;     Pick up 1 byte from memory where X register is pointing
;     Send it out to SCI port
;     Update X register to point to the next byte
;     Repeat until the byte data $00 is encountered
;       (String is terminated with NULL=$00)
;**********************************************
NULL           equ     $00
printmsg       psha                   ;Save registers
               pshx
printmsgloop   ldaa    1,X+           ;pick up an ASCII character from string
                                       ;   pointed by X register
                                       ;then update the X register to point to
                                       ;   the next byte
               cmpa    #NULL
               beq     printmsgdone   ;end of strint yet?
               jsr     putchar        ;if not, print character and do next
               bra     printmsgloop

printmsgdone   pulx 
               pula
               rts
;***********end of printmsg********************


;***************putchar************************
;* Program: Send one character to SCI port, terminal
;* Input:   Accumulator A contains an ASCII character, 8bit
;* Output:  Send one character to SCI port, terminal
;* Registers modified: CCR
;* Algorithm:
;    Wait for transmit buffer become empty
;      Transmit buffer empty is indicated by TDRE bit
;      TDRE = 1 : empty - Transmit Data Register Empty, ready to transmit
;      TDRE = 0 : not empty, transmission in progress
;**********************************************
putchar        brclr SCISR1,#%10000000,putchar   ; wait for transmit buffer empty
               staa  SCIDRL                      ; send a character
               rts
;***************end of putchar*****************


;****************getchar***********************
;* Program: Input one character from SCI port (terminal/keyboard)
;*             if a character is received, other wise return NULL
;* Input:   none    
;* Output:  Accumulator A containing the received ASCII character
;*          if a character is received.
;*          Otherwise Accumulator A will contain a NULL character, $00.
;* Registers modified: CCR
;* Algorithm:
;    Check for receive buffer become full
;      Receive buffer full is indicated by RDRF bit
;      RDRF = 1 : full - Receive Data Register Full, 1 byte received
;      RDRF = 0 : not full, 0 byte received
;**********************************************
getchar        brclr SCISR1,#%00100000,getchar7
               ldaa  SCIDRL
               rts
getchar7       clra
               rts
;****************end of getchar**************** 

;OPTIONAL
;more variable/data section below
; this is after the program code section
; of the RAM.  RAM ends at $3FFF
; in MC9S12C128 chip
;******************************************************

;error functions
;****************displayError1*****************
;* Program: Displays error for no input then
;*      	restarts
;* Register in use: X for printing message
showErr1	 
           	LDX   	#error1
           	;JSR   	nextLine
           	JSR   	printmsg
           	JSR   	nextline
           	RTS   
;****************endDisplayError1**************

;****************displayError2*****************

showErr2	 
           	LDX   	#error2
           	JSR   	nextline
           	JSR   	printmsg
           	JSR   	nextline
           	RTS   
;****************endDisplayError2**************

;****************displayError2*****************

showErr3	 
           	LDX   	#mustBeDigit
           	JSR   	printmsg
           	JSR   	nextline
           	RTS   
;****************endDisplayError2**************

   

;****************displayEarlyEnter*************
showEarlyEnter
          	LDX   	#earlyEnter
          	;JSR   	nextLine
          	JSR   	printmsg
          	JSR   	nextline
          	RTS
;**********************************************  

;****************displayMissingChar*************
showMissingChar
          	LDX   	#missingChar
          	;JSR   	nextLine
          	JSR   	printmsg
          	JSR   	nextline
          	RTS
;**********************************************  

   
;**************nextLine************************
nextline
           	psha
           	ldaa  	#CR
           	jsr   	putchar
           	ldaa  	#LF
           	jsr   	putchar
           	pula
           	rts
;**********************************************
            
; displaying error 
ErrorDisp
          	LDX   	#error1
          	JSR   	nextline
          	JSR   	printmsg
          	JSR   	nextline
          	RTS
;******************************************************
; messages
error1     	DC.B  	'Invalid input format', $00
error2     	DC.B  	'Overflow Error', $00
mustBeDigit	DC.B  	'Non-digit input', $00
earlyEnter 	DC.B  	'You hit enter too early', $00
missingChar	DC.B  	'No operand in first 4 characters', $00
quitting    DC.B     'Stop clock and start Typewrite program',$00

inst        DC.B     'For ATD press enter ONLY and see more prompts',$00
inst2       DC.B     'enter a number,operand(+-*/), then the second number',$00
inst3       DC.B     'The numbers can be at most three digits',$00
inst4       DC.B     'Enter s to set the clock',$00
inst5       DC.B     'Format for above:s XX with XX digits between 0-59',$00
inst6       DC.B     'Enter q ONLY to quit and enter a type writer program',$00

msg1        DC.B  'Hello, this is hw12 a combo of ATD conversion, clock,and a calculator.', $00
msg2        DC.B  'Hit enter key to continue', $00
msg3        DC.B  'Execute File AWAVE100s.cmd.txt in command window of simulation.', $00
msg4        DC.B  'Set terminal output capture file to a text file of your choice and set cache size to 10000',$00
msg5        DC.B  'Press switch SW0 (PORTA,bit0) to execute',$00
msg6        DC.B   'Done!!!',$00
msg7        DC.B   'Flip switch (SW0) again to run again make sure to handle input cmd and/or output file',$00
msg8        DC.B   'Need to double tap switch to run again',$00
 ;******************************************************
 ;errors
         	 
Error1    	 JSR    	showErr1  	; invalid input
          	 LBRA   	reset
Error2    	 JSR    	showErr2  	; overflow
          	 LBRA   	reset
MustBeDigit  JSR    	showErr3  	; used when an input is not a digit, but should be
          	 LBRA   	reset

EarlyEnter	 JSR    	showEarlyEnter
          	 LBRA   	reset
MissingChar  JSR    	showMissingChar
          	 LBRA   	reset

               END               ; this is end of assembly source file
                                 ; lines below are ignored - not assembled/compiled

# Digital-Clock-and-Calculator
Combine the Homework 7, Homework 8, and Homework11; that is, Write a program to make
a calculator, a digital clock, and an Analog Data acquisition on the HCS12 chip.

The calculator and digital clock rules are:

Input positive decimal numbers only
Input maximum three-digit numbers only
Valid operators are: +, -, *, and /
Input number with leading zero is OK
Input only two numbers and one operator in between, no spaces
Show 'Tcalc> 'prompt and echo print user keystrokes until Return key
Repeat print user input and print answer after the '=' sign
In case of an invalid input format, repeat print the user input until the error character
In case of an invalid input format, print error message on the next line: 'Invalid input format'
Keep 16bit internal binary number format, detect and flag overflow error
Use integer division and truncate any fraction
60 second (0 to 59) clock
"s" for 'set time' command
Update the time display every second
Time display: two 7-segment displays on PORTB
Calculator display: on the terminal screen
Use Real Time Interrupt feature to keep the time

The Terminal display should look something like the following (same rules as Homework 7 and 8):
Tcalc>
Tcalc> 123+4
       123+4=127
Tcalc> 96*15
       96*15=1440
Tcalc> 456@5
       456@
       Invalid input format
Tcalc> 7h4*12
       7h
       Invalid input format
Tcalc> 3*1234
       3*1234
       Invalid input format	;due to 4th digit
Tcalc> 003-678
       003-678=-675
Tcalc> 100+999*2
       100+999*
       Invalid input format
Tcalc> 555/3
       555/3=185
Tcalc> 7*(45+123)
       7*(
       Invalid input format
Tcalc> 78*999
       78*999
       Overflow error
Tcalc> -2*123
       -
       Invalid input format
Tcalc> 73/15
       73/15=4
Tcalc>
Tcalc> s 59
Tcalc> 
Tcalc> s 05:552:5
       Invalid time format. Correct example => 0 to 59
Tcalc> s 75
       Invalid time format. Correct example => 0 to 59
Tcalc> s 1F
       Invalid time format. Correct example => 0 to 59 
Tcalc> q
       Stop clock and calculator, start Typewrite program

In addition to the Calculator and the Digital Clock programs running, the ADC Data Acquisition program
should be running also when a user presses the Switch SW0 at PORTA bit 0.
The ADC Data Acquisition program is outlined as follows (similar to Homework 11):

The SCI port Terminal baud rate at 750Kbaud.
Activated when the Switch SW0 pressed at PORTA bit 0.
Start the Timer Module Channel 2 Output Compare interrupt generation at every 125usec (8KHz rate).
Each time the Output Compare interrupt occurs, carry out the following tasks:

Pick up the ADC result (from previous conversion) and set the flag 'happened'.
Only the lower 8-bit of the ADC result should be picked up (and saved temporalily,
to be converted to a decimal representation of the data in ASCII characters in main program later).
Start a single Analog-to-Digital conversion of the signal on the AN7 pin
Service the Output Compare (OC2) register (update the counter compare number) for the next interrupt.
Also clear the OC2 interrupt flag.

In the main program, if the Timer OC2 interrupt 'happened', then send the most recently acquired data
to the Terminal. Convert the data to decimal representation in ASCII characters before sending it to the Terminal.
Repeat until the transmit data count to be 1024
Print a completion message on the Terminal when the 1024 data transmission completes.
ADC Data Acquisition repeats every time the Switch SW0 is pressed while the Calculator and the Digital Clock is running at the same time.

Once your HW12 is finished, run it many times to test that it works. For the ADC Acquisition, Change the analog signal wave frequency as well as the wave type as you test your HW12. Repeat the data acquisition and plotting. Use the same wave form signal files given for the HW11

Write a report of your HW12 program and your experiments, similar to Homework 11.

Make your program user friendly by giving simple directions as to how to correctly use your program.

Also, make your program 'fool-proof', never crash or stop based on wrong user response.

You may add other features or decorations.

Use as many re-usable subroutines as possible, and make your overall program to be small. So you may re-visit your Homework 7, 8, and 11, and identify the tasks in your main program that can be made to be subroutines. Once you made those subroutines, your main program becomes much simpler and your overall program be smaller. In many cases, your program may be run faster too.

Design the program to start at $3100 and data to start at $3000.

;Program to sequence LEDs on port B, using a look up table 

;Stack and Stack Pointer Addresses 
.equ     SPH    =$3E              ;High Byte Stack Pointer Address 
.equ     SPL    =$3D              ;Low Byte Stack Pointer Address 
.equ     RAMEND =$25F             ;Stack Address 

;Port Addresses 

.equ    PORTA =$1B                 ;Port A Output Address 
.equ    DDRA  =$1A                 ;Port A Data Direction Register Address 

.equ    PORTB =$18                 ;Port B Output Address 
.equ    DDRB  =$17                 ;Port B Data Direction Register Address

.equ    DDRD  =$11                 ;Port D Data Direction Register Address 
.equ    PIND  =$10                 ;Port D Input Address 

;Register Definitions 
.def     leds   =r0               ;Register to store data pointed to by Z
.def     ledstwo =r1              ;Register to (temporarily) store data pointed to by Z
.def     temp   =r16              ;Temporary storage registers 
.def     count  =r17
.def     counttwo =r18 
.def     YL     =r28              ;Define low byte of Y 
.def     YH     =r29              ;Define high byte of Y 
.def     ZL     =r30              ;Define low byte of Z 
.def     ZH     =r31              ;Define high byte of Z 

;Program Initialisation 
;Set stack pointer to end of memory 
         ldi    temp,high(RAMEND) 
         out    SPH,temp          ;Load high byte of end of memory address 
         ldi    temp,low(RAMEND) 
         out    SPL,temp          ;Load low byte of end of memory address 

;Initialise Input Ports 
         ldi    temp,$00	
         out    DDRD,temp         ;Set Port A for input by sending $00 to direction register 

;Initialise output ports 
         ldi    temp,$ff	
         out    DDRB,temp         ;Set Port B for output by sending $FF to direction register 
		 out    DDRA,temp         ;Set Port A for output by sending $FF to direction register

;Generate pre-seeded number
         clr    count             ;set counter to 0
beginnin:inc    count             ;set counter to counter + 1
         rcall  smalldelay       
         MOV    r21,count         ;pre-seeded number is sent to r21 register
         in     r19,PIND          ;Get input from PORTD and set it in r19
         CPI    r19,$01           ;This checks to see if any input is on PORTD
		 BRSH   Generate
		 rjmp   beginnin          ;If there is no input yet, go back to the beginning

;Generate the puesdorandom number (n)
Generate:MOV    r22,r21           ;Make copies of the random number to 2 registers
		 MOV    r23,r21
		 ANDI   r22,$01           ;Get bit 0 in r21
		 ANDI   r23,$02           ;Get bit 1 in r21
		 LSR    r23               ;Make bit 1 move to bit 0 placeholder
         EOR    r22,r23           ;XOR the 2 bits 
		 LSR    r21               ;logic shift right r21
         LSL    r22
		 LSL    r22
		 LSL    r22
		 LSL    r22
		 LSL    r22
		 LSL    r22               ;Move the bit 6 times to the left to make it in bit 7 placeholder
		 OR     r21,r22   
         cpi    r21,$64           ;Compare the generated number with '100' in hex
		 BRSH   start             ;If the number is bigger or equal to '100', it can be used
		 rjmp   Generate          ;If the number is not bigger or equal to '100' another number is generated

;Use the random number (n) to call a delay n number of times, and then illuminate LED's
start:   rcall  delay             ;Start a delay
         dec    r21               ;decrement the random number in r21
		 cpi    r21,0             ;compare r21 to the number '0'
		 brne   start             ;If it isn't equal, it loop back to 'start'
         ldi    r20,$FF           ;If it is equal, illuminate the LED's
		 
;Main Program
         
;Get the MSB ready for the first time
main:    ldi    ZL,low(table*2)   ;Set Z pointer to start of table 
         ldi    ZH,high(table*2)         
		 clr    counttwo          ;Set the second table positioner counter to zero
         adiw   ZL,16             ;Set Z pointer to the value '0' for the MSD
		 lpm                      ;Load R0 with data pointed to by Z
		 mov    ledstwo, r0       ;Copy the value from r0 to r1 in preperation for the loop below

;Reset function  
reset:   ldi    ZL,low(table*2)   ;Set Z pointer to start of table 
         ldi    ZH,high(table*2)         
		 clr    count             ;Set table position counter to zero

;The main display loop for daul 7 segment display
lsd:
         out    PORTA,r20         ;the LED's on PORTA illuminate
         in     r19,PIND          ;Get input from PORTD and set it in r19
         CPI    r19,$02           ;This checks to see if any input (except the start switch) is on PORTD
		 BRSH   end               ;If any input is detected, it will go to end subroutine  
		 rcall  delay3            ;Call delay subroutine     
         lpm                      ;Load R0 with data pointed to by Z 
         out    PORTB,leds        ;display lsd data on port B
		 rcall  smalldelay
		 out    PORTB,ledstwo     ;display msd data on port B  
         adiw   ZL,1              ;Increment Z to point to next location in table 
         inc    count             ;Increment table position counter 
         cpi    count,16          ;and test if end of table has been reached 
         brne   lsd               ;if not the end of the table, get next data value in table 

msd:     inc    counttwo          ;Incriment a second counter for reference
         adc    r30, counttwo     ;Add second counter value to ZL to get the correct MSD value from the table
		 lpm                      ;Load R0 with data pointed to by Z
		 mov    ledstwo,r0        ;Copy The MSD to r1 for the lsd loop to reference
		 cpi    counttwo,15       ;Test if 'FF' has been reached (the max value)
		 brne   reset             ;if not true, reset Z pointer to start of table
         ldi    ZL,low(table*2)   ;if true, Set Z pointer to start of table 
         ldi    ZH,high(table*2)   
		 adiw   ZL,15             ;Then point it to the 16th value in the table
		 lpm                      ;Then copy this value to r0 in preperation for the 'FF' loop
         rjmp   end               ;loop 'FF' forever

;Delay Subroutine (1 s @ 1MHz) 
delay:   
         ldi    YH,high($2500)    ;Load high byte of Y 
         ldi    YL,low($2500)     ;Load low byte of Y 
loop:    sbiw   Y,1               ;Decrement Y 
         brne   loop              ;and continue to decrement until Y=0 
         ret                      ;Return 

;Delay Subroutine (10 ms @ 1MHz) 
delay3:   
         ldi    YH,high($03B3)    ;Load high byte of Y 
         ldi    YL,low($03B3)     ;Load low byte of Y 
loop3:   sbiw   Y,1               ;Decrement Y 
         brne   loop3             ;and continue to decrement until Y=0 
         ret                      ;Return

;Delay Subroutine (for the display only) (5 ms @ 1MHz)
smalldelay:   
         ldi    YH,high($0750)    ;Load high byte of Y 
         ldi    YL,low($0750)     ;Load low byte of Y 
loop2:   sbiw   Y,1               ;Decrement Y 
         brne   loop2             ;and continue to decrement until Y=0 
         ret  
         

;A subroutine/loop for displaying the value on r0 and r1
end:  	 lpm          
         out    PORTB,leds        ;Display whatever value is held on Least Significant Digit
		 rcall  smalldelay
		 out    PORTB,ledstwo     ;Display whatever value is held on Most Significant Digit
		 rcall  smalldelay
		 rjmp   end               ;Loop forever

table:   .DB $BF,$86,$DB,$CF,$E6,$ED,$FD,$87,$FF,$EF,$F7,$FC,$B9,$DE,$F9,$F1,$3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F,$77,$7C,$39,$5E,$79,$71

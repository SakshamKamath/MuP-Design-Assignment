#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#


	;address for ports of first 8255
	porta1 equ 00h
	portb1 equ 02h
	portc1 equ 04h
	creg1  equ 06h

	;address for ports of second 8255
	porta2 equ 08h
	portb2 equ 0ah
	portc2 equ 0ch
	creg2  equ 0eh

	;address for ports of 8253
	counter0 equ 10h
	counter1 equ 12h
	counter2 equ 14h
	creg3 equ 16h


; add your code here

jmp     start
db     5 dup(0)

;IVT entry for nmi

dw     nmi_isr          ;IP address for NMI Instruction Service Routine
dw     0000				;CS address for NMI INStruction Service Routine
db     1012 dup(0)		;Total 1024 locations reserved for populating IVT in ROM 

start:					;Branch to the end of IVT

mov ax,0200h  ;Initializing RAM with address 20000h(In proteus samllest ROM chip size is 4k therefore first 8k memory locations(00000-01FFF) is for ROM) 
mov ds,ax	  ;Initializing segments with the starting address of RAM for storing temporary data.
mov es,ax
mov ss,ax

mov sp,0FFFEH ;Initializing stack pointer to the penultimate location in stack segment

mov al,81h		;Initializing 8255B(All ports in mode 0)
out creg2,al    ;Initializing  Output Ports : PORT A2,PORT B2,PORT C2 UPPER
				;Input Port: PORT C2 LOWER

mov al,91h      ;Initializing 8255A(All ports in mode 0)
out creg1,al    ;Initializing  Output Ports :PORT B1,PORT C1 UPPER   
				;Input Ports: PORT C1 LOWER,PORT A1 UPPER


mov al,00010111b  ;Initializing Counter0 in mode 3,with BCD count. PCLK of 2.5Mhz given to 8253
out creg3,al	  

mov al,3h		;Count of 3 loaded in LSB in counter 0.	Output Clock of 833KHz given to clock of ADC0808
out counter0,al

x100:jmp x100	;infinite loop waiting for NMI interrupt to be raised


nmi_isr:      ;ISR for NMI

mov al,81h		;Reinitalizing 8255B
out creg2,al    

mov al,91h     ;Reinitializing 8255A
out creg1,al                     

mov ax,785		;The conversion factor is 785.2
mov [0020h],ax  ;Storing the conversion factor in memory
mov al,2        ;Integer and decimal part  of the conversion factor is stored in two separate contiguous blocks of memory.
mov [0022h],al   ;785 at 0020h memory loc and 2h at 0022h memory loc.

mov bx, 0023h    ;Address of next free location

;converting the analog value of first load cell into digital using adc 0808--------------------------

mov al,00000000b	;Selecting the first load cell present at channel 0.
out portb1,al

mov al,00001110b      ;Resetting soc to 0
out creg1,al

mov al,00001011b	;;Setting ale to 1
out creg1,al        

mov al,00001111b      ;Setting soc to 1
out creg1,al

mov al,00001010b	;Resetting ale to 0
out creg1,al        

mov al,00001110b     ;Resetting soc to 0
out creg1,al


EOC:    in al,portc2        ;Waiting for end of conversion.
and al,00000001b
jz EOC

mov al,00001011b	;Setting the OE for the data to be read into port A of 8255 from ADC
out creg2,al

mov al,91h			;Reading the digital equivalent of the analog value from ADC of load sensor one
out creg1,al

in al,porta1		;moving the first value to location 0023h
mov [bx],al

mov al,0001010b		;resetting OE to 0 to avoid reading garbage values from ADC
out creg2,al

;converting the analog value of second load cell into digital---------------------------------------------

mov al,91h			;Reintitalizing 8255A
out creg1,al

mov al,81h			;Reinitializing 8255B
out creg2,al

mov al,00000001b	;Selecting the second load cell present at channel 1.
out portb1,al

mov al,00001110b      ;setting soc to 0
out creg1,al

mov al,00001011b		;setting ale to 1
out creg1,al        

mov al,00001111b      ;setting soc to 1
out creg1,al

mov al,00001010b		;resetting ale to 0
out creg1,al        

mov al,00001110b     ;resetting soc to 0
out creg1,al


EOC1:    in al,portc2            ;Waiting for end of conversion to be raised
and al,00000001b
jz EOC1

mov al,00001011b		;Setting the OE for the data to be read into port A of 8255 from ADC
out creg2,al

mov al,91h				;Reading the digital equivalent of the analog value from ADC of  second load sensor 
out creg1,al

in al,porta1			;moving the second value to location 0024h
mov [bx+1],al

mov al,0001010b			;resetting OE to 0 to avoid reading garbage values from ADC
out creg2,al

;converting the analog value of third load cell into digital-----------


mov al,91h
out creg1,al

mov al,81h
out creg2,al

mov al,00000010b	;Selecting the third load cell present at channel 2.
out portb1,al

mov al,00001110b      ;setting soc to 0
out creg1,al

mov al,00001011b	 ;setting ale to 1
out creg1,al        

mov al,00001111b      ;setting soc to 1
out creg1,al

mov al,00001010b	 ;resetting ale to 0
out creg1,al        

mov al,00001110b     ;resetting soc to 0
out creg1,al

EOC2:    in al,portc2            ;Waiting for End of Conversion
and al,00000001b
jz EOC2

mov al,00001011b	;Setting the OE for the data to be read into port A of 8255 from ADC
out creg2,al

mov al,91h			;Reading the digital equivalent of the analog value from ADC of  second load sensor
out creg1,al

in al,porta1		;moving the third value to location 0025h
mov [bx+2],al

mov al,0001010b		;resetting OE to 0 to avoid reading garbage values from ADC
out creg2,al



; ;weight calculation       

; mov al,[0022h]     ;moving the decimal multiplier(2) into ax
; mov ah,0
; mov cl,[bx]      ;moving the first voltage value from memory
; mul cl           ;multiplying the two
; 				 ;result stored in ax

; mov cl,10
; div cl              ;dividing by 10 to get the quotient from the decimal multiplication
; mov [0027h],ah		;moving the remainder obtained from decimal multplication to location 0027h
; mov [0028h],al		;storing the quotient at location 0028h,0029h
; mov [0029h],0
; mov ax,[0020h]    ;loading integer multiplier
; mov ch,0
; mov cl,[bx]		  ;moving the first voltage value from memory
; mul cx
; add ax,[0028h]	  ;Adding to result of the integer multiplication the quotient obtained on dividing the decimal multiplication.
; mov cx,1000
; div cx			  ;Dividing by 1000 to get the final quotient obtained from multiplying 785.2 with the first load sensor value
; mov [0030h],ax	  ;Storing the final quotient at location 0030h
; mov ax,dx		  ;moving remainder obtained from integer multiplication to AX
; mov ch,0
; mov cl,10
; mul cx
; add al,[0027h]	;multiplying the remainder from integer multiplication with 10 and then adding it to remainder from decimal multiplication to get the final remainder.
; mov [0032h],ax 	;moving the final remainder to location 0032h


; ;calculating for the other two load cells
; inc bx

; mov al,[0022h]     ;moving the decimal multiplier into ax 
; mov ah,0
; mov cl,[bx]      ;moving the second voltage value from memory
; mul cl              ;multiplying the two
; 					;result stored in AX

; mov cl,10
; div cl              ;dividing by 10 to get the quotient from the decimal multiplication
; mov [0027h],ah		;moving the remainder obtained from decimal multplication to location 0027h
; mov [0028h],al		;storing the quotient at location 0028h,0029h
; mov [0029h],0
; mov ax,[0020h]    ;loading integer multiplier
; mov ch,0
; mov cl,[bx]	  ;moving the second voltage value from memory 
; mul cx
; add ax,[0028h]	;Adding to result of the integer multiplication the quotient obtained on dividing the decimal multiplication.
; mov cx,1000
; div cx			;Dividing by 1000 to get the final quotient obtained from multiplying 785.2 with the second load sensor value and storing result at 0034h
; mov [0034h],ax	
; mov ax,dx
; mov ch,0
; mov cl,10
; mul cx
; add al,[0027h]	;multiplying the remainder from integer multiplication with 10 and then adding it to remainder from decimal multiplication to get the final remainder.
; mov [0036h],ax   ;moving the final remainder to location 0036h


; ;calculating for the third load cell(SAME AS THE PREVIOUS TWO CASES)
; inc bx
; mov al,[0022h]     
; mov ah,0
; mov cl,[bx]      
; mul cl              
; mov cl,10
; div cl              
; mov [0027h],ah
; mov [0028h],al
; mov [0029h],0
; mov ax,[0020h]    
; mov ch,0
; mov cl,[bx]
; mul cx
; add ax,[0028h]
; mov cx,1000
; div cx
; mov [0038h],ax
; mov ax,dx
; mov ch,0
; mov cl,10
; mul cx
; add al,[0027h]
; mov [0040h],ax  ;moving the result back to memory


; ;ADDING ALL THE FINAL QUOTIENT
; mov bx,[0030h]
; add bx,[0034h]
; add bx,[0038h]   

; ;ADDING ALL THE FINAL REMAINDER
; mov ax,[0032h]
; add ax,[0036h]
; add ax,[0040h]   

; mov dx,0
; mov cx,10000
; div cx          ;dividing the remainder by 10000 to get the carry for the quotient
; add bx,ax       ;adding the quotient to the overall quotient
; ;Overall Quotient is stored in bx and
; ;overall remainder is stored in dx
; mov [0054h],dx  ;moving  overall remainder to 0054h

mov cl, 03
mov bx, 0023h
mov ax, 00
x1: add ax, bx
	inc bx
	dec cl
	JNZ x1

mov cl,3
div cl			;dividing the overall quotient by 3 to get average to get the final answer
mov bx, ax
; mov [0050h],ax	;moving the final answer to 0050h and the remainder obtained after divison of overall quotient to 0051h

; mov cx,10000
; mov al,ah
; mov ah,0
; mul cx            ;multiplying remainder of division of quotient of weight when divided by 3--- with 10000

; add ax,[0054h]	  ;adding the original remainder with the remainder obtained in the previous step due divison of quotient
; 				  ;The divison process used is a standard long divison process done manually.	

; mov cx,3
; mov dx,0
; div cx            ;Dividing the total remainder with 3

; mov dx,ax        ;now dx will have the decimal part of the weight
; mov cl,[0050h]
; mov ch,0

; mov bx,cx        ; bx will have the integer part of weight

cmp bx,99     ;comparing with 99
jb weight	  ;If bx value lesser than 99 jump to display weight.

cmp bx,99
ja buzzer	  ;If greater than 99 jump to sound the buzzer

; cmp dx,0000h  ;If the bx was equal to 99 then if the remainder part is 0 then jump to display the weight.
; je weight

buzzer:
mov al,00001001b
out creg2,al      ;sounds the buzzer
call delay_1		  ;Generates delay of 0.0045ms to allow the bbuzzer circuit to respond to the changes made at the terminal	

jmp buzzer

weight:
;dx has the decimal and bx has the integer
;extracting the digits of integer
mov al, bl
out porta1, al


;starting the display process
display:

; ;display the first digit

; mov al,81h
; out creg2,al

; mov al,[0040h]  ;moving the first digit to al
; out porta2,al     ;moving the first digit into the port
; 				;A of 8255(2) which is connected to 7447

; mov al,00000001b	;enabling the pb0 of 8255(2) which acts as the power for the seven segment display
; out portb2,al        ;value displayed on first display

; call delay_1		;delay generating 0.0045ms enough for the leds to glow.

; mov al,00000000b	;disabling the pb0 (sequential mapping of multiple led's using a single seven segment decoder)
; out portb2,al
; ;display the second digit

; mov al,[0042h]  ;moving the second digit to al
; out porta2,al     ;moving the second digit into the port
; 				;A of 8255(2) which is connected to 7447

; mov al,00000010b	;enabling the pb1 of 8255(2) which acts as the power for the seven segment display
; out portb2,al        ;value displayed on second display

; call delay_1		;delay generating 0.0045ms enough for the leds to glow.

; mov al,00000000b	;disabling the pb0 (sequential mapping of multiple led's using a single seven segment decoder)
; out portb2,al


delay_1  proc   near
;sub-routine for 2 minute delay 
;;delay calculation
; no. of cycles for loop = 18 if taken/ 5 if not taken = 499x 18 +5
;no. of cycles for ret 16
;no. of cycles for call 19
;no. of cycles for mov 4 
;no. of cycles for push 4
;no. of cycles for pop 4
;clock speed 2 MHz - 1 clock cycle 0.5us for proteus simulation
;clock soeed 5 Mhz -1 clock cycle 0.2us for real world design
;total no.cycles delay = clkcycles for call + mov cx,imm + (content of cx-1)*18+5 + ret + push+pop
;= (19 +4+ 18*499+5+16+4+4)0.2us = 0.0018ms for real world and 0.0045ms for proteus simulation 

push cx
mov cx,500
ps1:loop ps1
pop cx
ret
delay_1  endp
iret




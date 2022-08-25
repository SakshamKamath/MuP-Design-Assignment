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
	porta2 equ 10h
	portb2 equ 12h
	portc2 equ 14h
	creg2  equ 16h

	;address for ports of 8253
	counter0 equ 20h
	counter1 equ 22h
	counter2 equ 24h
	creg3 	 equ 26h


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




mov cl, 03
mov bx, 0023h
mov ax, 00
x1: mov dh, 00
	mov dl, [bx]
	add ax, dx
	inc bx
	dec cl
	JNZ x1

mov cl,3
div cl			;dividing the overall quotient by 3 to get average to get the final answer
mov bl, al
mov bh, 00


cmp bl,63h     ;comparing with 99
jbe weight	  ;If bx value lesser than 99 jump to display weight.

cmp bl,63h
ja alarm	  ;If greater than 99 jump to sound the alarm

; cmp dx,0000h  ;If the bx was equal to 99 then if the remainder part is 0 then jump to display the weight.
; je weight

alarm:
mov al,00001001b
out creg2, al      ;sounds the alarm

call delay_500		  

jmp alarm

weight:

mov al,81h
out creg2,al

mov al, bl

VALI:   MOV       BL,AL 
        MOV       AL,0
HTB:	ADD       AL,01
    	DAA
    	DEC       BL
    	JNZ       HTB

out porta2, al
push cx
mov cx, 50000
inf1:
	call delay_500
	loop inf1
pop cx



delay_500  proc   near

push cx
mov cx,500
ps1: loop ps1
pop cx
ret
delay_500  endp
iret




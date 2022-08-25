#make_bin#

; set loading address, .bin file will be loaded to this address:
#LOAD_SEGMENT=0000h#
#LOAD_OFFSET=0000h#

; set entry point:
#CS=0000h#	; same as loading segment
#IP=0000h#	; same as loading offset

; set segment registers
#DS=0000h#	; same as loading segment
#ES=0000h#	; same as loading segment

; set stack
#SS=0000h#	; same as loading segment
#SP=FFFEh#	; set to top of loading segment

; set general registers 
#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#
                          

;Jump to start of code
        JMP ST  
        NOP

;NOP is added so that we get proper intervals of 4 bytes, jmp st1 will be 3 bytes and nop will be 1 byte

        DW 114 DUP (0) ; int 01h to 39h unused  // 39h * 2 = 114d
        
;Interrupt for off alarm at vector 40h

        DW OFFA_ISR
        DW 0000H   

;Interrupt for weigh switch at vector 41h

        DW WEIGH_ISR
        DW 0000H
        
;Interrupt for eoc at vector 42h keeping cs as 0000 only
        
        DW ADC_ISR
        DW 0000H
        
; int 43h to FFh are unused
; FFH-43H+1H = BDH = 189D, 189D * 2D = 378D
        DW 378 DUP (0)   

;Defining some Labels

        ;8255 Addresses
        PORTA1 EQU 00H
        PORTB1 EQU 02H
        PORTC1 EQU 04H
        CREG1  EQU 06H

        ;8254 Addresses
        CNT3   EQU 20H             
        CREG3  EQU 26H
        
        ;8259 Addresses
        A82591 EQU 30H        
        A82592 EQU 32H        

;Main Program

ST:     CLI ; Clear interrupt flag so that no interrupts are recieved during initialization             
    
;Intialize ds, es,ss to start of RAM
        MOV       AX, 1000H
        MOV       DS,AX
        MOV       ES,AX
        MOV       SS,AX
        MOV       SI,AX ; used for storing weights measured temporarily
          
;Initializing ports          

        ;For 8255 Port A & B are inputs Port C is output

        MOV AL, 10010010B       ;8255 
        OUT CREG1,AL         
                  
        
        ;8254 - counter 0, read write lsb and msb, mode 3, binary
        MOV AL,00110110B
        OUT CREG3,AL               ;8254 Control Word
        MOV AL,05H
        OUT CNT3,AL              ;Giving count of 5 to counter0 of 8254
        MOV AL, 00H
        OUT CNT3, AL
        
        ;8259 initialization
        MOV AL, 00010011B       ;8259 ICW1
        OUT A82591,AL
        MOV AL, 01000000B       ;8259 ICW2, starting interrupt vector is 40H
        OUT A82592,AL
        MOV AL, 00000001B       ;8259 ICW4, since we dont have a slave, ICW3 is skipped
        OUT A82592,AL
        MOV AL, 11111000B       ;8259 OCW1 only IR0,IR1,IR2 are enabled 
        OUT A82592,AL
        

 ;Setting 8255 to i/o mode

        MOV AL, 10010010B       ;8255 
        OUT CREG1,AL 

        MOV AL, 00H      ; display 00 by default
        OUT PORTA1,AL   
        
        STI ;Set interrupt flag to enable recieving interrupts
       
INF1:   JMP INF1         ; Waiting for user to press the weigh switch for measurement

WEIGH_ISR:

        STI 
                
; Taking inputs from adc using 8255
; We have to take 3 values

        MOV CX,0003H
        MOV DH,00H
        MOV DI,0000H
        
; Ports need to be reconfigured

wloop:  MOV AL, DH
        OUT PORTC1, AL 
        
              
; Making ale 1 from BSR mode

        MOV AL, 00001011B
        OUT CREG1, AL  
        NOP
; Making soc 1 from BSR mode

        MOV AL, 00001001B
        OUT CREG1, AL

; Make ale 0 using bsr mode, since ALE must be active only for 1 clock cycle
        MOV AL, 00001010B
        OUT CREG1, AL  
        NOP 

; Make soc 0 using bsr mode, since SOC must be active only for 1 clock cycle
        MOV AL, 00001000B
        OUT CREG1, AL

;Wait for EOC to be received from the ADC 
        HLT

       
; Looping

        INC DH ; for taking in next analog input from load cell  
        INC DI
        LOOP wloop
        
; Average calculation

        MOV SI,0000H
        CLD
        MOV AH,00H
        MOV BX,0000H
        MOV CX,0003H
        
LLOOP:  LODSB
        ADD BX,AX
        
        LOOP LLOOP
        
        MOV AX,BX
        MOV BL,3
        DIV BL

; Compare with 99 
        
        ;IF WEIGHT<=99KG then it is valid
        CMP AL,99
        JBE VALI 

;Setting 8255 to i/o mode

        MOV AL, 10010010B       ;8255 
        OUT CREG1,AL 

        ;If weight > 99
        MOV AL, 99H      ; If weight exceeds 99kgs, we display 99
        OUT PORTA1,AL
        
; Switching ON Alarm using bsr  

        MOV AL,00001111B
        OUT CREG1,AL

        HLT ; Waiting for user to turn off alarm manually, this is part of assumption 
        
        JMP INVALI

; convert from hex to bcd
        
VALI:   MOV       BL,AL 
        MOV       AL,0
HTB:	ADD       AL,01
    	DAA
    	DEC       BL
    	JNZ       HTB
        
; Setting 8255 to input/output mode

        MOV AL, 10010010B       ;8255 
        OUT CREG1,AL

; display bcd
        
        OUT PORTA1,AL

INVALI: 
        ;ending interrupt using Non-Specific EOI
        MOV AL, 00100000b
        OUT A82591,AL

        IRET 

           
                
OFFA_ISR:
        
; Making alarm off using bsr 
       
        MOV AL,00001110B 
        OUT CREG1,AL 
          
        ;ending interrupt using Non-Specific EOI
        MOV AL, 00100000b
        OUT A82591,AL
        IRET
          

ADC_ISR:

; Making OE 1 using bsr for 8255

        MOV AL,00001101B
        OUT CREG1,AL

; Taking Inputs from Port B
; Setting 8255 to i/o mode

        MOV AL, 10010010B       ;8255 
        OUT CREG1,AL

        IN AL, PORTB1
        MOV [DI], AL     

        MOV AL,00001100B; Making OE low again
        OUT CREG1,AL

        ;ending interrupt using Non-Specific EOI
        MOV AL, 00100000b
        OUT A82591,AL

        IRET
        
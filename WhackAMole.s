;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;ENSE352 Final Project - Nolan Flegel , Nov 24, 2020
;;;;
;;;;WhackAMole.s Source code for ENSE352 Whack-A-Mole program on the ARM Cortex M3
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;M3 microcontroller.
	PRESERVE8
	THUMB


INITIAL_MSP EQU 0x20001000    ; Initial Main Stack Pointer Value
	
;;Port A	
GPIOA_CRL EQU 0x40010800
GPIOA_ODR EQU 0x4001080C  ;0x0C
GPIOA_IDR EQU 0x40010808  ;0x8h
GPIOA_CRH EQU 0x40010804  ;0x04

;;Port B
GPIOB_CRL EQU 0x40010C00
GPIOB_ODR EQU 0x40010C0C
GPIOB_IDR EQU 0x40010C08
GPIOB_CRH EQU 0x40011004

	
;;Clock Registers
RCC_APB2ENR EQU 0x40021018
		

;;Delay Timer
WAIT_PLAYER_BLINK 		EQU 0x70000
GAME_START_WAIT 		EQU 0x400000
LVL_ONE_BLINK			EQU 300000
LVL_TWO_BLINK			EQU 260000
LVL_THREE_BLINK			EQU 220000
		
;;Number of blinks
NUM_BLINKS EQU 0xF


; Vector Table Mapped to Address 0 at Reset, Linker requires __Vectors to be exported
	AREA RESET, DATA, READONLY
	EXPORT 	__Vectors


__Vectors 	DCD INITIAL_MSP ; stack pointer value when stack is empty
			DCD Reset_Handler ; reset vector

;My program, Linker requires Reset_Handler and it must be exported
	AREA MYCODE, CODE, READONLY
	ENTRY

	EXPORT Reset_Handler
		
Reset_Handler  PROC ;We only have one line of actual application code


	BL ClockInIt
	BL Set_INPUT_OUTPUT				;;Use Case 1 - System Startup

	BL WAITFORPLAYER		;;Use Case 2 - Wait for Player
	
GameLoop					
	BL POLL_BUTTONS
	BL OUTPUT_TO_LED
	B GameLoop
	
	ENDP

	ALIGN
ClockInIt PROC
	
	LDR R6, =RCC_APB2ENR
	MOV R0, #0xC
	STR R0, [R6]
	
	BX LR
	ENDP

	ALIGN
Set_INPUT_OUTPUT PROC
	
	;;;;;;;;;;;;;;
	;;Enable Port A
	;;;;;;;;;;;;;;;
	
	LDR R6, =GPIOA_CRL
	LDR R0, [R6]
	
	LDR R2,	=0x00030033
	ORR R0, R0, R2
	
	LDR R2, =0xFFF3FF33
	AND R0, R0, R2
	
	STR R0, [R6]
	
	;;;;;;;;;;;;;;
	;;Enable Port B
	;;;;;;;;;;;;;;;;;
	
	LDR R6, =GPIOB_CRL
	LDR R0, [R6]
	LDR R2,	=0x00000003
	ORR R0, R0, R2
	
	LDR R2, =0xFFFFFFF3
	AND R0, R0, R2
	
	STR R0, [R6]
	
	BX LR
	ENDP
	
	ALIGN
	
WAITFORPLAYER PROC
	
	LDR R6, =GPIOA_ODR   ;;Port A Address
	LDR R7, =GPIOB_ODR   ;;Port B Address
	LDR R3, =0x0 			;;for turning off LED in opposite port
	
	LDR R0, =0x1
	STR R0, [R6]
	STR R3, [R7]
waitForButton
	;;;;;;;;;;;;;;;;
	;;Toggle LEDs;;
	;;;;;;;;;;;;;;;;
	LDR R5, =WAIT_PLAYER_BLINK   ;;Delay value	
delay_LED1   ;delay LED On
	CMP R5, #0
	SUBNE R5, R5, #1
	BNE delay_LED1

	LDR R1, [R6]
	LDR R2, [R7]
	
	CMP R1, #1
	MOVEQ R3, #2
	MOVEQ R4, #0
	BEQ toggleLED

	CMP R1, #2
	MOVEQ R3, #16
	MOVEQ R4, #0
	BEQ toggleLED
	
	CMP R1, #16
	MOVEQ R3, #0
	MOVEQ R4, #1
	BEQ toggleLED
	
	CMP R2, #1
	MOVEQ R3, #1
	MOVEQ R4, #0
	BEQ toggleLED
	
toggleLED
	STR R3, [R6]
	STR R4, [R7]

;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;Polling Buttons;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;registers: 
;;		r0 - GPIOA address
;;		r1 - GPIOB address
;;		r2 - read codes from GPIO
;;		r3 - store codes from Port A
;;		r4 - store codes from Port B
;;		r5 - store result of AND
;;		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
switchLoop
	LDR R0, =GPIOB_IDR
	LDR R2, [R0]
	LDR R1, =0xFFFF
	EOR R2, R1
	LDR R1, =0x350   ;bit mask for 0011 0101 0000
	AND R2, R1 ;R1 contains switch input for SW0
	
	CMP R2, #0
	BGT startButtonPressed
	
	b waitForButton

startButtonPressed
	LDR R6, =GPIOA_ODR   ;;Port A Address
	LDR R7, =GPIOB_ODR   ;;Port B Address
	LDR R1, =0x0
	STR R1, [R6]
	STR R1, [R7]
	
	LDR R5, =GAME_START_WAIT
delay_GameStart   ;delay LED On
	CMP R5, #0
	SUBNE R5, R5, #1
	BNE delay_GameStart
	
	
	LDR R1, =0x13
	LDR R2, =0x1
	STR R1, [R6]
	STR R2, [R7]
	BX LR
	ENDP
	ALIGN
		
POLL_BUTTONS PROC
	LDR R3, =0x0
	LDR R6, =GPIOB_IDR
	LDR R0, [R6]
	LDR R1, =0x150  ;0001 0101 0000
	AND R0, R1 ;R1 contains switch input for SW0

;	Polling BTN1	
	MOV R4, R0
	LSR R4, #4
	AND R4, #0x1
	ORR R3, R4       ;Store BTN 1-3 LED values into R3	
	
;	Polling BTN2
	MOV R4, R0
	LSR R4, #5
	AND R4, #0x2
	ORR R3, R4
	
; 	Polling BTN3
	MOV R4, R0
	LSR R4, #4
	AND R4, #0x10
	ORR R3, R4
	
	PUSH {R3} 		;Store LED 1-3 codes on Stack

;	Polling BTN1
	LDR R6, =GPIOB_IDR
	LDR R0, [R6]
	LDR R1, =0x200  ;0010 0000 0000   position of BTN4 code
	
	AND R0, R1
	MOV R3, #0 ;Clear Previous Codes
	LSR R0, #9 ;Move code to correct position for LED4
	ORR R3, R0
	BX LR
	ENDP
	ALIGN
OUTPUT_TO_LED PROC
	;; LED 4 is on top of stack
	LDR R6, =GPIOB_ODR
	LDR R0, [R6]
	AND R3, R0
	STR R3, [R6]
	
	;; LED 1-3 stored on stack
	POP {R3}
	LDR R6, =GPIOA_ODR
	LDR R0, [R6]
	
	AND R3, R0
	STR R3, [R6]
	
	BX LR
	ENDP
;FINISH PROC
;	LDR R0, =0x1
;	LDR R6, =GPIOA_ODR
;	STR R0, [R6]
;	
;	LDR R6, =GPIOB_ODR
;	LDR R0, =0x1
;	STR R0, [R6]
;	BX LR
;	ENDP
		
	END
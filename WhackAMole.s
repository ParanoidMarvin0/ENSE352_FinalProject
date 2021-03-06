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
WAIT_PLAYER_BLINK 		EQU 0x50000
GAME_START_WAIT 		EQU 0x100000
;;LVL_ONE_BLINK			EQU 0x70005
;;LVL_TWO_BLINK			EQU 0x60000
;;LVL_THREE_BLINK			EQU 0x50000
REACT_TIMER				EQU 0x70005
GAME_END_WAIT			EQU 0x100000
SCORE_DISPLAY			EQU 0x5000000

;;;;Random number generator
RND_A					EQU 1664525
RND_C					EQU 1013904223
;;;   A * X + C
		
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
GameLoop
	BL WAITFORPLAYER		;;Use Case 2 - Wait for Player
	BL GAME_START
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
	LDR R8, =GPIOB_IDR		;;Button Port
	LDR R3, =0x0 			;;for turning off LED in opposite port
	
	LDR R0, =0x1
	STR R0, [R6]
	STR R3, [R7]
	LDR R10, =0x0   ;; SEED RND counter
waitForButton
	;;;;;;;;;;;;;;;;
	;;Toggle LEDs;;
	;;;;;;;;;;;;;;;;
	
	LDR R5, =WAIT_PLAYER_BLINK   ;;Delay value	
delay_LED1   ;delay LED On
	CMP R5, #0
	SUBNE R5, R5, #1
	ADD R10, #1
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
	PUSH {R6, R7}
	LDR R1, =0x0
	STR R1, [R6]
	STR R1, [R7]
	
	LDR R5, =GAME_START_WAIT
delay_GameStart   ;delay LED On
	CMP R5, #0
	SUBNE R5, R5, #1
	BNE delay_GameStart
	

	BX LR
	ENDP
	ALIGN

GAME_START PROC
	
;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;Pick RND LED;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;		R0 Score Counter
;;;		R1 round count
;;;		R2 ReactTimer
;;;		R3, R4 Store LED codes
;;;		
;;;		R5 BTN input mask
;;;
;;;		R6,R7,R8  store port addresses
;;;
;;;
;;; 	R9 - used for modulus function
;;;		R10 - Previous Seed
;;;		R11, R12 - store A and C for RND
;;;		
;;;
;;; const RND_A and RND_C
;;;
;;;  A * X + C
;;; 
;;;;;;;;;;;;;;;;;;;;;;;
	POP {R6, R7}
	PUSH {R10}
	MOV R9, #0
	MOV R0, #0
	MOV R1, #15
	LDR R2, =REACT_TIMER
pickLED
	LDR R5, =GAME_START_WAIT
pauseBetween
	CMP R5, #0
	SUBNE R5, R5, #1
	BNE pauseBetween
	
	POP {R10}
	LDR R11, =RND_A
	LDR R12, =RND_C
	MUL R10, R10, R11
	ADD R10, R10, R12
	PUSH {R10}
	LSR R10, #28
	AND R10, #0x00000003

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Perform Modulus 4 to get random LED
;;;
;;;  copy R10 to R9 so we can save original Value
;;;  store #4 in register
;;;  udiv to store quotient
;;;  multiply orginal by mod
;;;	 subtract difference for remainder
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	MOV R9, R10
	MOV R11, #4                    	      
	UDIV R9, R9, R11  
	MUL R9, R11  
	SUBS R9, R10, R9 

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	Turn on Random LED
;;  Use value in R10
;;	Value ranges from 0-3
;;	corresponds to LED number
;;
;;	store btn num in R5	
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	MOV R3, #0
	MOV R4, #0
	STR R3, [R6]
	STR R4, [R7]
	
;;;; LED 1
;;;;;;;;;;;;;;;;;
	CMP R9, #0
	MOVEQ R3, #1
	MOVEQ R5, #0x10
	BEQ rnd_LED_ON

;;;; LED 2
;;;;;;;;;;;;;;;;;;
	CMP R9, #1
	MOVEQ R3, #2
	MOVEQ R5, #0x40
	BEQ rnd_LED_ON

;;;;   LED 3
;;;;;;;;;;;;;;;;;;;;
	CMP R9, #2
	MOVEQ R3, #16
	MOVEQ R5, #0x100
	BEQ rnd_LED_ON
	
;;;    LED 4
;;;;;;;;;;;;;;;;;;;;;;;
	CMP R9, #3
	MOVEQ R4, #1
	MOVEQ R5, #0x200
	BEQ rnd_LED_ON

rnd_LED_ON
	STR R3, [R6]
	STR R4, [R7]
	MOV R9, R2
wait_for_whack
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;
	;;;   Check if button was pressed
	;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
	LDR R12, [R8]
	LDR R11, =0xFFFF
	EOR R12, R11
	MOV R11, R5   ;bit mask button pressed
	AND R12, R11 
	
	CMP R12, #0
	BGT moleHit
	
	CMP R9, #0
	SUBNE R9, R9, #1
	BNE wait_for_whack
	b newLED
	
moleHit
	ADD R0, #1
	SUB R2, #0x5000
newLED
	MOV R3, #0x0
	MOV R4, #0x0
	STR R3, [R6]
	STR R4, [R7]
	SUB R1, #1
	CMP R1, #0
	BEQ endGame
	b pickLED
	
endGame
	MOV R3, #0x13
	MOV R4, #0x1
	STR R3, [R6]
	STR R4, [R7]
	LDR R5, =GAME_END_WAIT
pauseEndGame
	CMP R5, #0
	SUBNE R5, R5, #1
	BNE pauseEndGame
	
	LDR R5, =SCORE_DISPLAY
	CMP R0, #0
	MOVEQ R3, #0
	MOVEQ R4, #0
	
	CMP R0, #1
	MOVEQ R3, #0x0
	MOVEQ R4, #0x1
	
	CMP R0, #2
	MOVEQ R3, #0x10
	MOVEQ R4, #0x0
	
	CMP R0, #3
	MOVEQ R3, #0x10
	MOVEQ R4, #0x1
	
	CMP R0, #4
	MOVEQ R3, #0x2
	MOVEQ R4, #0x0
	
	CMP R0, #5
	MOVEQ R3, #0x2
	MOVEQ R4, #0x1
	
	CMP R0, #6
	MOVEQ R3, #0x3
	MOVEQ R4, #0x0
	
	CMP R0, #7
	MOVEQ R3, #0x3
	MOVEQ R4, #0x1
	
	CMP R0, #8
	MOVEQ R3, #0x10
	MOVEQ R4, #0x0
	
	CMP R0, #9
	MOVEQ R3, #0x10
	MOVEQ R4, #0x1
	
	CMP R0, #10
	MOVEQ R3, #0x11
	MOVEQ R4, #0x0
	
	CMP R0, #11
	MOVEQ R3, #0x11
	MOVEQ R4, #0x1
	
	CMP R0, #12
	MOVEQ R3, #0x2
	MOVEQ R4, #0x0
	
	CMP R0, #13
	MOVEQ R3, #0x2
	MOVEQ R4, #0x1
	
	CMP R0, #14
	MOVEQ R3, #0x13
	MOVEQ R4, #0x0
	
	CMP R0, #15
	MOVEQ R3, #0x13
	MOVEQ R4, #0x1
	
	STR R3, [R6]
	STR R4, [R7]
	
showScore
	CMP R5, #0
	SUBNE R5, R5, #1
	BNE showScore
	BX LR
	ENDP
	ALIGN
		
	END
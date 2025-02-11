;
; PreLaboratorio02.asm

; Universidad del Valle de Guatemala
; Departamento de Ingenieria Mecatronica, Electronica y Biomedica
; IE2023 Semestre 1 2025 
;
; Created: 8/02/2025
; Author : Angie Recinos
; Carnet : 23294

// --------------------- Encabezado ------------------------------- //

.include "M328PDEF.inc"			// Incluye definiciones del ATMega328
.cseg							// Codigo en la flash
.org 0x0000						// Donde inicia el programa
.def COUNTER = R20				// Counter de desbordamientos

// Configurar el SP en 0x03FF (al final de la SRAM) 
LDI		R16, LOW(RAMEND)		// Carga los bits bajos (0x0FF)
OUT		SPL, R16				// Configura spl = 0xFF -> r16
LDI		R16, HIGH(RAMEND)		// Carga los bits altos (0x03)
OUT		SPH, R16				// Configura sph = 0x03) -> r16

TABLITA: .DB 0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0X5F, 0x70, 0x7F, 0X7B, 0x76, 0x1F, 0x4E, 0x3D, 0x4F, 0x47

// Configurar el microcontrolador
SETUP:
	// Utilizando oscilador a 1 MHz
	// Se configura prescaler principal
	LDI		R16, (1 << CLKPCE)		// Se selecciona el bit del CLK (bit 7) 
	STS		CLKPR, R16				// Se habilitar cambio para el prescaler
	LDI		R16, 0b00000100			// En la tabla se ubica qué bits deben encender
	STS		CLKPR, R16				// Se configura prescaler a 16 para 1MHz
	
	// Inicializar timer0
	// CALL	INIT_TMR0

	//	Configurar pines de entrada y salida (DDRx, PORTx, PINx) 
	//	Configurar PORTB como entrada con pull-up habilitado 
	//	PORTB como entrada con pull-up habilitado (por pb en sugerido)
	LDI		R16, 0x00
	OUT		DDRB, R16			// Setear puerto B como entrada (0 -> recibe)
	LDI		R16, 0xFF	
	OUT		PORTB, R16			// Habilitar pull-ups en puerto B

	//	PORTD como salida inicialmente encendido
	LDI		R16, 0xFF
	OUT		DDRD, R16			// Setear puerto D como salida (1 -> no recibe)
	OUT		DDRC, R16
	OUT		PORTD, R16			// Leds para display
	OUT		PORTC, R16			// Leds de contador normal - POST
	 
	LDI		R17, 0xFF			// Variable para guardar el estado de botones
	LDI		R19, 0x00			// Variable para contador de leds en Display7
	LDI		COUNTER, 0x00
	CALL	INIT_DIS7

// Loop infinito
MAIN:
	
	// Revisión de botones
	IN		R16, PINB			// Guardando el estado de PORTB (pb) en R16 0xFF
	CP		R17, R16			// Comparamos estado viejo con estado nuevo
	BREQ	MAIN				// Si no hay cambio, salta a MAIN
	CALL	DELAY				// Si hay cambio, salta a call y hace delay
	IN		R16, PINB			// Por si ocurre rebote vuelve a leer y a comparar
	CP		R17, R16
	BREQ	MAIN				// Si después del delay sigue igual, no hace nada
	
	// Volver a leer PINB
	MOV		R17, R16			// Si fueran diferentes, habría que updatearlos
	
	// Verificar si el boton1 esta presionado
	SBIS	PINB, 0				// Salta si el bit 0 del PINB es 1 (no apachado)
	CALL	INCREMENTAR1		// Si el bit 0 es 0 el boton esta apachado y (+)
	SBIS	PINB, 1				// Salta si el bit 1 del PINB es 1 (boton no apachado)
	CALL	DECREMENTAR1		// Si el bit 1 es 0 el boton esta apachado y (-)
	RJMP	MAIN				// Al revisar todos los bits 
	
	/*
	IN		R18, TIFR0			// Leer registro de interrupcion de TIMER 0
	SBRS	R18, TOV0			// Salta si el bit 0 esta "set" (TOV0 bit en TIFR0 de desborde)
	RJMP	MAIN				// Reiniciar loop
	SBI		TIFR0, TOV0			// Apaga bandera de overflow (TOV0) 
	LDI		R18, 158			// Como se usa TCNT0, se indica inicio
	OUT		TCNT0, R18			// Volver a cargar valor inicial en TCNT0
	//INC		COUNTER
	//CPI		COUNTER, 10			
	//BRNE	MAIN
	//CLR		COUNTER
	CALL	SUMAR
	RJMP	MAIN
	*/

// Sub-rutina (no de interrupcion)
// Delay
DELAY:
	LDI		R18, 0xFF
SUB_DELAY1:
	DEC		R18
	CPI		R18, 0
	BRNE	SUB_DELAY1
	LDI		R18, 0xFF
SUB_DELAY2:
	DEC		R18
	CPI		R18, 0
	BRNE	SUB_DELAY2
	LDI		R18, 0xFF
SUB_DELAY3:
	DEC		R18
	CPI		R18, 0
	BRNE	SUB_DELAY3
	RET	

// Se inicia el display
INIT_DIS7:
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	LPM		R16, Z
	OUT		PORTD, R16
	RET

INCREMENTAR1: 	
	ADIW	Z, 1				// Compara el valor del contador 
	INC		COUNTER				// Se aumenta un contador
	CPI		COUNTER, 0x10		// Se compara para ver si ya sumó 
    BREQ	RESET_COUNTER1		// Si al comparar no es igual, salta a mostrarlo
	LPM		R16, Z
	OUT		PORTD, R16
	RET							// Vuelve al ciclo main a repetir

RESET_COUNTER1:
    LDI		COUNTER, 0x00		// Resetea el contador a 0
	CALL	INIT_DIS7			// Reasigna la tabla al 0
	RET

DECREMENTAR1: 	
	SBIW	Z, 1				// Compara el valor del contador 
	CPI		COUNTER, 0xFF		// Se compara para ver si ya sumó 
    BREQ	RESET_COUNTER2		// Si al comparar no es igual, salta a mostrarlo
	DEC		COUNTER				// Se aumenta un contador
	LPM		R16, Z
	OUT		PORTD, R16
	RET							// Vuelve al ciclo main a repetir

RESET_COUNTER2:
    LDI		COUNTER, 0x0F		// Resetea el contador a 15
	CALL	INIT_DIS7			// Reinicia el valor de la tabla
	ADIW	Z, 15				// Carga el último valor de la tabla 
	RET
// Sub-rutina (no de interrupcion)
/*INIT_TMR0:
	LDI		R16, (1<<CS02) | (1<<CS00)
	OUT		TCCR0B, R16					// Setear prescaler del TIMER 0 a 1024
	LDI		R16, 158					// Indicar desde donde inicia
	OUT		TCNT0, R16					// Cargar valor inicial en TCNT0
	RET*/


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
.def COUNTER = R20				// Counter de desbordamientos en display
.def COUNTER2 = R21				// Counter de desbordamientos 4 bits

// Configurar el SP en 0x03FF (al final de la SRAM) 
LDI		R16, LOW(RAMEND)		// Carga los bits bajos (0x0FF)
OUT		SPL, R16				// Configura spl = 0xFF -> r16
LDI		R16, HIGH(RAMEND)		// Carga los bits altos (0x03)
OUT		SPH, R16				// Configura sph = 0x03) -> r16

// Display 7 Seg
TABLITA: .DB 0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0X5F, 0x70, 0x7F, 0X7B, 0x77, 0x1F, 0x4E, 0x3D, 0x4F, 0x47

// Configurar el microcontrolador
SETUP:
	// Utilizando oscilador a 1 MHz
	// Se configura prescaler principal
	LDI		R16, (1 << CLKPCE)		// Se selecciona el bit del CLK (bit 7) 
	STS		CLKPR, R16				// Se habilitar cambio para el prescaler
	LDI		R16, 0b00000100			// En la tabla se ubica qué bits deben encender
	STS		CLKPR, R16				// Se configura prescaler a 16 para 1MHz
	
	// Inicializar timer0
	CALL	INIT_TMR0

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
	LDI		R19, 0x00			// Variable para contador de leds
	LDI		COUNTER, 0x00		// Variable para contador de leds en Display7
	LDI		COUNTER2, 0x00		// Counter de desbordes
	
	// Inicializar el display
	CALL	INIT_DIS7

// Loop infinito
MAIN:
	// Revisión de botones
	IN		R16, PINB			// Guardando el estado de PORTB (pb) en R16 0xFF
	CP		R17, R16			// Comparamos estado viejo con estado nuevo
	BREQ	MAIN				// Si no hay cambio, salta a MAIN
	BREQ	C_4BITS
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
	
	// Sumar el contador binario de 4 bits
	IN		R18, TIFR0			// Leer registro de interrupcion de TIMER 0
	SBRC	R18, TOV0			// Salta si el bit 0 NO esta "set" (TOV0 bit en TIFR0 de desborde)
	CALL	TIMER				// Si es 1, hubo desborde, tiene que reiniciar 
	CP		R19, COUNTER		// Compara si el contador de 4 bits es igual al counter del display
	BREQ	TOGGLE_LED
	RJMP	MAIN				// Si es 0 el bit, irá a repetir


TOGGLE_LED: 
	CBI		PORTC, 0
	CBI		PORTC, 1
	CBI		PORTC, 2
	CBI		PORTC, 3
	MOV		PORTC, R23			// Guardo únicamente el estado del bit para el led
	LDI		R19, 0x00			// Reseteo el contador
	ADD		R23, R19			// En R23 está solo el estado de PC4, lo sumo con R19 que está en 0	
	
	SBRC	R23, 4				// Revisar si led está en 0
	CBI		R23, 4				// Si no, lo pone en 0
	SBI		R23, 4
	OUT		PORTC, R23
    RJMP	MAIN
    
// ----------------------------- Sub-rutina de contador 4 bits	----------------------------------------
TIMER:
	SBI		TIFR0, TOV0			// Apaga bandera de overflow (TOV0) 
	LDI		R18, 158			// Como se usa TCNT0, se indica inicio
	OUT		TCNT0, R18			// Volver a cargar valor inicial en TCNT0
	INC		COUNTER2			// Como la idea es contar que 10 veces se desborde 100 ms = 1 segundo
	CPI		COUNTER2, 10		// 0.1 * 10 = 1 
	BREQ	CLR_COUNTER2		// Revisa si ya pasó 1 segundo, si sí, hace la suma 
	RET							// Si no, vuelve al ciclo
	
CLR_COUNTER2:	
	CLR		COUNTER2			// Resetea el counter a 0
	CALL	SUMAR				// Llama a que sume el contador 1 bit
	RET 

SUMAR: 	
	CPI		R19, 0x0F					// Compara el valor del contador 
    BREQ	RESET_COUNTER2				// Si al comparar no es igual, salta a mostrarlo
	INC		R19							// Incrementa el valor
	OUT		PORTC, R19
	RET									// Vuelve al ciclo main a repetir

RESET_COUNTER2:
    LDI		R19, 0x00					// Resetea el contador a 0
	OUT		PORTC, R19
	RET

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

// ------------------------------- Se inicia el display ---------------------------------
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
	DEC		COUNTER				// Se aumenta un contador
	CPI		COUNTER, 0xFF		// Se compara para ver si ya resto max 
    BREQ	RESET_COUNTER1		// Si al comparar no es igual, salta a mostrarlo
	LPM		R16, Z
	OUT		PORTD, R16
	RET							// Vuelve al ciclo main a repetir


// Sub-rutina (no de interrupcion)
// Inicializar el timer
INIT_TMR0:
	LDI		R16, (1<<CS02) | (1<<CS00)
	OUT		TCCR0B, R16					// Setear prescaler del TIMER 0 a 1024
	LDI		R16, 158					// Indicar desde donde inicia
	OUT		TCNT0, R16					// Cargar valor inicial en TCNT0
	RET

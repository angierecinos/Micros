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

// Configurar el SP en 0x03FF (al final de la SRAM) 
LDI		R16, LOW(RAMEND)		// Carga los bits bajos (0x0FF)
OUT		SPL, R16				// Configura spl = 0xFF -> r16
LDI		R16, HIGH(RAMEND)		// Carga los bits altos (0x03)
OUT		SPH, R16				// Configura sph = 0x03) -> r16

// Configurar el microcontrolador
SETUP:
	// Utilizando oscilador a 1 MHz
	// Se configura prescaler principal
	LDI		R16, (1 << CLKPCE)		// Se selecciona el bit del CLK (bit 7) 
	STS		CLKPR, R16				// Se habilitar cambio para el prescaler
	LDI		R16, 0b00000100			// En la tabla se ubica qué bits deben encender
	STS		CLKPR, R16				// Se configura prescaler a 16 para 1MHz
	
	// Inicializar timer0
	CALL INIT_TMR0

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
	LDI		R16, 0b0001			// Primer bit encendido (prueba)
	OUT		PORTD, R16			// Encender primer bit del puerto D y C
	 
	LDI		R17, 0xFF			// Variable para guardar el estado de botones
	LDI		R19, 0x00			// Variable para contador

/****************************************/
// Loop Infinito
MAIN:
	IN R16, TIFR0 // Leer registro de interrupcion de TIMER 0
	SBRS R16, TOV0 // Salta si el bit 0 est "set" (TOV0 bit)?
	RJMP MAIN_LOOP // Reiniciar loop
	SBI TIFR0, TOV0 // Limpiar bandera de "overflow"
	LDI R16, 100
	OUT TCNT0, R16 // Volver a cargar valor inicial en TCNT0
	INC COUNTER
	CPI COUNTER, 50 // R20 = 50 after 500ms (since TCNT0 is set to 10 ms)
	BRNE MAIN_LOOP
	CLR COUNTER
	SBI PINB, PB5
	SBI PINB, PB0
	RJMP MAIN_LOOP

// Sub-rutina (no de interrupcion)
INIT_TMR0:
	LDI R16, (1<<CS01) | (1<<CS00)
	OUT TCCR0B, R16					// Setear prescaler del TIMER 0 a 64
	LDI R16, 100
	OUT TCNT0, R16					// Cargar valor inicial en TCNT0
	RET
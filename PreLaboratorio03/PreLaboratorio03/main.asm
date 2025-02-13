;
; PreLaboratorio03.asm
;
; 

; Universidad del Valle de Guatemala
; Departamento de Ingenieria Mecatronica, Electronica y Biomedica
; IE2023 Semestre 1 2025 
;
; Created: 8/02/2025
; Author : Angie Recinos
; Carnet : 23294
; 

// --------------------- Encabezado ------------------------------- //

.include "M328PDEF.inc"				// Incluye definiciones del ATMega328
.cseg								// Codigo en la flash

.org	0x0000						// Donde inicia el programa
	JMP	START					// Tiene que saltar para no ejecutar otros

.org	OVF0addr
	JMP	ISR_TMR0

START: 
	// Configurar el SP en 0x03FF (al final de la SRAM) 
	LDI		R16, LOW(RAMEND)		// Carga los bits bajos (0x0FF)
	OUT		SPL, R16				// Configura spl = 0xFF -> r16
	LDI		R16, HIGH(RAMEND)		// Carga los bits altos (0x03)
	OUT		SPH, R16				// Configura sph = 0x03) -> r16

SETUP:
	// Deshabilitar interrupciones globales
	CLI	
	
	// Utilizando oscilador a 1 MHz
	// Se configura prescaler principal
	LDI		R16, (1 << CLKPCE)		// Se selecciona el bit del CLK (bit 7) 
	STS		CLKPR, R16				// Se habilitar cambio para el prescaler
	LDI		R16, 0b00000100			// En la tabla se ubica qué bits deben encender
	STS		CLKPR, R16				// Se configura prescaler a 16 para 1MHz

	LDI		R16, (1<<CS01) | (1<<CS00)
	OUT		TCCR0B, R16					// Setear prescaler del TIMER 0 a 64
	LDI		R16, 100					// Indicar desde donde inicia
	OUT		TCNT0, R16					// Cargar valor inicial en TCNT0
	RET
	// Habilitar interrupciones con la máscara 
	LDI		R16, (1<<TOIE0)				// Habilitar interrupciones del bit 0 para el 
	STS		TIMSK0, R16

	//	Configurar PORTB como entrada con pull-up habilitado 
	//	PORTB como entrada con pull-up habilitado
	LDI		R16,	0x00
	OUT		DDRB,	R16					// Setear puerto B como entrada (0 -> recibe)
	LDI		R16,	0xFF	
	OUT		PORTB,	R16					// Habilitar pull-ups en puerto B

	//	PORTD y PORTC como salida inicialmente encendido
	LDI		R16,	0xFF			// Setear puerto C como salida (1 -> no recibe
	OUT		DDRC,	R16
	LDI		R16,	0b0000			// Apagados	
	OUT		PORTC,	R16				// Apagar bit del puerto C

	SEI
// Rutina de interrupción
TMR0_ISR: 
	PUSH	R16				// Para no perder el SREG
	IN		R16, SREG		// Copia el valor de SREG 
	PUSH	R16				// Lo saca

	LDI		R16, 100		// Cuando se reinicia hay que explicar donde empieza
	OUT		TCNT0, R16
	SBI		TIFR0, TOV0		// Limpiar la bandera
	INC		R20

	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI
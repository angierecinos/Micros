;
; PreLaboratorio01.asm
;
; Universidad del Valle de Guatemala
; Departamento de Ingenieria Mecatronica, Electronica y Biomedica
; IE2023 Semestre 1 2025 
;
; Created: 2/02/2025
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
	//	Configurar pines de entrada y salida (DDRx, PORTx, PINx) 
	//	Configurar PORTD como entrada con pull-up habilitado 
	//	PORTD como entrada con pull-up habilitado
	LDI		R16, 0x00	
	OUT		DDRD, R16			// Setear puerto D como entrada (0 -> recibe)
	LDI		R16, 0xFF	
	OUT		PORTD, R16			// Habilitar pull-ups en puerto D

	//	PORTB como salida inicialmente encendido
	LDI		R16, 0xFF
	OUT		DDRB, R16			// Setear puerto B como salida (1 -> no recibe)
	LDI		R16, 0b0001			// Primer bit encendido
	OUT		PORTB, R16			// Encender primer bit del puerto B
	 
	LDI		R17, 0xFF			// Variable para guardar el estado de botones
	LDI		R19, 0x00			// Variable para contador

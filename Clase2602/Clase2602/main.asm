;
; Clase2602.asm
;
; Created: 26/02/2025 16:11:23
; Author : Usuario
;


.include "M328PDEF.inc"					// Incluye definiciones del ATMega328

/*TIMER1
.equ	T1VALUE = 0xE17B

/*LDI		R16, LOW(T1VALUE) // 7B
STS		TCNT1L, R16
LDI		R16, HIGH(T1VALUE)  // E1
STS		TCNT1L, R16*/

.cseg									// Codigo en la flash

.org	0x0000							// Donde inicia el programa
	JMP	START							// Tiene que saltar para no ejecutar otros

.org	PCI0addr						// Dirección donde está el vector interrupción
	JMP	ISR_PCINT0

.org	OVF0addr						// Dirección del vector
	JMP	ISR_TIMER0_OVF

START: 
	// Configurar el SP en 0x03FF (al final de la SRAM) 
	LDI		R16, LOW(RAMEND)			// Carga los bits bajos (0x0FF)
	OUT		SPL, R16					// Configura spl = 0xFF -> r16
	LDI		R16, HIGH(RAMEND)			// Carga los bits altos (0x03)
	OUT		SPH, R16					// Configura sph = 0x03) -> r16

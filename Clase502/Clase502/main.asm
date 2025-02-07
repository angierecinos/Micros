;
; Clase502.asm
;
; Created: 5/02/2025 16:09:25
; Author : Usuario
;


; Encabezado
.include	"M328P.inc"
.cseg
.org		0x0000

; Universidad del Valle de Guatemala
; Departamento de Ingenieria Mecatronica, Electronica y Biomedica
; IE2023 Semestre 1 2025 
;
; Created: 5/02/2025
; Author : Angie Recinos
; Carnet : 23294
; 

// --------------------- Encabezado ------------------------------- //

.include "M328PDEF.inc"			// Incluye definiciones del ATMega328
.cseg							// Codigo en la flash
.org 0x0000						// Donde inicia el programa
.def COUNTER = R20

// Configurar el SP en 0x03FF (al final de la SRAM) 
LDI		R16, LOW(RAMEND)		// Carga los bits bajos (0x0FF)
OUT		SPL, R16				// Configura spl = 0xFF -> r16
LDI		R16, HIGH(RAMEND)		// Carga los bits altos (0x03)
OUT		SPH, R16				// Configura sph = 0x03) -> r16

//TABLA7SEG: .DB		0x7E, 0x30, 0x6D, 0x79 // (db es un byte)



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
	LDI		R19, 0x00			// Variable para contador1
	LDI		R20, 0X00			// Variable para contador2

// Loop infinito
MAIN:
	IN		R16, PIND			// Guardando el estado de PORTD (pb) en R16 0xFF
	CP		R17, R16			// Comparamos estado viejo con estado nuevo
	BREQ	MAIN				// Si no hay cambio, salta a MAIN
	CALL	DELAY				// Si hay cambio, salta a call y hace delay
	IN		R16, PIND			// Por si ocurre rebote vuelve a leer y a comparar
	CP		R17, R16
	BREQ	MAIN				// Si después del delay sigue igual, no hace nada
	
	// Volver a leer PIND
	MOV		R17, R16			// Si fueran diferentes, habría que updatearlos
	
	// Verificar si el boton1 esta presionado
	SBIS	R16, 0				// Salta si el bit 0 del PIND es 1 (no apachado)
	CALL	INCREMENTAR1		// Si el bit 0 es 0 el boton esta apachado y (+)
	SBIS	R16, 1				// Salta si el bit 1 del PIND es 1 (boton no apachado)
	CALL	DECREMENTAR1		// Si el bit 1 es 0 el boton esta apachado y (-)
	SBIS	R16, 2				// Salta si el bit 2 del PIND es 1
	CALL	INCREMENTAR2		// Si el bit 2 es 0 el boton esta apachado y (+)
	SBIS	R16, 3				// Salta si el bit 3 del PIND es 1
	CALL	DECREMENTAR2		// Si el bit 3 es 0 el boton esta apachado y (-)
	RJMP	MAIN				// Al revisar todos los bits 

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

// Sub-rutina para revisar contadores
INCREMENTAR1: 
	CPI		R19, 0x0F			// Compara el valor del contador 
    BREQ	RESET_COUNTER1		// Si al comparar no es igual, salta la instruccion
	INC		R19					// R19 aumentará si aun no llega a 15
	OUT		PORTB, R19				
	RET							// Vuelve al ciclo main a repetir

DECREMENTAR1: 
	CPI		R19, 0x00			// Si el contador llega a 0, reiniciar el contador
	BREQ	RET					// Si es igual a 0 no hace nada y vuelve a main
	DEC		R19					// R19 decrementará
	OUT		PORTB, R19
	RET

RESET_COUNTER1:
    LDI		R19, 0x00			// Resetea el contador a 0
	OUT		PORTB, R19			// Lo muestra en el portB
	RET

// Sub-rutina para revisar contador2
REVISAR_CONT2
	// Verificar si el boton3 esta presionado
	SBRS	R16, 4				// Salta si el bit 2 del PIND es 1 (no apachado)
	RJMP	INCREMENTAR2

	// Verificar si el boton4 esta presionado
	SBRS	R16, 5				// Salta si el bit 3 del PIND es 1 (no apachado)
	RJMP	DECREMENTAR2


INCREMENTAR2: 
	CPI		R20, 0x0F			// Compara el valor del contador 
    BREQ	RESET_COUNTER		// Si el contador está en 15, reinicia el contador
	INC		R20					// R19 aumentará si aun no llega a 15
	SBI		PINB, 0				// Toggle de PB0 -la salida-(cambio de estado pb1)
	OUT		PORTB, R20
	RJMP	MAIN				// Vuelve al ciclo main a repetir

// Para decrementar contador
DECREMENTAR2: 
	CPI		R20, 0x00			// Si el contador llega a 0, reiniciar el contador
	BREQ	MAIN				// Si es igual a 0 no hace nada y vuelve a main
	DEC		R20					// R19 decrementará
	SBI		PINB, 1				// Toggle de PB1 (cambio de estado pb 2)
	OUT		PORTB, R20
	RJMP	MAIN

RESET_COUNTER2:
    LDI		R20, 0x00			// Resetea el contador a 0
    RJMP	MAIN				// Regresa al main
	RET
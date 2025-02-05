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
	//	Configurar PORTB como entrada con pull-up habilitado 
	//	PORTB y PORTC como entrada con pull-up habilitado
	LDI		R16, 0x00
	LDI		R23, 0x00	
	OUT		DDRB, R16			// Setear puerto B como entrada (0 -> recibe)
	OUT		DDRC, R23
	LDI		R16, 0xFF	
	LDI		R23, 0XFF
	OUT		PORTB, R16			// Habilitar pull-ups en puerto B
	OUT		PORTC, R23

	//	PORTD como salida inicialmente encendido
	LDI		R16, 0xFF
	OUT		DDRD, R16			// Setear puerto B como salida (1 -> no recibe)
	LDI		R16, 0b0001			// Primer bit encendido
	OUT		PORTD, R16			// Encender primer bit del puerto D
	 
	LDI		R17, 0xFF			// Variable para guardar el estado de botones
	LDI		R19, 0x00			// Variable para contador1
	LDI		R20, 0X00			// Variable para contador2

// Loop infinito
MAIN:
	IN		R16, PINB			// Guardando el estado de PORTB (pb) en R16 0xFF
	CP		R17, R16			// Comparamos estado viejo con estado nuevo
	BREQ	MAIN				// Si no hay cambio, salta a MAIN
	CALL	DELAY				// Si hay cambio, salta a call y hace delay
	IN		R16, PINB			// Por si ocurre rebote vuelve a leer y a comparar
	CP		R17, R16
	BREQ	MAIN				// Si despu�s del delay sigue igual, no hace nada
	
	// Volver a leer PINB
	MOV		R17, R16			// Si fueran diferentes, habr�a que updatearlos
	
	// Verificar si el boton1 esta presionado
	SBIS	PINB, 0				// Salta si el bit 0 del PINB es 1 (no apachado)
	CALL	INCREMENTAR1		// Si el bit 0 es 0 el boton esta apachado y (+)
	SBIS	PINB, 1				// Salta si el bit 1 del PINB es 1 (boton no apachado)
	CALL	DECREMENTAR1		// Si el bit 1 es 0 el boton esta apachado y (-)
	SBIS	PINB, 2				// Salta si el bit 2 del PINB es 1
	CALL	INCREMENTAR2		// Si el bit 2 es 0 el boton esta apachado y (+)
	SBIS	PINB, 3				// Salta si el bit 3 del PINB es 1
	CALL	DECREMENTAR2		// Si el bit 3 es 0 el boton esta apachado y (-)
	SBIS	PINB, 4				// Salta si el bit 4 del PINB es 1
	CALL	SUMA				// Se hace la suma
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
    BREQ	RESET_COUNTER1		// Si al comparar no es igual, salta a mostrarlo
	INC		R19					// Incrementa el valor
	OUT		PORTD, R19			// Muestra en el portD el valor
	RET							// Vuelve al ciclo main a repetir

DECREMENTAR1: 
	CPI		R19, 0x00			// Si el contador llega a 0, reiniciar el contador
	BREQ	RESET_COUNTER1		// Si es igual a 0 no hace nada y vuelve a main
	DEC		R19					// R19 decrementar�
	OUT		PORTD, R19			// Muestra en el PORTD el cambio de contador
	RET							// Regresa a main si ya decremento

RESET_COUNTER1:
    LDI		R19, 0x00			// Resetea el contador a 0
	OUT		PORTD, R19			// Muestra el 0 y regresa
	RET

INCREMENTAR2: 
	CPI		R20, 0x0F			// Compara el valor del contador 
    BREQ	RESET_COUNTER2		// Si el contador est� en 15, reinicia el contador
	INC		R20					// R20 aumentar� si aun no llega a 15
	MOV		R21, R20			// Se copia el resultado 
	LSL		R21 				// Corre los bits 1 a la izquierda sin el carry
	LSL		R21 				// Corre los bits 1 a la izquierda sin el carry
	LSL		R21 				// Corre los bits 1 a la izquierda sin el carry
	LSL		R21 				// Corre los bits 1 a la izquierda sin el carry
	ADD		R21, R19			// Suma los bits para mostrarlos
	OUT		PORTD, R21
	RET							// Vuelve al ciclo main a repetir

DECREMENTAR2: 
	CPI		R20, 0x00			// Compara el valor del contador 
    BREQ	RESET_COUNTER2		// Si el contador est� en 15, reinicia el contador
	DEC		R20					// R20 aumentar� si aun no llega a 15
	MOV		R21, R20			// Se copia el resultado 
	ROL		R21 				// Corre los bits 1 a la izquierda sin el carry
	ROL		R21 				// Corre los bits 1 a la izquierda sin el carry
	ROL		R21 				// Corre los bits 1 a la izquierda sin el carry
	ROL		R21 				// Corre los bits 1 a la izquierda sin el carry
	ADD		R21, R19			// Suma los bits para mostrarlos
	OUT		PORTD, R21
	RET							// Vuelve al ciclo main a repetir

RESET_COUNTER2:
    LDI		R20, 0x00			// Resetea el contador a 0
	MOV		R21, R20
	ROL		R21 				// Corre los bits 1 a la izquierda sin el carry
	ROL		R21 				// Corre los bits 1 a la izquierda sin el carry
	ROL		R21 				// Corre los bits 1 a la izquierda sin el carry
	ROL		R21 				// Corre los bits 1 a la izquierda sin el carry
	ADD		R21, R19			// Suma los bits para mostrarlos
	OUT		PORTD, R21			// Lo muestra en el portB
	RET

SUMA:
	MOV		R22, R19			// Se copia el contador 1 para no alterarlo
	ADD		R22, R20			// Se suman ambos contadores y se guardan
	OUT		PORTC, R22			// Se muestra el resultado en el portC
	RET							// Si tiene overflow se muestra en led
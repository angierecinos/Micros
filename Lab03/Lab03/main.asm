;
; Lab03.asm
;
; Universidad del Valle de Guatemala
; Departamento de Ingenieria Mecatronica, Electronica y Biomedica
; IE2023 Semestre 1 2025 
;
; Created: 8/02/2025
; Author : Angie Recinos
; Carnet : 23294
; Descripci�n: El c�digo realiza un contador binario de 4 bits con interrupciones

// -------------------------------- Encabezado ------------------------------- //

.include "M328PDEF.inc"				// Incluye definiciones del ATMega328
.cseg								// Codigo en la flash

.org	0x0000						// Donde inicia el programa
	JMP	START						// Tiene que saltar para no ejecutar otros

.org	PCI0addr					// Direcci�n donde est� el vector interrupci�n
	JMP	ISR_PCINT0

.org	OVF0addr					// Direcci�n del vector
	JMP	ISR_TIMER0_OVF

START: 
	// Configurar el SP en 0x03FF (al final de la SRAM) 
	LDI		R16, LOW(RAMEND)		// Carga los bits bajos (0x0FF)
	OUT		SPL, R16				// Configura spl = 0xFF -> r16
	LDI		R16, HIGH(RAMEND)		// Carga los bits altos (0x03)
	OUT		SPH, R16				// Configura sph = 0x03) -> r16


SETUP:
	// Display 7 Seg
	TABLITA: .DB 0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0X5F, 0x70, 0x7F, 0X7B

	// Deshabilitar interrupciones globales
	CLI	
	
	// Utilizando oscilador a 1MHz
	// Se configura prescaler principal
	LDI		R16, (1 << CLKPCE)		// Se selecciona el bit del CLK (bit 7) 
	STS		CLKPR, R16				// Se habilitar cambio para el prescaler
	LDI		R16, 0b00000100			// En la tabla se ubica qu� bits deben encender
	STS		CLKPR, R16				// Se configura prescaler a 64 para 1MHz

	LDI		R16, (1<<CS01) | (1<<CS00)
	OUT		TCCR0B, R16					// Setear prescaler del TIMER 0 a 64
	LDI		R16, 100					// Indicar desde donde inicia -> desborde cada 10 ms
	OUT		TCNT0, R16					// Cargar valor inicial en TCNT0
	
	LDI		R16, (1 << TOIE0)	// Habilita interrupci�n por desborde del TIMER0
	STS		TIMSK0, R16		

													

	//	PORTD como salida inicialmente encendido
	LDI		R16, 0xFF
	OUT		DDRD, R16			// Setear puerto D como salida (1 -> no recibe)
	OUT		DDRC, R16
	
	LDI		R16, 0x00			
	LDI		R23, 0x00
	OUT		PORTD, R16
	OUT		PORTC, R23

// Configuraci�n de interrupci�n para botones
	LDI		R16, (1 << PCINT0) | (1 << PCINT1)		// Se seleccionan los bits de la m�scara (2)
	STS		PCMSK0, R16								// Bits habilitados (PB0 y PB1) por m�scara		

	LDI		R16, (1 << PCIE0)						// Habilita las interrupciones Pin-Change en PORTB
	STS		PCICR, R16								// "Avisa" al registros PCICR que se habilitan en PORTB
													// Da "permiso" "habilita"
	
	CALL	INIT_DIS7
	
	LDI		R17, 0x00								// Registro para contador
	SEI												// Se habilitan interrupciones globales

// Loop vac�o
LOOP:  
	 RJMP	LOOP

// Rutina de interrupci�n para revisar PB
ISR_PCINT0: 
	CLI							// Se desactivan las interrupciones para evitar cambios repentinos en PB
	IN		R18, PINB			// Se lee el pin
	LDI		R16, 217			// Se indica donde debe iniciar el TIMER
	OUT		TCNT0, R16			// Se activa justo al leer PINB
	LDI		R16, (1 << TOIE0)	// Habilita interrupci�n por desborde del TIMER0
	STS		TIMSK0, R16			
	LDI		R16, 0				// Deshabilitar interrupci�n de pines
	STS		PCICR, R16			// Se evita entrar en otra interrupci�n
	INC		R25					// R24 ser� un contador de la cant. de veces que lee el pin
	CPI		R25, 50				// Si ocurre 50 veces, ya pas� el tiempo para antirrebote
	BRNE	ISR_PCINT0
	SEI
	RETI

// Rutina de interrupci�n para aumentar display
ISR_TIMER0_OVF: 
	SBI		TIFR0, TOV0
	LDI		R16, 100			// Se indica donde debe iniciar el TIMER
	OUT		TCNT0, R16				
	INC		R24					// R24 ser� un contador de la cant. de veces que lee el pin
	CPI		R24, 100			// Si ocurre 100 veces, ya pas� el tiempo para modificar contador
	BREQ	CONTADOR
	RETI

// Rutina de no interrupci�n 
CONTADOR: 
	//CLI
	PUSH	R16					// Para no perder el SREG lo mete a la pila
	IN		R16, SREG			// Copia el valor de SREG 
	PUSH	R16					// Lo saca

	ADIW	Z, 1				// Compara el valor del contador 
	INC		R17					// Se aumenta un contador
	CPI		R17, 0x0A			// Se compara para ver si ya sum� 
    BREQ	RESET_COUNTER1		// Si al comparar no es igual, salta a mostrarlo
	LPM		R16, Z		
	OUT		PORTD, R16
	LDI		R24, 0x00
	
	POP		R16					// Vuelve a meterle el valor anterior del SREG
	OUT		SREG, R16
	POP		R16
	RETI							// Vuelve al ciclo main a repetir

RESET_COUNTER1:
    LDI		R17, 0x00			// Resetea el contador a 0
	CALL	INIT_DIS7			// Reasigna la tabla al 0
	RETI

// ------------------------------- Se inicia el display ---------------------------------
INIT_DIS7:
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	LPM		R16, Z
	OUT		PORTD, R16
	RET

/*INCREMENTAR1: 	
	ADIW	Z, 1				// Compara el valor del contador 
	INC		COUNTER				// Se aumenta un contador
	CPI		COUNTER, 0x10		// Se compara para ver si ya sum� 
    BREQ	RESET_COUNTER2		// Si al comparar no es igual, salta a mostrarlo
	LPM		R16, Z
	OUT		PORTD, R16
	RET							// Vuelve al ciclo main a repetir

RESET_COUNTER2:
    LDI		COUNTER, 0x00		// Resetea el contador a 0
	CALL	INIT_DIS7			// Reasigna la tabla al 0
	RET*/
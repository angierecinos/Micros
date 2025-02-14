;
; PreLab03.asm
;
; Universidad del Valle de Guatemala
; Departamento de Ingenieria Mecatronica, Electronica y Biomedica
; IE2023 Semestre 1 2025 
;
; Created: 8/02/2025
; Author : Angie Recinos
; Carnet : 23294
; Descripción: El código realiza un contador binario de 4 bits con interrupciones

// -------------------------------- Encabezado ------------------------------- //

.include "M328PDEF.inc"				// Incluye definiciones del ATMega328
.cseg								// Codigo en la flash

.org	0x0000						// Donde inicia el programa
	JMP	START						// Tiene que saltar para no ejecutar otros

.org	PCI0addr					// Dirección donde está el vector interrupción
	JMP	ISR_PCINT0

.org	OVF0addr					// Dirección del vector
	JMP	ISR_TIMER0_OVF

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
	LDI		R16, 0b00000110			// En la tabla se ubica qué bits deben encender
	STS		CLKPR, R16				// Se configura prescaler a 64 para 250KHz

	LDI		R16, (1<<CS01) | (1<<CS00)
	OUT		TCCR0B, R16					// Setear prescaler del TIMER 0 a 64
	LDI		R16, 217					// Indicar desde donde inicia -> desborde cada 10 ms
	OUT		TCNT0, R16					// Cargar valor inicial en TCNT0

	//	Configurar PORTB como entrada con pull-up habilitado 
	//	PORTB como entrada con pull-up habilitado
	LDI		R16,	0x00
	OUT		DDRB,	R16					// Setear puerto B como entrada (0 -> recibe)
	LDI		R16,	0xFF	
	OUT		PORTB,	R16					// Habilitar pull-ups en puerto B

	//	 PORTC como salida 
	LDI		R16,	0xFF				// Setear puerto C como salida (1 -> no recibe)
	OUT		DDRC,	R16
	LDI		R16,	0b0000				// Apagados	
	OUT		PORTC,	R16					// Apagar bit del puerto C
	
	// Configuración de interrupción para botones
	LDI		R16, (1 << PCINT0) | (1 << PCINT1)		// Se seleccionan los bits de la máscara (2)
	STS		PCMSK0, R16								// Bits habilitados (PB0 y PB1) por máscara		

	LDI		R16, (1 << PCIE0)						// Habilita las interrupciones Pin-Change en PORTB
	STS		PCICR, R16								// "Avisa" al registros PCICR que se habilitan en PORTB
													// Da "permiso" "habilita"
	SEI												// Se habilitan interrupciones globales

	LDI		R17, 0x00								// Registro para contador

// Loop vacío
LOOP:  
	 RJMP	LOOP

// Rutina de interrupción para revisar PB
ISR_PCINT0: 
	CLI							// Se desactivan las interrupciones para evitar cambios repentinos en PB
	IN		R18, PINB			// Se lee el pin
	LDI		R16, 217			// Se indica donde debe iniciar el TIMER
	OUT		TCNT0, R16			// Se activa justo al leer PINB
	LDI		R16, (1 << TOIE0)	// Habilita interrupción por desborde del TIMER0
	STS		TIMSK0, R16			
	LDI		R16, 0				// Deshabilitar interrupción de pines
	STS		PCICR, R16			// Se evita entrar en otra interrupción
	INC		R24					// R24 será un contador de la cant. de veces que lee el pin
	CPI		R24, 50				// Si ocurre 50 veces, ya pasó el tiempo para antirrebote
	BRNE	ISR_PCINT0
	SEI
	RETI

// Rutina de interrupción 
ISR_TIMER0_OVF: 
	CLI
	PUSH	R16					// Para no perder el SREG lo mete a la pila
	IN		R16, SREG			// Copia el valor de SREG 
	PUSH	R16					// Lo saca
	
	LDI		R16, 0				// Desactiva interrupción de timer
	STS		TIMSK0, R16			// Evito que el timer genere otras interrupciones

	// PB0 -> Incrementa | PB1 -> Decrementa	
	IN		R18, PINB			// Revisa el estado de PINB
	
	SBRS	R18, PB0			// Si el bit 0 está set salta (por pull-up 1 -> suelto) 
	CALL	INCREMENTAR1		// Si no está set incrementa (0 -> apachado) 

	SBRS	R18, PB1			// Revisa si el bit 1 está set (1 -> no apachado) 
	CALL	DECREMENTAR1		// Si no está set decrementa (0 -> apachado)  

	LDI		R16, (1 << PCIE0)	// Habilitar interrupciones PIN-CHANGE
	STS		PCICR, R16			// Ya que se revisó la interrupción se revisan otras

	POP		R16					// Vuelve a meterle el valor anterior del SREG
	OUT		SREG, R16
	POP		R16
	SEI
	RETI

// Sub-rutinas (no de interrupción) 
INCREMENTAR1: 	
	CPI		R17, 0x0F			// Compara el valor del contador 
    BREQ	RESET_COUNTER1		// Si al comparar no es igual, salta a mostrarlo
	INC		R17					// Incrementa el valor
	OUT		PORTC, R17			// Muestra en el portD el valor
	RET							// Vuelve al ciclo main a repetir

DECREMENTAR1: 
	CPI		R17, 0x00			// Si el contador llega a 0, reiniciar el contador
	BREQ	RESET_COUNTER1		// Si es igual a 0 no hace nada y vuelve a main
	DEC		R17					// R19 decrementará
	OUT		PORTC, R17			// Muestra en el PORTD el cambio de contador
	RET							// Regresa a main si ya decremento

RESET_COUNTER1:
    LDI		R17, 0x00			// Resetea el contador a 0
	OUT		PORTC, R17
	RET
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
; Descripción: El código realiza un contador binario de 4 bits con interrupciones

// --------------------------------------------------- Encabezado -------------------------------------------------- //

.include "M328PDEF.inc"					// Incluye definiciones del ATMega328
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

// Display 7 Seg
	TABLITA: .DB 0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0X5F, 0x70, 0x7F, 0X7B

SETUP:

	// Deshabilitar interrupciones globales
	CLI	
	
	// Utilizando oscilador a 1MHz
	// Se configura prescaler principal
	LDI		R16, (1 << CLKPCE)			// Se selecciona el bit del CLK (bit 7) 
	STS		CLKPR, R16					// Se habilitar cambio para el prescaler
	LDI		R16, 0b00000100				// En la tabla se ubica qué bits deben encender
	STS		CLKPR, R16					// Se configura prescaler a 64 para 1MHz

	LDI		R16, (1<<CS01) | (1<<CS00)
	OUT		TCCR0B, R16					// Setear prescaler del TIMER 0 a 64
	LDI		R16, 100					// Indicar desde donde inicia -> desborde cada 10 ms
	OUT		TCNT0, R16					// Cargar valor inicial en TCNT0
	
	LDI		R16, (1 << TOIE0)			// Habilita interrupción por desborde del TIMER0
	STS		TIMSK0, R16										

	//	PORTD como salida inicialmente encendido
	LDI		R16, 0xFF
	OUT		DDRD, R16					// Setear puerto D como salida (1 -> no recibe)
	OUT		DDRC, R16
	
	LDI		R16, 0x00			
	LDI		R23, 0x00
	OUT		PORTD, R16
	OUT		PORTC, R23
	LDI		R16, (1 << PB0) | (1 << PB1)
	OUT		PORTB, R16					// Habilitar pull-ups en PB0 y PB1

	// Configurar PB2 y PB3 como salidas para controlar los transistores
    LDI    R16, (1 << PB2) | (1 << PB3)
    OUT    DDRB, R16

	// ------------------------------------Configuración de interrupción para botones----------------------------------
	LDI		R16, (1 << PCINT0) | (1 << PCINT1)		// Se seleccionan los bits de la máscara (2)
	STS		PCMSK0, R16								// Bits habilitados (PB0 y PB1) por máscara		

	LDI		R16, (1 << PCIE0)						// Habilita las interrupciones Pin-Change en PORTB
	STS		PCICR, R16								// "Avisa" al registros PCICR que se habilitan en PORTB
													// Da "permiso" "habilita"

	//---------------------------------------------INICIALIZAR DISPLAY-------------------------------------------------
	CALL	INIT_DIS7
	
	//---------------------------------------------------REGISTROS-----------------------------------------------------
		  //R16 - MULTIUSOS GENERAL 
	LDI		R17, 0x00								// Registro para contador de 4 bits
		  //R18 - COMPARA BOTONES
	LDI		R19, 0x00								// Registro para contador de unidades display
	LDI		R20, 0xFF								// Guarda el estado de botones
	LDI		R21, 0x00								// Registro para cargar el valor de Z
	LDI		R22, 0x00								// Registro para contador de decenas
		  //R23 - USO GENERAL
	LDI		R24, 0x00								// Registro para contador de desbordamientos
	LDI		R25, 0x00								// Registro para estados de transistores
	SEI												// Se habilitan interrupciones globales

// Loop principal
LOOP:  
	SBRS	R24, 0
	RJMP	DISPLAY1
	
	// Mostrar decenas
	CBI		PORTB, PB2
	LDI		R21, 0x00
	OUT		PORTD, R21
	SBI		PORTB, PB3
	OUT		PORTD, R26
	RJMP	LOOP

DISPLAY1:
	CBI		PORTB, PB3
	LDI		R21, 0x00
	OUT		PORTD, R21
	SBI		PORTB, PB2
	OUT		PORTD, R25
	RJMP	LOOP

//------------------------------------------ Rutina de interrupción del timer -----------------------------------------
ISR_TIMER0_OVF: 	
	SBI		TIFR0, TOV0
	LDI		R16, 100			// Se indica donde debe iniciar el TIMER
	OUT		TCNT0, R16				
	INC		R24					// R24 será un contador de la cant. de veces que lee el pin
	CPI		R24, 100			// Si ocurre 100 veces, ya pasó el tiempo para modificar contador
	BREQ	CONTADOR
	RETI

//----------------------------------------------------INCREMENTA DISPLAY------------------------------------------------
// Rutina de no interrupción 
CONTADOR: 
	LDI		R24, 0x00				// Resetear contador de desbordes de timer
	ADIW	Z, 1					// Mueve el puntero
	RJMP	YA_ACTUALICE			// Va a revisar
	RETI

YA_ACTUALICE:
	INC		R19						// Se aumenta el contador de display uni
	CPI		R19, 0x0A				// Se compara para ver si ya sumó a 10
	BREQ	YA_DEC					// Si no está en 10, sigue aumentando
	
	LPM		R25, Z
	RETI							// Regresa al inicio

YA_DEC:
	// Si ya estába en 9, resetea el contador de unidades y aumenta decenas
	LDI		R19, 0x00				// Resetear unidades
	//CALL	INIT_DIS7				// Llamar set de display
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	LPM		R22, Z
	ADD		ZL, R22
			
	LPM		R26, Z					// Cargar el valor de 0 en el display
	INC		R22						// Aumentar el valor del contador de decenas
	CPI		R22, 0x06				// Comparamos si ya es 6
	BREQ	TOPAMOS					// Si no es 6, sigue para actualizar
	RJMP	DECENAS					// Va a actualizar decenas

DECENAS: 
	/*CALL	INIT_DIS7
	ADIW	Z, 1					// Mueve el puntero
	LPM		R26, Z					// Carga el valor de z en el registro
	RET¨*/
	LDI  ZL, LOW(TABLITA<<1)
	LDI  ZH, HIGH(TABLITA<<1)
	ADD  ZL, R22 	// Posiciona Z en la tabla según las decenas
	LPM  R26, Z 	// Carga el valor de la tabla en R26 (decenas)
	RETI

TOPAMOS:
	LDI		R19, 0x00
	LDI		R22, 0x00
	CALL	INIT_DIS7
	RETI		

// -------------------------------------------- Se inicia el display ---------------------------------------------------
INIT_DIS7:
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	LPM		R21, Z
	OUT		PORTD, R21
	RET

// --------------------------------------Rutina de interrupción para revisar PB ----------------------------------------
ISR_PCINT0: 
	//IN		R16, TIFR0			// Se hace un antirrebote con el timer
	//SBRS	R16, TOV0
	//RJMP	ISR_PCINT0				// Si no ha desbordado, sigue en el ciclo
	//SBI		TIFR0, TOV0			// Si la bandera de overflow esta encendida, la apaga
	//LDI		R16, 217			// Se indica donde debe iniciar el TIMER
	//OUT		TCNT0, R16	

	IN		R18, PINB				// Se lee el pin
	CP		R18, R20				// Se compara estado de los botones
	BREQ	NO_CAMBIO				// Si siguen siendo iguales, es porque no hubo cambio
	MOV		R20, R18				// Copia el estado de botones

	// PB0 -> Incrementa | PB1 -> Decrementa		
	SBRS	R18, PB0				// Si el bit 0 está set salta (por pull-up 1 -> suelto) 
	RJMP	INCREMENTAR1			// Si no está set incrementa (0 -> apachado) 

	SBRS	R18, PB1				// Revisa si el bit 1 está set (1 -> no apachado) 
	RJMP	DECREMENTAR1			// Si no está set decrementa (0 -> apachado)  

	LDI		R16, (1 << PCIE0)		// Habilitar interrupciones PIN-CHANGE
	STS		PCICR, R16				// Ya que se revisó la interrupción se revisan otras

	RETI

NO_CAMBIO: 
	RETI							// Lo regresa al loop

//-----------------------------------------------INC Y DEC PUSH-BUTTONS-------------------------------------------------
// Sub-rutinas (no de interrupción) 
INCREMENTAR1: 	
	CPI		R17, 0x0F				// Compara el valor del contador 
    BREQ	RESET_COUNTER1			// Si al comparar no es igual, salta a mostrarlo
	INC		R17						// Incrementa el valor
	OUT		PORTC, R17				// Muestra en el portD el valor
	RETI							// Vuelve al ciclo main a repetir

DECREMENTAR1: 
	DEC		R17						// R19 decrementará
	CPI		R17, 0xFF				// Si el contador llega a 0, reiniciar el contador
	BREQ	RESET_COUNTER2			// Si es igual a 0 no hace nada y vuelve a main
	OUT		PORTC, R17				// Muestra en el PORTD el cambio de contador
	RETI							// Regresa a main si ya decremento

RESET_COUNTER1:
    LDI		R17, 0x00				// Resetea el contador a 0
	OUT		PORTC, R17
	RETI
	
RESET_COUNTER2:
    LDI		R17, 0x0F				// Resetea el contador a 15
	OUT		PORTC, R17
	RETI
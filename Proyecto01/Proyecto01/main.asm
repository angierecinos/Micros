;
; Proyecto01.asm
;
;
; Universidad del Valle de Guatemala
; Departamento de Ingenieria Mecatronica, Electronica y Biomedica
; IE2023 Semestre 1 2025 
;
; Created: 24/02/2025
; Author : Angie Recinos
; Carnet : 23294
; Descripci�n: El c�digo ser� un reloj con diferentes opciones

// -------------------------------- Encabezado ------------------------------- //

.include "M328PDEF.inc"				// Incluye definiciones del ATMega328
.equ	VALOR_T1 = 0x1B1E

.cseg								// Codigo en la flash

.org	0x0000							// Donde inicia el programa
	JMP	START							// Tiene que saltar para no ejecutar otros

.org	PCI0addr						// Direcci�n donde est� el vector interrupci�n PORTB
	JMP	ISR_PCINT0

.org	OVF0addr						// Direcci�n del vector para timer0
	JMP	TIMER0_OVF

.org	OVF1addr						// Direcci�n del vector para timer1
	JMP	TIMER1_OVERFLOW
	
START: 
	// Configurar el SP en 0x03FF (al final de la SRAM) 
	LDI		R16, LOW(RAMEND)			// Carga los bits bajos (0x0FF)
	OUT		SPL, R16					// Configura spl = 0xFF -> r16
	LDI		R16, HIGH(RAMEND)			// Carga los bits altos (0x03)
	OUT		SPH, R16					// Configura sph = 0x03) -> r16

	// Display 7 Seg
	.org 0x100  ; Coloca la tabla en una direcci�n m�s alta de memoria
	TABLITA: .DB 0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0X5F, 0x70, 0x7F, 0X7B

SETUP:

	// Deshabilitar interrupciones globales
	CLI	
// ------------------------------------Configuraci�n del TIMER0----------------------------------
	// Utilizando oscilador a 1MHz - Permitir� parpadeo cada 500 ms
	// Se configura prescaler principal
	LDI		R16, (1 << CLKPCE)			// Se selecciona el bit del CLK (bit 7) 
	STS		CLKPR, R16					// Se habilitar cambio para el prescaler
	LDI		R16, 0b00000100				// En la tabla se ubica qu� bits deben encender
	STS		CLKPR, R16					// Se configura prescaler a 64 para 1MHz
	
	CALL	INIT_TMR0

	LDI		R16, (1 << TOIE0)			// Habilita interrupci�n por desborde del TIMER0
	STS		TIMSK0, R16										
	
// ------------------------------------Configuraci�n del TIMER1----------------------------------
	// Utilizando oscilador a 1MHz - Permitir� usar el contador cada minuto
	// Se configura prescaler principal
	/*LDI		R16, (1 << CLKPCE)			// Se selecciona el bit del CLK (bit 7) 
	STS		CLKPR, R16					// Se habilitar cambio para el prescaler
	LDI		R16, 0b00000100				// En la tabla se ubica qu� bits deben encender
	STS		CLKPR, R16					// Se configura prescaler a 64 para 1MHz*/

	CALL	INIT_TMR1

// Habilitar interrupci�n por desborde del TIMER1
	LDI		R16, (1 << TOIE1)			// Habilita interrupci�n por desborde del TIMER1
	STS		TIMSK1, R16					

// ------------------------------------Configuraci�n de los puertos----------------------------------
	//	PORTD, PORTC y PB5 como salida 
	LDI		R16, 0xFF
	OUT		DDRD, R16					// Setear puerto D como salida (1 -> no recibe)
	OUT		DDRC, R16					// Setear puerto C como salida 
	SBI		DDRB, PB5					// Para el led que hace toggle
	
	LDI		R16, 0x00			
	LDI		R23, 0x00
	OUT		PORTD, R16
	OUT		PORTC, R23
	CBI		PORTB, PB5					// Se le carga valor de 0 a PB5
	
	// Configurar PB como entradas con pull ups habilitados
	LDI		R16, (1 << PB0) | (1 << PB1) | (1 << PB2) | (1 << PB3) | (1 << PB4)
	OUT		PORTB, R16					// Habilitar pull-ups 

	// Configurar PC0, PC1, PC2 y PC3 como salidas para controlar los transistores
    LDI		R16, (1 << PC0) | (1 << PC1) | (1 << PC2) | (1 << PC3)
    OUT		DDRC, R16

// ------------------------------------Configuraci�n de interrupci�n para botones----------------------------------
	LDI		R16, (1 << PCINT0) | (1 << PCINT1) | (1 << PCINT2) | (1 << PCINT3)	| (1 << PCINT4)	// Se seleccionan los bits de la m�scara (5)
	STS		PCMSK0, R16								// Bits habilitados (PB0, PB1, PB2, PB3 y PB4) por m�scara		

	LDI		R16, (1 << PCIE0)						// Habilita las interrupciones Pin-Change en PORTB
	STS		PCICR, R16								// "Avisa" al registros PCICR que se habilitan en PORTB
													// Da "permiso" "habilita"

//---------------------------------------------INICIALIZAR DISPLAY-------------------------------------------------
	CALL	INIT_DIS7
	
//---------------------------------------------------REGISTROS-----------------------------------------------------
		  //R16 - MULTIUSOS GENERAL 
	LDI		R17, 0x00								// Registro para contador de 4 bits
		  //R18 - COMPARA BOTONES
	LDI		R19, 0x00								// Registro para contador de unidades (minutos) display
	LDI		R20, 0xFF								// Guarda el estado de botones
	LDI		R21, 0x00								// Registro para cargar el valor de Z
	LDI		R22, 0x00								// Registro para contador de decenas (minutos)
	LDI		R23, 0x00								// Registro para contador de unidades (horas)
	LDI		R24, 0x00								// Registro para contador de desbordamientos
	LDI		R25, 0x00								// Registro para contador de decenas (horas)
	LDI		R26, 0x00								// Registro para contador de unidades (d�as)
	LDI		R27, 0x00								// Registro para contador de decenas (d�as)
	SEI												// Se habilitan interrupciones globales

// Loop principal
LOOP:  
	SBRS	R24, 0
	RJMP	DISPLAY1
	
	// Mostrar decenas
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	ADD		ZL, R22					// Guardar el valor de Z en el contador de decnas
	LPM		R21, Z					// Se guarda el valor de Z		
	OUT		PORTD, R21
	CBI		PORTB, PB2				// Se deshabilita transistor para PB2
	SBI		PORTB, PB3				// Habilitar transistor 2
	RJMP	LOOP

DISPLAY1:
	// Mostrar unidades
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	ADD		ZL, R19					// Cargar el valor de Z en el contador de unidades

	LPM		R21, Z					// Guardar el valor de Z
	OUT		PORTD, R21
	CBI		PORTB, PB3				// Se deshabilita transistor para PB3
	SBI		PORTB, PB2				// Habilitar transistor 1
	RJMP	LOOP

//------------------------------------------ Rutina de interrupci�n del timer0 -----------------------------------------
TIMER0_OVF: 	
	SBI		TIFR0, TOV0
	LDI		R16, 158			// Se indica donde debe iniciar el TIMER
	OUT		TCNT0, R16				
	INC		R27					// R24 ser� un contador de la cant. de veces que lee el pin
	CPI		R27, 5				// Si ocurre 5 veces, ya pas� el tiempo para modificar los leds
	BREQ	TOGGLE	
	RETI

TOGGLE: 
	SBI		PIND, PD7			// Hace un toggle cada 500 ms para los leds
	RETI

//------------------------------------------ Rutina de interrupci�n del timer01 -----------------------------------------
TIMER1_OVERFLOW: 	
	LDI		R16, LOW(VALOR_T1)				// Cargar el byte bajo de 6942 (0x1E)
	STS		TCNT1L, R16
	LDI		R16, HIGH(VALOR_T1)				// Cargar el byte alto de 6942 (0x1B)
	STS		TCNT1H, R16			
	RJMP	CONTADOR	
	RETI

// Rutina de NO interrupci�n 
//----------------------------------------------------INCREMENTA DISPLAY------------------------------------------------

CONTADOR: 
	//ADIW	Z, 1					// Compara el valor del contador 
	INC		R19						// Se aumenta el contador de unidades de minutos
	CPI		R19, 0x0A				// Se compara para ver si ya sum� 
    BREQ	RESET_DISP1				// Si al comparar no es igual, salta a mostrarlo
	LPM		R21, Z		
	//OUT		PORTD, R16
	//LDI		R24, 0x00				// Reiniciar contador de desbordamientos de timer
	RETI

RESET_DISP1:
    //CLI
	LDI		R19, 0x00				// Resetea el contador a 0
	INC		R22						// Incrementamos el contador de decenas de minutos
	CPI		R22, 0x06				// Comparamos si ya es 6
	//LDI		R24, 0x00
	BREQ	HORAS					// Si no es 6, sigue para actualizar
	//SEI
	RETI

HORAS:
	LDI		R19, 0x00				// Resetea el contador de unidades de minutos
	LDI		R22, 0x00				// Resetea el contador de decenas de minutos
	INC		R23						// Incrementa el contador de unidades de horas
	CPI		R23, 0x04				// Compara para lograr formato de 24 horas
	BREQ	FORMATO_24

	//LDI		R24, 0x00
	CALL	INIT_DIS7
	RETI		

FORMATO_24: 
	CPI		R25, 0x02
	BREQ	
// -------------------------------------------- Se inicia el TIMER1 ---------------------------------------------------
INIT_TMR1:
	// Cargar valor inicial en TCNT1 para desborde cada 1 minuto
	LDI		R16, LOW(VALOR_T1)			// Cargar el byte bajo de 6942 (0x1E)
	STS		TCNT1L, R16
	LDI		R16, HIGH(VALOR_T1)			// Cargar el byte alto de 6942 (0x1B)
	STS		TCNT1H, R16	
	
	LDI		R16, 0x00
	STS		TCCR1A, R16					// Se configura en modo normal 

	LDI		R16, (1<<CS12) | (1<<CS10)	// Se configura prescaler de 1024
	STS		TCCR1B, R16					// Setear prescaler del TIMER 0 a 1024

	RET

// -------------------------------------------- Se inicia el TIMER0 ---------------------------------------------------
INIT_TMR0:
	// Cargar valor inicial en TCNT1 para desborde cada 100 ms
	LDI		R16, (1<<CS02) | (1<<CS00)
	OUT		TCCR0B, R16					// Setear prescaler del TIMER 0 a 1024
	LDI		R16, 158					// Indicar desde donde inicia -> desborde cada 100 ms
	OUT		TCNT0, R16					// Cargar valor inicial en TCNT0

	RET

// -------------------------------------------- Se inicia el display ---------------------------------------------------
INIT_DIS7:
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	LPM		R21, Z
	OUT		PORTD, R21
	RET

// --------------------------------------Rutina de interrupci�n para revisar PB ----------------------------------------
ISR_PCINT0: 

	IN		R18, PINB				// Se lee el pin
	CP		R18, R20				// Se compara estado de los botones
	BREQ	NO_CAMBIO				// Si siguen siendo iguales, es porque no hubo cambio
	MOV		R20, R18				// Copia el estado de botones

	// PB0 -> Incrementa | PB1 -> Decrementa		
	SBRS	R18, PB0				// Si el bit 0 est� set salta (por pull-up 1 -> suelto) 
	RJMP	INCREMENTAR1			// Si no est� set incrementa (0 -> apachado) 

	SBRS	R18, PB1				// Revisa si el bit 1 est� set (1 -> no apachado) 
	RJMP	DECREMENTAR1			// Si no est� set decrementa (0 -> apachado)  

	LDI		R16, (1 << PCIE0)		// Habilitar interrupciones PIN-CHANGE
	STS		PCICR, R16				// Ya que se revis� la interrupci�n se revisan otras

	RETI

NO_CAMBIO: 
	RETI							// Lo regresa al loop

//-----------------------------------------------INC Y DEC PUSH-BUTTONS-------------------------------------------------
// Sub-rutinas (no de interrupci�n) 
INCREMENTAR1: 	
	CPI		R17, 0x0F				// Compara el valor del contador 
    BREQ	RESET_COUNTER1			// Si al comparar no es igual, salta a mostrarlo
	INC		R17						// Incrementa el valor
	OUT		PORTC, R17				// Muestra en el portD el valor
	RETI							// Vuelve al ciclo main a repetir

DECREMENTAR1: 
	DEC		R17						// R19 decrementar�
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
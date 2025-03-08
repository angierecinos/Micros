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
; Descripción: El código será un reloj con diferentes opciones

// -------------------------------- Encabezado ------------------------------- //

.include "M328PDEF.inc"				// Incluye definiciones del ATMega328
//.equ	VALOR_T1 = 0x1B1E
.equ	VALOR_T1 = 0xFFF1
.equ	VALOR_T0 = 0xB2
//.equ	MODOS = 6
//.def	MODO = R28
.def	ACCION = R8
.cseg								// Codigo en la flash

.org	0x0000							// Donde inicia el programa
	JMP	START							// Tiene que saltar para no ejecutar otros

.org	PCI0addr						// Dirección donde está el vector interrupción PORTB
	JMP	ISR_PCINT0

.org	OVF1addr						// Dirección del vector para timer1
	JMP	TIMER1_OVERFLOW

.org	OVF0addr						// Dirección del vector para timer0
	JMP	TIMER0_OVF

TABLITA: .DB 0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0X5F, 0x70, 0x7F, 0X7B

START: 

	// Configurar el SP en 0x03FF (al final de la SRAM) 
	LDI		R16, LOW(RAMEND)			// Carga los bits bajos (0x0FF)
	OUT		SPL, R16					// Configura spl = 0xFF -> r16
	LDI		R16, HIGH(RAMEND)			// Carga los bits altos (0x03)
	OUT		SPH, R16					// Configura sph = 0x03) -> r16

SETUP:

	// Deshabilitar interrupciones globales
	CLI	
// ------------------------------------Configuración del TIMER0----------------------------------
	// Utilizando oscilador a 1MHz - Permitirá parpadeo cada 500 ms
	// Se configura prescaler principal
	LDI		R16, (1 << CLKPCE)			// Se selecciona el bit del CLK (bit 7) 
	STS		CLKPR, R16					// Se habilitar cambio para el prescaler
	LDI		R16, 0b00000100				// En la tabla se ubica qué bits deben encender
	STS		CLKPR, R16					// Se configura prescaler a 16 para 1MHz
	
	CALL	INIT_TMR0

	LDI		R16, (1 << TOIE0)			// Habilita interrupción por desborde del TIMER0
	STS		TIMSK0, R16										
	
// ------------------------------------Configuración del TIMER1----------------------------------
	// Utilizando oscilador a 1MHz - Permitirá usar el contador cada minuto
	// Se configura prescaler principal
	/*LDI		R16, (1 << CLKPCE)			// Se selecciona el bit del CLK (bit 7) 
	STS		CLKPR, R16					// Se habilitar cambio para el prescaler
	LDI		R16, 0b00000100				// En la tabla se ubica qué bits deben encender
	STS		CLKPR, R16					// Se configura prescaler a 64 para 1MHz*/

	CALL	INIT_TMR1

// Habilitar interrupción por desborde del TIMER1
	LDI		R16, (1 << TOIE1)			// Habilita interrupción por desborde del TIMER1
	STS		TIMSK1, R16					

// ------------------------------------Configuración de los puertos----------------------------------
	//	PORTD, PORTC y PB5 como salida 
	LDI		R16, 0xFF
	OUT		DDRD, R16					// Setear puerto D como salida (1 -> no recibe)
	OUT		DDRC, R16					// Setear puerto C como salida 
	LDI		R16, 0x00					// Se apagan las salidas
	OUT		PORTD, R16
	OUT		PORTC, R16
	
	// Configurar PB como entradas con pull ups habilitados
	LDI		R16, 0x20					// Se configura PB0->PB4 como entradas y PB5 como salida (0010 0000)
	OUT		DDRB, R16
	LDI		R16, (1 << PB0) | (1 << PB1) | (1 << PB2) | (1 << PB3) | (1 << PB4)
	OUT		PORTB, R16					// Habilitar pull-ups 
	CBI		PORTB, PB5					// Se le carga valor de 0 a PB5 (Salida apagada)

	// Configurar PC0, PC1, PC2 y PC3 como salidas para controlar los transistores
    LDI		R16, (1 << PC0) | (1 << PC1) | (1 << PC2) | (1 << PC3)
    OUT		DDRC, R16

// ------------------------------------Configuración de interrupción para botones----------------------------------
	LDI		R16, (1 << PCINT0) | (1 << PCINT1) | (1 << PCINT2) | (1 << PCINT3)	| (1 << PCINT4)	// Se seleccionan los bits de la máscara (5)
	STS		PCMSK0, R16								// Bits habilitados (PB0, PB1, PB2, PB3 y PB4) por máscara		

	LDI		R16, (1 << PCIE0)						// Habilita las interrupciones Pin-Change en PORTB
	STS		PCICR, R16								// "Avisa" al registros PCICR que se habilitan en PORTB
													// Da "permiso" "habilita"

//---------------------------------------------INICIALIZAR DISPLAY-------------------------------------------------
	CALL	INIT_DIS7
	
//---------------------------------------------------REGISTROS-----------------------------------------------------
		  //R16 - MULTIUSOS GENERAL 
	LDI		R17, 0x00								// Registro para contador de MODOS
		  //R18 - Multiplexa displays
	LDI		R19, 0x00								// Registro para contador de unidades (minutos) display
	LDI		R20, 0xFF								// Guarda el estado de botones
	LDI		R21, 0x00								// Registro para cargar el valor de Z
	LDI		R22, 0x00								// Registro para contador de decenas (minutos)
	LDI		R23, 0x00								// Registro para contador de unidades (horas)
	LDI		R24, 0x00								// Registro para contador de desbordamientos
	LDI		R25, 0x00								// Registro para contador de decenas (horas)
	LDI		R26, 0x00								// Registro para contador de unidades (días)
	LDI		R27, 0x00								// Registro para contador de decenas (días)
	SEI												// Se habilitan interrupciones globales

// Loop principal
MAIN:  
	// Se multiplexan displays
	MOV		R18, R24				// Se copia el valor de R24 (del timer0) en R17
	ANDI	R18, 0b00000011			// Se realiza un ANDI, con el propósito de multiplexar displays
	CPI		R18, 0 
	BREQ	MOSTRAR_UNI_MIN
	CPI		R18, 1
	BREQ	MOSTRAR_DEC_MIN
	CPI		R18, 2
	BREQ	MOSTRAR_UNI_HOR
	CPI		R18, 3
	BREQ	MOSTRAR_DEC_HOR
	// Se revisa el modo en el que está
	CPI		R17, 0 
	CALL	RELOJ_NORMAL
	CPI		R17, 1
	CALL	FECHA_NORMAL
	CPI		R17, 2
	CALL	CONFIG_RELOJ
	CPI		R17, 3
	CALL	CONFIG_FECHA
	CPI		R17, 4
	CALL	CONFIG_ALARMA
	CPI		R17, 5 
	CALL	APAGAR_ALARMA
	
	RJMP	MAIN

// Sub-rutinas para multiplexación de displays
MOSTRAR_UNI_MIN:
	// Mostrar unidades de minutos
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	IN		R16, PORTD
	ANDI	R16, 0b10000000			// Solo se toma el valor para PD7 y se ponen en 0 los demás
	MOV		R6, R19					// Para no afectar el valor del contador, se copia
	ADD		ZL, R6					// Cargar el valor del contador de unidades a z
	LPM		R21, Z					// Guardar el valor de Z
	OR		R21, R16				// Sumar el valor de PD7 con el valor del contador
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC0				// Habilitar transistor 1 - Unidades minutos
	OUT		PORTD, R21
	RJMP	MAIN

MOSTRAR_DEC_MIN: 
	// Mostrar decenas de minutos
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	IN		R16, PORTD
	ANDI	R16, 0b10000000			// Solo se toma el valor para PD7 y se ponen en 0 los demás
	MOV		R6, R22					// Para no afectar el valor del contador, se copia
	ADD		ZL, R6					// Cargar el valor del contador de unidades a z
	LPM		R21, Z					// Guardar el valor de Z
	OR		R21, R16					// Sumar el valor de PD7 con el valor del contador
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC1				// Habilitar transistor 2 - Decenas minutos
	OUT		PORTD, R21
	RJMP	MAIN

MOSTRAR_UNI_HOR: 
	// Mostrar decenas de horas
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	IN		R16, PORTD
	ANDI	R16, 0b10000000			// Solo se toma el valor para PD7 y se ponen en 0 los demás
	MOV		R6, R23					// Para no afectar el valor del contador, se copia
	ADD		ZL, R6					// Cargar el valor del contador de unidades a z
	LPM		R21, Z					// Guardar el valor de Z
	OR		R21, R16					// Sumar el valor de PD7 con el valor del contador
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC2				// Habilitar transistor 3 - Unidades horas
	OUT		PORTD, R21
	RJMP	MAIN

MOSTRAR_DEC_HOR:  
	// Mostrar decenas de horas
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	IN		R16, PORTD
	ANDI	R16, 0b10000000			// Solo se toma el valor para PD7 y se ponen en 0 los demás
	MOV		R6, R25					// Para no afectar el valor del contador, se copia
	ADD		ZL, R6					// Cargar el valor del contador de unidades a z
	LPM		R21, Z					// Guardar el valor de Z
	OR		R21, R16					// Sumar el valor de PD7 con el valor del contador
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	SBI		PORTC, PC3				// Habilitar transistor 4 - Decenas horas
	OUT		PORTD, R21
	RJMP	MAIN

RELOJ_NORMAL: 
	CBI		PORTC, PC4
	CBI		PORTC, PC5
	MOV		R16, ACCION
	CPI		R16, 0x00
	BRNE	NO_ES_EL_MODO
	LDI		R16, 0x00
	RJMP	CONTADOR

FECHA_NORMAL: 
CONFIG_RELOJ: 
CONFIG_FECHA:
CONFIG_ALARMA:
APAGAR_ALARMA:

NO_ES_EL_MODO: 
	RJMP	MAIN


// Rutina de NO interrupción 
//----------------------------------------------------INCREMENTA DISPLAY------------------------------------------------

CONTADOR: 
	//ADIW	Z, 1					// Compara el valor del contador 
	INC		R19						// Se aumenta el contador de unidades de minutos
	CPI		R19, 0x0A				// Se compara para ver si ya sumó 
    BREQ	DECENAS					// Si al comparar no es igual, salta a mostrarlo
	LPM		R21, Z		
	//OUT		PORTD, R16
	//LDI		R24, 0x00				// Reiniciar contador de desbordamientos de timer
	RETI

DECENAS:
    //CLI
	LDI		R19, 0x00				// Resetea el contador a 0
	INC		R22						// Incrementamos el contador de decenas de minutos
	CPI		R22, 0x06				// Comparamos si ya es 6
	//LDI		R24, 0x00
	BREQ	HORAS					// Si no es 6, sigue para actualizar
	//SEI
	RETI

HORAS:
	//LDI		R19, 0x00			// Resetea el contador de unidades de minutos
	LDI		R22, 0x00				// Resetea el contador de decenas de minutos
	CPI		R25, 0x02				// Compara valor de decenas de horas
	BRNE	NO_TOPAMOS				// Salta a rutina normal		
	INC		R23
	CPI		R23, 0x04				// Verifica el formato de 24 horas
	BRNE	SEGUIR			//
	RJMP	YA_24
	RETI		

NO_TOPAMOS: 
	INC		R23						// Incrementa el contador de unidades de horas
	CPI		R23, 0x0A				// Compara para lograr formato de 24 horas
	BRNE	SEGUIR	
	INC		R25
	LDI		R23, 0x00				// Resetea contador de unidades de horas	
	RETI

SEGUIR: 
	RETI

YA_24: 
	LDI		R19, 0x00
	LDI		R22, 0x00
	LDI		R23, 0x00
	LDI		R25, 0x00
	CALL	INIT_DIS7
	RETI
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
	LDI		R16, (1<<CS01) | (1<<CS00)
	OUT		TCCR0B, R16					// Setear prescaler del TIMER 0 a 64
	LDI		R16, VALOR_T0				// Indicar desde donde inicia -> desborde cada 5 ms
	OUT		TCNT0, R16					// Cargar valor inicial en TCNT0

	RET

// -------------------------------------------- Se inicia el display ---------------------------------------------------
INIT_DIS7:
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	LPM		R21, Z
	OUT		PORTD, R21
	RET
//------------------------------------------ Rutina de interrupción del timer0 -----------------------------------------
TIMER0_OVF: 	
	SBI		TIFR0, TOV0
	LDI		R16, VALOR_T0			// Se indica donde debe iniciar el TIMER
	OUT		TCNT0, R16				
	INC		R24					// R24 será un contador de la cant. de veces que lee el pin
	CPI		R24, 100				// Si ocurre 100 veces, ya pasó el tiempo para modificar los leds
	BREQ	TOGGLE	
	RETI

TOGGLE: 
	LDI		R24, 0x00			// Se reinicia el contador de desbordes	
	SBI		PIND, PD7			// Hace un toggle cada 500 ms para los leds
	RETI

/*TOGGLE:
    LDI     R24, 0x00                ; Se reinicia el contador de desbordes
    SBIS    PORTD, PD7               ; Si el LED está encendido, apágalo
    RJMP    ENCENDER_LED
    CBI     PORTD, PD7               ; Apagar el LED
    RETI

ENCENDER_LED:
    SBI     PORTD, PD7               ; Encender el LED
    RETI*/

//------------------------------------------ Rutina de interrupción del timer01 -----------------------------------------
TIMER1_OVERFLOW: 	
	// Guarda el estado del SREG
	PUSH	R7
	IN		R7, SREG
	PUSH	R7

	LDI		R16, LOW(VALOR_T1)				// Cargar el byte bajo de 6942 (0x1E)
	STS		TCNT1L, R16
	LDI		R16, HIGH(VALOR_T1)				// Cargar el byte alto de 6942 (0x1B)
	STS		TCNT1H, R16	
	
	CPI		R17, 2
	BREQ	SALIR_NO_TIMER	
	CPI		R17, 3
	BREQ	SALIR_NO_TIMER	
	CPI		R17, 4
	BREQ	SALIR_NO_TIMER		// Hay modos en los que no quiero usar el timer, me salgo
	LDI		R16, 0x01			// Se utilizará R8 para "indicar" que se debe realizar algo
	MOV		R8, R16
	RJMP	SALIR_NO_TIMER
	//RJMP	CONTADOR	// Vamos a quitar esto de la interrupción...

// Rutina segura para salir -> reestablece valor de SREG
SALIR_NO_TIMER: 
	POP		R7
	OUT		SREG, R7
	PUSH	R7
	RETI

// --------------------------------------Rutina de interrupción para revisar PB ----------------------------------------
ISR_PCINT0: 
	// Guarda el estado del SREG
	PUSH	R7
	IN		R7, SREG
	PUSH	R7

	IN		R9, PINB				// Se lee el pin
	CP		R9, R20				// Se compara estado de los botones
	BREQ	SALIR					// Si siguen siendo iguales, es porque no hubo cambio
	MOV		R20, R9				// Copia el estado de botones

	// PB0 -> Incrementa Min | PB1 -> Decrementa Min
	// PB2 -> Incrementa Hor | PB3 -> Decrementa Hor | PB4 -> Modo
	SBRS	R20, PB4				// Revisa activación de boton de modo
	INC		R17						// Si no está set incrementa modo (0 -> apachado) 
	LDI		R16, 0x06
	CPSE	R17, R16				// Compara si ya se excedió la cantidad de modos
	RJMP	PC+2
	LDI		R17, 0x00				// Reinicia el contador de botones a 0 y sigue revisando
	CPI		R17, 0					// Revisa en qué modo está
	BREQ	ISR_RELOJ_NORMAL
	CPI		R17, 1
	BREQ	ISR_FECHA_NORMAL
	CPI		R17, 2
	BREQ	ISR_CONFIG_RELOJ
	CPI		R17, 3
	BREQ	ISR_CONFIG_FECHA
	CPI		R17, 4
	BREQ	ISR_CONFIG_ALARMA
	CPI		R17, 5 
	BREQ	ISR_APAGAR_ALARMA
	RJMP	SALIR
	RETI
// Rutina segura para salir -> reestablece valor de SREG
SALIR: 
	POP		R7
	OUT		SREG, R7
	PUSH	R7
	RETI
ISR_RELOJ_NORMAL:
	// El modo reloj normal, únicamente quiero que sume en reloj normal
	LDI		R16, LOW(VALOR_T1)			// Cargar el byte bajo de 6942 (0x1E)
	STS		TCNT1L, R16
	LDI		R16, HIGH(VALOR_T1)			// Cargar el byte alto de 6942 (0x1B)
	STS		TCNT1H, R16	

	RJMP	SALIR

ISR_FECHA_NORMAL: 
	// El modo reloj normal, únicamente quiero que sume en reloj normal
	LDI		R16, LOW(VALOR_T1)			// Cargar el byte bajo de 6942 (0x1E)
	STS		TCNT1L, R16
	LDI		R16, HIGH(VALOR_T1)			// Cargar el byte alto de 6942 (0x1B)
	STS		TCNT1H, R16	

	RJMP	SALIR

ISR_CONFIG_RELOJ: 
	// Se revisan los pb, dependiendo de si se activan se sabrá qué acción realizar
	LDI		R16, 0x00
	SBIS	PINB, PB0			// Como para configurar reloj, se tienen 4 botones
	LDI		R16, 0x01			// Se enciende el indicador de que debe haber acción -> Inc Disp 1		
	
	SBIS	PINB, PB1			// Se revisan ambos botones
	LDI		R16, 0x02			// Se enciende el indicador de que debe haber acción -> Inc Disp 1
	
	SBIS	PINB, PB2			// Como para configurar reloj, se tienen 4 botones 
	LDI		R16, 0x03			// Se enciende el indicador de que debe haber acción			
	
	SBIS	PINB, PB3			// Se revisan ambos botones
	LDI		R16, 0x04			// Se enciende el indicador de que debe haber acción	
	
	MOV		ACCION, R16			// R8 -> ACCION guardará el valor de acción			
	RJMP	SALIR				// Permite indicar qué se va a hacer

ISR_CONFIG_FECHA:
	// Se revisan los pb, dependiendo de si se activan se sabrá qué acción realizar
	LDI		R16, 0x00
	SBIS	PINB, PB0			// Como para configurar reloj, se tienen 4 botones
	LDI		R16, 0x01			// Se enciende el indicador de que debe haber acción -> Inc Disp 1		
	
	SBIS	PINB, PB1			// Se revisan ambos botones
	LDI		R16, 0x02			// Se enciende el indicador de que debe haber acción -> Inc Disp 1
	
	SBIS	PINB, PB2			// Como para configurar reloj, se tienen 4 botones 
	LDI		R16, 0x03			// Se enciende el indicador de que debe haber acción			
	
	SBIS	PINB, PB3			// Se revisan ambos botones
	LDI		R16, 0x04			// Se enciende el indicador de que debe haber acción	
	
	MOV		ACCION, R16			// R8 -> ACCION guardará el valor de acción			
	RJMP	SALIR

ISR_CONFIG_ALARMA: 
	// Se revisan los pb, dependiendo de si se activan se sabrá qué acción realizar
	LDI		R16, 0x00
	SBIS	PINB, PB0			// Como para configurar reloj, se tienen 4 botones
	LDI		R16, 0x01			// Se enciende el indicador de que debe haber acción -> Inc Disp 1		
	
	SBIS	PINB, PB1			// Se revisan ambos botones
	LDI		R16, 0x02			// Se enciende el indicador de que debe haber acción -> Inc Disp 1
	
	SBIS	PINB, PB2			// Como para configurar reloj, se tienen 4 botones 
	LDI		R16, 0x03			// Se enciende el indicador de que debe haber acción			
	
	SBIS	PINB, PB3			// Se revisan ambos botones
	LDI		R16, 0x04			// Se enciende el indicador de que debe haber acción	
	
	MOV		ACCION, R16			// R8 -> ACCION guardará el valor de acción			
	RJMP	SALIR

ISR_APAGAR_ALARMA: 
	// El modo reloj normal, únicamente quiero que sume en reloj normal
	LDI		R16, LOW(VALOR_T1)			// Cargar el byte bajo de 6942 (0x1E)
	STS		TCNT1L, R16
	LDI		R16, HIGH(VALOR_T1)			// Cargar el byte alto de 6942 (0x1B)
	STS		TCNT1H, R16	
	RJMP	SALIR



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
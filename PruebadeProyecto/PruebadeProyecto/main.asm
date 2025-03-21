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
//.equ	VALOR_T1 = 0x1B1E
.equ	VALOR_T1 = 0xFF50
.equ	VALOR_T0 = 0xB2
//.equ	MODOS = 6
//.def	MODO = R28
.def	ACCION = R8
.cseg								// Codigo en la flash

.org	0x0000							// Donde inicia el programa
	JMP	START							// Tiene que saltar para no ejecutar otros

.org	PCI0addr						// Direcci�n donde est� el vector interrupci�n PORTB
	JMP	ISR_PCINT0

.org	OVF1addr						// Direcci�n del vector para timer1
	JMP	TIMER1_OVERFLOW

.org	OVF0addr						// Direcci�n del vector para timer0
	JMP	TIMER0_OVF

TABLITA: .DB 0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0X5F, 0x70, 0x7F, 0X7B
DIAS_POR_MES: .DB 32, 29, 32, 31, 32, 31, 32, 32, 31, 32, 31, 32
//DIAS_POR_MES: .DB 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31

START: 

	// Configurar el SP en 0x03FF (al final de la SRAM) 
	LDI		R16, LOW(RAMEND)			// Carga los bits bajos (0x0FF)
	OUT		SPL, R16					// Configura spl = 0xFF -> r16
	LDI		R16, HIGH(RAMEND)			// Carga los bits altos (0x03)
	OUT		SPH, R16					// Configura sph = 0x03) -> r16

SETUP:

	// Deshabilitar interrupciones globales
	CLI	
// ------------------------------------Configuraci�n del TIMER0----------------------------------
	// Utilizando oscilador a 1MHz - Permitir� parpadeo cada 500 ms
	// Se configura prescaler principal
	LDI		R16, (1 << CLKPCE)			// Se selecciona el bit del CLK (bit 7) 
	STS		CLKPR, R16					// Se habilitar cambio para el prescaler
	LDI		R16, 0b00000100				// En la tabla se ubica qu� bits deben encender
	STS		CLKPR, R16					// Se configura prescaler a 16 para 1MHz
	
	CALL	INIT_TMR0

	LDI		R16, (1 << TOIE0)			// Habilita interrupci�n por desborde del TIMER0
	STS		TIMSK0, R16										
	
// ------------------------------------Configuraci�n del TIMER1----------------------------------

	CALL	INIT_TMR1

// Habilitar interrupci�n por desborde del TIMER1
	LDI		R16, (1 << TOIE1)			// Habilita interrupci�n por desborde del TIMER1
	STS		TIMSK1, R16				

// ------------------------------------Configuraci�n de los puertos----------------------------------
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
	LDI		R17, 0x00								// Registro para contador de MODOS
		  //R18 - Multiplexa displays
	LDI		R19, 0x00								// Registro para contador de unidades (minutos) display
	LDI		R20, 0xFF								// Guarda el estado de botones
	LDI		R21, 0x00								// Registro para cargar el valor de Z
	LDI		R22, 0x00								// Registro para contador de decenas (minutos)
	LDI		R23, 0x00								// Registro para contador de unidades (horas)
	LDI		R24, 0x00								// Registro para contador de desbordamientos
	LDI		R25, 0x00								// Registro para contador de decenas (horas)
	LDI		R26, 0x01								// Registro para contador de unidades (d�as)
	LDI		R27, 0x00								// Registro para contador de decenas (d�as)
	LDI		R28, 0x01								// Registro para contador de unidades (meses)
	LDI		R29, 0x00								// Registro para contador de decenas (meses)
	
	SEI												// Se habilitan interrupciones globales

// Loop principal
MAIN:  
	CALL	MULTIPLEX
	// Se revisa el modo en el que est�
	CPI		R17, 0 
	BREQ	CALL_RELOJ_NORMAL
	CPI		R17, 1
	BREQ	CALL_FECHA_NORMAL
	CPI		R17, 2
	BREQ	CALL_CONFIG_RELOJ
	CPI		R17, 3
	BREQ	CALL_CONFIG_FECHA
	CPI		R17, 4
	BREQ	CALL_CONFIG_ALARMA
	CPI		R17, 5 
	BREQ	CALL_APAGAR_ALARMA
	RJMP	MAIN

MULTIPLEX:
	CPI		R17, 0 
	BREQ	MULTIPLEX_HORA
	CPI		R17, 1
	BREQ	MULTIPLEX_FECHA
	RET

CALL_RELOJ_NORMAL:
	CALL	RELOJ_NORMAL
	RJMP	MAIN	
CALL_FECHA_NORMAL:
	CALL	FECHA_NORMAL
	RJMP	MAIN
CALL_CONFIG_RELOJ:
	CALL	CONFIG_RELOJ
	RJMP	MAIN
CALL_CONFIG_FECHA:
	CALL	CONFIG_FECHA
	RJMP	MAIN
CALL_CONFIG_ALARMA:
	CALL	CONFIG_ALARMA
	RJMP	MAIN
CALL_APAGAR_ALARMA:
	CALL	APAGAR_ALARMA
	RJMP	MAIN

MULTIPLEX_HORA: 
	// Se multiplexan displays
	MOV		R18, R24				// Se copia el valor de R24 (del timer0) en R18
	ANDI	R18, 0b00000011			// Se realiza un ANDI, con el prop�sito de multiplexar displays
	CPI		R18, 0 
	BREQ	MOSTRAR_UNI_MIN
	CPI		R18, 1
	BREQ	MOSTRAR_DEC_MIN
	CPI		R18, 2
	BREQ	MOSTRAR_UNI_HOR
	CPI		R18, 3
	BREQ	MOSTRAR_DEC_HOR
	RET
MULTIPLEX_FECHA:
	MOV		R18, R24				// Se copia el valor de R24 (del timer0) en R18
	ANDI	R18, 0b00000011			// Se realiza un ANDI, con el prop�sito de multiplexar displays
	CPI		R18, 0 
	BREQ	MOSTRAR_UNIDAD_MES
	CPI		R18, 1
	BREQ	MOSTRAR_DECENA_MES
	CPI		R18, 2
	BREQ	MOSTRAR_UNIDAD_DIA
	CPI		R18, 3
	BREQ	MOSTRAR_DECENA_DIA
	RET

// Sub-rutinas para multiplexaci�n de displays
MOSTRAR_UNI_MIN:
	// Mostrar unidades de minutos
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	/*IN		R16, PORTD
	ANDI	R16, 0b10000000			// Solo se toma el valor para PD7 y se ponen en 0 los dem�s
	MOV		R6, R19	*/				// Para no afectar el valor del contador, se copia
	ADD		ZL, R19					// Cargar el valor del contador de unidades a z
	LPM		R21, Z					// Guardar el valor de Z
	//OR		R21, R16				// Sumar el valor de PD7 con el valor del contador
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC0				// Habilitar transistor 1 - Unidades minutos
	OUT		PORTD, R21
	RET

MOSTRAR_DEC_MIN: 
	// Mostrar decenas de minutos
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	/*IN		R16, PORTD
	ANDI	R16, 0b10000000			// Solo se toma el valor para PD7 y se ponen en 0 los dem�s
	MOV		R6, R22*/					// Para no afectar el valor del contador, se copia
	ADD		ZL, R22					// Cargar el valor del contador de unidades a z
	LPM		R21, Z					// Guardar el valor de Z
	//OR		R21, R16					// Sumar el valor de PD7 con el valor del contador
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC1				// Habilitar transistor 2 - Decenas minutos
	OUT		PORTD, R21
	RET

MOSTRAR_UNIDAD_MES:
	RJMP	MOSTRAR_UNI_MES
MOSTRAR_DECENA_MES:
	RJMP	MOSTRAR_DEC_MES

MOSTRAR_UNI_HOR: 
	// Mostrar decenas de horas
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	//IN		R16, PORTD
	//ANDI	R16, 0b10000000			// Solo se toma el valor para PD7 y se ponen en 0 los dem�s
	//MOV		R6, R23					// Para no afectar el valor del contador, se copia
	ADD		ZL, R23					// Cargar el valor del contador de unidades a z
	LPM		R21, Z					// Guardar el valor de Z
	//OR		R21, R16					// Sumar el valor de PD7 con el valor del contador
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC2				// Habilitar transistor 3 - Unidades horas
	OUT		PORTD, R21
	RET
MOSTRAR_DEC_HOR:  
	// Mostrar decenas de horas
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	/*IN		R16, PORTD
	ANDI	R16, 0b10000000			// Solo se toma el valor para PD7 y se ponen en 0 los dem�s
	MOV		R6, R25	*/				// Para no afectar el valor del contador, se copia
	ADD		ZL, R25					// Cargar el valor del contador de unidades a z
	LPM		R21, Z					// Guardar el valor de Z
	//OR		R21, R16					// Sumar el valor de PD7 con el valor del contador
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	SBI		PORTC, PC3				// Habilitar transistor 4 - Decenas horas
	OUT		PORTD, R21
	RET

MOSTRAR_UNIDAD_DIA:
	RJMP	MOSTRAR_UNI_DIA
MOSTRAR_DECENA_DIA:
	RJMP	MOSTRAR_DEC_DIA
	
	// Sub-rutinas para multiplexaci�n de displays
MOSTRAR_UNI_MES:
	// Mostrar unidades de minutos
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	/*IN		R16, PORTD
	ANDI	R16, 0b10000000			// Solo se toma el valor para PD7 y se ponen en 0 los dem�s
	MOV		R6, R28	*/				// Para no afectar el valor del contador, se copia
	ADD		ZL, R28					// Cargar el valor del contador de unidades a z
	LPM		R21, Z					// Guardar el valor de Z
	//OR		R21, R16				// Sumar el valor de PD7 con el valor del contador
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC0				// Habilitar transistor 1 - Unidades minutos
	OUT		PORTD, R21
	RET
MOSTRAR_DEC_MES: 
	// Mostrar decenas de minutos
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	/*IN		R16, PORTD
	ANDI	R16, 0b10000000			// Solo se toma el valor para PD7 y se ponen en 0 los dem�s
	MOV		R6, R29	*/				// Para no afectar el valor del contador, se copia
	ADD		ZL, R29					// Cargar el valor del contador de unidades a z
	LPM		R21, Z					// Guardar el valor de Z
	OR		R21, R16					// Sumar el valor de PD7 con el valor del contador
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC1				// Habilitar transistor 2 - Decenas minutos
	OUT		PORTD, R21
	RET
MOSTRAR_UNI_DIA: 
	// Mostrar decenas de horas
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	/*IN		R16, PORTD
	ANDI	R16, 0b10000000			// Solo se toma el valor para PD7 y se ponen en 0 los dem�s
	MOV		R6, R26*/					// Para no afectar el valor del contador, se copia
	ADD		ZL, R26					// Cargar el valor del contador de unidades a z
	LPM		R21, Z					// Guardar el valor de Z
	//OR		R21, R16					// Sumar el valor de PD7 con el valor del contador
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC2				// Habilitar transistor 3 - Unidades horas
	OUT		PORTD, R21
	RET
MOSTRAR_DEC_DIA:  
	// Mostrar decenas de horas
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	/*IN		R16, PORTD
	ANDI	R16, 0b10000000			// Solo se toma el valor para PD7 y se ponen en 0 los dem�s
	MOV		R6, R27	*/				// Para no afectar el valor del contador, se copia
	ADD		ZL, R27					// Cargar el valor del contador de unidades a z
	LPM		R21, Z					// Guardar el valor de Z
	//OR		R21, R16					// Sumar el valor de PD7 con el valor del contador
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	SBI		PORTC, PC3				// Habilitar transistor 4 - Decenas horas
	OUT		PORTD, R21
	RET

RELOJ_NORMAL: 
	// El modo reloj normal, �nicamente quiero que sume en reloj normal
	SBI		PORTC, PC4
	SBI		PORTC, PC5
	//MOV		R16, ACCION
	/*CPI		R16, 0x01
	BRNE	NO_ES_EL_MODO
	LDI		R16, 0x00
	MOV		ACCION, R16
	CPI		R17, 0x00
	RJMP	CONTADOR*/
	RET

FECHA_NORMAL: 
	SBI		PORTC, PC4
	CBI		PORTC, PC5
	/*MOV		R16, ACCION
	CPI		R16, 0x02
	BRNE	NO_ES_EL_MODO
	LDI		R16, 0x00
	MOV		ACCION, R16
	RJMP	CONTADOR*/
	RET

CONFIG_RELOJ: 
	SBI		PORTC, PC4
	CBI		PORTC, PC5
	MOV		R16, ACCION			// Revisar bandera de acci�n
	
	CPI		R16, 0x01
	BREQ	INC_DISP_MIN
	CPI		R16, 0x02
	BREQ	DEC_DISP_MIN
	CPI		R16, 0x01
	BREQ	INC_DISP_HOR
	CPI		R16, 0x03
	BREQ	DEC_DISP_HOR
	LDI		R16, 0x04
	RJMP	NO_ES_EL_MODO
	LDI		R16, 0x00			// Resetear bandera de acci�n
	MOV		ACCION, R16
	RET
CONFIG_FECHA:
	RET
CONFIG_ALARMA:
	RET
APAGAR_ALARMA:
	RET

NO_ES_EL_MODO: 
	RET

//-----------------------------------------------INC Y DEC PUSH-BUTTONS-------------------------------------------------
// Sub-rutinas (no de interrupci�n) - INC/DEC Display 1
INC_DISP_MIN: 	
	INC		R19						// Incrementa el valor
	CPI		R19, 0x0A				// Compara el valor del contador 
    BREQ	OVER_DECENAS			// Si al comparar no es igual, salta a mostrarlo
	LPM		R21, Z
	RET								// Vuelve al ciclo main a repetir

OVER_DECENAS:
    LDI		R19, 0x00				// Resetea el contador de unidades a 0
	INC		R22						// Incrementamos el contador de decenas de minutos
	CPI		R22, 0x06				// Comparamos si ya es 6
	BREQ	RESETEO_HORA			// Si no es 6, sigue para actualizar
	RET

RESETEO_HORA:
    LDI		R19, 0x00				// Resetea el contador a 0
	LDI		R22, 0x00
	RET

DEC_DISP_MIN: 
	DEC		R19						// R19 decrementar�
	CPI		R19, 0xFF				// Si el contador llega a 0, reiniciar el contador
	BREQ	RESET_MINUTOS			// Si es igual a 0 no hace nada y vuelve a main
	RET								// Regresa a main si ya decremento

RESET_MINUTOS: 
	LDI		R19, 0x09
	DEC		R22
	CPI		R22, 0xFF
	BREQ	RESET_DECENAS
	RET

RESET_DECENAS:
	LDI		R22, 0x05
	RET

// Sub-rutinas (no de interrupci�n) - INC/DEC Display 2
INC_DISP_HOR: 	
	CPI		R25, 0x02				// Compara valor de decenas de horas
	BRNE	NO_24					// Salta a rutina normal		
	INC		R23
	CPI		R23, 0x04				// Verifica el formato de 24 horas
	BRNE	SIGAMOS			
	RJMP	FORMATO24
	RET		

NO_24: 
	INC		R23						// Incrementa el contador de unidades de horas
	CPI		R23, 0x0A				// Compara para lograr formato de 24 horas
	BRNE	SIGAMOS	
	INC		R25
	LDI		R23, 0x00				// Resetea contador de unidades de horas	
	RET

SIGAMOS: 
	RET

FORMATO24: 
	LDI		R23, 0x00
	LDI		R25, 0x00
	RET

// Decrementar horas
DEC_DISP_HOR: 
	DEC		R23						// R23 decrementar�
	CPI		R23, 0xFF				// Si el contador llega a 0, reiniciar el contador
	BREQ	RESET_HOR				// Si es igual a 0 no hace nada y vuelve a main
	RET								// Regresa a main si ya decremento

RESET_HOR: 
	LDI		R23, 0x09
	DEC		R25
	CPI		R25, 0xFF
	BREQ	RESET_DECENAS2
	RET

RESET_DECENAS2:
	LDI		R23, 0x03
	CPI		R25, 0x02				// Compara valor de decenas de horas
	RET		



// -------------------------------------------- Se inicia el TIMER1 ---------------------------------------------------
INIT_TMR1:
	
	LDI		R16, (1<<CS12) | (1<<CS10)	// Se configura prescaler de 1024
	STS		TCCR1B, R16					// Setear prescaler del TIMER 0 a 1024

	// Cargar valor inicial en TCNT1 para desborde cada 1 minuto
	LDI		R16, HIGH(VALOR_T1)			// Cargar el byte alto de 6942 (0x1B)
	STS		TCNT1H, R16	
	LDI		R16, LOW(VALOR_T1)			// Cargar el byte bajo de 6942 (0x1E)
	STS		TCNT1L, R16
	
	LDI		R16, 0x00
	STS		TCCR1A, R16					// Se configura en modo normal 
	RET

// -------------------------------------------- Se inicia el TIMER0 ---------------------------------------------------
INIT_TMR0:
	// Cargar valor inicial en TCNT1 para desborde cada 100 ms
	LDI		R16, (1<<CS01) | (1<<CS00)
	OUT		TCCR0B, R16					// Setear prescaler del TIMER 0 a 64
	LDI		R16, VALOR_T0				// Indicar desde donde inicia -> desborde cada 5 ms
	OUT		TCNT0, R16					// Cargar valor inicial en TCNT0
	RET

// -------------------------------------------- Se inicia tabla meses ---------------------------------------------------
INIT_DIS7:
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	LPM		R21, Z
	OUT		PORTD, R21
	RET

//------------------------------------------ Rutina de interrupci�n del timer0 -----------------------------------------
TIMER0_OVF: 	
	SBI		TIFR0, TOV0
	LDI		R16, VALOR_T0			// Se indica donde debe iniciar el TIMER
	OUT		TCNT0, R16				
	INC		R24					// R24 ser� un contador de la cant. de veces que lee el pin
	CPI		R24, 100				// Si ocurre 100 veces, ya pas� el tiempo para modificar los leds
	BREQ	TOGGLE	
	RETI

TOGGLE: 
	LDI		R24, 0x00			// Se reinicia el contador de desbordes	
	//SBI		PIND, PD7			// Hace un toggle cada 500 ms para los leds
	RETI

//------------------------------------------ Rutina de interrupci�n del timer01 -----------------------------------------
TIMER1_OVERFLOW: 	
	// Guarda el estado del SREG
	PUSH	R7
	IN		R7, SREG
	PUSH	R7
	
	LDI		R16, HIGH(VALOR_T1)			// Cargar el byte alto de 6942 (0x1B)
	STS		TCNT1H, R16	
	LDI		R16, LOW(VALOR_T1)			// Cargar el byte bajo de 6942 (0x1E)
	STS		TCNT1L, R16

	CPI		R17, 2
	BREQ	SALIR_NO_TIMER	
	CPI		R17, 3
	BREQ	SALIR_NO_TIMER	
	CPI		R17, 4
	BREQ	SALIR_NO_TIMER		// Hay modos en los que no quiero usar el timer, me salgo
	
	/*LDI		R16, 0x01			// Se utilizar� R8 para "indicar" que se debe realizar algo
	MOV		ACCION, R16
	RJMP	SALIR_NO_TIMER*/
	RJMP	CONTADOR	// Vamos a quitar esto de la interrupci�n...

// Rutina segura para salir -> reestablece valor de SREG
SALIR_NO_TIMER: 
	POP		R7
	OUT		SREG, R7
	POP		R7
	RETI

// Rutina de NO interrupci�n 
//----------------------------------------------------INCREMENTA DISPLAY------------------------------------------------

CONTADOR: 
	INC		R19						// Se aumenta el contador de unidades de minutos
	CPI		R19, 0x0A				// Se compara para ver si ya sum� 
    BREQ	DECENAS					// Si al comparar no es igual, salta a mostrarlo
	LPM		R21, Z
	RJMP	SALIR_NO_TIMER		
	RETI

DECENAS:
	LDI		R19, 0x00				// Resetea el contador a 0
	INC		R22						// Incrementamos el contador de decenas de minutos
	CPI		R22, 0x06				// Comparamos si ya es 6
	BREQ	HORAS					// Si no es 6, sigue para actualizar
	RJMP	SALIR_NO_TIMER
	RETI

HORAS:
	LDI		R22, 0x00				// Resetea el contador de decenas de minutos
	CPI		R25, 0x02				// Compara valor de decenas de horas
	BRNE	NO_TOPAMOS				// Salta a rutina normal		
	INC		R23
	CPI		R23, 0x04				// Verifica el formato de 24 horas
	BRNE	SEGUIR			
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
	POP		R7
	OUT		SREG, R7
	POP		R7
	RETI

YA_24: 
	LDI		R19, 0x00
	LDI		R22, 0x00
	LDI		R23, 0x00
	LDI		R25, 0x00
	CALL	INIT_DIS7
	INC		R26						// Se incrementan las unidades de d�as
	CPI		R26, 0x0A				// Se compara para saber si lleg� a 10
	BREQ	INC_DECENAS_DIAS		// Si es 10, se incrementan las decenas
	CALL	VERIFICAR_DIAS			// Revisa que la cantidad de d�as coincidan con el mes
	RJMP	SALIR_NO_TIMER
	RETI

INC_DECENAS_DIAS: 
	LDI		R26, 0x00				// Se reinicia el contador de unidades d�as
	INC		R27						// Se incrementan las decenas de d�as
	CPI		R27, 0x04				// Se compara con 4 porque el maximo de dec son 3
	BREQ	REINICIAR_DIAS
	RJMP	SALIR_NO_TIMER
	RETI

REINICIAR_DIAS:
	LDI		R27, 0x00				// Se reinician las decenas 
	LDI		R26, 0x01				// Se reinician los d�as a 1 (el mes empieza en dia 1) 
	CALL	INCREMENTAR_MES
	RJMP	SALIR_NO_TIMER
	RETI

INCREMENTAR_MES: 
	INC		R28						// Si ya pasaron los d�as, se incrementa el mes
	CPI		R28, 0x0A				// Se compara para ver si ya es 10
	BREQ	INCREMENTAR_DECENAS_MES
	RET

INCREMENTAR_DECENAS_MES: 
	LDI		R28, 0x00				// Resetear unidades del mes
	INC		R29						// Incrementar decenas mes
	CPI		R29, 0x02				// No hay mas de 12 meses
	BREQ	REINICIAR_MESES			// Si se cumplen los 12 meses, se reinicia
	RJMP	SALIR_NO_TIMER
	RETI

REINICIAR_MESES: 
	LDI		R29, 0x00
	LDI		R28, 0x01				// Se reinician los meses al 1 (enero) 
	RJMP	SALIR_NO_TIMER
	RETI

VERIFICAR_DIAS:
    // Cargar la direcci�n de la tabla DIAS_POR_MES
    LDI     ZL, LOW(DIAS_POR_MES<<1)
    LDI     ZH, HIGH(DIAS_POR_MES<<1)

    // Calcular el �ndice del mes actual (mes - 1)
    MOV     R16, R28		        // Cargar unidades de mes
    DEC     R16                     // Restar 1 (la tabla empieza en 0)
    ADD     ZL, R16                 // Meter el �ndice a Z
    LPM     R18, Z                  // Leer la cantidad de d�as del mes actual

    // Comparar d�as actuales con d�as del mes
    MOV     R10, R27		        // Cargar decenas de d�as
    LSL	    R10                     // Convertir decenas a unidades (2 -> 20)
								    // X*2 (Desplazar a la izquierda una vez)
    MOV		R11, R10				// Guardamos el resultado temporalmente
    LSL		R10						// X*4 (Otro desplazamiento a la izquierda)
    LSL	    R10						// X*8 (Otro desplazamiento a la izquierda, ahora es X*8)
    ADD		R10, R11				// (X*8) + (X*2) = X*10 
    ADD     R10, R26		        // Sumar unidades de d�as (20 + 5 = 25)
    CP      R10, R18                // Comparar con d�as del mes
    BRLO    FIN_VERIFICAR_DIAS_MES  // Si es menor, no hacer nada
    CALL    REINICIAR_DIAS          // Si es igual o mayor, reiniciar d�as

FIN_VERIFICAR_DIAS_MES:
	RJMP	SALIR_NO_TIMER
    RET

// --------------------------------------Rutina de interrupci�n para revisar PB ----------------------------------------
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
	SBRS	R9, PB4				// Revisa activaci�n de boton de modo
	INC		R17						// Si no est� set incrementa modo (0 -> apachado) 
	LDI		R16, 0x06
	CPSE	R17, R16				// Compara si ya se excedi� la cantidad de modos
	RJMP	PC+2
	LDI		R17, 0x00				// Reinicia el contador de botones a 0 y sigue revisando
	LDI		R16, 0x00
	CPI		R17, 0					// Revisa en qu� modo est�
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
	POP		R7
	RETI

ISR_RELOJ_NORMAL:
	// El modo reloj normal, �nicamente quiero que sume en reloj normal
	/*LDI		R16, LOW(VALOR_T1)			// Cargar el byte bajo de 6942 (0x1E)
	STS		TCNT1L, R16
	LDI		R16, HIGH(VALOR_T1)			// Cargar el byte alto de 6942 (0x1B)
	STS		TCNT1H, R16*/	
	RJMP	SALIR

ISR_FECHA_NORMAL: 
	// El modo reloj normal, �nicamente quiero que sume en reloj normal
	/*LDI		R16, LOW(VALOR_T1)			// Cargar el byte bajo de 6942 (0x1E)
	STS		TCNT1L, R16
	LDI		R16, HIGH(VALOR_T1)			// Cargar el byte alto de 6942 (0x1B)
	STS		TCNT1H, R16
	LDI		R16, 0x02
	MOV		ACCION, R16*/
	RJMP	SALIR

ISR_CONFIG_RELOJ: 
	// Se revisan los pb, dependiendo de si se activan se sabr� qu� acci�n realizar
	LDI		R16, 0x00
	SBIS	PINB, PB0			// Como para configurar reloj, se tienen 4 botones
	RJMP	INC_DISP1			// Solo se considera un botonazo a la vez
			
	SBIS	PINB, PB1			// Se revisan ambos botones
	RJMP	DEC_DISP1			// Solo se considera un botonazo a la vez
	
	SBIS	PINB, PB2			// Como para configurar reloj, se tienen 4 botones 
	RJMP	INC_DISP2			// Solo se considera un botonazo a la vez			
	
	SBIS	PINB, PB3			// Se revisan ambos botones
	RJMP	DEC_DISP2			// Solo se considera un botonazo a la vez	
	
	MOV		ACCION, R16			// R8 -> ACCION guardar� el valor de acci�n			
	RJMP	SALIR

ISR_CONFIG_FECHA:
	// Se revisan los pb, dependiendo de si se activan se sabr� qu� acci�n realizar
	LDI		R16, 0x00
	SBIS	PINB, PB0			// Como para configurar reloj, se tienen 4 botones
	RJMP	INC_DISP1			// Solo se considera un botonazo a la vez
			
	SBIS	PINB, PB1			// Se revisan ambos botones
	RJMP	DEC_DISP1			// Solo se considera un botonazo a la vez
	
	SBIS	PINB, PB2			// Como para configurar reloj, se tienen 4 botones 
	RJMP	INC_DISP2			// Solo se considera un botonazo a la vez			
	
	SBIS	PINB, PB3			// Se revisan ambos botones
	RJMP	DEC_DISP2			// Solo se considera un botonazo a la vez	
	
	MOV		ACCION, R16			// R8 -> ACCION guardar� el valor de acci�n			
	RJMP	SALIR

ISR_APAGAR_ALARMA: 
	// El modo reloj normal, �nicamente quiero que sume en reloj normal
	LDI		R16, LOW(VALOR_T1)			// Cargar el byte bajo de 6942 (0x1E)
	STS		TCNT1L, R16
	LDI		R16, HIGH(VALOR_T1)			// Cargar el byte alto de 6942 (0x1B)
	STS		TCNT1H, R16	
	RJMP	SALIR

ISR_CONFIG_ALARMA: 
	// Se revisan los pb, dependiendo de si se activan se sabr� qu� acci�n realizar
	LDI		R16, 0x00
	SBIS	PINB, PB0			// Como para configurar reloj, se tienen 4 botones
	RJMP	INC_DISP1			// Solo se considera un botonazo a la vez
			
	SBIS	PINB, PB1			// Se revisan ambos botones
	RJMP	DEC_DISP1			// Solo se considera un botonazo a la vez
	
	SBIS	PINB, PB2			// Como para configurar reloj, se tienen 4 botones 
	RJMP	INC_DISP2			// Solo se considera un botonazo a la vez			
	
	SBIS	PINB, PB3			// Se revisan ambos botones
	RJMP	DEC_DISP2			// Solo se considera un botonazo a la vez	
	
	MOV		ACCION, R16			// R8 -> ACCION guardar� el valor de acci�n			
	RJMP	SALIR

INC_DISP1: 
	LDI		R16, 0x01			// Se enciende el indicador de que debe haber acci�n -> Inc Disp 1
	MOV		ACCION, R16
	RJMP	SALIR
DEC_DISP1: 
	LDI		R16, 0x02			// Se enciende el indicador de que debe haber acci�n -> Dec Disp 1
	MOV		ACCION, R16
	RJMP	SALIR
INC_DISP2: 
	LDI		R16, 0x03			// Se enciende el indicador de que debe haber acci�n -> Inc Disp 2
	MOV		ACCION, R16
	RJMP	SALIR
DEC_DISP2: 
	LDI		R16, 0x04			// Se enciende el indicador de que debe haber acci�n -> Dec Disp 2
	MOV		ACCION, R16
	RJMP	SALIR
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

// ----------------------------------------------- Encabezado ----------------------------------------------- // 

.include "M328PDEF.inc"				// Incluye definiciones del ATMega328
.equ	VALOR_T1 = 0x1B1E
//.equ	VALOR_T1 = 0xFF50
.equ	VALOR_T0 = 0xB2
.def	ACCION = R21
.cseg									// Codigo en la flash

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
MESES:		.DB	0x31, 0x28, 0x31, 0x30, 0x31, 0x30, 0x31, 0x31, 0x30, 0x31, 0x30, 0x31

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
	LDI		R16, (0 << PB1) | (0 << PB2) | (0 << PB4)	// Se configura PB1, PB2 y PB4 como entradas y PB5/PB3/PB1 como salida (0010 1010)
	OUT		DDRB, R16
	LDI		R16, (1 << PB0) | (1 << PB3) | (1 << PB5)	// Se configura PB1, PB2 y PB4 como entradas y PB5/PB3/PB1 como salida (0010 1010)
	OUT		DDRB, R16
	LDI		R16, (1 << PB1) | (1 << PB2) | (1 << PB4)
	OUT		PORTB, R16					// Habilitar pull-ups 
	CBI		PORTB, PB0					// Se le carga valor de 0 a PB0 (Salida apagada) 
	CBI		PORTB, PB3					// Se le carga valor de 0 a PB3 (Salida apagada)
	CBI		PORTB, PB5					// Se le carga valor de 0 a PB5 (Salida apagada)

// ------------------------------------Configuraci�n de interrupci�n para botones----------------------------------
	LDI		R16, (1 << PCINT1) | (1 << PCINT2) | (1 << PCINT4)	// Se seleccionan los bits de la m�scara (5)
	STS		PCMSK0, R16								// Bits habilitados (PB0, PB1, PB2, PB3 y PB4) por m�scara		

	LDI		R16, (1 << PCIE0)						// Habilita las interrupciones Pin-Change en PORTB
	STS		PCICR, R16								// "Avisa" al registros PCICR que se habilitan en PORTB
													// Da "permiso" "habilita"

//---------------------------------------------INICIALIZAR DISPLAY-------------------------------------------------
	CALL	INIT_DIS7
	
//---------------------------------------------------REGISTROS-----------------------------------------------------
	CLR		R4										// Registro para valores de Z
	CLR		R5										// Registro para unidades minutos alarma
	CLR		R3										// Registro para decenas minutos alarma
	CLR		R12										// Registro para unidades horas alarma
	CLR		R13										// Registro para decenas horas alarma
		  //R16 - MULTIUSOS GENERAL 
	LDI		R17, 0x00								// Registro para contador de MODOS
	LDI		R18, 0xFF								// Registro para guardar estado de botones
	LDI		R19, 0x00								// Registro para contador de unidades (minutos) display
	LDI		R20, 0x00								// Accion para timer
	LDI		R21, 0x00								// Registro para boton de accion
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
	// Revisa en qu� modo est� 
	CPI		R17, 0 
	BREQ	CALL_RELOJ_NORMAL
	CPI		R17, 1
	BREQ	CALL_FECHA_NORMAL
	CPI		R17, 2
	BREQ	CALL_CONFIG_MIN_RELOJ
	CPI		R17, 3
	BREQ	CALL_CONFIG_HOR_RELOJ
	CPI		R17, 4
	BREQ	CALL_CONFIG_MES_FECHA
	CPI		R17, 5
	BREQ	CALL_CONFIG_DIA_FECHA
	CPI		R17, 6
	BREQ	CALL_CONFIG_MIN_ALARMA
	CPI		R17, 7
	BREQ	CALL_CONFIG_HOR_ALARMA
	CPI		R17, 8 
	BREQ	CALL_APAGAR_ALARMA
	RJMP	MAIN

// Llama el modo para realizar acci�n
CALL_RELOJ_NORMAL:
	CALL	RELOJ_NORMAL
	RJMP	MAIN	
CALL_FECHA_NORMAL:
	CALL	FECHA_NORMAL
	RJMP	MAIN
CALL_CONFIG_MIN_RELOJ:
	CALL	CONFIG_MIN
	RJMP	MAIN
CALL_CONFIG_HOR_RELOJ:
	CALL	CONFIG_HOR
	RJMP	MAIN
CALL_CONFIG_MES_FECHA:
	CALL	CONFIG_MES
	RJMP	MAIN
CALL_CONFIG_DIA_FECHA:
	CALL	CONFIG_DIA
	RJMP	MAIN
CALL_CONFIG_MIN_ALARMA:
	CALL	CONFIG_MIN_ALARM
	RJMP	MAIN
CALL_CONFIG_HOR_ALARMA:
	CALL	CONFIG_HOR_ALARM
	RJMP	MAIN
CALL_APAGAR_ALARMA:
	CALL	ALARM_OFF
	RJMP	MAIN
// ---------------------------------------------- Subrutina de multiplexaci�n -----------------------------------
MULTIPLEX:
	CPI		R17, 0				// Modo reloj normal
	BREQ	MULTIPLEX_HORA		
	CPI		R17, 1				// Modo fecha normal
	BREQ	MULTIPLEX_FECHA
	CPI		R17, 2				// Modo config minutos
	BREQ	MULTIPLEX_HORA
	CPI		R17, 3				// Modo config horas
	BREQ	MULTIPLEX_HORA
	CPI		R17, 4				// Modo config mes
	BREQ	MULTIPLEX_FECHA
	CPI		R17, 5				// Modo config dias
	BREQ	MULTIPLEX_FECHA
	CPI		R17, 6				// Modo config min alarma
	BREQ	MULTIPLEX_ALARMA
	CPI		R17, 7				// Modo config horas alarma
	BREQ	MULTIPLEX_ALARMA
	CPI		R17, 8				// Modo apagar alarma
	BREQ	MULTIPLEX_ALARMA_OFF
	RET
MULTIPLEX_HORA: 
	// Se multiplexan displays
	MOV		R16, R24				// Se copia el valor de R24 (del timer0) 
	ANDI	R16, 0b00000011			// Se realiza un ANDI, con el prop�sito de multiplexar displays
	CPI		R16, 0 
	BREQ	MOSTRAR_UNI_MIN
	CPI		R16, 1
	BREQ	MOSTRAR_DEC_MIN
	CPI		R16, 2
	BREQ	MOSTRAR_UNI_HOR
	CPI		R16, 3
	BREQ	MOSTRAR_DEC_HOR
	RET
MULTIPLEX_FECHA:
	MOV		R16, R24				// Se copia el valor de R24 (del timer0)
	ANDI	R16, 0b00000011			// Se realiza un ANDI, con el prop�sito de multiplexar displays
	CPI		R16, 0 
	BREQ	MOSTRAR_UNIDAD_MES
	CPI		R16, 1
	BREQ	MOSTRAR_DECENA_MES
	CPI		R16, 2
	BREQ	MOSTRAR_UNIDAD_DIA
	CPI		R16, 3
	BREQ	MOSTRAR_DECENA_DIA
	RET
MULTIPLEX_ALARMA:
	MOV		R16, R24				// Se copia el valor de R24 (del timer0)
	ANDI	R16, 0b00000011			// Se realiza un ANDI, con el prop�sito de multiplexar displays
	CPI		R16, 0 
	BREQ	MOSTRAR_UNIDAD_MIN_AL
	CPI		R16, 1
	BREQ	MOSTRAR_DECENA_MIN_AL
	CPI		R16, 2
	BREQ	MOSTRAR_UNIDAD_HOR_AL
	CPI		R16, 3
	BREQ	MOSTRAR_DECENA_HOR_AL
	RET
MULTIPLEX_ALARMA_OFF:
	RJMP	MULTI_AL_OFF

// ---------------------------------------- Sub-rutinas para multiplexaci�n de displays -----------------------------------
MOSTRAR_UNI_MIN:
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	CBI		PORTC, PC0				// Habilitar transistor 1 - Unidades minutos
	// Mostrar unidades de minutos
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	ADD		ZL, R19					// Cargar el valor del contador de unidades a z
	LPM		R4, Z					// Guardar el valor de Z
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC0				// Habilitar transistor 1 - Unidades minutos
	OUT		PORTD, R4
	RET
MOSTRAR_DEC_MIN: 
	// Mostrar decenas de minutos
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	ADD		ZL, R22					// Cargar el valor del contador de unidades a z
	LPM		R4, Z					// Guardar el valor de Z
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC1				// Habilitar transistor 2 - Decenas minutos
	OUT		PORTD, R4
	RET

MOSTRAR_UNIDAD_MES:
	RJMP	MOSTRAR_UNI_MES
MOSTRAR_DECENA_MES:
	RJMP	MOSTRAR_DEC_MES
MOSTRAR_UNIDAD_DIA:
	RJMP	MOSTRAR_UNI_DIA
MOSTRAR_DECENA_DIA:
	RJMP	MOSTRAR_DEC_DIA

MOSTRAR_UNI_HOR: 
	// Mostrar decenas de horas
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	ADD		ZL, R23					// Cargar el valor del contador de unidades a z
	LPM		R4, Z					// Guardar el valor de Z
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC2				// Habilitar transistor 3 - Unidades horas
	OUT		PORTD, R4
	RET
MOSTRAR_DEC_HOR:  
	// Mostrar decenas de horas
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	ADD		ZL, R25					// Cargar el valor del contador de unidades a z
	LPM		R4, Z					// Guardar el valor de Z
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	SBI		PORTC, PC3				// Habilitar transistor 4 - Decenas horas
	OUT		PORTD, R4
	RET

MOSTRAR_UNIDAD_MIN_AL:
	RJMP	MOSTRAR_UNI_MIN_AL
MOSTRAR_DECENA_MIN_AL:
	RJMP	MOSTRAR_DEC_MIN_AL
MOSTRAR_UNIDAD_HOR_AL:
	RJMP	MOSTRAR_UNI_HOR_AL
MOSTRAR_DECENA_HOR_AL:
	RJMP	MOSTRAR_DEC_HOR_AL	

// Multiplexaci�n de fecha
MOSTRAR_UNI_MES:
	// Mostrar unidades de minutos
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	ADD		ZL, R28					// Cargar el valor del contador de unidades a z
	LPM		R4, Z					// Guardar el valor de Z
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC0				// Habilitar transistor 1 - Unidades minutos
	OUT		PORTD, R4
	RET
MOSTRAR_DEC_MES: 
	// Mostrar decenas de minutos
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	ADD		ZL, R29					// Cargar el valor del contador de unidades a z
	LPM		R4, Z					// Guardar el valor de Z
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC1				// Habilitar transistor 2 - Decenas minutos
	OUT		PORTD, R4
	RET
MOSTRAR_UNI_DIA: 
	// Mostrar decenas de horas
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	ADD		ZL, R26					// Cargar el valor del contador de unidades a z
	LPM		R4, Z					// Guardar el valor de Z
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC2				// Habilitar transistor 3 - Unidades horas
	OUT		PORTD, R4
	RET
MOSTRAR_DEC_DIA:  
	// Mostrar decenas de horas
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	ADD		ZL, R27					// Cargar el valor del contador de unidades a z
	LPM		R4, Z					// Guardar el valor de Z
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	SBI		PORTC, PC3				// Habilitar transistor 4 - Decenas horas
	OUT		PORTD, R4
	RET

// Multiplexaci�n para alarma
MOSTRAR_UNI_MIN_AL:
	// Mostrar unidades de minutos
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	ADD		ZL, R5					// Cargar el valor del contador de unidades a z
	LPM		R4, Z					// Guardar el valor de Z
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC0				// Habilitar transistor 1 - Unidades minutos
	OUT		PORTD, R4
	RET
MOSTRAR_DEC_MIN_AL: 
	// Mostrar decenas de minutos
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	ADD		ZL, R3					// Cargar el valor del contador de unidades a z
	LPM		R4, Z					// Guardar el valor de Z
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC1				// Habilitar transistor 2 - Decenas minutos
	OUT		PORTD, R4
	RET
MOSTRAR_UNI_HOR_AL: 
	// Mostrar decenas de horas
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	ADD		ZL, R12					// Cargar el valor del contador de unidades a z
	LPM		R4, Z					// Guardar el valor de Z
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC2				// Habilitar transistor 3 - Unidades horas
	OUT		PORTD, R4
	RET
MOSTRAR_DEC_HOR_AL:  
	// Mostrar decenas de horas
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	ADD		ZL, R13					// Cargar el valor del contador de unidades a z
	LPM		R4, Z					// Guardar el valor de Z
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	SBI		PORTC, PC3				// Habilitar transistor 4 - Decenas horas
	OUT		PORTD, R4
	RET

// Multiplexaci�n para modo de apagar alarma
MULTI_AL_OFF:
	MOV		R16, R24				// Se copia el valor de R24 (del timer0)
	ANDI	R16, 0b00000011			// Se realiza un ANDI, con el prop�sito de multiplexar displays
	CPI		R16, 0 
	BREQ	MOSTRAR_UNI_MIN_AL_OFF
	CPI		R16, 1
	BREQ	MOSTRAR_DEC_MIN_AL_OFF
	CPI		R16, 2
	BREQ	MOSTRAR_UNI_HOR_AL_OFF
	CPI		R16, 3
	BREQ	MOSTRAR_DEC_HOR_AL_OFF
	RET

MOSTRAR_UNI_MIN_AL_OFF:
	// Mostrar unidades de minutos
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC0				// Habilitar transistor 1 - Unidades minutos
	OUT		PORTD, R8
	RET
MOSTRAR_DEC_MIN_AL_OFF: 
	// Mostrar decenas de minutos
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC1				// Habilitar transistor 2 - Decenas minutos
	OUT		PORTD, R6
	RET
MOSTRAR_UNI_HOR_AL_OFF: 
	// Mostrar decenas de horas
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC3				// Se deshabilita transistor para PC3
	SBI		PORTC, PC2				// Habilitar transistor 3 - Unidades horas
	OUT		PORTD, R8
	RET
MOSTRAR_DEC_HOR_AL_OFF:  
	// Mostrar decenas de horas
	CBI		PORTC, PC0				// Se deshabilita transistor para PC0
	CBI		PORTC, PC1				// Se deshabilita transistor para PC1
	CBI		PORTC, PC2				// Se deshabilita transistor para PC2
	SBI		PORTC, PC3				// Habilitar transistor 4 - Decenas horas
	OUT		PORTD, R6
	RET

// -------------------------------------------------- MODOS --------------------------------------------------------
RELOJ_NORMAL: 
	// El modo reloj normal, �nicamente quiero que sume en reloj normal
	CBI		PORTC, PC4
	CBI		PORTC, PC5
	CBI		PORTB, PB3
	CPI		R20, 0x01				// Se compara bandera de activaci�n
	BRNE	NO_ES_EL_MODO			// Si no ha habido interrupci�n, sale
	LDI		R20, 0x00
	RJMP	CONTADOR				// Si hubo interrupci�n, va a la rutina para modificar el tiempo
	RET

FECHA_NORMAL: 
	SBI		PORTC, PC4
	CBI		PORTC, PC5
	CBI		PORTB, PB3
	CPI		R20, 0x01				// Se compara bandera de activaci�n
	BRNE	NO_ES_EL_MODO
	LDI		R20, 0x00				// Si hubo interrupci�n, va a la rutina para modificar el tiempo
	RJMP	CONTADOR
	RET
NO_ES_EL_MODO: 
	RET

CONFIG_MIN: 
	CBI		PORTC, PC4
	SBI		PORTC, PC5
	CBI		PORTB, PB3
	SBI		PORTB, PB0				// No se permite toggle en leds cada 500ms
	CPI		ACCION, 0x02			// Se revisa bandera de activaci�n
	BREQ	INC_MIN					// Dependiendo del valor de la bandera inc o dec
	CPI		ACCION, 0x03
	BREQ	DEC_MIN
	RET

CONFIG_HOR: 
	CBI		PORTC, PC4
	CBI		PORTC, PC5
	SBI		PORTB, PB3
	SBI		PORTB, PB0				// No se permite toggle en leds cada 500ms
	CPI		ACCION, 0x02			// Se revisa bandera de activaci�n
	BREQ	INC_HOR					// Dependiendo del valor de la bandera inc o dec
	CPI		ACCION, 0x03
	BREQ	DEC_HOR
	RET

CONFIG_MES:
	SBI		PORTC, PC4
	CBI		PORTC, PC5
	SBI		PORTB, PB3
	SBI		PORTB, PB0				// No se permite toggle en leds cada 500ms
	CPI		ACCION, 0x02			// Se revisa bandera de activaci�n
	BREQ	INC_MES					// Dependiendo del valor de la bandera inc o dec
	CPI		ACCION, 0x03
	BREQ	DEC_MES
	RET

CONFIG_DIA:
	SBI		PORTC, PC4
	SBI		PORTC, PC5
	CBI		PORTB, PB3
	SBI		PORTB, PB0				// No se permite toggle en leds cada 500ms
	CPI		ACCION, 0x02			// Se revisa bandera de activaci�n
	BREQ	INC_DIA					// Dependiendo del valor de la bandera inc o dec
	CPI		ACCION, 0x03
	BREQ	DEC_DIA
	RET

CONFIG_MIN_ALARM:
	CBI		PORTC, PC4
	SBI		PORTC, PC5
	SBI		PORTB, PB3
	CPI		ACCION, 0x02			// Se revisa bandera de activaci�n
	BREQ	INC_MIN_ALARM			// Dependiendo del valor de la bandera inc o dec
	CPI		ACCION, 0x03
	BREQ	DEC_MIN_ALARM
	RET

CONFIG_HOR_ALARM:
	SBI		PORTC, PC4
	SBI		PORTC, PC5
	SBI		PORTB, PB3
	CPI		ACCION, 0x02			// Se revisa bandera de activaci�n
	BREQ	INC_HOR_ALARM			// Dependiendo del valor de la bandera inc o dec
	CPI		ACCION, 0x03
	BREQ	DEC_HOR_ALARM
	RET

ALARM_OFF:
	CALL	SHOW_WAKE_UP
	CALL	TURN_ME_OFF
	RET
// -----------------------------------Subrutinas para ejecutar modos----------------------------------------------------
INC_MIN: 
	CALL	INC_DISP1
	LDI		ACCION, 0x00
	RET
DEC_MIN: 
	CALL	DEC_DISP1
	LDI		ACCION, 0x00
	RET
INC_HOR: 
	CALL	INC_DISP2
	LDI		ACCION, 0x00
	RET
DEC_HOR: 
	CALL	DEC_DISP2
	LDI		ACCION, 0x00
	RET

INC_MES: 
	CALL	INC_DISP_MES
	LDI		ACCION, 0x00
	RET
DEC_MES: 
	CALL	DEC_DISP_MES
	LDI		ACCION, 0x00
	RET
INC_DIA: 
	CALL	INC_DISP_DIA
	LDI		ACCION, 0x00
	RET
DEC_DIA: 
	CALL	DEC_DISP_DIA
	LDI		ACCION, 0x00
	RET

INC_MIN_ALARM:
	CALL	INC_DISP_MINAL
	LDI		ACCION, 0x00
	RET
DEC_MIN_ALARM:
	CALL	DEC_DISP_MINAL
	LDI		ACCION, 0x00
	RET
INC_HOR_ALARM:
	CALL	INC_DISP_HORAL
	LDI		ACCION, 0x00
	RET
DEC_HOR_ALARM:
	CALL	DEC_DISP_HORAL
	LDI		ACCION, 0x00
	RET

// --------------------------------------------------- Sub rutina para alarma ------------------------------------------
TAL_VEZ_WAKE_UP:
	// Se compara la hora de la alarma con la actual
	CP		R5, R19					// Comparamos unidades min
	BREQ	CONFIRMAR_DECENAS
	RET 

CONFIRMAR_DECENAS:
	CP		R3, R22					// Comparamos decenas min
	BREQ	CONFIRMAR_UNI_HRS
	RET

CONFIRMAR_UNI_HRS: 
	CP		R12, R23				// Comparamos unidades hrs
	BREQ	CONFIRMAR_DEC_HRS	
	RET

CONFIRMAR_DEC_HRS: 
	CP		R13, R25				// Comparamos decenas hrs
	BREQ	WAKE_UP
	
WAKE_UP: 
	SBI		PINB, PB5				// Se enciende la alarma
	RET

SHOW_WAKE_UP: 
	LDI		R16, 0x3E				// Valor para U
	MOV		R6, R16
	LDI		R16, 0x67				// Valor para P
	MOV		R8, R16					// Se mostrar� UP en modo apagar alarma
	RET
// --------------------------------------------------------- Apagar alarma ------------------------------------------------
TURN_ME_OFF: 
	SBIC	PINB, PB5				// Si est� apagada no hace nada
	SBI		PINB, PB5				// Si est� encendida la apaga
	RET	

// ------------------------------------------------- Subrutina para incrementar minutos ------------------------------------
INC_DISP1: 		
	INC		R19						// Incrementa el valor
	CPI		R19, 0x0A				// Compara el valor del contador 
    BREQ	OVER_DECENAS			// Si al comparar no es igual, salta a mostrarlo
	LPM		R4, Z
	RET					

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

// ------------------------------------------------ Subrutina para decrementar minutos --------------------------------------
DEC_DISP1: 
	DEC		R19						// R19 decrementar�
	CPI		R19, 0xFF				// Si el contador llega a 0, reiniciar el contador
	BREQ	RESET_MINUTOS			// Si es igual a 0 no hace nada y vuelve a main
	RET					// Regresa a main si ya decremento

RESET_MINUTOS: 
	LDI		R19, 0x09
	DEC		R22
	CPI		R22, 0xFF
	BREQ	RESET_DECENAS
	RET

RESET_DECENAS:
	LDI		R22, 0x05
	RET

// ----------------------------------------------- Subrutina para incrementar horas --------------------------------------------
INC_DISP2: 	
	CPI		R25, 0x02				// Compara valor de decenas de horas
	BREQ	LLEGA_24				// Revisa si llega a 20 y salta				
	RJMP	FORMATO24		

LLEGA_24: 
	CPI		R23, 0x03				// Compara para lograr formato de 24 horas
	BREQ	OVF_UNI_HORA	
	RJMP	FORMATO24				// Resetea contador de unidades de horas	

FORMATO24: 
	INC		R23
	CPI		R23, 0x0A
	BRNE	SALIR2
	LDI		R23, 0x00
	INC		R25
	RJMP	SALIR2

OVF_UNI_HORA: 
	LDI		R23, 0x00				// Resetea las unidades de las horas
	LDI		R25, 0x00				// Incrementa las decenas de horas
	RJMP	SALIR2

SALIR2: 
	RET

// ------------------------------------------------- Subrutina para decrementar horas ------------------------------------------
DEC_DISP2: 
	// Decrementar horas	
	CPI		R25, 0x00
	BREQ	REVISAR_UNI
	RJMP	DEC_HOURS

REVISAR_UNI: 
	CPI		R23, 0x00
	BREQ	RESET_DECENAS2
	RJMP	DEC_HOURS

DEC_HOURS: 
	DEC		R23						// R23 decrementar�
	CPI		R23, 0xFF				// Si el contador llega a 0, reiniciar el contador
	BRNE	SEGUIR2
	LDI		R23, 0x09
	DEC		R25						// Si es igual a 0 no hace nada y vuelve a main
	RET								// Regresa a main si ya decremento

RESET_DECENAS2:
	LDI		R23, 0x03
	LDI		R25, 0x02				// Compara valor de decenas de horas		
	RET	

SEGUIR2:
	RET

// --------------------------------------------------- Se incrementan los d�as ---------------------------------------------------
INC_DISP_DIA:
	INC		R26						// Se incrementan las unidades de d�as
	CPI		R26, 0x0A				// Se compara para saber si lleg� a 10
	BREQ	INC_DEC_DIAS			// Si es 10, se incrementan las decenas
	CALL	VERIFY_DIAS				// Revisa que la cantidad de d�as coincidan con el mes
	RET

INC_DEC_DIAS: 
	LDI		R26, 0x00				// Se reinicia el contador de unidades d�as
	INC		R27						// Se incrementan las decenas de d�as
	CPI		R27, 0x04				// Se compara con 4 porque el maximo de dec son 3
	BREQ	RESET_DIAS
	RET

RESET_DIAS:
	LDI		R27, 0x00				// Se reinician las decenas 
	LDI		R26, 0x01				// Se reinician los d�as a 1 (el mes empieza en dia 1) 
	RET

// ------------------------------------------------- Se decrementan los d�as ------------------------------------------------------
DEC_DISP_DIA:
	CPI		R27, 0x00				// Se revisan las decenas de los d�as
	BREQ	DEC_UNIDADES_DIAS
	RJMP	DEC_DEC_DIAS

DEC_UNIDADES_DIAS: 
	DEC		R26						// Se decrementan los d�as
	CPI		R26, 0x00				// Se revisa si los d�as hicieron underflow
	BREQ	AJUSTAR_MES				// Si hay underflow, se cargan los valores de d�as
	RET

DEC_DEC_DIAS:
	DEC		R26						// Si las decenas aun no son 0, decrementan unidades
	CPI		R26, 0xFF				// Se compara para saber si lleg� a 0
	BRNE	SALIR_DIAS				// Si aun no es 0, sigue
	LDI		R26, 0x09				// Se carga 9 a las unidades
	DEC		R27						// Se decrementan las decenas de d�as	
	RET

SALIR_DIAS:
		RET

AJUSTAR_MES: 
	LDI     ZL, LOW(MESES<<1)
    LDI     ZH, HIGH(MESES<<1)

	MOV		R6, R29					// Cargar decenas de mes
	LSL		R6						// Correr a la izq -> X*2
	MOV		R8, R6					// Se guarda el estado para poder sumar
	LSL		R6						// Correr a la izq -> X*4
	LSL		R6						// Correr a la izq -> X*8
	ADD		R6, R8					// Se suman para -> X*10 (Encontre decenas)
	// Encontrar unidad del mes
	MOV     R16, R28		        // Cargar unidades de mes
	ADD		R16, R6					// Se suma la decena con la unidad del mes
    DEC     R16                     // Restar 1 (la tabla empieza en 0)
    ADD     ZL, R16                 // Meter el �ndice a Z 
    LPM     R16, Z                  // Leer la cantidad de d�as del mes actual (Encuentro cuantos d�as hay)
	
	MOV		R27, R16				// Se copian los d�as a las decenas
	LSR		R27
	LSR		R27
	LSR		R27
	LSR		R27						// Se deja el valor de la decena como "unidad"
	ANDI	R16, 0x0F				// Solo se guardan las unidades
	MOV		R26, R16				// Se actualiza el valor de las unidades
	RET

// ------------------------------------------------- Se incrementan los meses -------------------------------------------------------
INC_DISP_MES:
	CPI		R29, 0x01				// Se revisa si ya lleg� a mes 20
	BREQ	REVISAR				
	RJMP	SEGUIR_MESES

REVISAR: 
	CPI		R28, 0x02				// Se revisa si lleg� al mes 13
	BREQ	RESET_MESES
	RJMP	SEGUIR_MESES

SEGUIR_MESES: 
	INC		R28						// Si ya pasaron los d�as, se incrementa el mes
	CPI		R28, 0x0A				// Se compara para ver si ya es 10
	BRNE	SALIR_MESES
	RJMP	INC_DECENAS_MES

SALIR_MESES: 
	RET

INC_DECENAS_MES: 
	LDI		R28, 0x00				// Resetear unidades del mes
	INC		R29						// Incrementar decenas mes
	RET

RESET_MESES: 
	LDI		R29, 0x00
	LDI		R28, 0x01				// Se reinician los meses al 1 (enero) 
	RET

VERIFY_DIAS:
    // Cargar la direcci�n de la tabla DIAS_POR_MES
    LDI     ZL, LOW(DIAS_POR_MES<<1)
    LDI     ZH, HIGH(DIAS_POR_MES<<1)

    // Calcular el �ndice del mes actual (mes - 1)
	MOV		R6, R29					// Cargar decenas de mes
	LSL		R6						// Correr a la izq -> X*2
	MOV		R8, R6					// Se guarda el estado para poder sumar
	LSL		R6						// Correr a la izq -> X*4
	LSL		R6						// Correr a la izq -> X*8
	ADD		R6, R8					// Se suman para -> X*10
	MOV     R16, R28		        // Cargar unidades de mes
	ADD		R16, R6					// Se suma la decena con la unidad del mes
    DEC     R16                     // Restar 1 (la tabla empieza en 0)
    ADD     ZL, R16                 // Meter el �ndice a Z
    LPM     R16, Z                  // Leer la cantidad de d�as del mes actual

    // Comparar d�as actuales con d�as del mes
    MOV     R10, R27		        // Cargar decenas de d�as
    LSL	    R10                     // Convertir decenas a unidades (2 -> 20)
								    // X*2 (Correr a la izquierda una vez)
    MOV		R11, R10				// Guardamos el resultado temporalmente
    LSL		R10						// X*4 (Otra vez a la izquierda)
    LSL	    R10						// X*8 (Otra vez a la izquierda)
    ADD		R10, R11				// (X*8) + (X*2) = X*10 
    ADD     R10, R26		        // Sumar unidades de d�as (20 + 5 = 25)
    CP      R10, R16                // Comparar con d�as del mes
    BRLO    FIN_VERIFY_DIAS_MES		// Si es menor, no hacer nada
    CALL    RESET_DIAS				// Si es igual o mayor, reiniciar d�as

FIN_VERIFY_DIAS_MES:
    RET

// -------------------------------------------------- Se decrementan los meses ----------------------------------------------------
DEC_DISP_MES:
	CPI		R29, 0x00				// Revisa si las decenas de mes son 0
	BREQ	REVISAR_UNI_MES			// Si s�, revisa si las unidades tambi�n son 0
	RJMP	DEC_MESESITO			// Sino, decrementa 

REVISAR_UNI_MES: 
	CPI		R28, 0x01
	BREQ	RESET_DECENAS_MES		// Si ambos son 0, entonces resetea meses
	RJMP	DEC_MESESITO			// Sino, sigue decrementando unidades

DEC_MESESITO: 
	DEC		R28						// R28 decrementar�
	CPI		R28, 0xFF				// Si el contador llega a 0, reiniciar el contador
	BRNE	SEGUIR3
	LDI		R28, 0x09				// Si es 0, lo regresa a 9
	DEC		R29						// Decrementa tambi�n las decenas
	RET								// Regresa a main si ya decremento

RESET_DECENAS_MES:
	LDI		R28, 0x02
	LDI		R29, 0x01				// Se corrigen valores para underflow		
	RET	

SEGUIR3:
	RET

// ------------------------------------------------------- Subrutina para configurar alarma -----------------------------------------------
// -------------------------------------------------------  Se incrementan minutos alarma -------------------------------------------------
INC_DISP_MINAL:
	MOV		R16, R5					// Se copia el valor de unidades min alarma
	INC		R16						// Incrementa el valor
	CPI		R16, 0x0A				// Compara el valor del contador 
    BREQ	OVF_DEC_AL				// Si al comparar no es igual, salta a mostrarlo
	MOV		R5, R16					// Actualizar el valor de unidades
	LPM		R4, Z
	RET								// Salir

OVF_DEC_AL:
    CLR		R5						// Resetea el contador de unidades a 0
	MOV		R16, R3					// Copia el valor de decenas de min alarma
	INC		R16						// Incrementamos el contador de decenas de minutos
	CPI		R16, 0x06				// Comparamos si ya es 6
	BREQ	RESETEO_MIN_AL			// Si no es 6, sigue para actualizar
	MOV		R3, R16					// Antes de salir, actualizar decenas de minutos
	RET

RESETEO_MIN_AL:
    LDI		R16, 0x00
	MOV		R5, R16					// Resetea el contador a 0
	MOV		R3, R16
	RET

// --------------------------------------------------- Subrutina para decrementar minutos alarma -------------------------------------------
DEC_DISP_MINAL:
	MOV		R16, R5					// Copiar el valor de R5
	DEC		R16						// "R5" decrementar�
	CPI		R16, 0xFF				// Si el contador llega a 0, reiniciar el contador
	BREQ	RESET_MINUTOS_AL		// Si es igual a 0 no hace nada y vuelve a main
	MOV		R5, R16					// Actualizar el valor para R5
	RET								// Regresa a main si ya decremento

RESET_MINUTOS_AL: 
	LDI		R16, 0x09
	MOV		R5, R16					// Si hay underflow, corrige el valor para unidades
	MOV		R16, R3					// Copiar valor de decenas para actualizarlo
	DEC		R16
	CPI		R16, 0xFF
	BREQ	RESET_DECENAS_AL
	MOV		R3, R16					// Si no ha topado sigue, se actualiza valor de decenas
	RET

RESET_DECENAS_AL:
	LDI		R16, 0x05
	MOV		R3, R16					// Se resetean decenas y se actualiza valor
	RET

// ------------------------------------------------------- Subrutina para incrementar horas alarma --------------------------------------------	
INC_DISP_HORAL:
	MOV		R16, R13				// Se copia el valor de decenas de horas
	CPI		R16, 0x02				// Compara valor de decenas de horas
	BREQ	LLEGA_24_AL				// Revisa si llega a 20 y salta				
	RJMP	FORMATO24_AL		

LLEGA_24_AL: 
	MOV		R13, R16				// Antes de modificar R16, se actualizan las decenas
	MOV		R16, R12				// Se copia el valor de unidades de horas
	CPI		R16, 0x03				// Compara para lograr formato de 24 horas
	BREQ	OVF_UNI_HORA_AL	
	RJMP	FORMATO24_AL			// Resetea contador de unidades de horas	

FORMATO24_AL: 
	MOV		R16, R12				// Se copia el valor de unidades para modificar
	INC		R16
	CPI		R16, 0x0A				// Se revisa si las unidades llegaron a 10
	MOV		R12, R16				// Se copia el valor actualizado para unidades
	BRNE	SALIR4
	MOV		R16, R12
	LDI		R16, 0x00				// Si llega a 10, limpia las unidades
	MOV		R12, R16				// Actualiza el valor de unidades
	MOV		R16, R13
	INC		R16						// Incrementa las decenas de horas
	MOV		R13, R16
	RJMP	SALIR4

OVF_UNI_HORA_AL: 
	LDI		R16, 0x00				// Resetea las horas
	MOV		R12, R16
	MOV		R13, R16				
	RJMP	SALIR4

SALIR4: 
	RET

// -------------------------------------------------------- Subrutina para decrementar horas alarma ----------------------------------------------
DEC_DISP_HORAL:	
	MOV		R16, R13				// Copiar valor de decenas horas
	CPI		R16, 0x00
	BREQ	REVISAR_UNI_AL
	RJMP	DEC_HOURS_AL

REVISAR_UNI_AL: 
	MOV		R16, R12				// Copiar el valor de unidades horas
	CPI		R16, 0x00
	BREQ	RESET_DECENAS2_AL
	RJMP	DEC_HOURS_AL

DEC_HOURS_AL: 
	MOV		R16, R12
	DEC		R16						// Decrementar� valor de unidades horas
	MOV		R12, R16				// Actualizar valor de unidades horas
	CPI		R16, 0xFF				// Si el contador llega a 0, reiniciar el contador
	BRNE	SEGUIR4
	LDI		R16, 0x09				// Si es 0, de carga el valor de 9 a las unidades
	MOV		R12, R16
	MOV		R16, R13
	DEC		R16						// Si es igual a 0 no hace nada y vuelve a main
	MOV		R13, R16				// Se actualiza el valor de decenas
	RET								// Regresa a main si ya decremento

RESET_DECENAS2_AL:
	LDI		R16, 0x03
	MOV		R12, R16
	LDI		R16, 0x02				
	MOV		R13, R16				// Se actualizan valores para las horas		
	RET	

SEGUIR4:
	RET

// Rutina de NO interrupci�n 
//---------------------------------------------------- INCREMENTA TIEMPO ------------------------------------------------
CONTADOR: 
	INC		R19						// Se aumenta el contador de unidades de minutos
	CPI		R19, 0x0A				// Se compara para ver si ya sum� 
    BREQ	DECENAS					// Si al comparar no es igual, salta a mostrarlo
	CALL	TAL_VEZ_WAKE_UP		
	RET

DECENAS:
	LDI		R19, 0x00				// Resetea el contador a 0
	INC		R22						// Incrementamos el contador de decenas de minutos
	CALL	TAL_VEZ_WAKE_UP	
	CPI		R22, 0x06				// Comparamos si ya es 6
	BREQ	HORAS					// Si no es 6, sigue para actualizar
	CALL	TAL_VEZ_WAKE_UP	
	RET

HORAS:
	LDI		R22, 0x00				// Resetea el contador de decenas de minutos
	CALL	TAL_VEZ_WAKE_UP	
	CPI		R25, 0x02				// Compara valor de decenas de horas
	BRNE	NO_TOPAMOS				// Salta a rutina normal		
	INC		R23
	CALL	TAL_VEZ_WAKE_UP	
	CPI		R23, 0x04				// Verifica el formato de 24 horas
	BRNE	SEGUIR			
	RJMP	YA_24
	RET		

NO_TOPAMOS: 
	INC		R23						// Incrementa el contador de unidades de horas
	CPI		R23, 0x0A				// Compara para lograr formato de 24 horas
	BRNE	SEGUIR	
	INC		R25
	LDI		R23, 0x00				// Resetea contador de unidades de horas
	CALL	TAL_VEZ_WAKE_UP		
	RET

SEGUIR: 
	CALL	TAL_VEZ_WAKE_UP	
	RET

YA_24: 
	LDI		R19, 0x00
	LDI		R22, 0x00
	LDI		R23, 0x00
	LDI		R25, 0x00
	CALL	TAL_VEZ_WAKE_UP	
	CALL	INIT_DIS7
	INC		R26						// Se incrementan las unidades de d�as
	CPI		R26, 0x0A				// Se compara para saber si lleg� a 10
	BREQ	INC_DECENAS_DIAS		// Si es 10, se incrementan las decenas
	CALL	VERIFICAR_DIAS			// Revisa que la cantidad de d�as coincidan con el mes
	RET

INC_DECENAS_DIAS: 
	LDI		R26, 0x00				// Se reinicia el contador de unidades d�as
	INC		R27						// Se incrementan las decenas de d�as
	CPI		R27, 0x04				// Se compara con 4 porque el maximo de dec son 3
	BREQ	REINICIAR_DIAS
	RET

REINICIAR_DIAS:
	LDI		R27, 0x00				// Se reinician las decenas 
	LDI		R26, 0x01				// Se reinician los d�as a 1 (el mes empieza en dia 1) 
	CALL	INCREMENTAR_MES
	RET

INCREMENTAR_MES: 
	CPI		R29, 0x01
	BREQ	REVISAR_MESES
	RJMP	SEGUIR_MES

REVISAR_MESES: 
	CPI		R28, 0x02
	BREQ	REINICIAR_MESES
	RJMP	SEGUIR_MES

SEGUIR_MES:
	INC		R28						// Si ya pasaron los d�as, se incrementa el mes
	CPI		R28, 0x0A				// Se compara para ver si ya es 10
	BRNE	FIN_VERIFICAR_DIAS_MES
	RJMP	INCREMENTAR_DECENAS_MES

INCREMENTAR_DECENAS_MES: 
	LDI		R28, 0x00				// Resetear unidades del mes
	INC		R29						// Incrementar decenas mes 
	RET

REINICIAR_MESES: 
	LDI		R29, 0x00
	LDI		R28, 0x01				// Se reinician los meses al 1 (enero) 
	RET

VERIFICAR_DIAS:
    // Cargar la direcci�n de la tabla DIAS_POR_MES
    LDI     ZL, LOW(DIAS_POR_MES<<1)
    LDI     ZH, HIGH(DIAS_POR_MES<<1)

    // Calcular el �ndice del mes actual (mes - 1)
    MOV		R6, R29					// Cargar decenas de mes
	LSL		R6						// Correr a la izq -> X*2
	MOV		R8, R6					// Se guarda el estado para poder sumar
	LSL		R6						// Correr a la izq -> X*4
	LSL		R6						// Correr a la izq -> X*8
	ADD		R6, R8					// Se suman para -> X*10
	MOV     R16, R28		        // Cargar unidades de mes
	ADD		R16, R6
    DEC     R16                     // Restar 1 (la tabla empieza en 0)
    ADD     ZL, R16                 // Meter el �ndice a Z
    LPM     R16, Z                  // Leer la cantidad de d�as del mes actual

    // Comparar d�as actuales con d�as del mes
    MOV     R10, R27		        // Cargar decenas de d�as
    LSL	    R10                     // Convertir decenas a unidades (2 -> 20)
								    // X*2 (Desplazar a la izquierda una vez)
    MOV		R11, R10				// Guardamos el resultado temporalmente
    LSL		R10						// X*4 (Otro desplazamiento a la izquierda)
    LSL	    R10						// X*8 (Otro desplazamiento a la izquierda, ahora es X*8)
    ADD		R10, R11				// (X*8) + (X*2) = X*10 
    ADD     R10, R26		        // Sumar unidades de d�as (20 + 5 = 25)
    CP      R10, R16                // Comparar con d�as del mes
    BRLO    FIN_VERIFICAR_DIAS_MES  // Si es menor, no hacer nada
    CALL    REINICIAR_DIAS          // Si es igual o mayor, reiniciar d�as

FIN_VERIFICAR_DIAS_MES:
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
	// Cargar valor inicial en TCNT1 para desborde cada 5 ms
	LDI		R16, (1<<CS01) | (1<<CS00)
	OUT		TCCR0B, R16					// Setear prescaler del TIMER 0 a 64
	LDI		R16, VALOR_T0				// Indicar desde donde inicia -> desborde cada 5 ms
	OUT		TCNT0, R16					// Cargar valor inicial en TCNT0

	RET

// -------------------------------------------- Se inicia tabla meses ---------------------------------------------------
INIT_DIS7:
	LDI		ZL, LOW(TABLITA<<1)
	LDI		ZH, HIGH(TABLITA<<1)
	LPM		R4, Z
	OUT		PORTD, R4
	RET
//------------------------------------------ Rutina de interrupci�n del timer0 -----------------------------------------
TIMER0_OVF: 	
	SBI		TIFR0, TOV0
	LDI		R16, VALOR_T0			// Se indica donde debe iniciar el TIMER
	OUT		TCNT0, R16				
	INC		R24						// R24 ser� un contador de la cant. de veces que lee el pin
	CPI		R24, 100				// Si ocurre 100 veces, ya pas� el tiempo para modificar los leds
	BREQ	TOGGLE	
	RETI

TOGGLE: 
	LDI		R24, 0x00			// Se reinicia el contador de desbordes	
	SBI		PINB, PB0			// Hace un toggle cada 500 ms para los leds
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
	BREQ	SALIR_NO_TIMER				// Hay modos en los que no quiero usar el timer, me salgo
	CPI		R17, 5
	BREQ	SALIR_NO_TIMER	
	
	LDI		R20, 0x01					// Se utilizar� R20 para "indicar" que se debe realizar algo
	RJMP	SALIR_NO_TIMER

// Rutina segura para salir -> reestablece valor de SREG
SALIR_NO_TIMER: 
	POP		R7
	OUT		SREG, R7
	POP		R7
	RETI

// --------------------------------------Rutina de interrupci�n para revisar PB ----------------------------------------
ISR_PCINT0: 
	// Guarda el estado del SREG
	PUSH	R7
	IN		R7, SREG
	PUSH	R7

	IN		R9, PINB			// Se lee el pin
	CP		R9, R18				// Se compara estado de los botones
	BREQ	SALIR				// Si siguen siendo iguales, es porque no hubo cambio
	MOV		R18, R9				// Copia el estado de botones

	// PB4 -> Modo | PB2 -> Incrementa | PB1 -> Decrementa 
	SBRS	R9, PB4				// Revisa activaci�n de boton de modo
	RJMP	CAMBIO_MODO
	RJMP	CHECK_MODE

CHECK_MODE:	
	CPI		R17, 0				// Revisa en qu� modo est�
	BREQ	ISR_RELOJ_NORMAL
	CPI		R17, 1
	BREQ	ISR_FECHA_NORMAL
	CPI		R17, 2
	BREQ	ISR_CONFIG_MIN
	CPI		R17, 3
	BREQ	ISR_CONFIG_HOR
	CPI		R17, 4	
	BREQ	ISR_CONFIG_MES
	CPI		R17, 5
	BREQ	ISR_CONFIG_DIA
	CPI		R17, 6	
	BREQ	ISR_CONFIG_MIN_ALARM
	CPI		R17, 7
	BREQ	ISR_CONFIG_HOR_ALARM
	CPI		R17, 8
	BREQ	ISR_APAGAR_ALARMA		
	RJMP	SALIR

// Revisa overflow modo
CAMBIO_MODO: 
	INC		R17
	CPI		R17, 0x09
	BREQ	OVER_MODO
	RJMP	SALIR
OVER_MODO: 
	LDI		R17, 0x00
	RJMP	SALIR

// Rutina segura para salir -> reestablece valor de SREG
SALIR: 
	POP		R7
	OUT		SREG, R7
	POP		R7
	RETI

ISR_RELOJ_NORMAL:
	// El modo reloj normal, �nicamente quiero que sume en reloj normal
	RJMP	SALIR
ISR_FECHA_NORMAL: 
	// El modo reloj normal, �nicamente quiero que sume en reloj normal
	RJMP	SALIR

ISR_CONFIG_MIN:
	// Se revisan los pb, dependiendo de si se activan se sabr� qu� acci�n realizar
	SBIS	PINB, PB2			// Revisa activaci�n de bot�n inc
	RJMP	ACT_INC
	SBIS	PINB, PB1			// Revisa activaci�n de bot�n dec
	RJMP	ACT_DEC
	RJMP	SALIR

ISR_CONFIG_HOR:
	// Se revisan los pb, dependiendo de si se activan se sabr� qu� acci�n realizar
	SBIS	PINB, PB2			// Revisa activaci�n de bot�n inc
	RJMP	ACT_INC
	SBIS	PINB, PB1			// Revisa activaci�n de bot�n dec
	RJMP	ACT_DEC
	RJMP	SALIR

ACT_INC: 
	SBIS	PINB, PB2			// Revisa si est� presionado (0 -> apachado)
	LDI		ACCION, 0x02		// Activa acci�n para PB0
	RJMP	SALIR

ACT_DEC: 
	SBIS	PINB, PB1			// Revisa si est� presionado (0 -> apachado)
	LDI		ACCION, 0x03		// Activa acci�n para PB0
	RJMP	SALIR

ISR_CONFIG_MES: 
	// El modo reloj normal, �nicamente quiero que sume en reloj normal	
	SBIS	PINB, PB2			// Revisa activaci�n de bot�n inc
	RJMP	ACT_INC
	SBIS	PINB, PB1			// Revisa activaci�n de bot�n dec
	RJMP	ACT_DEC
	RJMP	SALIR

ISR_CONFIG_DIA: 
	// Se revisan los pb, dependiendo de si se activan se sabr� qu� acci�n realizar		
	SBIS	PINB, PB2			// Revisa activaci�n de bot�n inc
	RJMP	ACT_INC
	SBIS	PINB, PB1			// Revisa activaci�n de bot�n dec
	RJMP	ACT_DEC
	RJMP	SALIR

ISR_CONFIG_MIN_ALARM: 
	// Se revisan los pb, dependiendo de si se activan se sabr� qu� acci�n realizar		
	SBIS	PINB, PB2			// Revisa activaci�n de bot�n inc
	RJMP	ACT_INC
	SBIS	PINB, PB1			// Revisa activaci�n de bot�n dec
	RJMP	ACT_DEC
	RJMP	SALIR

ISR_CONFIG_HOR_ALARM: 
	// Se revisan los pb, dependiendo de si se activan se sabr� qu� acci�n realizar		
	SBIS	PINB, PB2			// Revisa activaci�n de bot�n inc
	RJMP	ACT_INC
	SBIS	PINB, PB1			// Revisa activaci�n de bot�n dec
	RJMP	ACT_DEC
	RJMP	SALIR

ISR_APAGAR_ALARMA: 
	// El modo reloj normal, �nicamente quiero que sume en reloj normal	
	RJMP	SALIR
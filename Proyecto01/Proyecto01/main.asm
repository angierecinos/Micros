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
.equ	VALOR_T1 = 0x1B1E
//.equ	VALOR_T1 = 0xFF50
.equ	VALOR_T0 = 0xB2
.def	ACCION = R21
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
	LDI		R16, (0 << PB1) | (0 << PB2) | (0 << PB4)	// Se configura PB1, PB2 y PB4 como entradas y PB5/PB3/PB1 como salida (0010 1010)
	OUT		DDRB, R16
	LDI		R16, (1 << PB0) | (1 << PB3) | (1 << PB5)	// Se configura PB1, PB2 y PB4 como entradas y PB5/PB3/PB1 como salida (0010 1010)
	OUT		DDRB, R16
	LDI		R16, (1 << PB1) | (1 << PB2) | (1 << PB4)
	OUT		PORTB, R16					// Habilitar pull-ups 
	CBI		PORTB, PB0					// Se le carga valor de 0 a PB0 (Salida apagada) 
	CBI		PORTB, PB3					// Se le carga valor de 0 a PB3 (Salida apagada)
	CBI		PORTB, PB5					// Se le carga valor de 0 a PB5 (Salida apagada)

// ------------------------------------Configuración de interrupción para botones----------------------------------
	LDI		R16, (1 << PCINT1) | (1 << PCINT2) | (1 << PCINT4)	// Se seleccionan los bits de la máscara (5)
	STS		PCMSK0, R16								// Bits habilitados (PB0, PB1, PB2, PB3 y PB4) por máscara		

	LDI		R16, (1 << PCIE0)						// Habilita las interrupciones Pin-Change en PORTB
	STS		PCICR, R16								// "Avisa" al registros PCICR que se habilitan en PORTB
													// Da "permiso" "habilita"

//---------------------------------------------INICIALIZAR DISPLAY-------------------------------------------------
	CALL	INIT_DIS7
	
//---------------------------------------------------REGISTROS-----------------------------------------------------
	CLR		R4
	CLR		R5
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
	LDI		R26, 0x01								// Registro para contador de unidades (días)
	LDI		R27, 0x00								// Registro para contador de decenas (días)
	LDI		R28, 0x01								// Registro para contador de unidades (meses)
	LDI		R29, 0x00								// Registro para contador de decenas (meses)
	SEI												// Se habilitan interrupciones globales

// Loop principal
MAIN:  
	CALL	MULTIPLEX
	// Se revisa el modo en el que está
	//CPI		ACCION, 0x01					// Si se activa botón, se cambia de modo
	//BREQ	MODOS
	
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
	BREQ	CALL_CONFIG_ALARMA
	CPI		R17, 7 
	BREQ	CALL_APAGAR_ALARMA
	
	RJMP	MAIN

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
CALL_CONFIG_ALARMA:
	CALL	CONFIG_ALARM
	RJMP	MAIN
CALL_APAGAR_ALARMA:
	CALL	ALARM_OFF
	RJMP	MAIN

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
	RET
MULTIPLEX_HORA: 
	// Se multiplexan displays
	MOV		R16, R24				// Se copia el valor de R24 (del timer0) 
	ANDI	R16, 0b00000011			// Se realiza un ANDI, con el propósito de multiplexar displays
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
	ANDI	R16, 0b00000011			// Se realiza un ANDI, con el propósito de multiplexar displays
	CPI		R16, 0 
	BREQ	MOSTRAR_UNIDAD_MES
	CPI		R16, 1
	BREQ	MOSTRAR_DECENA_MES
	CPI		R16, 2
	BREQ	MOSTRAR_UNIDAD_DIA
	CPI		R16, 3
	BREQ	MOSTRAR_DECENA_DIA
	RET

// Sub-rutinas para multiplexación de displays
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

MOSTRAR_UNIDAD_DIA:
	RJMP	MOSTRAR_UNI_DIA
MOSTRAR_DECENA_DIA:
	RJMP	MOSTRAR_DEC_DIA
	
	// Sub-rutinas para multiplexación de displays
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

RELOJ_NORMAL: 
	// El modo reloj normal, únicamente quiero que sume en reloj normal
	CBI		PORTC, PC4
	CBI		PORTC, PC5
	CBI		PORTB, PB3
	CPI		R20, 0x01
	BRNE	NO_ES_EL_MODO
	LDI		R20, 0x00
	RJMP	CONTADOR
	RET

FECHA_NORMAL: 
	SBI		PORTC, PC4
	CBI		PORTC, PC5
	CBI		PORTB, PB3
	SBI		PORTB, PB0
	CPI		R20, 0x01
	BRNE	NO_ES_EL_MODO
	LDI		R20, 0x00
	RJMP	CONTADOR
	RET

CONFIG_MIN: 
	CBI		PORTC, PC4
	CBI		PORTC, PC5
	SBI		PORTB, PB3
	SBI		PORTB, PB0
	CPI		ACCION, 0x02
	BREQ	INC_MIN
	CPI		ACCION, 0x03
	BREQ	DEC_MIN
	RET

CONFIG_HOR: 
	CBI		PORTC, PC4
	SBI		PORTC, PC5
	CBI		PORTB, PB3
	CPI		ACCION, 0x02
	BREQ	INC_HOR
	CPI		ACCION, 0x03
	BREQ	DEC_HOR
	RET

CONFIG_MES:
	SBI		PORTC, PC4
	SBI		PORTC, PC5
	CBI		PORTB, PB3
	CPI		ACCION, 0x02
	BREQ	INC_MES
	CPI		ACCION, 0x03
	BREQ	DEC_MES
	RET
CONFIG_DIA:
	CBI		PORTC, PC4
	SBI		PORTC, PC5
	SBI		PORTB, PB3
	CPI		ACCION, 0x02
	BREQ	INC_DIA
	CPI		ACCION, 0x03
	BREQ	DEC_DIA
	RET

CONFIG_ALARM:
	RET
ALARM_OFF:
	RET

NO_ES_EL_MODO: 
	RET

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

// Subrutina para incrementar minutos
INC_DISP1: 		
	INC		R19						// Incrementa el valor
	CPI		R19, 0x0A				// Compara el valor del contador 
    BREQ	OVER_DECENAS			// Si al comparar no es igual, salta a mostrarlo
	LPM		R4, Z
	RET					// Vuelve r

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

// Subrutina para decrementar minutos
DEC_DISP1: 
	DEC		R19						// R19 decrementará
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

// Subrutina para incrementar horas
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

// Subrutina para decrementar horas
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
	DEC		R23						// R23 decrementará
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

// Se incrementan los días 
INC_DISP_DIA:
	INC		R26						// Se incrementan las unidades de días
	CPI		R26, 0x0A				// Se compara para saber si llegó a 10
	BREQ	INC_DEC_DIAS		// Si es 10, se incrementan las decenas
	CALL	VERIFY_DIAS			// Revisa que la cantidad de días coincidan con el mes
	RET

INC_DEC_DIAS: 
	LDI		R26, 0x00				// Se reinicia el contador de unidades días
	INC		R27						// Se incrementan las decenas de días
	CPI		R27, 0x04				// Se compara con 4 porque el maximo de dec son 3
	BREQ	RESET_DIAS
	RET

RESET_DIAS:
	LDI		R27, 0x00				// Se reinician las decenas 
	LDI		R26, 0x01				// Se reinician los días a 1 (el mes empieza en dia 1) 
	RET

DEC_DISP_DIA:
	RET

// Se incrementan los meses
INC_DISP_MES:
	CPI		R29, 0x01				// Se revisa si ya llegó a mes 20
	BREQ	REVISAR				
	RJMP	SEGUIR_MESES

REVISAR: 
	CPI		R28, 0x02				// Se revisa si llegó al mes 13
	BREQ	RESET_MESES
	RJMP	SEGUIR_MESES

SEGUIR_MESES: 
	INC		R28						// Si ya pasaron los días, se incrementa el mes
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
    // Cargar la dirección de la tabla DIAS_POR_MES
    LDI     ZL, LOW(DIAS_POR_MES<<1)
    LDI     ZH, HIGH(DIAS_POR_MES<<1)

    // Calcular el índice del mes actual (mes - 1)
	MOV		R6, R29					// Cargar decenas de mes
	LSL		R6						// Correr a la izq -> X*2
	MOV		R8, R6					// Se guarda el estado para poder sumar
	LSL		R6						// Correr a la izq -> X*4
	LSL		R6						// Correr a la izq -> X*8
	ADD		R6, R8					// Se suman para -> X*10
	MOV     R16, R28		        // Cargar unidades de mes
	ADD		R16, R6					// Se suma la decena con la unidad del mes
    DEC     R16                     // Restar 1 (la tabla empieza en 0)
    ADD     ZL, R16                 // Meter el índice a Z
    LPM     R16, Z                  // Leer la cantidad de días del mes actual

    // Comparar días actuales con días del mes
    MOV     R10, R27		        // Cargar decenas de días
    LSL	    R10                     // Convertir decenas a unidades (2 -> 20)
								    // X*2 (Desplazar a la izquierda una vez)
    MOV		R11, R10				// Guardamos el resultado temporalmente
    LSL		R10						// X*4 (Otro desplazamiento a la izquierda)
    LSL	    R10						// X*8 (Otro desplazamiento a la izquierda, ahora es X*8)
    ADD		R10, R11				// (X*8) + (X*2) = X*10 
    ADD     R10, R26		        // Sumar unidades de días (20 + 5 = 25)
    CP      R10, R16                // Comparar con días del mes
    BRLO    FIN_VERIFY_DIAS_MES  // Si es menor, no hacer nada
    CALL    RESET_DIAS          // Si es igual o mayor, reiniciar días

FIN_VERIFY_DIAS_MES:
    RET

DEC_DISP_MES:

	RET

// Rutina de NO interrupción 
//----------------------------------------------------INCREMENTA DISPLAY------------------------------------------------
CONTADOR: 
	INC		R19						// Se aumenta el contador de unidades de minutos
	CPI		R19, 0x0A				// Se compara para ver si ya sumó 
    BREQ	DECENAS					// Si al comparar no es igual, salta a mostrarlo		
	RET

DECENAS:
	LDI		R19, 0x00				// Resetea el contador a 0
	INC		R22						// Incrementamos el contador de decenas de minutos
	CPI		R22, 0x06				// Comparamos si ya es 6
	BREQ	HORAS					// Si no es 6, sigue para actualizar
	RET

HORAS:
	LDI		R22, 0x00				// Resetea el contador de decenas de minutos
	CPI		R25, 0x02				// Compara valor de decenas de horas
	BRNE	NO_TOPAMOS				// Salta a rutina normal		
	INC		R23
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
	RET

SEGUIR: 
	RET

YA_24: 
	LDI		R19, 0x00
	LDI		R22, 0x00
	LDI		R23, 0x00
	LDI		R25, 0x00
	CALL	INIT_DIS7
	INC		R26						// Se incrementan las unidades de días
	CPI		R26, 0x0A				// Se compara para saber si llegó a 10
	BREQ	INC_DECENAS_DIAS		// Si es 10, se incrementan las decenas
	CALL	VERIFICAR_DIAS			// Revisa que la cantidad de días coincidan con el mes
	RET

INC_DECENAS_DIAS: 
	LDI		R26, 0x00				// Se reinicia el contador de unidades días
	INC		R27						// Se incrementan las decenas de días
	CPI		R27, 0x04				// Se compara con 4 porque el maximo de dec son 3
	BREQ	REINICIAR_DIAS
	RET

REINICIAR_DIAS:
	LDI		R27, 0x00				// Se reinician las decenas 
	LDI		R26, 0x01				// Se reinician los días a 1 (el mes empieza en dia 1) 
	CALL	INCREMENTAR_MES
	RET

INCREMENTAR_MES: 
	INC		R28						// Si ya pasaron los días, se incrementa el mes
	CPI		R28, 0x0A				// Se compara para ver si ya es 10
	BREQ	INCREMENTAR_DECENAS_MES
	RET

INCREMENTAR_DECENAS_MES: 
	LDI		R28, 0x00				// Resetear unidades del mes
	INC		R29						// Incrementar decenas mes
	CPI		R29, 0x02				// No hay mas de 12 meses
	BREQ	REINICIAR_MESES			// Si se cumplen los 12 meses, se reinicia
	RET

REINICIAR_MESES: 
	LDI		R29, 0x00
	LDI		R28, 0x01				// Se reinician los meses al 1 (enero) 
	RET

VERIFICAR_DIAS:
    // Cargar la dirección de la tabla DIAS_POR_MES
    LDI     ZL, LOW(DIAS_POR_MES<<1)
    LDI     ZH, HIGH(DIAS_POR_MES<<1)

    // Calcular el índice del mes actual (mes - 1)
    MOV     R16, R28		        // Cargar unidades de mes
    DEC     R16                     // Restar 1 (la tabla empieza en 0)
    ADD     ZL, R16                 // Meter el índice a Z
    LPM     R16, Z                  // Leer la cantidad de días del mes actual

    // Comparar días actuales con días del mes
    MOV     R10, R27		        // Cargar decenas de días
    LSL	    R10                     // Convertir decenas a unidades (2 -> 20)
								    // X*2 (Desplazar a la izquierda una vez)
    MOV		R11, R10				// Guardamos el resultado temporalmente
    LSL		R10						// X*4 (Otro desplazamiento a la izquierda)
    LSL	    R10						// X*8 (Otro desplazamiento a la izquierda, ahora es X*8)
    ADD		R10, R11				// (X*8) + (X*2) = X*10 
    ADD     R10, R26		        // Sumar unidades de días (20 + 5 = 25)
    CP      R10, R16                // Comparar con días del mes
    BRLO    FIN_VERIFICAR_DIAS_MES  // Si es menor, no hacer nada
    CALL    REINICIAR_DIAS          // Si es igual o mayor, reiniciar días

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
	LPM		R4, Z
	OUT		PORTD, R4
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
	SBI		PINB, PB0			// Hace un toggle cada 500 ms para los leds
	RETI

//------------------------------------------ Rutina de interrupción del timer01 -----------------------------------------
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
	
	LDI		R20, 0x01			// Se utilizará R8 para "indicar" que se debe realizar algo
	RJMP	SALIR_NO_TIMER
	//RJMP	CONTADOR	// Vamos a quitar esto de la interrupción...

// Rutina segura para salir -> reestablece valor de SREG
SALIR_NO_TIMER: 
	POP		R7
	OUT		SREG, R7
	POP		R7
	RETI

// --------------------------------------Rutina de interrupción para revisar PB ----------------------------------------
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
	SBRS	R9, PB4				// Revisa activación de boton de modo
	RJMP	CAMBIO_MODO
	RJMP	CHECK_MODE

CHECK_MODE:	
	CPI		R17, 0				// Revisa en qué modo está
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
	RJMP	SALIR

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
	// El modo reloj normal, únicamente quiero que sume en reloj normal
	RJMP	SALIR
ISR_FECHA_NORMAL: 
	// El modo reloj normal, únicamente quiero que sume en reloj normal
	RJMP	SALIR

ISR_CONFIG_MIN:
	// Se revisan los pb, dependiendo de si se activan se sabrá qué acción realizar
	SBIS	PINB, PB2			// Revisa activación de botón inc
	RJMP	ACT_INC
	SBIS	PINB, PB1			// Revisa activación de botón dec
	RJMP	ACT_DEC
	RJMP	SALIR

ISR_CONFIG_HOR:
	// Se revisan los pb, dependiendo de si se activan se sabrá qué acción realizar
	SBIS	PINB, PB2			// Revisa activación de botón inc
	RJMP	ACT_INC
	SBIS	PINB, PB1			// Revisa activación de botón dec
	RJMP	ACT_DEC
	RJMP	SALIR

ACT_INC: 
	SBIS	PINB, PB2			// Revisa si está presionado (0 -> apachado)
	LDI		ACCION, 0x02		// Activa acción para PB0
	RJMP	SALIR

ACT_DEC: 
	SBIS	PINB, PB1			// Revisa si está presionado (0 -> apachado)
	LDI		ACCION, 0x03		// Activa acción para PB0
	RJMP	SALIR

ISR_CONFIG_MES: 
	// El modo reloj normal, únicamente quiero que sume en reloj normal	
	SBIS	PINB, PB2			// Revisa activación de botón inc
	RJMP	ACT_INC
	SBIS	PINB, PB1			// Revisa activación de botón dec
	RJMP	ACT_DEC
	RJMP	SALIR

ISR_CONFIG_DIA: 
	// Se revisan los pb, dependiendo de si se activan se sabrá qué acción realizar		
	SBIS	PINB, PB2			// Revisa activación de botón inc
	RJMP	ACT_INC
	SBIS	PINB, PB1			// Revisa activación de botón dec
	RJMP	ACT_DEC
	RJMP	SALIR

ISR_APAGAR_ALARMA: 
	// El modo reloj normal, únicamente quiero que sume en reloj normal	
	RJMP	SALIR

ISR_CONFIG_ALARMA: 
	// Se revisan los pb, dependiendo de si se activan se sabrá qué acción realizar		
	RJMP	SALIR

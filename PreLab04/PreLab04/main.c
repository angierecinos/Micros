/*
 * PreLab04.c
 ;
 ;
 ; Universidad del Valle de Guatemala
 ; Departamento de Ingenieria Mecatronica, Electronica y Biomedica
 ; IE2023 Semestre 1 2025
 ;
 ; Created: 28/03/2025
 ; Author : Angie Recinos
 ; Carnet : 23294
 ; Descripción: El código será un contador binario de 8 bits
 */ 

// Encabezado (Libraries)
#define F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>

#define BTN_INC		(1 << PB0)  // Botón de incremento
#define BTN_DEC		(1 << PB1)  // Botón de decremento
#define DISP1		(1 << PC0)  // Control de primer display
#define DISP2		(1 << PC1)  // Control de segundo display
#define MOST_CONT	(1 << PC2)	// Control de muestreo contador

uint8_t contador = 0;
uint8_t contador_5ms;
uint8_t verify_button = 0;

// Function prototypes
void setup();
void initTMR0(); 


// Non-interupt
void setup ()
{
	cli();
	
	// Configurar prescaler de sistemas
	CLKPR	=	(1 << CLKPCE);								// Habilita cambios en prescaler
	CLKPR	=	(1 << CLKPS2);								// Setea prescaler a 16 para 1MHz
	
	DDRB	&= ~(BTN_INC | BTN_DEC);						// PB0 y PB1 como entradas
	PORTB	|=	(BTN_INC | BTN_DEC);						// Activar pull-ups internos

	DDRC	|=	(DISP1 | DISP2 | MOST_CONT);				// PC0, PC1 y PC2 como salidas
	PORTC	&= ~(DISP1 | DISP2 | MOST_CONT);				// Apagar displays y control de muestreo

	DDRD	=	0xFF;										// PORTD como salida para los segmentos del display
	
	// Configurar interrupciones de cambio de pin
	PCICR	|= (1 << PCIE0);								// Habilitar interrupciones para PCINT0 (PB0 y PB1)
	PCMSK0	|= (1 << PCINT0) | (1 << PCINT1);				// Habilitar interrupciones para PB0 (PCINT0) y PB1 (PCINT1)
	
	UCSR0B	=	0x00;										// Apaga serial
	
	//initTMR0();												// Iniciar timer
	
	sei();
}

/*void initTMR0()
{
	TCCR0A	=	0;	TCCR0B |=	(1 << CS01) | (1 << CS00);		// Setear prescaler a 64	TCNT0	=	178;							// Cargar valor para delay de 5ms	TIMSK0	=	(1 << TOIE0);
}*/

// Main
int main(void)
{
	setup();
	/* Replace with your application code */
	while (1)
	{
		// Encender el transistor para mostrar el contador
		PORTC |= MOST_CONT;  // Enciende el transistor en PC2 (para muestreo de contador)
		
		// Mostrar el valor del contador en PORTD
		PORTD = contador;  // Muestra el valor del contador en los 8 bits de PORTD
	}
}

//------------------------ Interrupt routines ------------------------
/*ISR(TIMER0_OVF_vect)
{
	TCNT0 = 178;
	contador_5ms++;
	if (contador_5ms == 50)
	{
		PORTB++;		PORTB &= 0x0F;		contador_5ms = 0;
	}
}*/

// Interrupción por cambio en botones
ISR(PCINT0_vect) { 
	if (!(PINB & BTN_INC)) {
		if (contador < 255)			// Revisa si aún no es 255
		{
			contador++;
		} else {
			contador = 0;			// Si hay overflow se regresa a 0
		}	
	}
	if (!(PINB & BTN_DEC)) {
		if (contador > 0)			// Revisa si ya pasó del valor mínimo
		{
			contador--;
		} else {
			contador = 255;			// Si hay underflow regresa a 255
		}
	}
}
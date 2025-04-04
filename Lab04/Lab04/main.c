/*
 * Lab04.c
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
#include <util/delay.h>

#define BTN_INC		(1 << PORTB0)  // Botón de incremento
#define BTN_DEC		(1 << PORTB1)  // Botón de decremento
#define DISP1		(1 << PORTC0)  // Control de primer display
#define DISP2		(1 << PORTC1)  // Control de segundo display
#define MOST_CONT	(1 << PORTC2)	// Control de muestreo contador

uint8_t contador = 0;
uint8_t contador_5ms = 0;
uint8_t verify_button = 0;
uint8_t previous_state = 0xFF; 
uint8_t current_state = 0xFF; 
int tabla_7seg[16] = {0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0X5F, 0x70, 0x7F, 0X7B, 0x77, 0x1F, 0x4E, 0x3D, 0x4F, 0x47};
uint8_t lectura_adc; 
uint8_t dig_1;
uint8_t dig_2; 

// Function prototypes
void setup();
void initTMR0(); 
void initADC();


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
	
	initADC();
	initTMR0();												// Iniciar timer
	
	ADCSRA |= (1 << ADSC);
	
	sei();
}

// Main
int main(void)
{
	setup();
	while (1)
	{
	}
}

void initTMR0()
{
	TCCR0A	=	0;	TCCR0B |=	(1 << CS01) | (1 << CS00);		// Setear prescaler a 64	TCNT0	=	200;							// Cargar valor para delay de 5ms	TIMSK0	=	(1 << TOIE0);
}

void initADC()
{
	ADMUX	= 0;
	ADMUX	|= (1 << REFS0);	//ADMUX &= ~(1<< REFS1); // Se ponen los 5V como ref
	
	ADMUX	|= (1 << ADLAR);					// Justificación a la izquierda
	ADMUX	|= (1 << MUX1) | (1<< MUX0);		// Seleccionar el ADC3
	ADCSRA	= 0;
	ADCSRA	|= (1 << ADPS1) | (1 << ADPS0);		// Frecuencia de muestreo de 125kHz
	ADCSRA	|= (1 << ADIE);						// Hab interrupción
	ADCSRA	|= (1 << ADEN);		
}

ISR(PCINT0_vect){
	if (!(PINB & (1 << PORTB0))) {
		contador++;
		
	}
	if (!(PINB & (1 << PORTB1))) {  // Si PB1 está presionado
		contador--;
	}
}

//------------------------ Interrupt routines ------------------------
ISR(TIMER0_OVF_vect)
{
	TCNT0 = 200;
	
	contador_5ms++;
	if (contador_5ms > 2){
		contador_5ms = 0;
	}
	
	
	switch(contador_5ms) {
		case 0:
			PORTC &= ~(DISP1 | DISP2 | MOST_CONT);
			PORTD = contador;
			PORTC |= MOST_CONT;
			break;
		
		case 1:
			PORTC &= ~(DISP1 | DISP2 | MOST_CONT);
			PORTD = tabla_7seg[dig_1];
			PORTC |= DISP1;
			break;
		
		case 2:
			PORTC &= ~(DISP1 | DISP2 | MOST_CONT);
			PORTD = tabla_7seg[dig_2];
			PORTC |= DISP2;
			break;
		
		default:
			break;
	}
	if (lectura_adc >= contador){
		PORTC |= (1 << PORTC5);
	}else{
		PORTC &= ~(1 << PORTC5);
	}
}


ISR(ADC_vect)
{
	lectura_adc	= ADCH;
	dig_2 = (lectura_adc >> 4) & 0x0F;  
	dig_1 = lectura_adc & 0x0F;         
	ADCSRA |= (1 << ADSC);
}

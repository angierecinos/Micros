/*
 * PWM0.c
 *
 * Created: 14/04/2025 19:29:54
 *  Author: Usuario
 */ 
#include "PWM0.h"
#include <avr/interrupt.h>

/*uint8_t pwm_counter = 0;*/

//uint8_t pwm = 0;

void initPWM0A(uint8_t invertido, uint16_t prescaler)
{
	DDRD	|= (1 << DDD6); // Como salida PD6
	TCCR0A	&= ~((1 << COM0A1) | (1<<COM0A0));
	
	if (invertido == invert)
	{
		TCCR0A	|= (1 << COM0A1) | (1 << COM0A0); //Invertido
		} else {
		TCCR0A	|= (1 << COM0A1);
	}
	
	TCCR0A	|= (0 << WGM02) | (0 << WGM01) | (0 << WGM00); // Modo  normal (2 -> CTC TOP -> OCRA / TOV -> 255)
	
	TCCR0B	&= ~((1 << CS02) | (1<<CS01) | (1<<CS00));
	switch(prescaler){
		case 1:
		TCCR0B	|= (1 << CS00); // Presc de 256 segun excel
		break;
		case 8:
		TCCR0B	|= (1 << CS01); // Presc de 256 segun excel
		break;
		case 64:
		TCCR0B	|= (1 << CS01) | (1 << CS00); // Presc de 256 segun excel
		break;
		case 256:
		TCCR0B	|= (1 << CS02); // Presc de 256 segun excel
		break;
		case 1024:
		TCCR0B	|= (1 << CS02) | (1<< CS00); // Presc de 256 segun excel
		break;
	}
	
	//OCR0A = 127;             // Interrupción cada 125kHz / (124 + 1) = 1 kHz (1 ms)

	TIMSK0 |= (1 << TOIE0); // Habilita la interrupción del timer
}


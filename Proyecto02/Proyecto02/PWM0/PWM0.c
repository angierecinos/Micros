/*
 * PWM0.c
 *
 * Created: 28/04/2025 15:33:38
 *  Author: Angie
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
	
	TCCR0A	|= (1 << WGM01) | (1 << WGM00); // Modo 3 -> Fast PWM y top 0xFF; 
	
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

	//TIMSK0 |= (1 << TOIE0); // Habilita la interrupción del timer
}

void initPWM0B(uint8_t invertido, uint16_t prescaler)
{
	DDRD	|= (1 << DDD5); // Como salida PD6
	TCCR0A	&= ~((1 << COM0B1) | (1<<COM0B0));
	
	if (invertido == invert)
	{
		TCCR0A	|= (1 << COM0B1) | (1 << COM0B0); //Invertido
		} else {
		TCCR0A	|= (1 << COM0B1);
	}
	
	TCCR0A	|= (1 << WGM01) | (1 << WGM00); // Modo 3 -> Fast PWM y top 0xFF; 
	
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

	//TIMSK0 |= (1 << TOIE0); // Habilita la interrupción del timer
}
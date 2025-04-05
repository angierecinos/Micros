/*
 * PWM0.c
 *
 * Created: 5/04/2025 11:44:14
 *  Author: Usuario
 */
 
#include "PWM0.h"

void initPWM0A(uint8_t invertido, uint16_t prescaler)
{
	DDRD	|= (1 << DDD6);								// Como salida PD6
	TCCR0A	&= ~((1 << COM0A1) | (1<<COM0A0));			// Unicamente quiero modificar estos 2
	
	if (invertido == invert)
	{
		TCCR0A	|= (1 << COM0A1) | (1 << COM0A0);		// Invertido
		} else {
		TCCR0A	|= (1 << COM0A1);						// No invertido
	}
	
	TCCR0A	|= (1 << WGM01) | (1 << WGM00);				// Modo 3 -> Fast PWM y top 0xFF
	
	TCCR0B	&= ~((1 << CS02) | (1<<CS01) | (1<<CS00));	// Apago únicamente los necesarios
	
	switch(prescaler){
		case 1:
		TCCR0B	|= (1 << CS00);
		break;
		case 8:
		TCCR0B	|= (1 << CS01);
		break;
		case 64:
		TCCR0B	|= (1 << CS01) | (1 << CS00);
		break;
		case 256:
		TCCR0B	|= (1 << CS02);							// Presc de 256 segun excel
		break;
		case 1024:
		TCCR0B	|= (1 << CS02) | (1<< CS00);			// Presc de 256 segun excel
		break;
		default:
		break;
	}
	
}

void updateDutyCycle(uint8_t duty)
{
	OCR0A = duty;
}
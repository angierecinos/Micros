/*
 * PWM0.c
 *
 * Created: 5/04/2025 11:44:14
 *  Author: Angie
 */
 
#include "PWM1.h"

void initPWM1A(uint8_t invertido, uint16_t prescaler)
{
	ICR1	 = 2499;									// Será mi valor TOP
	DDRB	|= (1 << DDB1);							// Como salida PB1
	
	TCCR1A	&= ~((1 << COM1A1) | (1<<COM1A0));			// Unicamente quiero modificar estos 2
	
	if (invertido == invert)
	{
		TCCR1A	|= (1 << COM1A1) | (1 << COM1A0);		// Invertido
		} else {
		TCCR1A	|= (1 << COM1A1);						// No invertido
	}
	
	TCCR1A	|= (1 << WGM11);							// Modo 14 -> Fast PWM y top ICR1
	TCCR1B	|= (1 << WGM13) | (1 << WGM12);				// Modo 14 -> Fast PWM y top ICR1
	TCCR1B	&= ~((1 << CS12) | (1<<CS11) | (1<<CS10));	// Apago únicamente los necesarios
	
	switch(prescaler){
		case 1:
			TCCR1B	|= (1 << CS10);
			break;
		case 8:
			TCCR1B	|= (1 << CS11);
			break;
		case 64:
			TCCR1B	|= (1 << CS11) | (1 << CS10);
			break;
		case 256:
			TCCR1B	|= (1 << CS12);							// Presc de 256 segun excel
			break;
		case 1024:
			TCCR1B	|= (1 << CS12) | (1<< CS10);			// Presc de 256 segun excel
			break;
		default:
			break;
	}
}

void initPWM1B(uint8_t invertido, uint16_t prescaler)
{
	
	ICR1	 = 2499;
	DDRB	|= (1 << DDB2);								// Como salida PB2
	TCCR1A	&= ~((1 << COM1B1) | (1<<COM1B0));			// Unicamente quiero modificar estos 2
	
	if (invertido == invert)
	{
		TCCR1A	|= (1 << COM1B1) | (1 << COM1B0);		// Invertido
		} else {
		TCCR1A	|= (1 << COM1B1);						// No invertido
	}
	
	TCCR1A	|= (1 << WGM11);							// Modo 14 -> Fast PWM y top ICR1
	TCCR1B	|= (1 << WGM13) | (1 << WGM12);				// Modo 14 -> Fast PWM y top ICR1
	TCCR1B	&= ~((1 << CS12) | (1<<CS11) | (1<<CS10));  // Apago para encender los necesarios
	
	switch(prescaler){
		case 1:
			TCCR1B	|= (1 << CS10);
			break;
		case 8:
			TCCR1B	|= (1 << CS11);
			break;
		case 64:
			TCCR1B	|= (1 << CS11) | (1 << CS10);
			break;
		case 256:
			TCCR1B	|= (1 << CS12);							
			break;
		case 1024:
			TCCR1B	|= (1 << CS12) | (1<< CS10);			
			break;
		default:
			break;
	}
	
}


/*
 * CFile1.c
 *
 * Created: 7/04/2025 16:46:58
 *  Author: Usuario
 */ 
#include "PWM2.h"
void initPWM2A(uint8_t invertido, uint16_t prescaler)
{
	DDRB	|= (1 << DDB3); // Como salida PB3
	TCCR2A	&= ~((1 << COM2A1) | (1<<COM2A0));
	
	if (invertido == invert)
	{
		TCCR2A	|= (1 << COM2A1) | (1 << COM2A0); //Invertido
		} else {
		TCCR2A	|= (1 << COM2A1);
	}
	
	TCCR2A	|= (1 << WGM21) | (1 << WGM20); // Modo 3 -> Fast PWM y top 0xFF
	
	TCCR2B	&= ~((1 << CS22) | (1<<CS01) | (1<<CS20));
	switch(prescaler){
		case 1:
		TCCR2B	|= (1 << CS20); 
		break;
		case 8:
		TCCR2B	|= (1 << CS21);
		break;
		case 32:
		TCCR2B	|= (1 << CS21) | (1 << CS20); 
		break;
		case 64:
		TCCR2B	|= (1 << CS22); 
		break;
		case 128:
		TCCR2B	|= (1 << CS22) | (1 << CS20);
		break;
		case 256:
		TCCR2B	|= (1 << CS22) | (1 << CS21); 
		break;
		case 1024:
		TCCR2B	|= (1 << CS22) | (1 << CS21) | (1<< CS20); 
		break;
	}
	
}
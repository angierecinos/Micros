/*
 * SERVO.c
 *
 * Created: 28/04/2025 15:42:51
 *  Author: Angie
 */ 

# include "SERVO.h"

void servo_positionA(uint16_t angulo)
{

	OCR0A = 16 + (angulo * (31-16)/180);

}

void servo_positionB(uint16_t angulo)
{
	OCR0B =  2 + (angulo*(50-2)/180);
}

void servo_position1A(uint16_t angulo)
{
	OCR1A = 71 + (angulo * (312-71) / 180);
}

void servo_position1B(uint16_t angulo)
{
	OCR1B =  71 + (angulo*(312-71)/180);
}

uint16_t mapeoADCtoPulse(uint16_t adc_val)
{
	return ((adc_val * 180) / 255);		// Escalar 0-255 a 125-250
}

uint16_t mapeoADCtoPulse1(uint16_t adc_val)
{
	return ((adc_val * 180) / 255);		// Escalar 0-255 a 125-250
}

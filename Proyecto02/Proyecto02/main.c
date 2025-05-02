/*
 * Proyecto02.c
 *
 * Created: 28/04/2025 15:24:47
 * Author: Angie Recinos 
 * Description: Se realiza el proyecto  2
 */

//
// Encabezado (Libraries)
#define F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include "PWM0/PWM0.h"
#include "PWM1/PWM1.h"
#include "SERVO/SERVO.h"

uint8_t lectura_adc;
uint16_t adc_value2;
uint16_t adc_value;
uint16_t pulse;
uint16_t pulse2;
uint8_t pin = 0;
uint8_t eleccion_adc =0;
uint8_t counter = 0;
uint8_t manual = 0;

//
// Function prototypes
void setup();
void initADC();

//
// Main Function
int main(void)
{
	setup();
	while (1)
	{
	}
}

//
// NON-Interrupt subroutines
void setup()
{
	cli();
	
	// Configurar prescaler de sistemas
	CLKPR	= (1 << CLKPCE);					// Habilita cambios en prescaler
	CLKPR	= (1 << CLKPS2);					// Setea presc a 16 para 1MHz
	
	initPWM0A(non_invert, 64);
	initPWM0B(non_invert, 64);					// No invertido prescaler de 8
	initPWM1A(non_invert, 8);
	initPWM1B(non_invert, 8);					// No invertido y prescaler de 8

	initADC();
	
	DDRB  |= (1 << PORTB1) | (1 << PORTB2);	// En el timer1 pines PB1 | PB2
	DDRD  |= (1 << PORTD6) | (1 << PORTD5);
	UCSR0B	= 0x00;								// Apaga serial
	
	sei();
}

void initADC()
{
	ADMUX	= 0;
	ADMUX	|= (1 << REFS0);					//ADMUX &= ~(1<< REFS1); // Se ponen los 5V como ref
	
	ADMUX	|= (1 << ADLAR);					// Justificaci�n a la izquierda
	ADMUX	|= (1 << MUX0); //| (1<< MUX0);		// Seleccionar el ADC1
	ADCSRA	= 0;
	ADCSRA	|= (1 << ADPS1) | (1 << ADPS0);		// Frecuencia de muestreo de 125kHz
	ADCSRA	|= (1 << ADIE);						// Hab interrupci�n
	ADCSRA	|= (1 << ADEN);
	ADCSRA	|= (1 << ADSC);						// Inicia con la conversi�n
}

//
// Interrupt routines
ISR(ADC_vect)
{
	eleccion_adc = ADMUX & 0x0F;
	lectura_adc = ADCH; 
	/*if (eleccion_adc == 3)
	{
		//adc_value = lectura_adc;
		pin = 3; 
	}else if (eleccion_adc == 2){
		//adc_value2 = lectura_adc;
		pin = 2;
	}*/
	
	//pin = (ADMUX & 0x03); 
	
	
	switch(eleccion_adc){
		case 1:
			ADMUX	&= 0xF0;
			pulse = mapeoADCtoPulse(lectura_adc);
			servo_positionA(pulse);
			ADMUX  |= (1 << MUX1);								// Selecciona al ADC2
			break;
		
		case 2: 			
			ADMUX	&= 0xF0;
			pulse = mapeoADCtoPulse(lectura_adc);
			servo_positionB(pulse);
			ADMUX  |= (1 << MUX1) | (1<< MUX0);					// Seleccionar el ADC3
			break;
		case 3:
			ADMUX	&= 0xF0;
			pulse2 = mapeoADCtoPulse1(lectura_adc);
			servo_position1A(pulse2);
			ADMUX  |= (1 << MUX2);								// Seleccionar el ADC4
			break;
		 
		case 4:
			ADMUX	&= 0xF0;
			pulse2 = mapeoADCtoPulse1(lectura_adc);
			servo_position1B(pulse2);
			ADMUX  |= (1 << MUX0);								// Seleccionar el ADC1
			break;	
		
		default: 
			break;  
	}
	
	ADCSRA |= (1 << ADSC);								// Inicia conversi�n otra vez
}

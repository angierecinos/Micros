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
#include "UART/UART.h"

uint8_t lectura_adc;
uint16_t option = 0;
uint16_t adc_value;
uint16_t pulse;
uint16_t pulse2;
uint8_t eleccion_adc =0;
uint8_t counter = 0;
uint8_t manual = 0;
#define MAX_CHAR 20
char input_angle[MAX_CHAR];
char texto = 0;
uint8_t input_index = 0;
uint8_t new_data_flag = 0;

//
// Function prototypes
void setup();
void initADC();
void processCoord(char texto);
//
// Main Function
int main(void)
{
	setup();
	while (1)
	{
		if (option == 1 && new_data_flag)
		{
			processCoord(input_angle);
			new_data_flag = 0;
		}
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
	initUART();
	
	DDRB  |= (1 << PORTB1) | (1 << PORTB2) | (1 << PORTB0);		// En el timer1 pines PB1 | PB2 ??
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

void processCoord(char* texto)
{
	
}

//
// Interrupt routines
ISR(ADC_vect)
{
	eleccion_adc = ADMUX & 0x0F;
	lectura_adc = ADCH; 	
	
	if (manual == 1)
	{
	
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
	manual = 0; 
	ADCSRA |= (1 << ADSC);								// Inicia conversi�n otra vez
	}
	else {
		ADCSRA |= (1 << ADSC);	
	}
}

ISR(USART_RX_vect)
{
	// Se mostrará menú para seleccionar modo 
	char temporal = UDR0;
	// Eco automático de dato ingresado
	writeChar(temporal);
	sendString(" \r\n");
	
	if (option == 0)
	{
		// Dependiendo de lo que se elija, será el modo
		if(temporal == '1') {
			
			// Modo manual - Con la interrupción de ADC
			sendString("\r\nModifique manualmente cada motor\r\n");
			PORTB |= (1 << PORTB0);
			manual = 1;
			} else if (temporal == '2') {
			// Modo UART
			sendString("\r\nIngrese las posiciones de los cuatro motores en un angulo de 0° - 180° separados por comas.\r\n");
			sendString("\r\nPor ejemplo: 30,60,90,180.\r\n");
			PORTB &= ~(1 << PORTB0);
			PORTD |= (1 << PORTD7);
			option = 1; 
		} else {
		sendString("\r\nOpción no valida. Intente nuevamente.\r\n");
		}
	} else if (option == 1)
		{
			sendString("\r\nCoordenadas: \r\n");
			
			writeChar(temporal);

			if (temporal == '\n') {
				input_angle[input_index] = '\0';		 // Final del texto
				input_index = 0;						 // Se resetea el indice de lo que entra
				new_data_flag = 1;						 // Señal de que hay nueva cadena para procesar
			}
			else if (input_index < MAX_CHAR - 1) {
				input_angle[input_index++] = temporal;	 // Se guarda en un array el valor actual que se vaya leyendo
			}
			
		}
	
}
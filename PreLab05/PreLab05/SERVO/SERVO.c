/*
 * ADC.c
 *
 * Created: 6/04/2025 15:55:21
 *  Author: Angie
 */ 

// El ancho de pulso normal para un servo 1ms - 2ms (se trabajará para 0.55 ms - 2.5 ms)
// donde 1ms -> 0° y 2ms -> 180°
// Considerando lo anterior y período mínimo de PWM de 20ms
// Según cálculos, el valor mínimo para OCR1A debe ser 71 (5% duty_cycle)
// Según cálculos, el valor máximo para OCR1A debe ser 312 (10% duty_cycle)
// 
// Se debe escalar el valor del ADC entre los 125 y los 250 que dicta el pulso

# include "SERVO.h"
void servo_positionA(uint16_t angulo)
{
	//OCR1A =  71 + (angulo*(312-71)/180); 
	//if(angulo > 180) angulo = 180;
	OCR1A = 71 + (angulo * (312-71) / 180);
	//OCR1A =  125 + (angulo*(125UL)/180); //map(pulse, 0, 1023, 0, 250); //pulse; 
}

void servo_positionB(uint16_t angulo)
{
	OCR1B =  71 + (angulo*(312-71)/180);
}

void servo_position2A(uint16_t angulo)
{
	if(angulo > 180) angulo = 180;
	OCR2A = 2 + (angulo * (50-2) / 180);
	//OCR2A =  71 + (angulo*(312-71)/180);
	//OCR1A =  125 + (angulo*(125UL)/180); //map(pulse, 0, 1023, 0, 250); //pulse;
}

uint16_t mapeoADCtoPulse(uint16_t adc_val)
{
	return ((adc_val * 180) / 255);		// Escalar 0-255 a 125-250
}

uint16_t mapeoADCtoPulse2(uint16_t adc_val)
{
	return ((adc_val * 180) / 255);		// Escalar 0-255 a 125-250
}

void initADC()
{
	ADMUX	= 0;
	ADMUX	|= (1 << REFS0);					//ADMUX &= ~(1<< REFS1); // Se ponen los 5V como ref
	
	ADMUX	|= (1 << ADLAR);					// Justificación a la izquierda
	ADMUX	|= (1 << MUX1); //| (1<< MUX0);		// Seleccionar el ADC2
	ADCSRA	= 0;
	ADCSRA	|= (1 << ADPS1) | (1 << ADPS0);		// Frecuencia de muestreo de 125kHz
	ADCSRA	|= (1 << ADIE);						// Hab interrupción
	ADCSRA	|= (1 << ADEN);
	ADCSRA	|= (1 << ADSC);
}

// Leer un valor de ADC en un pin específico
/*uint8_t ADC_read(uint8_t pin)
{
	//if (pin > 7) return 0;							// Comprobar que el canal esté dentro del rango válido
	ADMUX = (ADMUX & 0xF0) | pin;					// Asignar el pin que es
	ADCSRA |= (1 << ADSC);							// Iniciar la conversión
	while (ADCSRA & (1 << ADSC)); // Esperar fin de conversión
	return ADC;										// Se obtiene el valor de ADC (10 bits)
}*/

/*uint16_t map(uint16_t x, uint16_t in_min, uint16_t in_max, uint16_t out_min, uint16_t out_max) {
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}*/


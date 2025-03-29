/*
 * Ejemplo_clase_26.c
 *
 * Created: 26/03/2025 16:51:57
 * Author : Usuario
 */ 

// Encabezado (Libraries)
#define F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>

// Function prototypes
void setup();
void initADC();
 
// Non-interupt 
void setup ()
{
	cli();
	
	// Configurar prescaler de sistemas 
	CLKPR	= (1 << CLKPCE); // HABILITA CAMBIOS EN PRESC
	CLKPR	= (1 << CLKPS2); // Setea presc a 16 para 1Mhz
	DDRD	= 0xFF; 
	UCSR0B	= 0x00; // apaga serial
	
	initADC(); 
	ADCSRA	|= (1 << ADSC);
	
	sei(); 
}
// Main
int main(void)
{
    /* Replace with your application code */
    while (1) 
    {
    }
}

void initADC()
{
	ADMUX = 0;
	ADMUX	|= (1<<REFS0);  // Se ponen los 5V como ref
	//ADMUX &= ~(1<< REFS1);
	ADMUX	|= (1 << ADLAR); // JUSTIF IZQ
	ADMUX	|= (1 << MUX2) | (1<< MUX1); //Seleccionar el ADC6
	// Por ultimo iniciar conversion
	
	ADCSRA	= 0; 
	ADCSRA	|= (1 << ADPS1) | (1 << ADPS0); // Frecuencia de muestreo de 125kHz
	ADCSRA	|= (1 << ADIE); // Hab inter
	ADCSRA	|= (1 << ADEN); // 
	
	//ADCSRA	|= (1<< ADSC);
}

// Interrupt routines
ISR(ADC_vect)
{
	PORTD = ADCH;
	ADCSRA	|= (1<< ADSC);
}

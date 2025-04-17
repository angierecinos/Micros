/*
 * Laboratorio06.c
 *
 * Created: 17/04/2025 11:48:01
 * Author : Angie
 * Description: Se utiliza comunicación serial
 */ 

//*******************************************
// Encabezado (Libraries)
#include <avr/io.h>
#include <avr/interrupt.h>

//*******************************************
// Function prototypes
void setup();
void initUART(); 
void writeChar(char caracter); 

//*******************************************
// Main Function
int main(void)
{
	setup();
	writeChar('A');
	writeChar('N');
	writeChar('G');
	writeChar('I');
	writeChar('E');
	while (1)
	{
	}
}


//*******************************************
// NON-Interrupt subroutines
void setup()
{
	cli();
	DDRB = 0xFF;						// Se setea puerto B como salida 
	PORTB = 0x00;						// Apaga la salida
	initUART();
	sei();
}

void initUART()
{
	// Configurar PD0 y PD1 
	DDRD |=  (1 << DDD1);
	DDRD &= ~(1 << DDD0); 
	
	// Se apaga (no utilizo doble velocidad) 
	UCSR0A = 0; 
	// Habilitar interrupts recibir, recepcion y transmision 
	UCSR0B |= (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0); 
	// Modo asíncrono y con paridad deshabilitada | Quiero 8 bits 
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00); 
	// Valor UBRR = 103 -> 9600 @ 16MHz 
	UBRR0 = 103; 
}

void writeChar(char caracter)
{
	// Si no se hubiera esperado a que termine de trasladar, puede dar un error
	//uint8_t temporal = UCSR0A & (1 << UDRE0);
	while ((UCSR0A & (1 << UDRE0)) == 0);
	UDR0 = caracter; 
	
}
//*******************************************
// Interrupt routines
ISR(USART_RX_vect)
{
	char temporal = UDR0;
	writeChar(temporal);
	PORTB = temporal;
}

// NON - Interrupt

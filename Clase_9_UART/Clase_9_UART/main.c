/*
 * Clase_9_UART.c
 *
 * Created: 9/04/2025 16:49:22
 * Author : Usuario
 */ 

/*
 * Clase_9_UART.c
 *
 * Created: 4/9/2025 4:51:57 PM
 * Author : edvin
 * Description: Después lo pongo xd
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
	while (1)
	{
		writeChar('H');
		writeChar('O');
		writeChar('L');
		writeChar('A');
	}
}


//*******************************************
// NON-Interrupt subroutines
void setup()
{
	cli();
	initUART();
	sei();
}

void initUART()
{
	// Configurar PD0 y PD1 
	DDRD |=  (1 << DDD1);
	DDRD &= ~(1 << DDD0); 
	
	// 
	UCSR0A = 0; 
	// Habilitar interrupts recibir, recepcion y transmision 
	UCSR0B |= (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0); 
	// 
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00); 
	// UBRR = 103 -> 9600 @ 16MHz 
	UBRR0 = 103; 
}

void writeChar(char caracter)
{
	// Si no se hubiera esperado a que termine de trasladar, puede dar un error
	uint8_t temporal = UCSR0A & (1 << UDRE0);
	while ((UCSR0A & (1 << UDRE0)) == 0);
	UDR0 = caracter; 
	
}
//*******************************************
// Interrupt routines

// NON - Interrupt
ISR(USART_RX_vect)
{
	char temporal = UDR0;
	writeChar(temporal);
}
/*
 * Clase_9_UART.c
 *
 * Created: 9/04/2025 16:49:22
 * Author : Angie
 * Description: Clase para UART
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


//*******************************************
// Interrupt routines

// NON - Interrupt
ISR(USART_RX_vect)
{
	char temporal = UDR0;
	writeChar(temporal);
}
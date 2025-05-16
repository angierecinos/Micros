/*
 * UART.c
 *
 * Created: 29/04/2025 11:56:33
 *  Author: Angie
 */ 

#include "UART.h"

void initUART()
{
	// Configurar PD0 y PD1
	DDRD |=  (1 << DDD1);
	DDRD &= ~(1 << DDD0);
	
	// Double speed
	UCSR0A |= (1 << U2X0); 
	// Habilitar interrupts recibir, recepcion y transmision
	UCSR0B |= (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0);
	//
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
	// UBRR = 12 -> 9600 @ 1MHz
	UBRR0 = 12;
}

void writeChar(char caracter)
{
	// Si no se hubiera esperado a que termine de trasladar, puede dar un error
	while ((UCSR0A & (1 << UDRE0)) == 0);
	UDR0 = caracter;
	
}

void sendString(char* texto)
{
	// Se hace siempre que indice sea diferente de un valor "nulo"
	// Aumenta el valor de indice
	for (uint8_t indice = 0; *(texto + indice) != '\0'; indice++)
	{
		writeChar(texto[indice]);
	}
}

void angle_to_str(uint8_t value, char* str)
{
	if (value >= 100) {
		*str++ = (value / 100) + '0';	// 123 / 100 = 1 ? almacena '1'
		value %= 100;					// 123 % 100 = 23 ? ahora value = 23
		*str++ = (value / 10) + '0';	// 23 / 10 = 2 ? almacena '2'
		value %= 10;					// 23 % 10 = 3 ? ahora value = 3
		*str++ = value + '0';			// almacena '3'
	} else if (value >= 10) {
		*str++ = (value / 10) + '0';
		value %= 10;
		*str++ = value + '0';
	} else {
		*str++ = value + '0';
	}

	*str = '\0';  
}
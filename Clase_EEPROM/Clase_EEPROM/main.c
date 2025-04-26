/*
 * Clase_EEPROM.c
 *
 * Created: 23/04/2025 16:01:27
 * Author: Angie
 * Description: Clase con EEPROM
 */
//
// Encabezado (Libraries)
#include <avr/io.h>

//
// Function prototypes
void writeEEPROM(uint8_t dato, uint16_t direccion); 
void readEEPROM();
//
// Main Function
int main(void)
{
	initUART();
	uint8_t temporal = readEEPROM(0x00); 
	writeChar(temporal); 
	/* Replace with your application code */
	while (1)
	{
	}
}
//
// NON-Interrupt subroutines
void writeEEPROM(uint8_t dato, uint16_t direccion)
{
	//uint8_t temporal = EECR & ( 1 << EEPE); //0b000000x0
	while(EECR & ( 1 << EEPE)); // Esperar a que termine la escritura 
	// Asigna dirección 
	EEAR = direccion; 
	// Asignar dato a escribir
	EEDR = dato; 
	// Setea en 1 el master write enable (Hay que esperar 4 ciclos para el write enable) 
	EECR |= (1 << EEMPE);
	// Setea en 1 el write enable
	EECR |= (1 << EEPE);
}

uint8_t readEEPROM(uint16_t direccion)
{
	while(EECR & (1 << EE))
}
//
// Interrupt routines






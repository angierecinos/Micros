/*
 * EEPROM.c
 *
 * Created: 9/05/2025 11:55:04
 *  Author: Usuario
 */ 

#include "EEPROM.h"

void writeEEPROM(uint8_t dato, uint8_t direccion){
	// Esperar a que termine la escritura anterior
	while (EECR & (1 << EEPE));
	// Asignar dirección de escritura
	EEAR = direccion;
	// Asignar dato a "escribir"
	EEDR = dato;
	// Setear en 1 el "master write enable"
	EECR |= (1 << EEMPE);
	// Empezar a escribir
	EECR |= (1 << EEPE);
}

uint8_t readEEPROM(uint8_t direccion){
	// Esperar a que termine la escritura anterior
	while (EECR & (1 << EEPE));
	// Asignar dirección de escritura
	EEAR = direccion;
	// Empezar a leer
	EECR |= (1 << EERE);
	return EEDR;
}

void eraseEEPROM()
{
	uint8_t i=0;
	uint8_t valor = readEEPROM(i);
	while(valor != 0xFF)
	{
		writeEEPROM(0xFF,i);
		i++;
		valor = readEEPROM(i);
	}
}
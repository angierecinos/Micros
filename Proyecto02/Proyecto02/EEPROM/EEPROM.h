/*
 * EEPROM.h
 *
 * Created: 9/05/2025 11:54:51
 *  Author: Usuario
 */ 


#ifndef EEPROM_H_
#define EEPROM_H_

#include <avr/io.h>

void writeEEPROM(uint8_t dato, uint8_t direccion);
uint8_t readEEPROM(uint8_t direccion);
void eraseEEPROM();


#endif /* EEPROM_H_ */
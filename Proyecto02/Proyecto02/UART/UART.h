/*
 * UART.h
 *
 * Created: 29/04/2025 11:56:47
 *  Author: Angie
 */ 


#ifndef UART_H_
#define UART_H_

#include <avr/io.h>

void initUART();
void writeChar(char caracter);
void sendString(char* texto);
void angle_to_str(uint8_t value, char* str);

#endif /* UART_H_ */
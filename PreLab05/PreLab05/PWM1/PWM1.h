/*
 * PWM1.h
 *
 * Created: 5/04/2025 11:43:05
 *  Author: Usuario
 */ 


#ifndef PWM1_H_
#define PWM1_H_

#include <avr/io.h>

#define invert 1
#define non_invert 0

void initPWM1A(uint8_t invertido, uint16_t prescaler);
void initPWM1B(uint8_t invertido, uint16_t prescaler);


#endif /* PWM1_H_ */
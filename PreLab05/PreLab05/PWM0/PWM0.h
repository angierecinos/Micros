/*
 * PWM0.h
 *
 * Created: 14/04/2025 19:29:36
 *  Author: Usuario
 */ 


#ifndef PWM0_H_
#define PWM0_H_

#include <avr/io.h>

#define invert 1
#define non_invert 0

void initPWM0A(uint8_t invertido, uint16_t prescaler);


#endif /* PWM0_H_ */
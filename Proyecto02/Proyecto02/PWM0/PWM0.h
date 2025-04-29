/*
 * PWM0.h
 *
 * Created: 28/04/2025 15:33:52
 *  Author: Angie
 */ 


#ifndef PWM0_H_
#define PWM0_H_

#include <avr/io.h>

#define invert 1
#define non_invert 0

void initPWM0A(uint8_t invertido, uint16_t prescaler);
void initPWM0B(uint8_t invertido, uint16_t prescaler);

#endif /* PWM0_H_ */
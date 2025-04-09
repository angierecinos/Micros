/*
 * IncFile1.h
 *
 * Created: 7/04/2025 16:46:48
 *  Author: Usuario
 */ 


#ifndef PWM2_H_
#define PWM2_H_

#include <avr/io.h>

#define invert 1
#define non_invert 0

void initPWM2A(uint8_t invertido, uint16_t prescaler);


#endif /* INCFILE1_H_ */
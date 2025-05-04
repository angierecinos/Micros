/*
 * SERVO.h
 *
 * Created: 28/04/2025 15:43:08
 *  Author: Usuario
 */ 


#ifndef SERVO_H_
#define SERVO_H_

#include <avr/io.h>

void initADC();

uint16_t mapeoADCtoPulse(uint16_t adc_val);
uint16_t mapeoADCtoPulse1(uint16_t adc_val);

void servo_positionA(uint16_t pulse);
void servo_positionB(uint16_t pulse);
void servo_position1A(uint16_t pulse);
void servo_position1B(uint16_t pulse);

void processCoord();

#endif /* SERVO_H_ */
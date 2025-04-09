/*
 * SERVO.h
 *
 * Created: 6/04/2025 15:55:02
 *  Author: Usuario
 */ 


#ifndef SERVO_H_
#define SERVO_H_

#include <avr/io.h>

void initADC();

uint16_t mapeoADCtoPulse(uint16_t adc_val); 

void servo_positionA(uint16_t pulse);
void servo_positionB(uint16_t pulse);
void servo_position2A(uint16_t pulse);

//uint8_t ADC_read(uint8_t pin);
//uint16_t map(uint16_t x, uint16_t in_min, uint16_t in_max, uint16_t out_min, uint16_t out_max);


#endif /* SERVO_H_ */
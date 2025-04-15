/*
 * PreLab05.c
 *
 * Created: 5/04/2025 09:04:06
 * Author : Angie Recinos
 * Description:
 */

 /****************************************/
 // Encabezado (Libraries)
 #define F_CPU 16000000
 #include <avr/io.h>
 #include <avr/interrupt.h>
 #include <util/delay.h>
 #include "PWM0/PWM0.h"
 #include "PWM1/PWM1.h"
 #include "PWM2/PWM2.h"
 #include "SERVO/SERVO.h"
 
 // Configuración de los canales de ADC
 uint8_t lectura_adc; 
 uint16_t adc_value2;
 uint16_t adc_value;
 uint16_t pulse;
 uint16_t pulse2;
 uint8_t PWM_TOP = 127; //ciclo de trabajo al 50%
 uint8_t pin = 0; 
 uint8_t eleccion_adc =0; 
 uint8_t counter = 0;
 uint8_t manual = 0;
 /****************************************/
 // Function prototypes
 void setup();
 void initADC(); 
 
 /****************************************/
 // Main Function
 int main(void)
 {
	 setup();
	 while (1)
	 {
		//servo_positionA(pulse);
		//_delay_ms(1000);
		//servo_position2A(pulse2);
		//_delay_ms(10);
	 }
 }

 /****************************************/
 // NON-Interrupt subroutines
 void setup()
 {
	 cli();
	 
	 // Configurar prescaler de sistemas
	 CLKPR	= (1 << CLKPCE);					// Habilita cambios en prescaler
	 CLKPR	= (1 << CLKPS2);					// Setea presc a 16 para 1MHz
	 
	 initPWM0A(non_invert, 8);
	 initPWM1A(non_invert, 8);					// No invertido y prescaler de 8
	 initPWM2A(non_invert, 64);					// No invertido y prescaler de 8
	 initADC(); 
	 
	 DDRB  |= (1 << PORTB1) | (1 << PORTB2) | (1 << PORTB3);	// En el timer1 pines PB1 | PB2
	 DDRD  |= (1 << PORTD7);
	 UCSR0B	= 0x00;								// Apaga serial
	 
	 sei();
 }

 
 /****************************************/
 // Interrupt routines
ISR(ADC_vect)
{
	eleccion_adc = ADMUX & 0x03;
	lectura_adc = ADCH; 
	/*if (eleccion_adc == 3)
	{
		//adc_value = lectura_adc;
		pin = 3; 
	}else if (eleccion_adc == 2){
		//adc_value2 = lectura_adc;
		pin = 2;
	}*/
	
	//pin = (ADMUX & 0x03); 
	
	
	switch(eleccion_adc){
		case 2: 			
			ADMUX	&= 0xF0;
			pulse2 = mapeoADCtoPulse2(lectura_adc);
			servo_position2A(pulse2);
			ADMUX  |= (1 << MUX1) | (1<< MUX0);					// Seleccionar el ADC3
			break;
		case 3:
			ADMUX	&= 0xF0;
			pulse = mapeoADCtoPulse(lectura_adc);
			servo_positionA(pulse);
			ADMUX  |= (1 << MUX2);								// Seleccionar el ADC4
			break;
		 case 0: 
			ADMUX	&= 0xF0;
			//OCR0A = 127;						// Hace que el valor del pwm sea el ADC
			manual = (lectura_adc * PWM_TOP) / 255;
			ADMUX  |= (1 << MUX1); // | (1<< MUX0);						// Selecciona al ADC2
			break; 
			
		default: 
			break;  
	}
	
	ADCSRA |= (1 << ADSC);								// Inicia conversión otra vez
}

/*ISR(TIMER0_COMPA_vect)
{
		//PORTD &= ~(1 << PORTD6);			// Apaga el LED
}*/


ISR(TIMER0_OVF_vect)
{
		counter++;
		if (counter >= manual){
			PORTD &= ~(1 << PORTD7);
			//PORTD |= (1 << PORTD7);  // LED OFF
		}
		else{
			PORTD |= (1 << PORTD7); // LED ON
		}
		if (counter >= PWM_TOP){
			counter = 0;
		}
}
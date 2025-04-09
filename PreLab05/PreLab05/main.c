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
 #include "PWM1/PWM1.h"
 #include "PWM2/PWM2.h"
 #include "SERVO/SERVO.h"
 
 // Configuración de los canales de ADC
 uint8_t lectura_adc; 
 uint8_t lectura_adc2; 
 uint16_t adc_value;
 uint16_t pulse;
 uint16_t pulse2;
 uint8_t pin_adc = 0; 
 uint8_t pin = 0; 
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
		servo_positionA(pulse);
		//_delay_ms(10);
		servo_position2A(pulse2);
		//_delay_ms(10);
		//adc_value = ADC_read(0);					// Leer del "pin" 0
		//pulse = mapeoADCtoPulse(adc_value);			// Escalar a 125–250
		//servo_positionA(pulse);						// Actualizar servo
		//_delay_ms(10);								// Pequeño delay para estabilidad*
		/*servo_positionA(0); // 0°
		_delay_ms(100);
		servo_positionA(250); // 180°
		_delay_ms(100);*/
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
	 
	 initPWM1A(non_invert, 8);					// No invertido y prescaler de 8
	 initPWM2A(non_invert, 8);					// No invertido y prescaler de 8
	 initADC(); 
	 
	 DDRB  |= (1 << PORTB1) | (1 << PORTB2);	// En el timer1 pines PB1 | PB2
	 UCSR0B	= 0x00;								// Apaga serial
	 
	 sei();
 }

 
 /****************************************/
 // Interrupt routines
ISR(ADC_vect)
{
	pin = (ADMUX & 0x03); 
	lectura_adc = ADCH; 
	switch(pin){
		case 3: 
			pulse = mapeoADCtoPulse(lectura_adc);
			
			ADMUX	|= (1 << MUX1);		// Seleccionar el ADC3
			break; 
		case 2: 
			//ADMUX	|= (1<< MUX1);								// Seleccionar el ADC2
			//lectura_adc2 = ADCH; 
			pulse2 = mapeoADCtoPulse(lectura_adc);
			
			ADMUX	|= (1 << MUX1) | (1<< MUX0);		// Seleccionar el ADC3
			break;
		default: 
			break;  
	}
	
	ADCSRA |= (1 << ADSC);								// Inicia conversión otra vez
}



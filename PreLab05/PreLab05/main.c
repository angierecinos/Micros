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
 #include "SERVO/SERVO.h"
 
 // Configuración de los canales de ADC
 uint8_t adc_pins[8] = {0, 1, 2, 3, 4, 5, 6, 7};  // Pines de 0 a 7
 uint8_t dutyCycle = 101; 
 uint8_t lectura_adc; 
 uint16_t adc_value;
 uint16_t pulse;
 
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
	 initADC(); 
	 
	 DDRB  |= (1 << PORTB1) | (1 << PORTB2);	// En el timer1 pines PB1 | PB2
	 UCSR0B	= 0x00;								// Apaga serial
	 
	 sei();
 }

 
 /****************************************/
 // Interrupt routines
ISR(ADC_vect)
{
	lectura_adc	= ADCH;									// Guarda el valor de ADC
	pulse = mapeoADCtoPulse(lectura_adc);
	servo_positionA(pulse);	
	ADCSRA |= (1 << ADSC);								// Inicia conversión otra vez
}



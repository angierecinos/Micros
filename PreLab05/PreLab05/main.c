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
 uint8_t dutyCycle = 101; 
 
 /****************************************/
 // Function prototypes
 void setup();

 /****************************************/
 // Main Function
 int main(void)
 {
	 setup();
	 while (1)
	 {
		 updateDutyCycle(dutyCycle); 
		 dutyCycle++; 
		 _delay_ms(1); 
	 }
 }

 /****************************************/
 // NON-Interrupt subroutines
 void setup()
 {
	 cli();
	 
	 // Configurar prescaler de sistemas
	 CLKPR	= (1 << CLKPCE);		// Habilita cambios en prescaler
	 CLKPR	= (1 << CLKPS2);		// Setea presc a 16 para 1MHz
	 
	 initPWM0A(invert, 8);
	 
	 DDRD	= 0xFF;
	 UCSR0B	= 0x00;					// Apaga serial
	 
	 sei();
 }
 
 /****************************************/
 // Interrupt routines




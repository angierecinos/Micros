/*
 * Proyecto02.c
 *
 * Created: 28/04/2025 15:24:47
 * Author: Angie Recinos 
 * Description: Se realiza el proyecto  2
 */

//
// Encabezado (Libraries)
#define F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include "PWM0/PWM0.h"
#include "PWM1/PWM1.h"
#include "SERVO/SERVO.h"
#include "UART/UART.h"
#include "EEPROM/EEPROM.h"

uint8_t lectura_adc;
uint16_t option = 0;
uint16_t adc_value;
uint16_t pulse;
uint16_t pulse2;
uint8_t eleccion_adc =0;
uint8_t counter = 0;
uint8_t manual = 0;
#define MAX_CHAR 20
char input_angle[MAX_CHAR];
char texto = 0;
uint8_t input_index = 0;
uint8_t new_data_flag = 0;
uint8_t modo = 1; 
uint8_t btn_eeprom = 0; 
uint8_t uart_act = 0;
#define EEPROM_CONTADOR_POSICIONES 0 // dirección 0 reservada para contador
uint8_t cant_posiciones_eeprom = 0;  // variable en RAM
uint8_t positions = 0;
uint8_t rpr_counter = 0; 
uint8_t direccion = 0;
//char valor;
uint8_t start_save = 1; 
uint8_t ubicacion = 0;
uint8_t reproduction = 0;
//
// Function prototypes
void setup();
void initADC();
void processCoord(char* texto);
void manual_mode();
void uart_mode();
void eeprom_mode();
//
// Main Function
int main(void)
{
	setup();
	cant_posiciones_eeprom = readEEPROM(EEPROM_CONTADOR_POSICIONES);
	//uint8_t temp1 = readEEPROM(EEPROM_CONTADOR_POSICIONES);
	/*if (temp1 != 0xFF)
	{
		cant_posiciones_eeprom = temp1;
	}
	else
	{
		cant_posiciones_eeprom = 0;
		writeEEPROM(cant_posiciones_eeprom, EEPROM_CONTADOR_POSICIONES);
	}*/
	//eraseEEPROM();
	/*uint8_t i = 0;
	uint8_t valor2 = readEEPROM(i);
	while(valor2 != 0xFF)
	{
		writeChar(valor2);
		i++;
		valor2 = readEEPROM(i);
	}*/
	while (1)
	{
		switch(modo){
			case 1: 
				
				manual_mode();
				uart_act = 0;
				break;
			case 2: 
				manual = 0;
				uart_mode();
				break;
			case 3: 
				manual = 0;
				eeprom_mode();
				break;
		}
		
	}
}

//
// NON-Interrupt subroutines
void setup()
{
	cli();
	
	// Configurar prescaler de sistemas
	CLKPR	= (1 << CLKPCE);					// Habilita cambios en prescaler
	CLKPR	= (1 << CLKPS2);					// Setea presc a 16 para 1MHz
	
	DDRB  |= (1 << PORTB1) | (1 << PORTB2) | (1 << PORTB0);		// En el timer1 pines PB1 | PB2 y PB0 como led para modo
	PORTB &= ~(1 << PORTB0);									// Se apaga el led para modo
	
	DDRC  &= ~((1 << PORTC5) | (1 << PORTC0));					// Se setean PC5 y PC0 como entradas
	PORTC |= (1 << PORTC5) | (1 << PORTC0);						// Se habilitan los pull ups internos
	
	DDRD  |= (1 << PORTD6) | (1 << PORTD5) | (1 << PORTD7);		// En el timer0 PD5 y PD6 | Led PD7
	PORTD &= ~(1 << PORTD7);									// Se apaga el led para modo
	//UCSR0B	= 0x00;												// Apaga serial
	
	PCICR	|= (1 << PCIE1);									// Se habilitan interrupciones pin-change
	PCMSK1	|= (1 << PCINT13) | (1 << PCINT8);					// Se habilitan solo para los PC5 y PC6
	
	initPWM0A(non_invert, 64);
	initPWM0B(non_invert, 64);					// No invertido prescaler de 8
	initPWM1A(non_invert, 8);
	initPWM1B(non_invert, 8);					// No invertido y prescaler de 8

	initADC();
	initUART();
	
	sei();
}

void initADC()
{
	ADMUX	= 0;
	ADMUX	|= (1 << REFS0);					//ADMUX &= ~(1<< REFS1); // Se ponen los 5V como ref
	
	ADMUX	|= (1 << ADLAR);					// Justificaci�n a la izquierda
	ADMUX	|= (1 << MUX0); //| (1<< MUX0);		// Seleccionar el ADC1
	ADCSRA	= 0;
	ADCSRA	|= (1 << ADPS1) | (1 << ADPS0);		// Frecuencia de muestreo de 125kHz
	ADCSRA	|= (1 << ADIE);						// Hab interrupci�n
	ADCSRA	|= (1 << ADEN);
	ADCSRA	|= (1 << ADSC);						// Inicia con la conversi�n
}

void manual_mode()
{
		// Modo manual - Con la interrupción de ADC
		PORTB |= (1 << PORTB0);
		PORTD &= ~(1 << PORTD7);
		manual = 1;
		
		// En el modo manual deben poder guardarse las posiciones
		if (btn_eeprom == 1 && cant_posiciones_eeprom <= 6)
		{
			// Se calcula dirección de escritura
			// Por cada serie de posiciones se almacena la posición de 4 servos 
			// -> Luego de 4 posiciones empieza el nuevo set de posiciones
			direccion = 1 + cant_posiciones_eeprom * 4;			// empieza en dirección 1 (En la 0 guardamos cuantos sets de pos se guardan)
			
			// La posición de c/servo se almacena en un espacio independiente
			writeEEPROM(OCR1A, direccion++);
			writeEEPROM(OCR1B, direccion++);
			writeEEPROM(OCR0A, direccion++);
			writeEEPROM(OCR0B, direccion++);

			// Incrementar contador de posiciones 
			cant_posiciones_eeprom++;
			// Se guarda en la EEPROM cuantos set de posiciones se han almacenado
			writeEEPROM(cant_posiciones_eeprom, EEPROM_CONTADOR_POSICIONES);
			
			// Se reestablece el botón para poder guardar nuevas posiciones
			btn_eeprom = 0;
			
		}
		else if (btn_eeprom == 1 && cant_posiciones_eeprom > 6)
		{
			writeEEPROM(0, EEPROM_CONTADOR_POSICIONES); // Borra el contador
			cant_posiciones_eeprom = 0;
			btn_eeprom = 0;
		}
}

void uart_mode()
{
		// Modo UART
		manual = 0;
		PORTB &= ~(1 << PORTB0);
		PORTD |= (1 << PORTD7);
	
}

void eeprom_mode()
{
	PORTB |= (1 << PORTB0);
	PORTD |= (1 << PORTD7);
	
	if (btn_eeprom == 1)
	{
		
		if (rpr_counter >= cant_posiciones_eeprom)
		{
			rpr_counter = 0;
		}
		
		if (cant_posiciones_eeprom > 0) {
			ubicacion = 1 + rpr_counter * 4;
			OCR1A = readEEPROM(ubicacion++);
			OCR1B = readEEPROM(ubicacion++);
			OCR0A = readEEPROM(ubicacion++);
			OCR0B = readEEPROM(ubicacion++);
			rpr_counter++;
		}
		
		btn_eeprom = 0; 
	}
}
//
// Interrupt routines
ISR(ADC_vect)
{
	eleccion_adc = ADMUX & 0x0F;
	lectura_adc = ADCH; 	
	
	if (manual == 1)
	{
	
	switch(eleccion_adc){
		case 1:
			ADMUX	&= 0xF0;
			pulse = mapeoADCtoPulse(lectura_adc);
			servo_positionA(pulse);
			ADMUX  |= (1 << MUX1);								// Selecciona al ADC2
			break;
		
		case 2: 			
			ADMUX	&= 0xF0;
			pulse = mapeoADCtoPulse(lectura_adc);
			servo_positionB(pulse);
			ADMUX  |= (1 << MUX1) | (1<< MUX0);					// Seleccionar el ADC3
			break;
		case 3:
			ADMUX	&= 0xF0;
			pulse2 = mapeoADCtoPulse1(lectura_adc);
			servo_position1A(pulse2);
			ADMUX  |= (1 << MUX2);								// Seleccionar el ADC4
			break;
		 
		case 4:
			ADMUX	&= 0xF0;
			pulse2 = mapeoADCtoPulse1(lectura_adc);
			servo_position1B(pulse2);
			ADMUX  |= (1 << MUX0);								// Seleccionar el ADC1
			break;	
		
		default: 
			break;  
	} 
	ADCSRA |= (1 << ADSC);								// Inicia conversi�n otra vez
	}
	else {
		ADCSRA |= (1 << ADSC);	
	}
}

ISR(USART_RX_vect)
{
	// Dependiendo del modo se realiza la acción 
	char temporal = UDR0;
	// Eco automático de dato ingresado
	//writeChar(temporal);
	//sendString(" \r\n");
	//if (temporal == 'M:1')
	if (temporal == 'M')
	{
		modo++;
		if (modo >=4)
		{
			modo = 1;
		}
	}
	else if (temporal == 'E')
	{
		btn_eeprom = 1;
	}
	
	
	if (modo == 2)
	{
			

			if (temporal == '\n' || temporal == '\r') {
				//sendString("\r\nCoordenadas implementadas: \r\n");
				input_angle[input_index] = '\0';		 // Final del texto
				//sendString(input_angle);
				uint8_t servo_index = 0;		// Indice de ángulos
				uint16_t act_val = 0;			// Guarda el caracter actual
				uint8_t angulos[4] = {0};		// Para guardar los valores de los ángulos

				// Hasta que el indice sea igual al valor del indice de los datos ingresados
				for (uint8_t indice = 0; indice <= input_index; indice++) {
					// Se guarda el valor del caracter que va recorriendo
					char valor = input_angle[indice];
					
					// Se debe trabajar con números no con ASCII
					if (valor >= '0' && valor <= '9') {
						// Al restar '0' del valor de entrada se obtiene su valor decimal correcto
						// Al multiplicar por 10, se encuentra si es centa, decena o unidad
						act_val = act_val * 10 + (valor - '0');
					}
					
					// únicamente después de , o de ' ' o de '\0' guardará el valor (de lo contrario no ha terminado el ángulo)
					else if (valor == ',' || valor == '\0') {
						if (servo_index < 4) {
							if (act_val > 180) {
								//sendString("Ángulo %u inválido, ajustado a 180\r\n");
								act_val = 180;
							}
								// act_val contiene el valor numérico del ángulo
								// lo almacena en una posición diferente del array
								angulos[servo_index++] = act_val;
								act_val = 0;
						}
					}
				}
					// Guardar el último número si no terminó en coma
					if (servo_index < 4 && act_val > 0) {
						if (act_val > 180) act_val = 180;
						angulos[servo_index++] = act_val;
					}
				
					if (servo_index == 4) {
						OCR1A = 71 + (angulos[0] * (312 - 71)) / 180;
						OCR1B = 71 + (angulos[1] * (312 - 71)) / 180;
						OCR0A = 8 + (angulos[2] * (37 - 8)) / 180;
						OCR0B = 16 + (angulos[3] * (31 - 16)) / 180;
						
						// Enviar por UART como string tipo: 90,120,30,0\n
						// Temporal con tamaño max de 4 caracteres
						char str_val[4];
						for (uint8_t j = 0; j < 4; j++) {
							angle_to_str(angulos[j], str_val);
							sendString(str_val);
							if (j < 3) writeChar(',');  // No coma final
						}
						writeChar('\n');
						
					}

					input_index = 0;						 // Se resetea el indice de lo que entra
			}
			// Se establece un límite max en MAX_CHAR para los caracteres que puedan haber dejando espacio siempre para \n
			// Siempre que el valor sea diferente de \n
			else if (input_index < MAX_CHAR - 1) {
				input_angle[input_index++] = temporal;	 // Se guarda en un array el valor actual que se vaya leyendo
			}
	}
	
}




ISR(PCINT1_vect){
	if (!(PINC & (1 << PORTC5)))						// Se revisa si el botón de modo está presionado
	{
		//writeChar('M');
		modo++;
		if (modo >= 4)
		{
			modo = 1;
		}
	}
	else if (!(PINC & (1 << PORTC0)))					// Se revisa si el botón de EEPROM está presionado
	{
		//writeChar('E');
		btn_eeprom = 1;						
	}
}
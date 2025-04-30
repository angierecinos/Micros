/*
 * PreClase.c
 *
 * Created: 29/04/2025 15:38:49
 * Author: Angie
 * Description: Se hace la preclase
 */

//
// Encabezado (Libraries)
#include <avr/io.h>
#include <avr/interrupt.h>

uint8_t option = 0;
uint8_t menu_flag = 1;
uint8_t adc_value = 0;
uint8_t estado = 0;

//
// Function prototypes
void setup();
void initUART();
void sendString(char* texto);
void writeChar(char texto);
void showMenu(); 

//
// Main Function
int main(void)
{
	setup();
	while (1)
	{
		if (menu_flag)
		{
			//showMenu();
			menu_flag = 0;
		}
	}
}

//
// NON-Interrupt subroutines
void setup()
{
	cli();
	
	DDRB	&= ~(1 << PORTB0);				// Se setea puerto B como entrada
	PORTB	|= (1 << PORTB0);				// Se habilitan los pull ups internos
	DDRD	|= (1 << DDD7) | (1 << DDD6);	// Se setean PD6 y PD7 como salidas
	PORTD	= 0x00;							// Apaga la salida
	
	PCICR	|= (1 << PCIE0);				// Se habilitan interrupciones pin-change
	PCMSK0	|= (1 << PCINT0); 
	
	initUART();
	
	sei();
}

void showMenu()
{
	/*sendString("\r\n*** MENU ***\r\n");
	sendString("1: Encender led\r\n");
	sendString("2: Apagar led\r\n");
	sendString("Seleccione opcion: ");*/
	sendString("\r\n"
	"*** MENU ***\r\n"
	"1: Encender led\r\n"
	"2: Apagar led\r\n"
	"Seleccione opcion: ");
}

//
// Interrupt routines
ISR(USART_RX_vect)
{
	// Se recibe el dato
	char temporal = UDR0;
	// Eco automático de dato ingresado
	writeChar(temporal);
	sendString(" \r\n");
	
	if(temporal == '1') {
		sendString("\r\nLed encendido.\r\n");
		PORTD |= (1 << PORTD7);
			
	} else if(temporal == '2') {
		sendString("\r\nLed apagado.\r\n");
		PORTD &= ~(1 << PORTD7);
	} else {
		sendString("\r\nOpción no valida. Intente nuevamente.\r\n");	
	}
		menu_flag = 1;
}


ISR(PCINT0_vect){
	if (!(PINB & (1 << PORTB0))){
		if (estado == 0){
			PORTD |= (1 << PORTD6);
			estado = 1;
		} else if (estado == 1){
			PORTD &= ~(1 << PORTD6);
			estado = 0;
		}
	}
}

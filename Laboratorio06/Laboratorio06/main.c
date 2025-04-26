/*
 * Laboratorio06.c
 *
 * Created: 17/04/2025 11:48:01
 * Author : Angie
 * Description: Se utiliza comunicación serial
 */ 

//*******************************************
// Encabezado (Libraries)
#include <avr/io.h>
#include <avr/interrupt.h>

char temporalB; 
char temporalD;
uint8_t option = 0;
uint8_t menu_flag = 1; 
uint8_t adc_value = 0; 

//*******************************************
// Function prototypes
void setup();
void initUART(); 
void initADC();
void writeChar(char caracter); 
void sendString(char* texto); 
void showMenu();
void processASCII(char ascii); 

//*******************************************
// Main Function
int main(void)
{
	setup();
	//showMenu();
	/*writeChar('A');
	writeChar('N');
	writeChar('G');
	writeChar('I');
	writeChar('E');*/
	//sendString(" Me salio?");
	while (1)
	{
		// Si se activa la bandera, se muestra el menú
		// Se desactiva para ingresar la opción 
		if(menu_flag) {
			showMenu();
			menu_flag = 0;
		}
	}
}


//*******************************************
// NON-Interrupt subroutines
void setup()
{
	cli();
	DDRB = 0xFF;						// Se setea puerto B como salida 
	DDRD |=  (1 << DDD7) | (1 << DDD6);
	PORTB = 0x00;						// Apaga la salida
	initUART();
	initADC();
	sei();
}

void initUART()
{
	// Configurar PD0 y PD1 
	DDRD |=  (1 << DDD1);
	DDRD &= ~(1 << DDD0); 
	
	// Se apaga (no utilizo doble velocidad) 
	UCSR0A = 0; 
	// Habilitar interrupts recibir, recepcion y transmision 
	UCSR0B |= (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0); 
	// Modo asíncrono y con paridad deshabilitada | Quiero 8 bits 
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00); 
	// Valor UBRR = 103 -> 9600 @ 16MHz 
	UBRR0 = 103; 
}

void initADC()
{
	ADMUX	= 0;
	ADMUX	|= (1 << REFS0);					//ADMUX &= ~(1<< REFS1); // Se ponen los 5V como ref
	
	ADMUX	|= (1 << ADLAR);					// Justificación a la izquierda
	ADMUX	|= (1 << MUX1); //| (1<< MUX0);		// Seleccionar el ADC2
	ADCSRA	= 0;
	ADCSRA	|= (1 << ADPS1) | (1 << ADPS0);		// Frecuencia de muestreo de 125kHz
	ADCSRA	|= (1 << ADIE);						// Hab interrupción
	ADCSRA	|= (1 << ADEN);
	
}

void writeChar(char caracter)
{
	// Si no se hubiera esperado a que termine de trasladar, puede dar un error
	//uint8_t temporal = UCSR0A & (1 << UDRE0);
	while ((UCSR0A & (1 << UDRE0)) == 0);
	UDR0 = caracter; 
	
}

void sendString(char* texto)
{
	// Se hace siempre que indice sea diferente de un valor "nulo"
	// Aumenta el valor de indice
	for (uint8_t indice = 0; *(texto + indice) != '\0'; indice++)
	{
		writeChar(texto[indice]);
	}
}

void showMenu()
{
	sendString("\r\n*** MENU ***\r\n");
	sendString("1: Leer Potenciómetro\r\n");
	sendString("2: Enviar ASCII\r\n");
	sendString("Seleccione opción: ");
}

void processASCII(char ascii)
{
	
	// Se muestra el valor ascii ingresado en el puerto
	temporalB = ascii & 0x3F;
	temporalD = (ascii & 0xC0);
	PORTD = temporalD;
	PORTB = temporalB;
	menu_flag = 1; 
}

//*******************************************
// Interrupt routines
ISR(USART_RX_vect)
{
	// Se recibe el dato
	char temporal = UDR0;
	// Eco automático de dato ingresado
	writeChar(temporal);
	sendString(" \r\n");
	if(option == 0) {
		// Estamos en el menú principal
		if(temporal == '1') {
			option = 1;
			sendString("\r\nLeyendo potenciómetro... ");
			// Inicia una conversión
			ADCSRA	|= (1 << ADSC);
			} else if(temporal == '2') {
			option = 2;
			sendString("\r\nIngrese un caracter: ");
			} else {
			sendString("\r\nOpción no valida. Intente nuevamente.\r\n");
			menu_flag = 1;
		}
		} else if(option == 2) {
		// Estamos esperando un caracter ASCII una vez se selecciona option 2
		processASCII(temporal);
		option = 0;
	}
	
	/*temporalB = temporal & 0x3F;
	temporalD = (temporal & 0xC0);
	PORTD = temporalD;
	PORTB = temporalB;*/
}

ISR(ADC_vect)
{
	adc_value = ADCH;
	sendString("\r\nValor del potenciómetro: ");
	 
	// Convertir a ASCII y enviar dígito por dígito
	uint8_t centenas = adc_value / 100;					// únicamente se usa parte entera
	uint8_t decenas = (adc_value % 100) / 10;			// se utiliza residuo para obtener decenas
	uint8_t unidades = adc_value % 10;					// se utiliza residuo para obtener unidades
	 
	// '0' permite hacer conversión a un valor ascii (el que se mostrará)
	// Si no se suma a '0' se muestra el valor incorrecto
	writeChar(centenas + '0');
	writeChar(decenas + '0');
	writeChar(unidades + '0');
	sendString(" \r\n");
	 
	// Mostrar en puertos
	temporalB = adc_value & 0x3F;
	temporalD = (adc_value & 0xC0);
	PORTD = temporalD;
	PORTB = temporalB;
	menu_flag = 1;
	option = 0; 
}

/*
 * SERVO.c
 *
 * Created: 28/04/2025 15:42:51
 *  Author: Angie
 */ 

# include "SERVO.h"

void servo_positionA(uint16_t angulo)
{

	OCR0A = 2 + (angulo * (50-2)/240);

}

void servo_positionB(uint16_t angulo)
{
	OCR0B =  2 + (angulo*(50-2)/180);
}

void servo_position1A(uint16_t angulo)
{
	OCR1A = 71 + (angulo * (312-71) / 180);
}

void servo_position1B(uint16_t angulo)
{
	OCR1B =  71 + (angulo*(312-71)/180);
}

uint16_t mapeoADCtoPulse(uint16_t adc_val)
{
	return ((adc_val * 180) / 255);		// Escalar 0-255 a 125-250
}

uint16_t mapeoADCtoPulse1(uint16_t adc_val)
{
	return ((adc_val * 180) / 255);		// Escalar 0-255 a 125-250
}

void processCoord(char* input, uint16_t* angulos)
{
	uint8_t servo_index = 0;
	uint16_t temp_val = 0;
	char mensaje[40];

	for (uint8_t i = 0; input[i] != '\0'; i++) {
		if (input[i] >= '0' && input[i] <= '9') {
			temp_val = temp_val * 10 + (input[i] - '0');
		}
		else if (input[i] == ',' || input[i] == ' ') {
			if (servo_index < 4) {
				if (temp_val > 180) {
					sendString(mensaje, "Ángulo %u inválido, ajustado a 180\r\n", temp_val);
					sendString(mensaje);
					temp_val = 180;
				}
				angulos[servo_index++] = temp_val;
				temp_val = 0;
			}
		}
	}

	if (servo_index < 4) {
		if (temp_val > 180) {
			sendString(mensaje, "Ángulo %u inválido, ajustado a 180\r\n", temp_val);
			sendString(mensaje);
			temp_val = 180;
		}
		angulos[servo_index++] = temp_val;
	}

	while (servo_index < 4) {
		angulos[servo_index++] = 0;
	}
}
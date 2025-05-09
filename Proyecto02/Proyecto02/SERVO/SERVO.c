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

void processCoord(char* input)
{
	uint8_t servo_index = 0;		// Indice de ángulos
	uint16_t act_val = 0;			// Guarda el caracter actual
	uint8_t angulos[4] = {0};		// Para guardar los valores de los ángulos
		
	for (uint8_t indice = 0; input[indice] != '\0'; indice++) {
		// Se debe trabajar con números no con ASCII
		if (input[indice] >= '0' && input[indice] <= '9') {
			// Al restar '0' del valor de entrada se obtiene su valor decimal correcto
			// Al multiplicar por 10, se encuentra si es centa, decena o unidad
			act_val = act_val * 10 + (input[indice] - '0');
		}
		// únicamente después de , o de ' ' guardará el valor (de lo contrario no ha terminado el ángulo)
		else if (input[indice] == ',' || input[indice] == ' ') {
			if (servo_index < 4) {
				if (act_val > 180) {
					//sendString("Ángulo %u inválido, ajustado a 180\r\n");
					act_val = 180;
				}
				angulos[servo_index++] = act_val;
				act_val = 0;
			}
		}
	}

	// Guardar el último número si no terminó en coma
	if (servo_index < 4) {
		angulos[servo_index++] = act_val;
	}

	if (servo_index == 4) {
		servo_positionA(angulos[0]);
		servo_positionB(angulos[1]);
		servo_position1A(angulos[2]);
		servo_position1B(angulos[3]);
	} else {
		//sendString("Error: Ingrese 4 ángulos válidos.\r\n");
	}
	
}
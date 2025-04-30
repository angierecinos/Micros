import serial

#Crear comunicación serial con arduino -COM4- 
com_arduino = serial.Serial(port = 'COM4', baudrate=9600, timeout=0.1)

while True:
    ingreso = input("Seleccione 1 para encender el led o 2 para apagar el led: ")
    com_arduino.write(bytes(ingreso, 'utf-8'))
    retorno = com_arduino.readline().decode('utf-8').strip()
    print("Datos recibidos: ", retorno)
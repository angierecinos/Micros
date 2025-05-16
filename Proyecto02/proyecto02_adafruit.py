# Import standard python modules.
import sys
import time
import serial

# This example uses the MQTTClient instead of the REST client
from Adafruit_IO import MQTTClient
from Adafruit_IO import Client, Feed

# holds the count for the feed
run_count = 0

# Set to your Adafruit IO username and key.
# Remember, your key is a secret,
# so make sure not to publish it when you publish this code!
ADAFRUIT_IO_USERNAME = ""
ADAFRUIT_IO_KEY = ""

# Set to the ID of the feed to subscribe to for updates.
FEED_ID_Servo1_TX = 'Servo1_TX'
FEED_ID_Servo1_RX = 'Servo1_RX'
FEED_ID_Servo2_TX = 'Servo2_TX'
FEED_ID_Servo2_RX = 'Servo2_RX'
FEED_ID_Servo3_TX = 'Servo3_TX'
FEED_ID_Servo3_RX = 'Servo3_RX'
FEED_ID_Servo4_TX = 'Servo4_TX'
FEED_ID_Servo4_RX = 'Servo4_RX'
FEED_ID_Mode_TX = 'Mode_TX'
FEED_ID_EEPROM_TX = 'EEPROM_TX'

# Define "callback" functions which will be called when certain events 
# happen (connected, disconnected, message arrived).
def connected(client):
    """Connected function will be called when the client is connected to
    Adafruit IO.This is a good place to subscribe to feed changes. The client
    parameter passed to this function is the Adafruit IO MQTT client so you
    can make calls against it easily.
    """
    # Subscribe to changes on a feed named Counter.
    print('Subscribing to Feeds')
    client.subscribe(FEED_ID_Servo1_TX)
    client.subscribe(FEED_ID_Servo2_TX)
    client.subscribe(FEED_ID_Servo3_TX)
    client.subscribe(FEED_ID_Servo4_TX)
    client.subscribe(FEED_ID_Mode_TX)
    client.subscribe(FEED_ID_EEPROM_TX)
    print('Waiting for feed data...')

def disconnected(client):
    """Disconnected function will be called when the client disconnects."""
    sys.exit(1)

# Lista para almacenar los valores de los 4 servos
servo_values = [None, None, None, None]
caracter = 0

# Asignación de feeds a índice en la lista 
feed_to_index = {
    'Servo1_TX': 0,
    'Servo2_TX': 1,
    'Servo3_TX': 2,
    'Servo4_TX': 3,
}

def message(client, feed_id, payload):
    """Message function will be called when a subscribed feed has a new value.
    The feed_id parameter identifies the feed, and the payload parameter has
    the new value.
    """
    global caracter, servo_values
    print(f'Feed {feed_id} received new value: {payload}')

    # Mode change & EEPROM 
    if feed_id == FEED_ID_Mode_TX:
        if payload == "1":
            caracter = 'M'
            #print('Modo actualizado a: {modo_actual}')
            com_arduino.write(bytes ((str(caracter) + '\n'), 'utf-8'))
    elif feed_id == FEED_ID_EEPROM_TX:
        if payload == "1":
            caracter = 'E'
            com_arduino.write(bytes ((str(caracter) + '\n'), 'utf-8'))
        
    # Update value for servo feeds
    if feed_id in feed_to_index:
       index = feed_to_index[feed_id]
       servo_values[index] = int(payload)

    # Once each value has been defined
    if None not in servo_values:
        #if modo_actual == 2:
        # map function allows servo_values -> 'values'
        comando = ','.join(map(str, servo_values)) + '\n'
        com_arduino.write(bytes (comando, 'utf-8'))
        
        # Resetear para el próximo grupo
        #servo_values = [None, None, None, None]

    # Publish or "send" message to corresponding feed
    # print('Sendind data back: {0}'.format(payload))
    # client.publish(FEED_ID_Send, payload)
    # Since expecting real feedback, do not copy TX value directly on RX
    
com_arduino = serial.Serial(port = 'COM4', baudrate=9600, timeout=0.1)

# Create an MQTT client instance.
client = MQTTClient(ADAFRUIT_IO_USERNAME, ADAFRUIT_IO_KEY)

# Setup the callback functions defined above.
client.on_connect = connected
client.on_disconnect = disconnected
client.on_message = message

# Connect to the Adafruit IO server.
client.connect()

# The first option is to run a thread in the background so you can continue
# doing things in your program.
client.loop_background()

while True:
    """ 
    # Uncomment the next 3 lines if you want to constantly send data
    # Adafruit IO is rate-limited for publishing
    # so we'll need a delay for calls to aio.send_data()
    run_count += 1
    print('sending count: ', run_count)
    client.publish(FEED_ID_Send, run_count)
    """
    print('Running "main loop" ')
    global valores
    # Feedback reading
    if com_arduino.in_waiting:
        datos = com_arduino.readline().decode()
        print(f'Datos recibidos: "{datos}"')
        valores = datos.split(',')

        if len(valores) == 4:
            client.publish(FEED_ID_Servo1_RX, valores[0])
            client.publish(FEED_ID_Servo2_RX, valores[1])
            client.publish(FEED_ID_Servo3_RX, valores[2])
            client.publish(FEED_ID_Servo4_RX, valores[3])

    time.sleep(2)

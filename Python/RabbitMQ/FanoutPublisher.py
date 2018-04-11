import pika
import time
import random

# Create a connection using all defaults (username, password, port, etc...) on localhost
connection = pika.BlockingConnection(pika.ConnectionParameters('localhost'))

try:
    # Everything is done through the connection channel
    channel = connection.channel()

    #
    channel.exchange_declare(exchange='status',
                             exchange_type='fanout')

    while True:
        t = random.randint(1, 1000)
        # This is to publish an object on a queue designated by routing_key.
        channel.basic_publish(exchange='status',
                              routing_key='',
                              body=str(t))
        time.sleep(.001)

finally:
    # Ensure the connection is closed, even in case of an error
    connection.close()

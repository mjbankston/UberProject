import pika
import time
import random

# Create a connection using all defaults (username, password, port, etc...) on localhost
connection = pika.BlockingConnection(pika.ConnectionParameters('localhost'))

try:
    # Everything is done through the connection channel
    channel = connection.channel()

    # This call ensures there is a 'status' queue. If this is called multiple times,
    # the queue will only be created once.
    channel.queue_declare(queue='work_queue', durable=True)

    while True:
        t = random.randint(1, 5)
        # This is to publish an object on a queue designated by routing_key.
        channel.basic_publish(exchange='',
                              routing_key='work_queue',
                              body=str(t),
                              properties=pika.BasicProperties(
                                  delivery_mode=2,  # make message persistent
                              ))
        time.sleep(1)

finally:
    # Ensure the connection is closed, even in case of an error
    connection.close()

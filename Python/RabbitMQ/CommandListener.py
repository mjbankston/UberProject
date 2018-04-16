import pika
import time

parent_callback = None
channel = None


def command_callback(ch, method, properties, body):
    print('Received command: ' + str(body))
    ch.basic_ack(delivery_tag=method.delivery_tag)


def start_consuming():
    print('Waiting for commands...')
    channel.start_consuming()


def start_command_listener(callback):
    global parent_callback, channel
    parent_callback = callback
    connection = pika.BlockingConnection(
        pika.ConnectionParameters('localhost'))

    channel = connection.channel()

    channel.queue_declare(queue='command', durable=True)

    # Set prefetch_count to 1 to ensure each worker only gets one message a time.
    # This is to defeat dumb round-robin task queuing.
    channel.basic_qos(prefetch_count=1)

    channel.basic_consume(command_callback,
                          queue='command')

    try:
        start_consuming()
    except KeyboardInterrupt:
        connection.close()


if __name__ == '__main__':
    start_command_listener(command_callback)

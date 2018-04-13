import pika
import time

_parent_callback = None
_channel = None


def _command_callback(ch, method, properties, body):
    print('Received command: ' + str(body), end='', flush=True)
    ch.basic_ack(delivery_tag=method.delivery_tag)

def _start_consuming():
    print('Waiting for commands...')
    _channel.start_consuming()


def start_command_listener(callback):
    global _parent_callback, _channel
    _parent_callback = callback
    _connection = pika.BlockingConnection(
        pika.ConnectionParameters('localhost'))

    _channel = _connection.channel()

    _channel.queue_declare(queue='command', durable=True)

    # Set prefetch_count to 1 to ensure each worker only gets one message a time.
    # This is to defeat dumb round-robin task queuing.
    _channel.basic_qos(prefetch_count=1)

    _channel.basic_consume(_command_callback,
                           queue='command')

    _start_consuming()

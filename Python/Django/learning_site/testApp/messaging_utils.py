import json
import logging
import pika
import threading

logger = logging.getLogger('django.server')


_connection = None
_channel = None
_callback_functions = []


def _callback(ch, method, properties, body):
    for callback in _callback_functions:
        if callback is not None:
            callback(body)
        else:
            _callback_functions.remove(callback)


def _start_thread(ch):
    ch.start_consuming()


def _connect():
    _connection = pika.BlockingConnection(
        pika.ConnectionParameters(host='localhost'))
    if _connection is None:
        logger.error('Error connecting to RabbitMQ!')
        return
    _channel = _connection.channel()
    _channel.exchange_declare(exchange='status',
                              exchange_type='fanout')

    result = _channel.queue_declare(exclusive=True)
    queue_name = result.method.queue

    _channel.queue_bind(exchange='status',
                        queue=queue_name)

    _channel.basic_consume(_callback,
                           queue=queue_name,
                           no_ack=True)

    _consuming_thread = threading.Thread(
        target=_start_thread(_channel), daemon=True)
    _consuming_thread.start()


def start_streaming(callback):
    _callback_functions.append(callback)
    if _connection is None:
        _connect()

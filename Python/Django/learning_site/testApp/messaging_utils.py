import json
import logging
import pika
import threading

logger = logging.getLogger('django.server')


_connection = None
_channel = None
_callback_functions = []


def _on_connected(connection):
    global _connection
    _connection = connection
    _connection.channel(_on_channel_open)


def _on_channel_open(new_channel):
    global _channel
    _channel = new_channel
    _channel.exchange_declare(exchange='status',
                              exchange_type='fanout')
    _channel.queue_declare(_on_queue_declareok, exclusive=True)


def _on_queue_declareok(frame):
    _channel.queue_bind(_on_bindok,
                        exchange='status',
                        queue='')


def _on_bindok(frame):
    _channel.basic_consume(_handle_delivery,
                           queue='',
                           no_ack=True)


def _handle_delivery(channel, method, header, body):
    for callback in _callback_functions:
        if callback is not None:
            callback(body)
        else:
            _callback_functions.remove(callback)


def _start_thread():
    global _connection
    try:
        _connection.ioloop.start()
    except Exception as ex:
        logger.error(ex)
        _connection.close()
        _connection.ioloop.start()


def _connect():
    global _connection
    _connection = pika.SelectConnection(
        pika.ConnectionParameters(host='localhost'),
        _on_connected)
    #_channel = _connection.channel()
    # _channel.exchange_declare(exchange='status',
    #                          exchange_type='fanout')

    #result = _channel.queue_declare(exclusive=True)
    #queue_name = result.method.queue

    # _channel.queue_bind(exchange='status',
    #                    queue=queue_name)

    # _channel.basic_consume(_callback,
    #                       queue=queue_name,
    #                       no_ack=True)

    _consuming_thread = threading.Thread(
        target=_start_thread, daemon=True)
    _consuming_thread.start()


def start_streaming(callback):
    _callback_functions.append(callback)
    if _connection is None:
        _connect()


def stop_streaming(callback):
    if callback in _callback_functions:
        _callback_functions.remove(callback)
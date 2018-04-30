import json
import logging
import pika
import threading

logger = logging.getLogger('mq_messaging')


class BroadcastListener:

    def __init__(self, host, name):
        self.name = name
        self.host = host
        self._connection = None
        self._channel = None
        self._callback_functions = []

    def start_listening(self, callback):
        self._callback_functions.append(callback)
        if self._connection is None:
            self._connect()

    def stop_listening(self, callback):
        if callback in self._callback_functions:
            self._callback_functions.remove(callback)

    def _connect(self):
        self._connection = pika.SelectConnection(
            pika.ConnectionParameters(host=self.host),
            self._on_connected)
        self._consuming_thread = threading.Thread(
            target=self._start_thread, daemon=True)
        self._consuming_thread.start()

    def _on_connected(self, connection):
        self._connection = connection
        self._connection.channel(self._on_channel_open)

    def _on_channel_open(self, new_channel):
        self._channel = new_channel
        self._channel.exchange_declare(exchange=self.name,
                                       exchange_type='fanout')
        self._channel.queue_declare(self._on_queue_declareok, exclusive=True)

    def _on_queue_declareok(self, frame):
        self._channel.queue_bind(self._on_bindok,
                                 exchange=self.name,
                                 queue='')

    def _on_bindok(self, frame):
        self._channel.consume(self._handle_delivery,
                              queue='',
                              no_ack=True)

    def _handle_delivery(self, channel, method, header, body):
        for callback in self._callback_functions:
            if callback is not None:
                callback(body)
            else:
                self._callback_functions.remove(callback)

    def _start_thread(self):
        try:
            self._connection.ioloop.start()
        except Exception as ex:
            logger.error(ex)
        finally:
            self._connection.close()
            self._connection.ioloop.start()


class QueueConsumer:

    def __init__(self, host, queue_name):
        self.queue_name = queue_name
        self.host = host
        self._connection = None
        self._channel = None
        self._callback_functions = []

    def start_listening(self, callback):
        self._callback_functions.append(callback)
        if self._connection is None:
            self._connect()

    def stop_listening(self, callback):
        if callback in self._callback_functions:
            self._callback_functions.remove(callback)

    def _connect(self):
        self._connection = pika.SelectConnection(
            pika.ConnectionParameters(host=self.host),
            self._on_connected)
        self._consuming_thread = threading.Thread(
            target=self._start_thread, daemon=True)
        self._consuming_thread.start()

    def _on_connected(self, connection):
        self._connection = connection
        self._connection.channel(self._on_channel_open)

    def _on_channel_open(self, new_channel):
        self._channel = new_channel
        self._channel.queue_declare(self._on_queue_declareok, exclusive=True)

    def _on_queue_declareok(self, frame):
        self._channel.queue_bind(self._on_bindok,
                                 exchange='',
                                 queue=self.queue_name)

    def _on_bindok(self, frame):
        self._channel.consume(self._handle_delivery,
                              queue=self.queue_name,
                              no_ack=False)

    def _handle_delivery(self, channel, method, header, body):
        for callback in self._callback_functions:
            if callback is not None:
                callback(body)
            else:
                self._callback_functions.remove(callback)
        channel.basic_ack(delivery_tag=method.delivery_tag)

    def _start_thread(self):
        try:
            self._connection.ioloop.start()
        except Exception as ex:
            logger.error(ex)
        finally:
            self._connection.close()
            self._connection.ioloop.start()


class QueuePublisher:

    def __init__(self, host):
        self.host = host
        self._connection = None
        self._connect()

    def publish_queue_message(self, queue_name, msg):
        try:
            if self._connection.is_closed:
                self._connect()
            channel = self._connection.channel()
            channel.queue_declare(queue=queue_name, durable=True)
            channel.publish(exchange='',
                            routing_key=queue_name,
                            body=str(msg),
                            properties=pika.BasicProperties(
                                delivery_mode=2,  # make message persistent
                            ))
            logger.info('Successfully sent message to queue "' +
                        queue_name + '"')
        except Exception as ex:
            logger.error(ex)

    def _connect(self):
        self._connection = pika.BlockingConnection(
            pika.ConnectionParameters(self.host))

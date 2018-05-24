import json
import logging
import pika
import threading
import signal
import time

logger = logging.getLogger('mq_messaging')


class BlockingBroadcastListener:

    def __init__(self, host, broadcast_channel_name):
        self.name = broadcast_channel_name
        self.host = host
        self._connection = None
        self._channel = None
        self._callback_function = None

    def start_listening(self, callback):
        self._callback_function = callback
        self._connection = pika.BlockingConnection(
            pika.ConnectionParameters(self.host))
        self._channel = self._connection.channel()
        self._channel.exchange_declare(exchange=self.name,
                                       exchange_type='fanout')
        self._channel.queue_declare(exclusive=True)
        self._channel.queue_bind(exchange=self.name,
                                 queue='')

        self._channel.basic_consume(self._broadcast_callback,
                                    queue='',
                                    no_ack=True)
        try:
            self._channel.start_consuming()
        except KeyboardInterrupt:
            pass
        except Exception as ex:
            logger.error(ex)
        finally:
            self._connection.close()

    def close(self):
        self._connection.close()

    def _broadcast_callback(self, channel, method, properties, body):
        if self._callback_function is not None:
            self._callback_function(body)


class AsyncBroadcastListener:

    def __init__(self, host, broadcast_channel_name):
        self.name = broadcast_channel_name
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

    def close(self):
        self._connection.close()
        self._connection.ioloop.start()

    def _connect(self):
        self._connection = pika.SelectConnection(
            pika.ConnectionParameters(host=self.host),
            self._on_connected)
        self._consuming_thread = threading.Thread(
            target=self._start_thread)
        self._consuming_thread.daemon = True
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
        self._channel.basic_consume(self._handle_delivery,
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
        except KeyboardInterrupt:
            pass
        except Exception as ex:
            logger.error(ex)
        finally:
            self.close()


class BlockingTaskConsumer:

    def __init__(self, host, task_name):
        self.queue_name = task_name
        self.host = host
        self._connection = None
        self._channel = None
        self._callback_function = None

    def start_listening(self, callback):
        self._callback_function = callback
        self._connection = pika.BlockingConnection(
            pika.ConnectionParameters(self.host))
        self._channel = self._connection.channel()
        self._channel.queue_declare(queue=self.queue_name, durable=True)
        self._channel.basic_qos(prefetch_count=1)
        self._channel.basic_consume(self._queue_callback,
                                    queue=self.queue_name)
        try:
            self._channel.start_consuming()
        except KeyboardInterrupt:
            pass
        except Exception as ex:
            logger.error(ex)
        finally:
            self._connection.close()

    def close(self):
        self._connection.close()

    def _queue_callback(self, channel, method, properties, body):
        if self._callback_function is not None:
            self._callback_function(body)
            channel.basic_ack(delivery_tag=method.delivery_tag)


class AsyncTaskConsumer:

    def __init__(self, host, task_name):
        self.queue_name = task_name
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

    def close(self):
        self._connection.close()
        self._connection.ioloop.start()

    def _connect(self):
        self._connection = pika.SelectConnection(
            pika.ConnectionParameters(host=self.host),
            self._on_connected)
        self._consuming_thread = threading.Thread(
            target=self._start_thread)
        self._consuming_thread.daemon = True
        self._consuming_thread.start()

    def _on_connected(self, connection):
        self._connection = connection
        self._connection.channel(self._on_channel_open)

    def _on_channel_open(self, new_channel):
        self._channel = new_channel
        self._channel.queue_declare(
            self._on_queue_declareok, queue=self.queue_name, durable=True)

    def _on_queue_declareok(self, frame):
        self._channel.basic_qos(prefetch_count=1)
        self._channel.basic_consume(self._handle_delivery,
                                    queue=self.queue_name)

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
        except KeyboardInterrupt:
            pass
        except Exception as ex:
            logger.error(ex)
        finally:
            close()


class BroadcastPublisher:

    def publish_broadcast_message(self, broadcast_channel_name, msg):
        try:
            if self._connection is None or self._channel is None:
                self._connect()
            if self._connection.is_closed:
                self._connect()
            elif self._connection.is_closing:
                logger.warn(
                    'Failure to broadcast message because connection is closing.')
                return
            if self._channel.is_closed:
                self._channel = self._connection.channel()
            elif self._channel.is_closing:
                logger.warn(
                    'Failure to broadcast message because channel is closing.')
                return
            self._channel.exchange_declare(exchange=broadcast_channel_name,
                                           exchange_type='fanout')
            self._channel.publish(exchange=broadcast_channel_name,
                                  routing_key='',
                                  body=json.dumps(msg))
            logger.info(
                'Successfully sent broadcast message on channel "%s"' % broadcast_channel_name)
        except Exception as ex:
            logger.error(ex)

    def __init__(self, host):
        self.host = host
        self._connection = None
        self._channel = None
        self._connect()

    def _connect(self):
        try:
            self._connection = pika.BlockingConnection(
                pika.ConnectionParameters(self.host))
            self._channel = self._connection.channel()
        except Exception as ex:
            logger.error(ex)


class TaskPublisher:

    def publish_task(self, task_name, msg, timeout=30):
        try:
            if self._connection is None or self._channel is None:
                self._connect()
            if self._connection.is_closed:
                self._connect()
            elif self._connection.is_closing:
                logger.warn(
                    'Failure to broadcast message because connection is closing.')
                return
            if self._channel.is_closed:
                self._channel = self._connection.channel()
            elif self._channel.is_closing:
                logger.warn(
                    'Failure to broadcast message because channel is closing.')
                return
            self._channel.queue_declare(queue=task_name, durable=True)
            self._channel.publish(exchange='',
                                  routing_key=task_name,
                                  body=json.dumps(msg),
                                  properties=pika.BasicProperties(
                                      delivery_mode=2,  # make message persistent
                                      # expiration needs milliseconds as a string but take timeout in seconds as an integer
                                      expiration=str(timeout*1000)
                                  ))
            logger.info(
                'Successfully sent task message to queue "%s"' % task_name)
        except Exception as ex:
            logger.error(ex)

    def __init__(self, host):
        self.host = host
        self._connection = None
        self._channel = None
        self._connect()

    def _connect(self):
        try:
            self._connection = pika.BlockingConnection(
                pika.ConnectionParameters(self.host))
            self._channel = self._connection.channel()
        except Exception as ex:
            logger.error(ex)


def start_blocking_loop():
    print('Started blocking loop. Press Ctrl-C to finish...')
    try:
        while True:
            time.sleep(0.01)
    except KeyboardInterrupt:
        print('Blocking loop finished.')

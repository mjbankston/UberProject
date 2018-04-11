from channels.generic.websocket import WebsocketConsumer
from channels.generic.websocket import AsyncWebsocketConsumer
import json
import logging
import time
import pika
import threading

logger = logging.getLogger('django.server')


class StatusConsumer(WebsocketConsumer):

    def callback(self, ch, method, properties, body):
        self.send(text_data=json.dumps({
            'value': str(int(body))
        }))

    def start_streaming(self):
        logger.info('Starting status streaming...')
        self.connection = pika.BlockingConnection(
            pika.ConnectionParameters(host='localhost'))
        self.channel = self.connection.channel()
        self.channel.exchange_declare(exchange='status',
                                      exchange_type='fanout')

        self.result = self.channel.queue_declare(exclusive=True)
        self.queue_name = self.result.method.queue

        self.channel.queue_bind(exchange='status',
                                queue=self.queue_name)

        self.channel.basic_consume(self.callback,
                                   queue=self.queue_name,
                                   no_ack=True)

        self.channel.start_consuming()

    def connect(self):
        logger.info('Accepting a new connection...')
        self.accept()
        self.consuming_thread = threading.Thread(
            target=self.start_streaming, daemon=True)
        self.consuming_thread.start()

    def disconnect(self, close_code):
        pass

    def receive(self, text_data=None, bytes_data=None):
        logger.info('WebSocket Consumer received a message: ' + text_data)
        text_data_json = json.loads(text_data)
        message = 'Couldn\'t parse message.'
        if 'payload' in text_data_json:
            payload = text_data_json['payload']
            if 'message' in payload:
                message = payload['message']
        elif 'message' in text_data_json:
            message = text_data_json['message']

        self.send(text_data=json.dumps({
            'message': message
        }))

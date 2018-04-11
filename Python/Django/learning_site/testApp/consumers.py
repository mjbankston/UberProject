from channels.generic.websocket import WebsocketConsumer
from channels.generic.websocket import AsyncWebsocketConsumer
from . import messaging_utils
import json
import logging
import time
import pika
import threading

logger = logging.getLogger('django.server')


class StatusConsumer(WebsocketConsumer):

    def status_callback(self, body):
        self.send(text_data=json.dumps({
            'value': str(int(body))
        }))

    def connect(self):
        logger.info('Accepting a new connection...')
        self.accept()
        messaging_utils.start_streaming(self.status_callback)

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

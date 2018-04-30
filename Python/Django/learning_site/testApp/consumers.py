from channels.generic.websocket import WebsocketConsumer
from channels.generic.websocket import AsyncWebsocketConsumer
from mq_messaging.messenger import BroadcastListener
from mq_messaging.messenger import QueuePublisher
import json
import logging
import time
import pika
import threading

logger = logging.getLogger('django.server')


class StatusConsumer(WebsocketConsumer):

    def __init__(self, scope):
        super().__init__(scope)
        self.status_broadcast_listener = BroadcastListener(
            'localhost', 'status')
        self.queue_publisher = QueuePublisher('localhost')

    def status_callback(self, body):
        self.send(text_data=json.dumps({
            'value': str(int(body))
        }))

    def connect(self):
        self.accept()
        self.status_broadcast_listener.start_listening(self.status_callback)

    def disconnect(self, close_code):
        self.status_broadcast_listener.stop_listening(self.status_callback)

    def receive(self, text_data=None, bytes_data=None):
        if text_data is None:
            logger.info(
                'Websocket Consumer received a message but there is no text_data.')
            return
        text_data_json = json.loads(text_data)
        message = 'Couldn\'t parse message.'
        if 'stream' in text_data_json:
            payload = text_data_json['payload']
            if 'message' in payload:
                message = payload['message']
        elif 'sender' in text_data_json:
            if 'message' in text_data_json:
                message = text_data_json['message']
                if text_data_json['sender'] == 'command_button':
                    self.queue_publisher.publish_queue_message(
                        'command', message)
        else:
            logger.error(
                'WebSocket Consumer received a message without a sender field!')

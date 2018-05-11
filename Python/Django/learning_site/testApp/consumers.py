from channels.generic.websocket import WebsocketConsumer
from channels.generic.websocket import AsyncWebsocketConsumer
import mq_messaging.messenger as mq
import json
import logging
import time
import pika
import threading

logger = logging.getLogger('django.server')


class StatusConsumer(WebsocketConsumer):

    def __init__(self, scope):
        super().__init__(scope)
        self.signal_waveform_listener = mq.AsyncBroadcastListener(
            'localhost', 'signal_waveform')
        self.signal_psd_listener = mq.AsyncBroadcastListener(
            'localhost', 'psd')
        self.queue_publisher = mq.TaskPublisher('localhost')

    def signal_waveform_callback(self, body):
        ob = json.loads(body)
        real = []
        imag = []
        for c in ob:
            real.append(c[0])
            imag.append(c[1])
        self.send(text_data=json.dumps({
            'type': 'signal',
            'real': real,
            'imag': imag
        }))

    def psd_callback(self, body):
        ob = json.loads(body)
        self.send(text_data=json.dumps({
            'type': 'psd',
            'psd': ob,
        }))

    def connect(self):
        self.accept()
        self.signal_waveform_listener.start_listening(
            self.signal_waveform_callback)
        self.signal_psd_listener.start_listening(
            self.psd_callback)

    def disconnect(self, close_code):
        self.signal_waveform_listener.stop_listening(
            self.signal_waveform_callback)
        self.signal_psd_listener.stop_listening(
            self.psd_callback)

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

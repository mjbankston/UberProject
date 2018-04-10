from channels.generic.websocket import WebsocketConsumer
import json
import logging

logger = logging.getLogger('django.server')


class StatusConsumer(WebsocketConsumer):
    def connect(self):
        logger.info('Accepting a new connection...')
        self.accept()

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

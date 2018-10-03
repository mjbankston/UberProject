from kombu import Connection, Exchange, Queue
from kombu.mixins import ConsumerMixin

rabbit_url = 'amqp://guest:guest@localhost//'


class Worker(ConsumerMixin):
    def __init__(self, connection, queues):
        self.connection = connection
        self.queues = queues

    def get_consumers(self, Consumer, channel):
        return [Consumer(queues=self.queues,
                         callbacks=[self.on_message])]

    def on_message(self, body, message):
        print('Message is of type %s and is %i bytes long.',
              (type(body), len(body)))
        message.ack()


exchange = Exchange("acquisition", type="direct")
queues = [Queue("acquisiton-queue", exchange, routing_key="big")]

with Connection(rabbit_url, heartbeat=4) as conn:
    worker = Worker(conn, queues)
    print('Waiting for messages...')
    worker.run()

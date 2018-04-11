import pika

channel = None


def on_bindok(frame):
    def callback(ch, method, properties, body):
        print(int(body))

    channel.basic_consume(callback,
                          queue='',
                          no_ack=True)


def on_queue_declareok(frame):
    channel.queue_bind(on_bindok,
                       exchange='status',
                       queue='')


def on_channel_open(channel):
    channel.exchange_declare(exchange='status',
                             exchange_type='fanout')
    channel.queue_declare(on_queue_declareok, exclusive=True)


def on_connection_open(connection):
    global channel
    channel = connection.channel(on_open_callback=on_channel_open)


connection = pika.SelectConnection(
    pika.ConnectionParameters(host='localhost'),
    on_connection_open,
    stop_ioloop_on_close=False)

try:
    connection.ioloop.start()
except KeyboardInterrupt:
    connection.close()

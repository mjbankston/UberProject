import pika
import time

# Create a connection using all defaults (username, password, port, etc...) on localhost
connection = pika.BlockingConnection(pika.ConnectionParameters('localhost'))

# Everything is done through the connection channel
channel = connection.channel()

# This call ensures there is a 'status' queue. If this is called multiple times,
# the queue will only be created once.
channel.queue_declare(queue='work_queue', durable=True)

onJob = 0


def statusCallback(ch, method, properties, body):
    ''' 
    This is the callback method given to basic_consume. It receives the channel, method,
    properties context objects along with the body.
    '''
    global onJob
    print(str(onJob) + ': Received work to complete...', end='', flush=True)
    time.sleep(int(body))
    print('done. Acknowledging.')
    ch.basic_ack(delivery_tag=method.delivery_tag)
    onJob += 1


# Set prefetch_count to 1 to ensure each worker only gets one message a time.
# This is to defeat dumb round-robin task queuing.
channel.basic_qos(prefetch_count=1)

channel.basic_consume(statusCallback,
                      queue='work_queue')

print('Waiting for work to do...')
channel.start_consuming()

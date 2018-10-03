import kombu
import random
import time

SIZE = 2**19

a = bytearray()
b = bytearray()
for _ in range(SIZE):
    a.append(random.randint(0, 255))
    b.append(random.randint(0, 255))


def send_signals(producer: kombu.Producer):
    start = time.perf_counter_ns()
    for x in [a, b]:
        producer.publish(x, content_type='binary/signal',
                         content_encoding='binary')
    end = time.perf_counter_ns()
    diff_ms = (end - start) / 1000000
    print('Two signals sent in %ims' % diff_ms)


with kombu.Connection('amqp://guest:guest@localhost//') as conn:
    channel = conn.channel()
    exchange = kombu.Exchange("acquisition", type="direct")
    producer = kombu.Producer(
        exchange=exchange, channel=channel, routing_key="big")
    queue = kombu.Queue(name="acquisiton-queue",
                        exchange=exchange, routing_key="big")
    queue.maybe_bind(conn)
    queue.declare()
    for x in range(10):
        send_signals(producer)

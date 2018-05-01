import mq_messaging.messenger as mq
import random
import time
import string
import sys


def main(broadcast_channel_name):
    q = mq.BroadcastPublisher('localhost')
    while True:
        try:
            c = ''
            for i in range(10):
                c = c + random.choice(string.ascii_letters)
            print('Publishing broadcast message "%s" to channel %s' % (
                c, broadcast_channel_name))
            q.publish_broadcast_message(broadcast_channel_name, c)
            time.sleep(random.random())
        except KeyboardInterrupt:
            break


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print('Please supply a broadcast channel name.')
        sys.exit(1)
    main(sys.argv[1])
    sys.exit(0)

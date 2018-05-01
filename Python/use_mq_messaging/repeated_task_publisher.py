import mq_messaging.messenger as mq
import random
import time
import sys


def main(task_channel):
    q = mq.TaskPublisher('localhost')
    while True:
        try:
            n = random.randint(1, 1000)
            print('Publishing %s with value %i' % (task_channel, n))
            q.publish_task(task_channel, str(n), timeout=10)
            time.sleep(random.random())
        except KeyboardInterrupt:
            break


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print('Please supply a task channel name.')
        sys.exit(1)
    main(sys.argv[1])
    sys.exit(0)

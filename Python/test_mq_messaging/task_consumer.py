import mq_messaging as mq
import time
import random


def do_task1(task_data):
    print('Peforming task 1: %s' % task_data)
    time.sleep(random.random() * 5)


def do_task2(task_data):
    print('Peforming task 2: %s' % task_data)
    time.sleep(random.random() * 5)


def main():
    try:
        aq = mq.AsyncTaskConsumer('localhost', 'task1')
        aq.start_listening(do_task1)
        print('Started async task consumer for task1 channel.')
        bq = mq.BlockingTaskConsumer('localhost', 'task2')
        print('Starting blocking task listener for task2 channel...')
        bq.start_listening(do_task2)
    except KeyboardInterrupt:
        print('Stopping task consumer...')
        aq.stop_listening(do_task1)
        bq.close()


if __name__ == "__main__":
    main()

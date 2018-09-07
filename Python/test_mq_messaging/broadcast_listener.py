import mq_messaging as mq


def print_status(msg):
    print('Received broadcast STATUS message: %s' % msg)


def print_log(msg):
    print('Received broadcast LOG message: %s' % msg)


def main():
    q1 = mq.AsyncBroadcastListener('localhost', 'status')
    q1.start_listening(print_status)
    print('Now listening to STATUS broadcast messages asynchronously.')
    print('Starting blocking listener to LOG broadcast messages...')
    q2 = mq.BlockingBroadcastListener('localhost', 'log')
    try:
        q2.start_listening(print_log)
    except KeyboardInterrupt:
        print('Closing broadcast listener...')
        q1.stop_listening(print_status)
        q2.close()


if __name__ == "__main__":
    main()

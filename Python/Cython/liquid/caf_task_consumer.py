import mq_messaging.messenger as mq


def process_caf_request(req):
    print(req)


def main():
    print('Waiting for CAF requests...')
    q = mq.BlockingTaskConsumer('localhost', 'CAF_task')
    q.start_listening(process_caf_request)


if __name__ == "__main__":
    main()

import mq_messaging as mq


def process_caf_task(caf_task_input):
    print(caf_task_input)


print('Listening for CAF requests...')
caf_task_listener = mq.BlockingTaskConsumer('localhost', 'caf_task')
caf_task_listener.start_listening(process_caf_task)

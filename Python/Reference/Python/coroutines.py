import asyncio
from collections import namedtuple
import random
import uuid

TaskMessage = namedtuple('TaskMessage', ['type', 'uuid', 'data'])


async def client_connected(reader, writer):
    await reader.readline()


async def start_server(host, port):
    srv = await asyncio.start_server(client_connected, host, port)
    await srv.serve_forever()


async def task_reject(task):
    print('Rejecting task ' + task)


async def task_runner(task):
    print('Completing task ' + task.uuid + '...', end='')
    asyncio.sleep(1)
    print('done')


async def infinite_task_producer():
    try:
        while True:
            print('infinite_task_producer sending TaskMessage to task_filter')
            TaskMessage('task_type%i' % random.randint(1, 5), uuid.uuid4(),
                        '%i' % random.randint(1, 500))
            await asyncio.sleep(0.5)
    except KeyboardInterrupt:
        pass


asyncio.run(infinite_task_producer())

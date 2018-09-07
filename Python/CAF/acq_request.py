import mq_messaging as mq

req = {}
req['satellite1'] = 'testSat1'
req['satellite2'] = 'testSat2'

acq = mq.TaskPublisher('localhost')
acq.publish_task('acquisition_task', req)

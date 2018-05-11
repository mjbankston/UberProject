import liquid as l
import mq_messaging.messenger as mq
import time
import math
from timeit import default_timer as timer


def print_single_signal():
    signal = l.generate_signal(128, 2, 'QPSK')
    for c in signal:
        print(c)


def send_continuous_signal(num_samples=2**16, psd_fft_size=2**8, num_samples_to_send=128, send_rate_hz=0.1):
    running = True
    signal_publish = mq.BroadcastPublisher('localhost')
    try:
        last = timer()
        now = last
        while running:
            time.sleep(send_rate_hz - (now - last))
            now = timer()
            start = timer()
            signal = l.generate_signal(num_samples, 2, 'QPSK')
            end = timer()
            print('Signal generation took %f seconds.' % (end - start))

            signal_msg = []
            for c in signal:
                signal_msg.append([c.real, c.imag])
                if len(signal_msg) == num_samples_to_send:
                    break

            signal_publish.publish_broadcast_message(
                'signal_waveform', signal_msg)

            start = timer()
            psd = l.estimate_psd(psd_fft_size, signal)
            end = timer()
            print('Estimate PSD took %f seconds.' % (end - start))

            signal_publish.publish_broadcast_message('signal1_psd', psd)

            last = timer()
    except KeyboardInterrupt:
        running = False


def send_continuous_band(num_samples, psd_fft_size, send_rate_hz=0.05, noise_floor_dB=-60.0):

    TAU = 2*math.pi
    sources = []
    # sources.append(l.Source(source_type='NOISE',
    #                         normalized_center_frequency=0.4*2*math.pi,
    #                         gain=-40.0))

    sources.append(l.Source(source_type='TONE',
                            normalized_center_frequency=-0.4*TAU,
                            gain=-40.0))
    sources.append(l.Source(source_type='MODEM',
                            mod_type='QPSK',
                            normalized_center_frequency=-0.2*TAU,
                            samples_per_symbol=32,
                            gain=-40.0
                            ))
    sources.append(l.Source(source_type='MODEM',
                            mod_type='QPSK',
                            normalized_center_frequency=-0.1*TAU,
                            samples_per_symbol=32,
                            gain=-40.0
                            ))
    sources.append(l.Source(source_type='MODEM',
                            mod_type='QPSK',
                            normalized_center_frequency=0.0*TAU,
                            samples_per_symbol=32,
                            gain=-40.0
                            ))
    sources.append(l.Source(source_type='MODEM',
                            mod_type='BPSK',
                            normalized_center_frequency=0.3*TAU,
                            samples_per_symbol=8,
                            gain=-50.0
                            ))
    running = True
    psd_publish = mq.BroadcastPublisher('localhost')
    last = timer()
    now = last
    while running:
        try:
            time.sleep(send_rate_hz - (now - last))
            now = timer()
            start = timer()
            signal = l.generate_multi_source(
                num_samples=num_samples, sources=sources)
            end = timer()
            print('Band generation took %f seconds.' % (end - start))

            start = timer()
            psd = l.estimate_psd(psd_fft_size, signal)
            end = timer()
            print('Band estimate PSD took %f seconds.' % (end - start))

            psd_publish.publish_broadcast_message('psd', psd)

            last = timer()
        except KeyboardInterrupt:
            running = False

# print_single_signal()
# send_continuous_signal(num_samples=2**17, psd_fft_size=2**7, num_samples_to_send=256, send_rate_hz=0.1)


send_continuous_band(num_samples=2**11, psd_fft_size=2**11,
                     send_rate_hz=0.01, noise_floor_dB=-60.0)

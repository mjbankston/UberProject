from libc.stdlib cimport *

cdef extern from "liquid_test.h":
    int test()

cdef extern from "liquid_wrapper.h":

    cdef enum ModType:
        LIQUID_MODEM_UNKNOWN=0, # Unknown modulation scheme

        # Phase-shift keying (PSK)
        LIQUID_MODEM_PSK2,      LIQUID_MODEM_PSK4,
        LIQUID_MODEM_PSK8,      LIQUID_MODEM_PSK16,
        LIQUID_MODEM_PSK32,     LIQUID_MODEM_PSK64,
        LIQUID_MODEM_PSK128,    LIQUID_MODEM_PSK256,

        # Differential phase-shift keying (DPSK)
        LIQUID_MODEM_DPSK2,     LIQUID_MODEM_DPSK4,
        LIQUID_MODEM_DPSK8,     LIQUID_MODEM_DPSK16,
        LIQUID_MODEM_DPSK32,    LIQUID_MODEM_DPSK64,
        LIQUID_MODEM_DPSK128,   LIQUID_MODEM_DPSK256,

        # amplitude-shift keying
        LIQUID_MODEM_ASK2,      LIQUID_MODEM_ASK4,
        LIQUID_MODEM_ASK8,      LIQUID_MODEM_ASK16,
        LIQUID_MODEM_ASK32,     LIQUID_MODEM_ASK64,
        LIQUID_MODEM_ASK128,    LIQUID_MODEM_ASK256,

        # rectangular quadrature amplitude-shift keying (QAM)
        LIQUID_MODEM_QAM4,
        LIQUID_MODEM_QAM8,      LIQUID_MODEM_QAM16,
        LIQUID_MODEM_QAM32,     LIQUID_MODEM_QAM64,
        LIQUID_MODEM_QAM128,    LIQUID_MODEM_QAM256,

        # amplitude phase-shift keying (APSK)
        LIQUID_MODEM_APSK4,
        LIQUID_MODEM_APSK8,     LIQUID_MODEM_APSK16,
        LIQUID_MODEM_APSK32,    LIQUID_MODEM_APSK64,
        LIQUID_MODEM_APSK128,   LIQUID_MODEM_APSK256,

        # specific modem types
        LIQUID_MODEM_BPSK,      # Specific: binary PSK
        LIQUID_MODEM_QPSK,      # specific: quaternary PSK
        LIQUID_MODEM_OOK,       # Specific: on/off keying
        LIQUID_MODEM_SQAM32,    # 'square' 32-QAM
        LIQUID_MODEM_SQAM128,   # 'square' 128-QAM
        LIQUID_MODEM_V29,       # V.29 star constellation
        LIQUID_MODEM_ARB16OPT,  # optimal 16-QAM
        LIQUID_MODEM_ARB32OPT,  # optimal 32-QAM
        LIQUID_MODEM_ARB64OPT,  # optimal 64-QAM
        LIQUID_MODEM_ARB128OPT, # optimal 128-QAM
        LIQUID_MODEM_ARB256OPT, # optimal 256-QAM
        LIQUID_MODEM_ARB64VT,   # Virginia Tech logo

        # arbitrary modem type
        LIQUID_MODEM_ARB        # arbitrary QAM

    cdef enum source_type_enum:
        NOISE,
        TONE,
        MODEM

    cdef struct liquid_source:
        int source_type,
        float normalized_center_frequency,
        float normalized_noise_bandwidth,
        float gain,
        int modem_mod_type,
        int modem_samples_per_symbol,
        int modem_filter_delay,
        float modem_excess_bandwidth

    void liquid_generate_signal(int num_samples, int samples_per_symbol, int modType, float complex *signal_output)
    void liquid_estimate_psd(int num_samples, int fft_size, float complex *signal, float *psd)
    void liquid_generate_multi_source(int num_samples, int num_sources, liquid_source *sources, float noise_floor_dB, float complex *signal_output)

class Source:

    def __init__(self, source_type='NOISE', normalized_center_frequency=0.0, normalized_noise_bandwidth=1.0, mod_type='UNKNOWN', gain=0.0, samples_per_symbol=2, filter_delay=7, excess_bandwidth=0.3):
        self.source_type = source_type
        self.normalized_center_frequency = normalized_center_frequency
        self.normalized_noise_bandwidth = normalized_noise_bandwidth
        self.mod_type = mod_type
        self.gain = gain
        self.samples_per_symbol = samples_per_symbol
        self.filter_delay = filter_delay
        self.excess_bandwidth = excess_bandwidth

def _get_liquid_mod_type(mod_type_str):
    cdef int m = 0
    mt = mod_type_str.upper()
    if mt == "BPSK":
        m = ModType.LIQUID_MODEM_BPSK
    elif mt == "QPSK":
        m = ModType.LIQUID_MODEM_QPSK
    else:
        m = ModType.LIQUID_MODEM_UNKNOWN
    return m

def test():
    num_samples = 30000
    fft_size = 4096
    cdef float complex *signal = <float complex*> malloc(num_samples*sizeof(float complex))
    cdef float *psd = <float*> malloc(fft_size*sizeof(float))
    try:
        liquid_generate_signal(num_samples, 2, ModType.LIQUID_MODEM_BPSK, signal)
        liquid_estimate_psd(num_samples, fft_size, signal, psd)
        for i in range(fft_size):
            print(psd[i])
    finally:
        free(signal)
        free(psd)

def generate_signal(num_samples, samples_per_symbol, mod_type):
    cdef float complex *signal = <float complex*> malloc(num_samples*sizeof(float complex))
    cdef int m = _get_liquid_mod_type(mod_type)
    try:

        liquid_generate_signal(num_samples, samples_per_symbol, m, signal)
        result = []
        for i in range(num_samples):
            result.append(signal[i])
        return result
    finally:
        free(signal)

def estimate_psd(fft_size, signal):
    num_samples = len(signal)
    cdef float complex *c_signal = <float complex*> malloc(num_samples*sizeof(float complex))
    cdef float *psd = <float*> malloc(fft_size*sizeof(float))
    try:
        for index, c in enumerate(signal):
            c_signal[index] = c
        liquid_estimate_psd(num_samples, fft_size, c_signal, psd)
        result = []
        for i in range(fft_size):
            f = (i / fft_size) - 0.5
            result.append({'x' : round(f, 2), 'y' : psd[i]})
        return result
    finally:
        free(c_signal)
        free(psd)

def generate_multi_source(num_samples, sources=[], noise_floor_dB=-60):
    cdef liquid_source *liquid_sources = <liquid_source*> malloc(len(sources)*sizeof(liquid_source))
    cdef float complex *signal = <float complex*> malloc(num_samples*sizeof(float complex))
    for i, s in enumerate(sources):
        next_source = {'source_type' : source_type_enum.NOISE, 'normalized_center_frequency' : s.normalized_center_frequency, 
                      'normalized_noise_bandwidth' : s.normalized_noise_bandwidth, 'gain' : s.gain,
                      'modem_mod_type' : _get_liquid_mod_type(s.mod_type),
                      'modem_samples_per_symbol' : s.samples_per_symbol, 'modem_filter_delay' : s.filter_delay,
                      'modem_excess_bandwidth' : s.excess_bandwidth}
        ty = s.source_type.upper()
        if ty == 'TONE':
            next_source['source_type'] = source_type_enum.TONE
        elif ty == 'MODEM':
            next_source['source_type'] = source_type_enum.MODEM
        liquid_sources[i] = next_source
    liquid_generate_multi_source(num_samples, len(sources), liquid_sources, noise_floor_dB, signal)
    result = []
    for i in range(num_samples):
        result.append(signal[i])
    return result
    
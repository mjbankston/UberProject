from libc.stdlib cimport *

cdef extern from "<complex.h>":
    pass

cdef extern from "liquid_wrapper.h":
    int test()

cdef extern from "liquid_generator.h":
    cdef float complex[:] complex_array

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
    void generate_signal(int num_samples, int samples_per_symbol, ModType modType, float complex *sample_array)

def test():
    num_samples = 30000
    cdef float complex *signal = <float complex*> malloc(num_samples*sizeof(float complex))
    try:
        generate_signal(num_samples, 2, ModType.LIQUID_MODEM_BPSK, signal)
        
    finally:
        free(c) 
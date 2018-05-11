#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "liquid.h"

enum source_type_enum
{
    NOISE,
    TONE,
    MODEM
};

struct liquid_source
{
    int source_type;
    float normalized_center_frequency;
    float normalized_noise_bandwidth;
    float gain;
    int modem_mod_type;
    int modem_samples_per_symbol;
    int modem_filter_delay;
    float modem_excess_bandwidth;
};

void liquid_generate_signal(int num_samples, int samples_per_symbol, int modType, float complex *signal_output)
{
    unsigned int m = 7; // filter delay (symbols)
    float beta = 0.30f; // filter excess bandwidth factor
    symstreamcf gen = symstreamcf_create_linear(LIQUID_FIRFILT_ARKAISER, samples_per_symbol, m, beta, modType);
    symstreamcf_write_samples(gen, signal_output, num_samples);
    symstreamcf_destroy(gen);
}

void liquid_estimate_psd(int num_samples, int fft_size, float complex *signal, float *psd)
{
    // This function creates and destroys a spgramcf object
    spgramcf_estimate_psd(fft_size, signal, num_samples, psd);
}

void liquid_generate_multi_source(int num_samples, int num_sources, struct liquid_source *sources, float noise_floor_dB, float complex *signal_output)
{
    msourcecf gen = msourcecf_create();
    // Add the noise floor
    int id;
    id = msourcecf_add_noise(gen, 1.00f);
    msourcecf_set_gain(gen, id, noise_floor_dB);

    // Now add sources one by one
    for (int i = 0; i < num_sources; i++)
    {
        struct liquid_source source = sources[i];
        if (source.source_type == NOISE)
        {
            id = msourcecf_add_noise(gen, source.normalized_noise_bandwidth);
        }
        else if (source.source_type == TONE)
        {
            id = msourcecf_add_tone(gen);
        }
        else if (source.source_type == MODEM)
        {
            id = msourcecf_add_modem(gen, source.modem_mod_type, source.modem_samples_per_symbol,
                                     source.modem_filter_delay, source.modem_excess_bandwidth);
        }
        if (source.normalized_center_frequency != 0.0)
        {
            msourcecf_set_frequency(gen, id, source.normalized_center_frequency);
        }
        if (source.gain != 0.0)
        {
            msourcecf_set_gain(gen, id, source.gain);
        }
    }
    msourcecf_write_samples(gen, signal_output, num_samples);
    msourcecf_destroy(gen);
}

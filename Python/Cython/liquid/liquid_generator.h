#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "liquid.h"

void generate_signal(int num_samples, int samples_per_symbol, int modType, float complex *sample_array)
{
    float complex z1 = 1.0 + 2.0 * I;
    printf("Generating signal\n");
    printf("    Number of samples to return: %d\n", num_samples);
    printf("    ModType is: %d\n", modType);
    unsigned int m = 7; // filter delay (symbols)
    float beta = 0.20f; // filter excess bandwidth factor
    symstreamcf gen = symstreamcf_create_linear(LIQUID_FIRFILT_ARKAISER, samples_per_symbol, m, beta, modType);
    symstreamcf_write_samples(gen, sample_array, num_samples);
    symstreamcf_destroy(gen);
}
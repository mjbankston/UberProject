#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "liquid.h"

int test()
{
    srand(time(NULL));
    float phase_offset = M_PI / 10;
    float frequency_offset = 0.001f;
    float SNRdB = 30.0f;
    float pll_bandwidth = 0.02f;
    modulation_scheme ms = LIQUID_MODEM_QPSK;
    unsigned int n = 256; // number of iterations
    unsigned int d = n / 32;

    nco_crcf nco_tx = nco_crcf_create(LIQUID_VCO);
    nco_crcf nco_rx = nco_crcf_create(LIQUID_VCO);

    modem mod = modem_create(ms);
    modem demod = modem_create(ms);

    unsigned int bps = modem_get_bps(mod);

    nco_crcf_set_phase(nco_tx, phase_offset);
    nco_crcf_set_frequency(nco_tx, frequency_offset);
    nco_crcf_pll_set_bandwidth(nco_rx, pll_bandwidth);
    float noise_power = powf(10.0f, -SNRdB / 20.0f);

    unsigned int i, M = 1 << bps, sym_in, sym_out, num_errors = 0;
    float phase_error;
    float complex x, r, v, noise;
    for (i = 0; i < n; i++)
    {
        // generate random symbol
        sym_in = rand() % M;

        // modulate
        modem_modulate(mod, sym_in, &x);

        // channel
        //r = nco_crcf_cexpf(nco_tx);
        nco_crcf_mix_up(nco_tx, x, &r);

        // add complex white noise
        crandnf(&noise);
        r += noise * noise_power;

        //
        //v = nco_crcf_cexpf(nco_rx);
        nco_crcf_mix_down(nco_rx, r, &v);

        // demodulate
        modem_demodulate(demod, v, &sym_out);
        num_errors += count_bit_errors(sym_in, sym_out);

        // error estimation
        //phase_error = cargf(r*conjf(v));
        phase_error = modem_get_demodulator_phase_error(demod);

        // perfect error estimation
        //phase_error = nco_tx->theta - nco_rx->theta;

        if ((i + 1) % d == 0 || i == n - 1)
        {
            printf("  %4u: e_hat : %6.3f, phase error : %6.3f, freq error : %6.3f\n",
                   i + 1,                                                          // iteration
                   phase_error,                                                    // estimated phase error
                   nco_crcf_get_phase(nco_tx) - nco_crcf_get_phase(nco_rx),        // true phase error
                   nco_crcf_get_frequency(nco_tx) - nco_crcf_get_frequency(nco_rx) // true frequency error
            );
        }

        // update tx nco object
        nco_crcf_step(nco_tx);

        // update pll
        nco_crcf_pll_step(nco_rx, phase_error);

        // update rx nco object
        nco_crcf_step(nco_rx);
    }

    nco_crcf_destroy(nco_tx);
    nco_crcf_destroy(nco_rx);

    modem_destroy(mod);
    modem_destroy(demod);

    printf("bit errors: %u / %u\n", num_errors, bps * n);
    printf("done.\n");

    return 0;
}


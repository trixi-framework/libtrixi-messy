#include <stdio.h>
#include <math.h>

/* 
 * Example for an external source term evaluation
 * Diagonally running wave, taken from Trixi.jl's source_terms_convergence_test
 */
void source_term_wave(const double * u, const double * x, const double t,
                      const double gamma, double * sourceterm) {

    const double c = 2.0;
    const double A = 0.1;
    const double L = 2.0;
    const double f = 1.0 / L;
    const double omega = 2 * M_PI * f;

    const double si = sin(omega * (x[0] + x[1] - t));
    const double co = cos(omega * (x[0] + x[1] - t));
    const double rho = c + A * si;
    const double rho_x = omega * A * co;
    const double tmp = (2 * rho - 1) * (gamma - 1);

    sourceterm[0] = rho_x;
    sourceterm[1] = rho_x * (1 + tmp);
    sourceterm[2] = sourceterm[1];
    sourceterm[3] = 2 * rho_x * (rho + tmp);
}

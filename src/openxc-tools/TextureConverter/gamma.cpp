/*
 * gamma.cpp -- --gamma_in and --gamma_out.
 *
 * Both take a number or the word sRGB.  A number is a power law over the
 * colour channels, alpha untouched, and both are NVTT's: at a gamma of exactly 2.2 it does not call powf at all but a
 * pair of table-and-polynomial approximations good to about three parts in
 * a million, which is far enough from a correctly rounded powf to show in
 * every second sample.  Anything else goes through powf.
 *
 * See nvmath/Gamma.cpp and nvimage/FloatImage.cpp: this is FloatImage's
 * toLinear and toGamma over three components, on an interleaved image
 * rather than a planar one.
 *
 * Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include "nvmath/Gamma.h"

#include <cmath>

#include "gamma.h"

/*
 * The sRGB transfer, which is what the word asks for rather than a power
 * of 2.2.  Both directions are NVTT's Surface.cpp, and the encode is not
 * the specification's: its exponent is 0.41666 where the standard says
 * five twelfths, and that shows in the sixth digit of every sample.  The
 * decode is the standard one.
 */
void
image_srgb(float *rgba, int w, int h, int to_linear)
{
	size_t n = (size_t)w * (size_t)h, i;
	int c;

	for (i = 0; i < n; i++) {
		for (c = 0; c < 3; c++) {
			float *p = &rgba[i * 4 + (size_t)c];
			float f = *p;

			if (to_linear) {
				if (f < 0.0f)
					f = 0.0f;
				else if (f < 0.04045f)
					f = f / 12.92f;
				else if (f <= 1.0f)
					f = powf((f + 0.055f) / 1.055f, 2.4f);
				else
					f = 1.0f;
			} else {
				if (f != f || f <= 0.0f)
					f = 0.0f;
				else if (f <= 0.0031308f)
					f = 12.92f * f;
				else if (f <= 1.0f)
					f = (powf(f, 0.41666f) * 1.055f) -
					    0.055f;
				else
					f = 1.0f;
			}
			*p = f;
		}
	}
}

void
image_gamma(float *rgba, int w, int h, float gamma, int to_linear)
{
	size_t n = (size_t)w * (size_t)h, i;
	int c;

	for (i = 0; i < n; i++) {
		for (c = 0; c < 3; c++) {
			float *p = &rgba[i * 4 + (size_t)c];

			if (gamma == 2.2f) {
				if (to_linear)
					nv::powf_11_5(p, p, 1);
				else
					nv::powf_5_11(p, p, 1);
			} else {
				*p = powf(*p < 0.0f ? 0.0f : *p,
				    to_linear ? gamma : 1.0f / gamma);
			}
		}
	}
}

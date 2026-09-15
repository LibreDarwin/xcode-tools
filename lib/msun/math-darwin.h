/*
 * math.h -- the interface, for a system that does not publish one.
 *
 * This is an adapter, not a math library.  The declarations come from
 * msun/math.h next to it, taken unmodified from FreeBSD so it can be
 * updated by replacing the file; what this adds is the handful of
 * macros that file is written against.
 *
 * msun gates its declarations on FreeBSD's visibility macros --
 * __ISO_C_VISIBLE and friends, set by FreeBSD's <sys/cdefs.h>.  Apple's
 * cdefs.h answers the same question with __DARWIN_C_LEVEL and defines
 * none of them, so msun's math.h parses on this system and declares
 * almost nothing: FP_NAN and the rest sit inside "#if __ISO_C_VISIBLE >=
 * 1999" and never appear.  That is why installing it alone left <cmath>
 * still unable to find them.
 *
 * The values below are the visibility FreeBSD's cdefs.h selects for a
 * default compilation -- C11, POSIX 2008, XSI 7, BSD extensions on --
 * which is what a macOS SDK exposes too.  Each is guarded, so a program
 * that has already chosen its own level keeps it.
 *
 * Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

#ifndef _XNUPORTS_MATH_H_
#define _XNUPORTS_MATH_H_

#include <sys/cdefs.h>

#ifndef __ISO_C_VISIBLE
#define __ISO_C_VISIBLE		2011
#endif
#ifndef __POSIX_VISIBLE
#define __POSIX_VISIBLE		200809
#endif
#ifndef __XSI_VISIBLE
#define __XSI_VISIBLE		700
#endif
#ifndef __BSD_VISIBLE
#define __BSD_VISIBLE		1
#endif
#ifndef __EXT1_VISIBLE
#define __EXT1_VISIBLE		1
#endif

/*
 * The evaluation types.  FreeBSD declares __float_t and __double_t in
 * <machine/_types.h>; Apple's has no such thing, so they are derived
 * here from the compiler's own account of how it evaluates floating
 * point, which is what the C standard says they mean.
 */
#ifndef __FLT_EVAL_METHOD__
#define __FLT_EVAL_METHOD__	0
#endif

#if __FLT_EVAL_METHOD__ == 0
typedef float		__float_t;
typedef double		__double_t;
#elif __FLT_EVAL_METHOD__ == 1
typedef double		__float_t;
typedef double		__double_t;
#else
typedef long double	__float_t;
typedef long double	__double_t;
#endif

/*
 * __INT_MAX is FreeBSD's, from <machine/_limits.h>.  Darwin has no such
 * header, and msun's math.h writes FP_ILOGB0 and FP_ILOGBNAN in terms
 * of it.
 */
#ifndef __INT_MAX
#define __INT_MAX		2147483647
#endif

#include <msun/math.h>

/*
 * FP_ILOGB0 and FP_ILOGBNAN, corrected to this platform's.
 *
 * C allows either INT_MIN or -INT_MAX for FP_ILOGB0, and msun picks
 * FreeBSD's answer: -INT_MAX for zero and +INT_MAX for NaN.  The libm
 * this SDK links is Apple's, and it returns INT_MIN for both --
 * measured, ilogb(0.0) and ilogb(NAN) are each -2147483648, which is
 * what Apple's own math.h says.  msun's FP_ILOGBNAN does not merely
 * differ, it has the wrong sign, so anything comparing against it
 * would be wrong about every NaN.
 *
 * Redefined after the include because msun defines them unguarded.
 */
#undef FP_ILOGB0
#undef FP_ILOGBNAN
#define FP_ILOGB0		(-2147483647 - 1)
#define FP_ILOGBNAN		(-2147483647 - 1)

/*
 * The classification macros, pointed at the libm this SDK links.
 *
 * msun spells the double forms FreeBSD's way -- __isinf, __isfinite,
 * __isnormal, __signbit -- and libSystem on arm64 has none of them, so
 * isinf() on a double compiled and then did not link.  Nor are Apple's
 * d-suffixed exports a substitute: __isnormald answers 1 for a
 * subnormal.  Apple's math.h calls neither under clang; it tests the
 * value inline with the compiler's builtins, and so do these.  (It falls
 * back to library calls only under -ffast-math, where the inline tests
 * are unreliable; builtins are no worse there than those calls.)
 *
 * FP_NAN and the rest are Apple's numbers for the same reason as
 * FP_ILOGB0 above: fpclassify() is Apple's __fpclassifyd, which answers
 * 1 for a NaN where msun's constants say 2, so every comparison against
 * msun's values was wrong.
 */
#undef FP_NAN
#undef FP_INFINITE
#undef FP_ZERO
#undef FP_NORMAL
#undef FP_SUBNORMAL
#define FP_NAN			1
#define FP_INFINITE		2
#define FP_ZERO			3
#define FP_NORMAL		4
#define FP_SUBNORMAL		5

#undef isfinite
#undef isinf
#undef isnan
#undef isnormal
#undef signbit
#define isfinite(x)	__builtin_isfinite(x)
#define isinf(x)	__builtin_isinf(x)
#define isnan(x)	__builtin_isnan(x)
#define isnormal(x)	__builtin_isnormal(x)
#define signbit(x)	__builtin_signbit(x)

#endif /* _XNUPORTS_MATH_H_ */

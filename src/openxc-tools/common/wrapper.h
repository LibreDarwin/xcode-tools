/*
 * wrapper.h -- run one of two implementations of a tool, the way Xcode's
 * m4 and yacc do.
 *
 * Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

#ifndef __WRAPPER_H__
#define __WRAPPER_H__

#include <getopt.h>

struct wrapper_impl {
	const char		*name;		/* the tool xcrun runs */
	const char		*optstring;	/* its short options */
	const struct option	*longopts;	/* its long options */
	const char		*prepend;	/* an argument put first, or NULL */
};

/*
 * Choose gnu or bsd and exec it through xcrun with argv's arguments.
 *
 * The environment variable envvar names one outright when it is exactly
 * that implementation's name.  Otherwise the arguments decide: gnu when
 * its options accept them all, else bsd when bsd's do, else gnu.
 * Returns only on failure, after reporting it.
 */
int	wrapper_execute(int argc, char *argv[], const char *envvar,
	    const struct wrapper_impl *gnu, const struct wrapper_impl *bsd);

#endif /* __WRAPPER_H__ */

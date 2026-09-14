/*
 * wrapper.c -- run one of two implementations of a tool, the way Xcode's
 * m4 and yacc do.
 *
 * Xcode's toolchain carries GNU and BSD versions of both -- gm4 and bm4,
 * bison and byacc -- and m4 and yacc are small programs that pick one.
 * Written from how Apple's behave:
 *
 *   - COMMAND_M4 or COMMAND_YACC set to exactly one implementation's name
 *     picks it.  Any other value, a path included, is ignored.
 *   - Otherwise the arguments are parsed with each implementation's own
 *     options, permuted as getopt_long permutes.  The GNU one is used when
 *     it accepts everything; the BSD one when it does; and the GNU one when
 *     neither does, so its error is the one printed.  So "m4 -g" runs bm4,
 *     "m4 -D -g" (where -g is -D's argument) runs gm4, and "m4 -Q -g",
 *     which neither accepts, runs gm4.
 *   - The choice runs through xcrun under its own name, with the arguments
 *     unchanged -- except that bison is given -y first, which is what makes
 *     it behave as yacc.
 *
 * Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <err.h>
#include <limits.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "wrapper.h"
#include "xcselect.h"

static bool
accepts(int argc, char *argv[], const struct wrapper_impl *impl)
{
	int c;

	optind = 1;
	optreset = 1;
	opterr = 0;
	while ((c = getopt_long(argc, argv, impl->optstring, impl->longopts,
	    NULL)) != -1) {
		if (c == '?' || c == ':')
			return false;
	}
	return true;
}

int
wrapper_execute(int argc, char *argv[], const char *envvar,
    const struct wrapper_impl *gnu, const struct wrapper_impl *bsd)
{
	const struct wrapper_impl *impl;
	char devdir[PATH_MAX];
	const char *env;
	char **args;
	int n = 0;

	/*
	 * The parses run on argv itself, and getopt_long permutes it, so what
	 * is passed on has its options ahead of its operands -- "m4 x.m4 -g"
	 * runs "bm4 -g x.m4", as Apple's does.  A name in the environment
	 * skips the parse and passes argv as it came.
	 */
	env = getenv(envvar);
	if (env != NULL && strcmp(env, gnu->name) == 0)
		impl = gnu;
	else if (env != NULL && strcmp(env, bsd->name) == 0)
		impl = bsd;
	else if (accepts(argc, argv, gnu))
		impl = gnu;
	else if (accepts(argc, argv, bsd))
		impl = bsd;
	else
		impl = gnu;

	if ((args = calloc((size_t)argc + 1, sizeof(*args))) == NULL)
		err(1, "malloc");
	if (impl->prepend != NULL)
		args[n++] = (char *)impl->prepend;
	for (int i = 1; i < argc; i++)
		args[n++] = argv[i];

	if (!xcselect_get_developer_dir_path(devdir, sizeof(devdir), NULL, NULL,
	    NULL))
		errx(1, "Could not obtain developer dir path");
	xcselect_invoke_xcrun(impl->name, n, args, 0);
	err(1, "execv(%s)", impl->name);
}

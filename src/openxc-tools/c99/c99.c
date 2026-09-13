/*
 * c99 -- the POSIX c99 command.
 *
 * A front end that runs the clang installed beside it, with c99's options
 * translated into clang's.  Apple publish no source for theirs, so this is
 * written from what it passes: a fixed set of flags, then the options and
 * operands in the order given, each spelled as clang spells it, then -m64
 * unless -W chose a pointer size, then -liconv when the command links.
 *
 *	-D -U -I -L -O	joined to their argument
 *	-l lib		-llib; -l pthread and -l xnet are dropped
 *	-W 32|64	-m32 or -m64
 *	-W verbose	-v
 *	-W macros	-x c -E -dM /dev/null, and counts as -E
 *
 * Options are recognised after operands as well as before them.  After
 * "--" everything is an operand, and one beginning with '-' is passed as
 * ./<name> so that clang cannot take it for an option.
 *
 * Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <err.h>
#include <limits.h>
#include <mach-o/dyld.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sysexits.h>
#include <unistd.h>

static const char *const prepended[] = {
	"-std=iso9899:1999", "-pedantic", "-Wextra-tokens",
	"-Wno-error=return-type", "-Wstatic-in-inline", "-Wignored-qualifiers",
	"-fmath-errno", "-fno-blocks", "-Wno-nullability-completeness",
	"-Wno-nullability-extension", "-iworkdir=os",
};

static char **args;
static size_t nargs, cargs;

static void
add(const char *s)
{
	if (nargs == cargs) {
		cargs = cargs ? cargs * 2 : 64;
		if ((args = realloc(args, cargs * sizeof(*args))) == NULL)
			err(EX_OSERR, "malloc");
	}
	args[nargs++] = (char *)s;
}

static const char *
cat(const char *a, const char *b)
{
	char *s;

	if (asprintf(&s, "%s%s", a, b) < 0)
		err(EX_OSERR, "malloc");
	return s;
}

static void __dead2
usage(void)
{
	fprintf(stderr,
	    "usage: c99 [-cEgs] [-D name[=value]] [-I directory] ... [-L directory] ...\n"
	    "       [-o outfile] [-O optlevel] [-U name]... [-W 64] operand ...\n");
	exit(1);
}

int
main(int argc, char *argv[])
{
	bool cflag = false, Eflag = false, wflag = false, dashdash = false;
	int noperands = 0;
	char exe[PATH_MAX], real[PATH_MAX], *slash;
	uint32_t size = sizeof(exe);

	add(NULL);			/* the compiler's path, once known */
	for (size_t j = 0; j < sizeof(prepended) / sizeof(*prepended); j++)
		add(prepended[j]);

	for (int i = 1; i < argc; i++) {
		const char *a = argv[i], *arg, *opt;
		char flag[3] = "-?";

		if (dashdash || a[0] != '-' || a[1] == '\0') {
			add(dashdash && a[0] == '-' ? cat("./", a) : a);
			noperands++;
			continue;
		}
		if (strcmp(a, "--") == 0) {
			dashdash = true;
			continue;
		}
		for (const char *p = a + 1; *p != '\0'; p++) {
			if (*p == ':' || (opt = strchr("cD:EgI:L:o:O:sU:W:l:", *p)) == NULL) {
				fprintf(stderr, "%s: illegal option -- %c\n", argv[0], *p);
				usage();
			}
			flag[1] = *p;
			if (opt[1] != ':') {
				cflag |= *p == 'c';
				Eflag |= *p == 'E';
				add(cat(flag, ""));
				continue;
			}
			if (p[1] != '\0')
				arg = p + 1;
			else if (i + 1 < argc)
				arg = argv[++i];
			else {
				fprintf(stderr, "%s: option requires an argument -- %c\n",
				    argv[0], *p);
				usage();
			}
			switch (*p) {
			case 'o':
				add("-o");
				add(arg);
				break;
			case 'l':
				if (strcmp(arg, "pthread") != 0 && strcmp(arg, "xnet") != 0)
					add(cat("-l", arg));
				break;
			case 'W':
				if (strcmp(arg, "32") == 0 || strcmp(arg, "64") == 0) {
					add(cat("-m", arg));
					wflag = true;
				} else if (strcmp(arg, "verbose") == 0) {
					add("-v");
				} else if (strcmp(arg, "macros") == 0) {
					add("-x");
					add("c");
					add("-E");
					add("-dM");
					add("/dev/null");
					Eflag = true;
				} else {
					errx(EX_USAGE, "invalid argument `%s' to -W", arg);
				}
				break;
			default:
				add(cat(flag, arg));
				break;
			}
			break;
		}
	}
	if (!wflag)
		add("-m64");
	if (!cflag && !Eflag && noperands > 0)
		add("-liconv");
	add(NULL);

	/* The compiler is the clang in the directory this binary is in. */
	if (_NSGetExecutablePath(exe, &size) != 0 || realpath(exe, real) == NULL)
		err(EX_OSERR, "cannot locate %s", argv[0]);
	if ((slash = strrchr(real, '/')) == NULL)
		errx(EX_OSERR, "unexpected path name: %s", real);
	strlcpy(slash + 1, "clang", sizeof(real) - (size_t)(slash + 1 - real));
	args[0] = real;

	setenv("DISABLE_CRASH_RECOVERY_C99", "1", 1);
	execv(real, args);
	err(EX_OSERR, "failed to exec compiler %s", real);
}

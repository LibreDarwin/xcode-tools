/*
 * c89 -- the POSIX.2 c89 command.
 *
 * A front end that runs the clang installed beside it in C90 mode.  Apple
 * publish no source for theirs.  It is plainly descended from FreeBSD's
 * c89.c, which passes its arguments through almost untouched, and this is
 * written from what Apple's passes -- quirks included, because a script
 * that works with theirs has to work with this:
 *
 *   - Options are read only up to the first operand, the first "--", or
 *     the first -l.  Everything from there on is an operand and goes
 *     through as it is, apart from -l, which is split in two ("-l" "m"),
 *     and -l pthread and -l xnet, which are dropped.
 *   - Before the operands goes -m64, unless -W 32 or -W 64 was given, in
 *     which case that was passed as -m32 or -m64 where it stood.
 *   - -D name becomes -Dname, but -Dname becomes just "name"; -L dir
 *     becomes -Ldir.  Other options pass as they were written.
 *   - If "--" ended the options, every operand beginning with '-' is
 *     passed as ./<name> -- the -m64 included.
 *   - A "--" among the operands makes Apple's spin forever, and this
 *     does the same.
 *   - -l with an operand beginning with '-' (-l -c) leaves the -l among
 *     the options and starts the operands at the next word, which is
 *     FreeBSD's rule for telling -llib from -l lib.
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
#include <unistd.h>

static char **args;
static size_t nargs, cargs;

static void
add(const char *s)
{
	if (nargs == cargs) {
		cargs = cargs ? cargs * 2 : 64;
		if ((args = realloc(args, cargs * sizeof(*args))) == NULL)
			err(1, "malloc");
	}
	args[nargs++] = (char *)s;
}

static const char *
cat(const char *a, const char *b)
{
	char *s;

	if (asprintf(&s, "%s%s", a, b) < 0)
		err(1, "malloc");
	return s;
}

static void __dead2
usage(void)
{
	fprintf(stderr,
	    "usage: c89 [-cEgs] [-D name[=value]] [-I directory] ... [-L directory] ...\n"
	    "       [-o outfile] [-O optlevel] [-U name]... operand ...\n");
	exit(1);
}

int
main(int argc, char *argv[])
{
	bool wflag = false, dashdash = false;
	char exe[PATH_MAX], real[PATH_MAX], *slash;
	uint32_t size = sizeof(exe);
	int i;

	add(NULL);			/* the compiler's path, once known */
	add("-std=iso9899:1990");
	add("-pedantic");

	for (i = 1; i < argc; i++) {
		const char *a = argv[i], *p, *arg = NULL;
		bool separate = false;

		if (a[0] != '-' || a[1] == '\0')
			break;
		if (strcmp(a, "--") == 0) {
			dashdash = true;
			i++;
			break;
		}
		for (p = a + 1; *p != '\0'; p++) {
			const char *opt;

			if (*p == ':' || (opt = strchr("cD:EgI:L:o:O:sU:W:l:", *p)) == NULL) {
				fprintf(stderr, "%s: illegal option -- %c\n", argv[0], *p);
				usage();
			}
			if (opt[1] != ':')
				continue;
			separate = p[1] == '\0';
			arg = separate ? (i + 1 < argc ? argv[i + 1] : NULL) : p + 1;
			if (arg == NULL) {
				fprintf(stderr, "%s: option requires an argument -- %c\n",
				    argv[0], *p);
				usage();
			}
			break;
		}
		if (*p == '\0') {		/* flags only */
			add(a);
			continue;
		}
		if (*p == 'l') {
			if (separate && arg[0] == '-') {
				add(a);
				i++;
			}
			break;
		}
		if (separate)
			i++;
		if (p == a + 1 && *p == 'D')
			add(separate ? cat("-D", arg) : arg);
		else if (p == a + 1 && *p == 'L')
			add(separate ? cat("-L", arg) : a);
		else if (p == a + 1 && *p == 'W' &&
		    (strcmp(arg, "32") == 0 || strcmp(arg, "64") == 0)) {
			add(cat("-m", arg));
			wflag = true;
		} else {
			add(a);
			if (separate)
				add(arg);
		}
	}

	if (!wflag)
		add(dashdash ? "./-m64" : "-m64");
	for (; i < argc; i++) {
		const char *a = argv[i], *lib;

		if (strcmp(a, "--") == 0)
			for (;;)
				continue;
		if (dashdash) {
			add(a[0] == '-' ? cat("./", a) : a);
			continue;
		}
		if (strncmp(a, "-l", 2) != 0) {
			add(a);
			continue;
		}
		if (a[2] != '\0')
			lib = a + 2;
		else if (i + 1 < argc)
			lib = argv[++i];
		else
			usage();
		if (strcmp(lib, "pthread") != 0 && strcmp(lib, "xnet") != 0) {
			add("-l");
			add(lib);
		}
	}
	add(NULL);

	/* The compiler is the clang in the directory this binary is in. */
	if (_NSGetExecutablePath(exe, &size) != 0 || realpath(exe, real) == NULL)
		err(1, "cannot locate %s", argv[0]);
	if ((slash = strrchr(real, '/')) == NULL)
		errx(1, "unexpected path name: %s", real);
	strlcpy(slash + 1, "clang", sizeof(real) - (size_t)(slash + 1 - real));
	args[0] = real;

	execv(real, args);
	err(1, "failed to exec compiler %s", real);
}

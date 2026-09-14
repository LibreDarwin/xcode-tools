/*
 * m4 -- run gm4 or bm4, as Xcode's m4 does.  See common/wrapper.c.
 *
 * The option tables are the two m4s' own: GNU M4 1.4.6's src/m4.c and
 * FreeBSD's usr.bin/m4/main.c, limited to the names Xcode's m4 carries.
 *
 * Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <getopt.h>

#include "wrapper.h"

static const struct option gm4_longopts[] = {
	{ "help",		no_argument,		NULL,	'h' },
	{ "version",		no_argument,		NULL,	'v' },
	{ "fatal-warnings",	no_argument,		NULL,	'E' },
	{ "interactive",	no_argument,		NULL,	'e' },
	{ "prefix-builtins",	no_argument,		NULL,	'P' },
	{ "quiet",		no_argument,		NULL,	'Q' },
	{ "silent",		no_argument,		NULL,	'Q' },
	{ "define",		required_argument,	NULL,	'D' },
	{ "include",		required_argument,	NULL,	'I' },
	{ "synclines",		no_argument,		NULL,	's' },
	{ "undefine",		required_argument,	NULL,	'U' },
	{ "traditional",	no_argument,		NULL,	'G' },
	{ "hashsize",		required_argument,	NULL,	'H' },
	{ "nesting-limit",	required_argument,	NULL,	'L' },
	{ "freeze-state",	required_argument,	NULL,	'F' },
	{ "reload-state",	required_argument,	NULL,	'R' },
	{ "debug",		optional_argument,	NULL,	'd' },
	{ "arglength",		required_argument,	NULL,	'l' },
	{ "error-output",	required_argument,	NULL,	'o' },
	{ "trace",		required_argument,	NULL,	't' },
	{ NULL,			0,			NULL,	0 },
};

static const struct option bm4_longopts[] = {
	{ "define",		required_argument,	NULL,	'D' },
	{ "debug",		optional_argument,	NULL,	'd' },
	{ "fatal-warnings",	no_argument,		NULL,	'E' },
	{ "traditional",	no_argument,		NULL,	'G' },
	{ "gnu",		no_argument,		NULL,	'g' },
	{ "include",		required_argument,	NULL,	'I' },
	{ "error-output",	required_argument,	NULL,	'o' },
	{ "prefix-builtins",	no_argument,		NULL,	'P' },
	{ "synclines",		no_argument,		NULL,	's' },
	{ "trace",		required_argument,	NULL,	't' },
	{ "undefine",		required_argument,	NULL,	'U' },
	{ NULL,			0,			NULL,	0 },
};

static const struct wrapper_impl gm4 = {
	"gm4", "EePQD:I:sU:GH:L:F:R:d::l:o:t:", gm4_longopts, NULL
};

static const struct wrapper_impl bm4 = {
	"bm4", "D:d::EGgI:o:Pst:U:", bm4_longopts, NULL
};

int
main(int argc, char *argv[])
{
	return wrapper_execute(argc, argv, "COMMAND_M4", &gm4, &bm4);
}

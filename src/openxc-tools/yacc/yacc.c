/*
 * yacc -- run bison or byacc, as Xcode's yacc does.  See common/wrapper.c.
 *
 * The option tables are bison 2.3's and byacc 20230201's, limited to the
 * names Xcode's yacc carries.  One entry is not bison's: bison takes an
 * optional argument to --defines, and Xcode's yacc treats --defines=file
 * as not bison's -- it runs byacc for it -- so here it takes none.
 *
 * Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <getopt.h>

#include "wrapper.h"

static const struct option bison_longopts[] = {
	{ "help",		no_argument,		NULL,	'h' },
	{ "version",		no_argument,		NULL,	'V' },
	{ "print-localedir",	no_argument,		NULL,	1 },
	{ "yacc",		no_argument,		NULL,	'y' },
	{ "skeleton",		required_argument,	NULL,	'S' },
	{ "debug",		no_argument,		NULL,	't' },
	{ "locations",		no_argument,		NULL,	2 },
	{ "name-prefix",	required_argument,	NULL,	'p' },
	{ "no-lines",		no_argument,		NULL,	'l' },
	{ "no-parser",		no_argument,		NULL,	'n' },
	{ "token-table",	no_argument,		NULL,	'k' },
	{ "defines",		no_argument,		NULL,	'd' },
	{ "report",		required_argument,	NULL,	'r' },
	{ "verbose",		no_argument,		NULL,	'v' },
	{ "file-prefix",	required_argument,	NULL,	'b' },
	{ "output",		required_argument,	NULL,	'o' },
	{ "graph",		optional_argument,	NULL,	'g' },
	{ NULL,			0,			NULL,	0 },
};

static const struct option byacc_longopts[] = {
	{ "defines",		required_argument,	NULL,	'H' },
	{ "file-prefix",	required_argument,	NULL,	'b' },
	{ "graph",		no_argument,		NULL,	'g' },
	{ "help",		no_argument,		NULL,	'h' },
	{ "name-prefix",	required_argument,	NULL,	'p' },
	{ "no-lines",		no_argument,		NULL,	'l' },
	{ "output",		required_argument,	NULL,	'o' },
	{ "version",		no_argument,		NULL,	'V' },
	{ NULL,			0,			NULL,	0 },
};

static const struct wrapper_impl bison = {
	"bison", "hVyS:tp:lnkdr:vb:o:g", bison_longopts, "-y"
};

static const struct wrapper_impl byacc = {
	"byacc", "hb:BdH:iglLo:p:PrstvV", byacc_longopts, NULL
};

int
main(int argc, char *argv[])
{
	return wrapper_execute(argc, argv, "COMMAND_YACC", &bison, &byacc);
}

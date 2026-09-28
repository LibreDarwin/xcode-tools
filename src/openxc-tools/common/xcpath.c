/*
 * xcpath.c -- path helpers shared by the tool.
 *
 * Copyright (c) 2026 Sunneva N. Mariu
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <limits.h>
#include <stdio.h>
#include <string.h>

#include "xcpath.h"

const char *
xc_dirname(const char *path, char *buf, size_t len)
{
	char tmp[PATH_MAX];
	char *slash;

	if (path == NULL || buf == NULL || len == 0)
		return NULL;
	if (snprintf(tmp, sizeof(tmp), "%s", path) >= (int)sizeof(tmp))
		return NULL;

	slash = strrchr(tmp, '/');
	if (slash == NULL) {
		/* A bare name: what holds it is the current directory. */
		if (len < 2)
			return NULL;
		strcpy(buf, ".");
	} else if (slash == tmp) {
		/* "/Foo" -- the directory is the root itself. */
		if (len < 2)
			return NULL;
		strcpy(buf, "/");
	} else {
		*slash = '\0';
		if (snprintf(buf, len, "%s", tmp) >= (int)len)
			return NULL;
	}

	return buf;
}

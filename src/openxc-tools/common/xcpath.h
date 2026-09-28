/*
 * xcpath.h -- path helpers shared by the tool.
 *
 * Copyright (c) 2026 Sunneva N. Mariu
 * SPDX-License-Identifier: BSD-3-Clause
 */

#ifndef _XCODE_TOOLS_XCPATH_H_
#define _XCODE_TOOLS_XCPATH_H_

#include <stddef.h>

/**
 * @func xc_dirname -- the directory holding a path
 * @arg path - the path to take apart
 * @arg buf - storage for the result
 * @arg len - size of @arg buf
 *
 * A path with no '/' in it names something in the current directory, so
 * its directory is ".".  Returning the path itself instead -- which is
 * what a plain "cut at the last slash" gives, having no slash to cut at
 * -- turns a bare "Foo.xcodeproj" into a source root of "Foo.xcodeproj",
 * and every relative path in the project then resolves beneath a file
 * that is not a directory.
 *
 * @return: @arg buf, always NUL-terminated, or NULL if @arg path is
 *          NULL or @arg buf is too small.
 */
const char *xc_dirname(const char *path, char *buf, size_t len);

#endif /* _XCODE_TOOLS_XCPATH_H_ */

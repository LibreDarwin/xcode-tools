/*
 * reallocarray.h -- reallocarray for FreeBSD's m4 on macOS.
 *
 * FreeBSD's m4 calls reallocarray, which FreeBSD's libc has.  macOS's
 * libSystem carries one only as reallocarray$DARWIN_EXTSN, and the SDK
 * declares none, so the call does not compile.  Xcode's bm4 does not
 * import it either: its only allocation imports are malloc, calloc and
 * realloc.  So this is realloc behind the overflow check reallocarray
 * makes, and it is force-included rather than written into the vendored
 * sources, which stay unmodified.
 *
 * Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

#ifndef BM4_COMPAT_REALLOCARRAY_H
#define BM4_COMPAT_REALLOCARRAY_H

#include <errno.h>
#include <stdint.h>
#include <stdlib.h>

static inline void *
bm4_reallocarray(void *p, size_t n, size_t size)
{
	if (size != 0 && n > SIZE_MAX / size) {
		errno = ENOMEM;
		return NULL;
	}
	return realloc(p, n * size);
}

#define reallocarray(p, n, size)	bm4_reallocarray((p), (n), (size))

#endif /* BM4_COMPAT_REALLOCARRAY_H */

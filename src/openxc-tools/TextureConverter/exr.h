/*
 * exr.h -- OpenEXR in and out.
 *
 * Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

#ifndef TEXTURECONVERTER_EXR_H
#define TEXTURECONVERTER_EXR_H

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Write one level of RGBA halves, tightly packed and top row first, to
 * path.  Returns 0 on success.
 */
int	exr_write_rgba16(const char *path, const void *halves, int w, int h);

/*
 * Read an EXR as RGBA floats, top row first, printing its header the way
 * Apple's tool does.  Returns a malloc'd image or NULL.
 */
float	*exr_read_rgba(const char *path, int *wp, int *hp);

/* Print an EXR's header as OpenEXRCore does at full verbosity. */
int	exr_print_header(const char *path);

#ifdef __cplusplus
}
#endif

#endif /* TEXTURECONVERTER_EXR_H */

/*
 * exr.h -- writing a level as OpenEXR.
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

#ifdef __cplusplus
}
#endif

#endif /* TEXTURECONVERTER_EXR_H */

/*
 * exr.cpp -- writing a level as OpenEXR, through OpenEXR.
 *
 * Apple's tool links OpenEXR 3.3.2 statically, and its file is what
 * OpenEXR's own OutputFile writes from a default header: the four
 * channels A, B, G and R as halves, PIZ compression, both windows the
 * image, rows top first.  So this is that and nothing more, and it comes
 * out byte for byte theirs.
 *
 * Only RGBA16.  Apple's writer reads every format's pixels four halves to
 * a texel, so for R16, RG16 and RGB16 it runs off the end of the buffer
 * it was given and writes whatever the heap held there -- two runs on the
 * same image differ.  There is no file to match, and the caller refuses
 * those.
 *
 * Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <OpenEXR/ImfChannelList.h>
#include <OpenEXR/ImfCompression.h>
#include <OpenEXR/ImfFrameBuffer.h>
#include <OpenEXR/ImfHeader.h>
#include <OpenEXR/ImfInputFile.h>
#include <OpenEXR/ImfOutputFile.h>
#include <OpenEXR/openexr.h>

#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <vector>

#include "exr.h"

extern "C" int
exr_write_rgba16(const char *path, const void *halves, int w, int h)
{
	static const char *const names[4] = { "R", "G", "B", "A" };
	const uint8_t *src = (const uint8_t *)halves;
	std::vector<uint16_t> plane[4];

	try {
		Imf::Header hdr(w, h);
		Imf::FrameBuffer fb;
		int c;

		hdr.compression() = Imf::PIZ_COMPRESSION;
		for (c = 0; c < 4; c++) {
			plane[c].resize((size_t)w * (size_t)h);
			for (size_t i = 0; i < plane[c].size(); i++)
				memcpy(&plane[c][i], src + (i * 4 + c) * 2, 2);
			hdr.channels().insert(names[c],
			    Imf::Channel(Imf::HALF));
			fb.insert(names[c], Imf::Slice(Imf::HALF,
			    (char *)plane[c].data(), 2, 2 * (size_t)w));
		}

		Imf::OutputFile out(path, hdr);

		out.setFrameBuffer(fb);
		out.writePixels(h);
	} catch (...) {
		return (-1);
	}
	return (0);
}

/*
 * The header dump on its own, for the conversion path, which prints it a
 * second time after its banner the way it prints a resize twice.
 */
extern "C" int
exr_print_header(const char *path)
{
	exr_context_initializer_t init = EXR_DEFAULT_CONTEXT_INITIALIZER;
	exr_context_t ctxt = NULL;

	if (exr_start_read(&ctxt, path, &init) != EXR_ERR_SUCCESS)
		return (-1);
	exr_print_context_info(ctxt, 1);
	exr_finish(&ctxt);
	return (0);
}

/*
 * Reading one, through OpenEXR as well.  ImageIO reads an EXR too, but it
 * hands a two channel file back as one channel with green gone, and Apple
 * keep both -- because they read it this way.
 *
 * They also print its whole header first, and that is not theirs but
 * OpenEXRCore's exr_print_context_info at full verbosity, left switched
 * on.  Its "flags longnames" is not a flag bit in the file: it is the
 * reader's name limit, which is the long one by default.
 *
 * Channels the file does not have come back as nothing, and alpha as one.
 * Returns a malloc'd RGBA float image, top row first, or NULL.
 */
extern "C" float *
exr_read_rgba(const char *path, int *wp, int *hp)
{
	static const char *const names[4] = { "R", "G", "B", "A" };
	float *out = NULL;

	if (exr_print_header(path) != 0)
		return (NULL);

	try {
		Imf::InputFile in(path);
		const Imath::Box2i &dw = in.header().dataWindow();
		int w = dw.max.x - dw.min.x + 1, h = dw.max.y - dw.min.y + 1;
		std::vector<float> plane[4];
		Imf::FrameBuffer fb;
		int c;

		for (c = 0; c < 4; c++) {
			plane[c].resize((size_t)w * (size_t)h);
			fb.insert(names[c], Imf::Slice(Imf::FLOAT,
			    (char *)plane[c].data() -
			    (dw.min.x + (ptrdiff_t)dw.min.y * w) * 4,
			    sizeof(float), sizeof(float) * (size_t)w, 1, 1,
			    c == 3 ? 1.0 : 0.0));
		}
		in.setFrameBuffer(fb);
		in.readPixels(dw.min.y, dw.max.y);
		out = (float *)malloc((size_t)w * (size_t)h * 4 * sizeof(*out));
		if (out == NULL)
			return (NULL);
		for (size_t i = 0; i < (size_t)w * (size_t)h; i++)
			for (c = 0; c < 4; c++)
				out[i * 4 + (size_t)c] = plane[c][i];
		*wp = w;
		*hp = h;
	} catch (...) {
		free(out);
		return (NULL);
	}
	return (out);
}

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
#include <OpenEXR/ImfOutputFile.h>

#include <cstdint>
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

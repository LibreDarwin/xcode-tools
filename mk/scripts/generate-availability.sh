#!/bin/sh
#
# generate-availability.sh -- run AvailabilityVersions' own generator over
# its templates, the way its CMakeLists does.
#
# Apple's Availability headers are not written by hand: the version data
# lives in availability.dsl, and the availability script expands the
# @@...@@ macros in templates/ from it.  The script first preprocesses
# itself, embedding the DSL, and that copy expands every template.  The
# results land in OUTDIR under their template names; which of them
# install where is sdk-headers.mk's business.
#
# Usage: generate-availability.sh <AvailabilityVersions-src> <outdir>
#
# Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause
#
set -e

if [ $# -ne 2 ]; then
	echo "usage: $0 <AvailabilityVersions-src> <outdir>" >&2
	exit 1
fi

SRC=$1
OUT=$2

mkdir -p "$OUT"
python3 "$SRC/availability" --preprocess "$SRC/availability" "$OUT/availability"
for t in "$SRC"/templates/*; do
	python3 "$OUT/availability" --preprocess "$t" "$OUT/${t##*/}"
done

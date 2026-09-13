#!/bin/sh
#
# Replace a Mach-O binary's run paths with the ones given, in order.
#
# Usage: set-rpaths.sh <binary> <rpath>...
#
# Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause
#
set -e

if [ $# -lt 1 ]; then
	echo "usage: $0 <binary> <rpath>..." >&2
	exit 1
fi

BIN=$1
shift

otool -l "$BIN" | awk '/cmd LC_RPATH/ { getline; getline; print $2 }' |
while read -r p; do
	install_name_tool -delete_rpath "$p" "$BIN"
done
for p in "$@"; do
	install_name_tool -add_rpath "$p" "$BIN"
done

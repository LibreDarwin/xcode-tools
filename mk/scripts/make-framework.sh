#!/bin/sh
#
# Lay a built library out as a framework the way Xcode's SharedFrameworks
# are: Versions/A/<name> and Versions/A/Resources/{Info,version}.plist,
# with Versions/Current, <name> and Resources linked at the top.  Nothing
# else -- Xcode's installed frameworks carry no Headers or Modules.  The
# plists are written by bundle-plists.sh.
#
# Usage: make-framework.sh <library> <dest>/<name>.framework <identifier>
#            <short-version> <version> <project> <build-version>
#            [<resource>...]
#
# BUILD_ALIAS_OF and PRODUCT_BUILD_VERSION in the environment add those
# keys to version.plist.
#
# Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause
#
set -e

if [ $# -lt 7 ]; then
	echo "usage: $0 <library> <name>.framework <identifier> <short-version> <version> <project> <build-version> [<resource>...]" >&2
	exit 1
fi

. "$(dirname "$0")/bundle-plists.sh"

LIB=$1 FW=$2 ID=$3 SHORT=$4 VERSION=$5 PROJECT=$6 BUILDVERSION=$7
shift 7
NAME=$(basename "$FW" .framework)

rm -rf "$FW"
mkdir -p "$FW/Versions/A/Resources"
cp "$LIB" "$FW/Versions/A/$NAME"
for r in "$@"; do
	cp -R "$r" "$FW/Versions/A/Resources/"
done
ln -s A "$FW/Versions/Current"
ln -s "Versions/Current/$NAME" "$FW/$NAME"
ln -s Versions/Current/Resources "$FW/Resources"

write_info_plist "$FW/Versions/A/Resources/Info.plist" "$NAME" "$NAME" "$ID" \
    FMWK "$SHORT" "$VERSION" "$(minimum_macos "$LIB")"
write_version_plist "$FW/Versions/A/Resources/version.plist" \
    "$SHORT" "$VERSION" "$PROJECT" "$BUILDVERSION"

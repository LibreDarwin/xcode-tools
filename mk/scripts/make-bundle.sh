#!/bin/sh
#
# Lay out a bundle the way Xcode's are: Contents/Info.plist,
# Contents/version.plist and, when there is one, the executable in
# Contents/MacOS.  What goes in Contents/Frameworks, PlugIns or Resources
# is the caller's to add.  The plists are written by bundle-plists.sh.
#
# Usage: make-bundle.sh <executable-or-"-"> <dest>/<name>.<ext> <identifier>
#            <short-version> <version> <project> <build-version>
#            <minimum-macos>
#
# "-" for the executable makes a bundle with none, as an .ideplugin of
# specifications is.  BUILD_ALIAS_OF and PRODUCT_BUILD_VERSION in the
# environment add those keys to version.plist.
#
# Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause
#
set -e

if [ $# -ne 8 ]; then
	echo "usage: $0 <executable-or-\"-\"> <name>.<ext> <identifier> <short-version> <version> <project> <build-version> <minimum-macos>" >&2
	exit 1
fi

. "$(dirname "$0")/bundle-plists.sh"

EXE=$1 BUNDLE=$2 ID=$3 SHORT=$4 VERSION=$5 PROJECT=$6 BUILDVERSION=$7 MINOS=$8
NAME=$(basename "$BUNDLE")
NAME=${NAME%.*}

mkdir -p "$BUNDLE/Contents"
EXENAME=
if [ "$EXE" != - ]; then
	EXENAME=$NAME
	mkdir -p "$BUNDLE/Contents/MacOS"
	cp "$EXE" "$BUNDLE/Contents/MacOS/$NAME"
fi

write_info_plist "$BUNDLE/Contents/Info.plist" "$NAME" "$EXENAME" "$ID" \
    BNDL "$SHORT" "$VERSION" "$MINOS"
write_version_plist "$BUNDLE/Contents/version.plist" \
    "$SHORT" "$VERSION" "$PROJECT" "$BUILDVERSION"

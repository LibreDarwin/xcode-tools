#!/bin/sh
#
# Turn a CMake build's lib<Name>.dylib libraries into the frameworks Xcode
# ships them as.  In the build directory each library is renamed in place
# to @rpath/<Name>.framework/Versions/A/<Name>, and its references to the
# others to match, so that whatever links against them afterwards records
# the framework names; then each is laid out by make-framework.sh into
# <dest>, with /usr/lib/swift as its run path, as Xcode's are.
#
# The libraries have to be linked with -headerpad_max_install_names: the
# framework names are longer than the ones CMake gave them.
#
# Usage: frameworkize.sh <libdir> <dest> <identifier-prefix> <short-version>
#            <version> <project> <build-version> <Name>...
#
# Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause
#
set -e

if [ $# -lt 8 ]; then
	echo "usage: $0 <libdir> <dest> <identifier-prefix> <short-version> <version> <project> <build-version> <Name>..." >&2
	exit 1
fi

LIBDIR=$1 DEST=$2 PREFIX=$3 SHORT=$4 VERSION=$5 PROJECT=$6 BUILDVERSION=$7
shift 7
HERE=$(dirname "$0")

for n in "$@"; do
	lib=$LIBDIR/lib$n.dylib
	install_name_tool -id "@rpath/$n.framework/Versions/A/$n" "$lib"
	for m in "$@"; do
		install_name_tool -change "@rpath/lib$m.dylib" \
		    "@rpath/$m.framework/Versions/A/$m" "$lib"
	done
	sh "$HERE/set-rpaths.sh" "$lib" /usr/lib/swift
done

mkdir -p "$DEST"
for n in "$@"; do
	sh "$HERE/make-framework.sh" "$LIBDIR/lib$n.dylib" "$DEST/$n.framework" \
	    "$PREFIX.$n" "$SHORT" "$VERSION" "$PROJECT" "$BUILDVERSION"
done

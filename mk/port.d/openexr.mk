# OpenEXR, with the Imath and libdeflate it is built against.
#
# TextureConverter writes a single level of RGBA16 as OpenEXR, and Apple's
# links OpenEXR 3.3.2 statically to do it -- the symbols are Imf_3_3 and
# Imath_3_1 and the version string is in the binary.  Their file is PIZ
# compressed, a wavelet and a Huffman coder, and OpenEXR's own writer with
# its default header gives it back byte for byte, so this is linked rather
# than written again.
#
# BSD-3-Clause for OpenEXR and Imath, MIT for libdeflate.
#
# OpenEXR 3.3.2 wants Imath 3.1 and libdeflate, and fetches either from the
# network when it cannot find one.  Nothing here fetches: both are
# submodules pinned to the tags 3.3.2 itself names (Imath v3.1.12,
# libdeflate v1.18), and FetchContent is pointed at them as source
# directories, so it builds them in place without a clone.  That is also
# how their libraries end up static and inside this build rather than
# found on the system.
P_BUILDSYS=	cmake
P_CMAKE_SRC=	.
P_OBJDIR=	${P_WORKDIR}/build
P_NOSTAGE=	yes
P_PROGS=

# Copied, not built beside the submodule, for libdeflate's sake: OpenEXR's
# cmake hides libdeflate's symbols by rewriting lib/lib_common.h in the
# source directory it is given, which would write into the submodule.  So
# libdeflate gets a private copy too, and FetchContent is pointed at that.
P_COPY=		yes
P_PREPARE=	rsync -a --delete --exclude .git \
		    ${TOP}/src/extras/libdeflate/ ${P_WORKDIR}/libdeflate/

P_CONFIGURE_ARGS=	-DBUILD_SHARED_LIBS=OFF \
			-DOPENEXR_FORCE_INTERNAL_IMATH=ON \
			-DOPENEXR_FORCE_INTERNAL_DEFLATE=ON \
			-DFETCHCONTENT_FULLY_DISCONNECTED=ON \
			-DFETCHCONTENT_SOURCE_DIR_IMATH=${TOP}/src/extras/imath \
			-DFETCHCONTENT_SOURCE_DIR_DEFLATE=${P_WORKDIR}/libdeflate \
			-DOPENEXR_BUILD_TOOLS=OFF \
			-DOPENEXR_INSTALL_TOOLS=OFF \
			-DOPENEXR_BUILD_EXAMPLES=OFF \
			-DOPENEXR_TEST_LIBRARIES=OFF \
			-DOPENEXR_TEST_TOOLS=OFF \
			-DOPENEXR_TEST_PYTHON=OFF \
			-DOPENEXR_INSTALL_DOCS=OFF \
			-DBUILD_TESTING=OFF

# The install rules are the libraries and their headers and nothing else,
# once the tools, the examples and the tests are off -- and the internal
# Imath brings its own -- so they are run into dest rather than the pieces
# gathered by hand.  libdeflate has no library to install: built internal,
# its sources go straight into OpenEXRCore.
P_POST_BUILD=	DESTDIR=${P_OBJDIR}/dest ninja install >/dev/null

P_RELEASE_MERGE=	dest/usr/lib usr/local/lib \
			dest/usr/include usr/local/include

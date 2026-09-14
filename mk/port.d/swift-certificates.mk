# swift-certificates -- built for SwiftPM, which links it statically to
# verify signed packages and package collections.  Nothing of it is
# installed.
.include "${TOP}/mk/with-swift-cmake.mk"

P_BUILDSYS=	cmake
P_CMAKE_SRC=	.
P_OBJDIR=	${P_WORKDIR}/build
P_NOSTAGE=	yes
P_CONFIGURE_ARGS=	${SWIFT_CMAKE_ARGS} \
	-DBUILD_SHARED_LIBS=NO \
	-DBUILD_TESTING=OFF \
	-DSwiftASN1_DIR=${TOP}/build/ports/swift-asn1/build/cmake/modules \
	-DSwiftCrypto_DIR=${TOP}/build/ports/swift-crypto/build/cmake/modules
P_PROGS=

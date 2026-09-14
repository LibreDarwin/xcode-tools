# swift-asn1 -- built for swift-crypto and swift-certificates, and so for
# SwiftPM, which links all three statically.  Nothing of it is installed.
.include "${TOP}/mk/with-swift-cmake.mk"

P_BUILDSYS=	cmake
P_CMAKE_SRC=	.
P_OBJDIR=	${P_WORKDIR}/build
P_NOSTAGE=	yes
P_CONFIGURE_ARGS=	${SWIFT_CMAKE_ARGS} \
	-DBUILD_SHARED_LIBS=NO \
	-DBUILD_TESTING=OFF
P_PROGS=

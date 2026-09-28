# xccov -- reads the coverage report out of a result bundle.  Shares the
# bundle reader with xcresulttool; the keyed-archive reader is its own.
# The bundle reader gets Info.plist through CoreFoundation, so this links the
# same parser Apple's tools do rather than our own.
T_SRCS+=	xccov.c bkeyed.c
T_SRCS+=	src/openxc-tools/common/xcresult.c
T_CFLAGS+=	-I${TOP}/src/openxc-tools/common
T_CFLAGS+=	-I${RELEASE}/usr/local/include
T_LDADD+=	-framework CoreFoundation
T_LDADD+=	${RELEASE}/usr/local/lib/libzstd.a

# xcresulttool -- reads a .xcresult bundle.  The bundle reader is shared
# with xccov, which needs it to find the coverage report inside one.  It gets
# Info.plist through CoreFoundation, so this links the same parser Apple's
# tools do rather than our own.
T_SRCS+=	xcresulttool.c
T_SRCS+=	src/openxc-tools/common/xcresult.c
T_CFLAGS+=	-I${TOP}/src/openxc-tools/common
T_CFLAGS+=	-I${RELEASE}/usr/local/include
T_LDADD+=	-framework CoreFoundation
T_LDADD+=	${RELEASE}/usr/local/lib/libzstd.a

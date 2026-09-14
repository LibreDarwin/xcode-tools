# xcresulttool -- reads a .xcresult bundle.  The bundle reader is shared
# with xccov, which needs it to find the coverage report inside one.
.include "${TOP}/mk/with-plist.mk"

T_SRCS+=	xcresulttool.c
T_SRCS+=	src/openxc-tools/common/xcresult.c
T_CFLAGS+=	-I${RELEASE}/usr/local/include
T_LDADD+=	${RELEASE}/usr/local/lib/libzstd.a

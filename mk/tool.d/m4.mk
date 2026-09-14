# m4 -- runs gm4 or bm4, as Xcode's m4 does; see common/wrapper.c.
T_SRCS=		m4.c src/openxc-tools/common/wrapper.c
T_CFLAGS+=	-I${TOP}/src/openxc-tools/common
.include "${TOP}/mk/with-xcselect.mk"

# It lives in the toolchain, where ../lib is the toolchain's and not the
# Developer directory's usr/lib that libxcselect is in.
T_LDADD+=	-Wl,-rpath,@executable_path/../../../../usr/lib

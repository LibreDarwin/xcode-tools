# yacc -- runs bison or byacc, as Xcode's yacc does; see common/wrapper.c.
T_SRCS=		yacc.c src/openxc-tools/common/wrapper.c
T_CFLAGS+=	-I${TOP}/src/openxc-tools/common
.include "${TOP}/mk/with-xcselect.mk"

# It lives in the toolchain, where ../lib is the toolchain's and not the
# Developer directory's usr/lib that libxcselect is in.
T_LDADD+=	-Wl,-rpath,@executable_path/../../../../usr/lib

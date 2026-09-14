# unwinddump -- dumps a Mach-O file's __unwind_info, from ld64.
#
# One source, built as ld64.xcodeproj's unwinddump target builds it: none
# of ld's libraries, only libc++ and libSystem.  It needs ld64's headers
# and the configure.h mk/tool.d/ld.mk generates, which is why the progs.mk
# entry follows ld's.
L=		${TOP}/src/apple/distribution-Developer_Tools/ld64/src
T_SRCS=		src/apple/distribution-Developer_Tools/ld64/src/other/unwinddump.cpp
T_CFLAGS+=	-I${TOP}/build/gen/ld64 -I${L}/ld -I${L}/abstraction -I${L}/mach_o
T_CXXFLAGS+=	-std=c++20
T_LDADD+=	-Wl,-exported_symbol,__mh_execute_header

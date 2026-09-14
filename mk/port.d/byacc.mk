# byacc -- Thomas Dickey's Berkeley yacc, as Xcode's toolchain carries it.
#
# Xcode's byacc reports 2.0 20230201 and is built without the backtracking
# extension: its -h lists -B and -L, as every byacc's does, but using them
# says "-B flag unsupported, reconfigure with --enable-btyacc".  configure
# enables it by default, so it is turned off here.
#
# Apple's also differs from upstream 20230201 in what it writes, and
# mk/patches/byacc makes the same two changes, to the copy: an anonymous
# %union, and NULL rather than 0 in the parser skeleton.
#
# The build makes a program named yacc; Apple install it as byacc, beside
# the yacc that chooses between it and bison.
P_PREPARE=	for p in ${TOP}/mk/patches/byacc/*.patch; do \
		    patch -s -p1 < $$p || exit 1; \
		done
P_CONFIGURE_ARGS=	--disable-btyacc
P_NOSTAGE=	yes
P_POST_BUILD=	cp -f yacc byacc
P_PROGS=	byacc

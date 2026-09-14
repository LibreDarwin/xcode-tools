# bison -- GNU Bison 2.3, as Xcode's toolchain carries it.
#
# Built with Apple's bison.xcodeproj, for the reason mk/port.d/gm4.mk
# gives.  Apple's source finds its skeletons in ../share/bison and its m4
# as the gm4 beside it, relative to the executable; the skeletons are
# installed there, the same files Apple's xcodescripts/install-files.sh
# installs.
#
# From a copy: xcodebuild writes project.xcworkspace into the project.
BISON_DATA=	README c++.m4 c.m4 glr.c glr.cc lalr1.cc location.cc yacc.c

P_BUILDSYS=	make
P_OBJDIR=	${P_WORKDIR}/sym/Release
P_MAKE=		cd ${P_BUILDSRC} && xcodebuild
P_MAKE_ARGS=	-project bison.xcodeproj -configuration Release \
		ARCHS=$$(uname -m) \
		SYMROOT=${P_WORKDIR}/sym OBJROOT=${P_WORKDIR}/obj \
		CODE_SIGNING_ALLOWED=NO build
P_POST_BUILD=	mkdir -p share/bison/m4sugar && \
		for f in ${BISON_DATA}; do \
			cp -f ${P_BUILDSRC}/data/$$f share/bison/ || exit 1; \
		done && \
		cp -f ${P_BUILDSRC}/data/m4sugar/m4sugar.m4 share/bison/m4sugar/
P_NOSTAGE=	yes
P_PROGS=	bison
P_RELEASE_MERGE=	share/bison ${XCTOOLCHAIN}/usr/share/bison

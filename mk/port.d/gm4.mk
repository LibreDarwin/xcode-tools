# gm4 -- GNU M4 1.4.6, as Xcode's toolchain carries it.
#
# Built with Apple's own gm4.xcodeproj rather than configure.  The drop
# ships the config.h Apple build with; configure instead makes the bundled
# gnulib -- two decades older than the SDK -- replace <stdint.h> and
# <inttypes.h>, after which the SDK's _inttypes.h no longer sees intmax_t.
#
# From a copy: xcodebuild writes project.xcworkspace into the project.
P_BUILDSYS=	make
P_OBJDIR=	${P_WORKDIR}/sym/Release
P_MAKE=		cd ${P_BUILDSRC} && xcodebuild
P_MAKE_ARGS=	-project gm4.xcodeproj -configuration Release \
		ARCHS=$$(uname -m) \
		SYMROOT=${P_WORKDIR}/sym OBJROOT=${P_WORKDIR}/obj \
		CODE_SIGNING_ALLOWED=NO build
P_NOSTAGE=	yes
P_PROGS=	gm4

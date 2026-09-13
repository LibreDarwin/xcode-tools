# dyld -- dyld_info and dyld_analyzer, the two dyld tools Xcode's
# toolchain carries: dyld_info prints what is in a Mach-O file, down to
# its fixups and a disassembly, and dyld_analyzer measures the static
# archives in a directory tree.
#
# Built with xcodebuild from dyld's own project, which is the only thing
# that knows how its sources fit together; mk/scripts/build-dyld-tools.sh
# says how.  Against the internal SDK, because that is what the project
# is written for: libc_private.h, _simple.h and the rest come from there.
# dyld_info also links this tree's libLTO, which is why the llvm port has
# to come first.
#
# From a copy, so the two patches in mk/patches/dyld can be applied: the
# source release strips the body of LinkerOptimizationHints::valid(), and
# its disassembler callback is written against Apple's libLTO rather
# than llvm-project's.
P_COPY=		yes
P_PREPARE=	for p in ${TOP}/mk/patches/dyld/*.patch; do \
		    patch -s -p1 < $$p || exit 1; \
		done
P_BUILDSYS=	make
P_OBJDIR=	${P_WORKDIR}/sym/Release
P_MAKE=		sh ${TOP}/mk/scripts/build-dyld-tools.sh ${TOP} ${P_WORKDIR}
P_MAKE_ARGS=
P_NOSTAGE=	yes
P_PROGS=	dyld_info dyld_analyzer

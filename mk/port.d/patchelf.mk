# patchelf -- edit the dynamic linking metadata of ELF binaries.
#
# Darwin uses Mach-O, so this looks out of place until you remember
# what it is for: this tree builds tooling that reads and writes other
# platforms' binaries, and NABI runs ELF executables here.  It builds
# and runs natively -- given an ELF it parses the header and reports on
# it -- so it is carried rather than cross-built.
#
# It rewrites other platforms' binaries rather than building ours, so
# opt/bin with the rest of the extras.
P_BUILDSYS=	cmake
P_CMAKE_SRC=	.
P_OBJDIR=	${P_WORKDIR}/build
P_NOSTAGE=	yes
P_PROGS=	src/patchelf

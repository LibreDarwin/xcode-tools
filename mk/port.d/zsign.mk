# zsign -- sign iOS application bundles.
#
# Re-signs other people's bundles rather than signing our builds, so
# opt/bin beside ldid.  Its Makefile lives under build/macos
# rather than at the top, so make is pointed at it.
P_BUILDSYS=	make
P_MAKE_ARGS=	-C build/macos
P_NOSTAGE=	yes
P_PROGS=	bin/zsign

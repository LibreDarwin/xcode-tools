# ldid -- Mach-O code signing.
#
# Signs and inspects Mach-O signatures outside Apple's rules -- fake
# entitlements, ad-hoc signing for jailbroken devices -- so it goes to
# opt/bin with the other extras rather than beside our codesign.
#
# Its Makefile builds and installs by itself; there is no configure.
P_BUILDSYS=	make
P_MAKE_ARGS=	PREFIX=${P_PREFIX}

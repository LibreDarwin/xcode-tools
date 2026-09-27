# mk/with-plist.mk
#
# Shared fragment: build against src/openxc-tools/common/plist.c, our property
# list parser.  Used by anything that has to read Apple's plist-based
# metadata and is not already linking CoreFoundation for it.
#
# Only the result-bundle reader still needs this: common/xcresult.c parses
# Info.plist out of an .xcresult, which xccov and xcresulttool share.  Tools
# that resolve SDKs and toolchains get the same plists through CoreFoundation
# instead -- see mk/with-sdkpath.mk -- so they no longer pull this in.

T_CFLAGS+=	-I${TOP}/src/openxc-tools/common
T_SRCS+=	src/openxc-tools/common/plist.c
T_SRCS+=	src/openxc-tools/common/xmlplist.c
T_SRCS+=	src/openxc-tools/common/bplist.c

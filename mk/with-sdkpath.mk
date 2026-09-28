# mk/with-sdkpath.mk
#
# Shared fragment: build against src/openxc-tools/common/sdkpath.c, which knows
# where SDKs and toolchains live inside a Developer directory.  It reads the
# plists describing them (SDKSettings.plist, ToolchainInfo.plist) through
# CoreFoundation, so it needs no plist parser of its own.
#
# cfplist.c is that reader, shared rather than private to sdkpath.c so that a
# tool with a plist to read of its own need not write another one.

T_SRCS+=	src/openxc-tools/common/sdkpath.c
T_SRCS+=	src/openxc-tools/common/cfplist.c

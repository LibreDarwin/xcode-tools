# mk/with-sdkpath.mk
#
# Shared fragment: build against src/openxc-tools/common/sdkpath.c, which knows
# where SDKs and toolchains live inside a Developer directory.  It reads the
# plists describing them (SDKSettings.plist, ToolchainInfo.plist) through
# CoreFoundation, so it needs no plist parser of its own.

T_SRCS+=	src/openxc-tools/common/sdkpath.c

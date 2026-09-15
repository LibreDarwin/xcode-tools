# swift-format, built with SwiftPM from the checkouts beside it, as
# Apple's is; see P_BUILDSYS=swiftpm in mk/port.mk.  Stripped, with only
# /usr/lib/swift as a run path, which is what Xcode's carries.
.include "${TOP}/mk/with-swift-cmake.mk"

P_BUILDSYS=	swiftpm
P_SWIFTPM_PRODUCT=	swift-format
P_SWIFTPM_DEPS=	cmark swiftlang-llvm/swift-cmark \
		swift-argument-parser swiftlang-llvm/swift-argument-parser \
		swift-markdown swiftlang-llvm/swift-markdown \
		swift-syntax swiftlang-llvm/swift-syntax
P_POST_BUILD=	strip swift-format && \
		sh ${TOP}/mk/scripts/set-rpaths.sh swift-format /usr/lib/swift
P_PROGS=	swift-format

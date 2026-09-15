# swift-docc -- docc, built with SwiftPM from the checkouts beside it, as
# Apple's is; see P_BUILDSYS=swiftpm in mk/port.mk.  Stripped, with only
# /usr/lib/swift as a run path, which is what Xcode's carries.
#
# And usr/share/docc beside it, which docc looks for relative to itself:
# render/, the web renderer, is swift-docc-render-artifact's dist, and
# features.json is swift-docc's own.
.include "${TOP}/mk/with-swift-cmake.mk"

P_BUILDSYS=	swiftpm
P_SWIFTPM_PRODUCT=	docc
P_SWIFTPM_DEPS=	cmark swiftlang-llvm/swift-cmark \
		swift-argument-parser swiftlang-llvm/swift-argument-parser \
		swift-asn1 swiftlang-llvm/swift-asn1 \
		swift-atomics swiftlang-llvm/swift-atomics \
		swift-collections swiftlang-llvm/swift-collections \
		swift-crypto swiftlang-llvm/swift-crypto \
		swift-docc-symbolkit swiftlang-llvm/swift-docc-symbolkit \
		swift-lmdb swiftlang-llvm/swift-lmdb \
		swift-markdown swiftlang-llvm/swift-markdown \
		swift-nio swiftlang-llvm/swift-nio \
		swift-system swiftlang-llvm/swift-system
P_POST_BUILD=	strip docc && \
		sh ${TOP}/mk/scripts/set-rpaths.sh docc /usr/lib/swift && \
		rm -rf share/docc && mkdir -p share/docc && \
		cp -R ${TOP}/src/swiftlang-llvm/swift-docc-render-artifact/dist share/docc/render && \
		cp ${P_BUILDSRC}/features.json share/docc/
P_PROGS=	docc
P_TREES=	share/docc

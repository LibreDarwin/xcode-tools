# with-swift-cmake.mk -- for ports whose CMake builds Swift.
#
# The compiler is this tree's swiftc, not the host's.  The SDK is named
# explicitly because CMake passes none to swiftc when it links, and the
# link then fails on -lobjc.
#
# macOS 14.0 is what Xcode's Swift tools and frameworks are built for.
# Left alone, swiftc targets the SDK's own version, 26, and CMake does not
# turn CMAKE_OSX_DEPLOYMENT_TARGET into a Swift target, so the Swift half
# is named separately from the C and C++ half.
SWIFTC_BIN=	${RELEASE}/${XCTOOLCHAIN}/usr/bin/swiftc
MACOS_SDK!=	xcrun --show-sdk-path
SWIFT_DEPLOYMENT_TARGET=	14.0
SWIFT_CMAKE_ARGS=	-DCMAKE_Swift_COMPILER=${SWIFTC_BIN} \
			-DCMAKE_OSX_SYSROOT=${MACOS_SDK} \
			-DCMAKE_OSX_DEPLOYMENT_TARGET=${SWIFT_DEPLOYMENT_TARGET} \
			-DCMAKE_Swift_COMPILER_TARGET=arm64-apple-macosx${SWIFT_DEPLOYMENT_TARGET}

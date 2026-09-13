# with-swift-cmake.mk -- for ports whose CMake builds Swift.
#
# The compiler is this tree's swiftc, not the host's.  The SDK is named
# explicitly because CMake passes none to swiftc when it links, and the
# link then fails on -lobjc.
SWIFTC_BIN=	${TOP}/build/release/${XCTOOLCHAIN}/usr/bin/swiftc
MACOS_SDK!=	xcrun --show-sdk-path
SWIFT_CMAKE_ARGS=	-DCMAKE_Swift_COMPILER=${SWIFTC_BIN} \
			-DCMAKE_OSX_SYSROOT=${MACOS_SDK}

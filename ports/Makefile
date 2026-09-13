# ports/Makefile
#
# Drives every entry of mk/ports.mk by recursing into mk/port.mk once
# per port, the same way src/Makefile drives mk/tool.mk.

TOP?=		${.CURDIR}/..

.include "${TOP}/mk/xcodetools.sys.mk"
.include "${TOP}/mk/ports.mk"

# Ports are opt-in: mk/ports.mk defines PORTS only under MK_PORTS=yes,
# so without it every loop below iterates over an empty list.  Left to
# themselves the targets would then succeed in silence -- and check-ports
# would announce that every port produced its binaries having looked at
# none of them, which is the one thing a check must never do.  Say what
# happened instead.
.if ${MK_PORTS:tl} != "yes"

PORTS_OFF=	ports: disabled (MK_PORTS=no).  Enable with: bmake MK_PORTS=yes

all clean late list-ports:
	@${ECHO} "${PORTS_OFF}"

check-ports:
	@${ECHO} "${PORTS_OFF}"
	@${ECHO} "check: no ports checked"

.else

all:
.for d p b in ${PORTS}
.if empty(DISABLED_PROGS:M${p})
	-@${MAKE} -f ${TOP}/mk/port.mk TOP=${TOP} \
		P_DIR=${d} P_NAME=${p} P_BIN=${b}
.endif
.endfor

clean:
.for d p b in ${PORTS}
	-@${MAKE} -f ${TOP}/mk/port.mk TOP=${TOP} \
		P_DIR=${d} P_NAME=${p} P_BIN=${b} clean
.endfor

# As in src/Makefile, the recursion above ignores per-port failures so
# one bad port does not stop the rest -- and ports are the likeliest
# thing to fail, since each drives a foreign build system.  check-ports
# is the guard.
check-ports:
.for d p b in ${PORTS} ${PORTS_LATE}
	@${MAKE} -f ${TOP}/mk/port.mk TOP=${TOP} \
		P_DIR=${d} P_NAME=${p} P_BIN=${b} check
.endfor
	@${ECHO} "check: every port produced its binaries"

# The ports that need the SDK, which the top-level Makefile assembles
# after the ports; it runs this once that is done.
late:
.for d p b in ${PORTS_LATE}
.if empty(DISABLED_PROGS:M${p})
	-@${MAKE} -f ${TOP}/mk/port.mk TOP=${TOP} \
		P_DIR=${d} P_NAME=${p} P_BIN=${b}
.endif
.endfor

print-installs:
.for d p b in ${PORTS} ${PORTS_LATE}
.if empty(DISABLED_PROGS:M${p})
	@${MAKE} -f ${TOP}/mk/port.mk TOP=${TOP} \
		P_DIR=${d} P_NAME=${p} P_BIN=${b} print-installs
.endif
.endfor

list-ports:
.for d p b in ${PORTS}
	@${ECHO} "${b}/${p}	<- src/${d}"
.endfor

.endif

.PHONY: all clean late check-ports list-ports print-installs

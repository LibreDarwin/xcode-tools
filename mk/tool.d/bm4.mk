# bm4 -- FreeBSD's m4, vendored in lib/bm4 (see its README).
#
# The sources FreeBSD's Makefile names, and ohash from its libopenbsd.
# -DEXTENDED is FreeBSD's too: it enables paste and spaste, which Xcode's
# bm4 has.
#
# tokenizer.l includes the grammar's header as parser.h, where tool.mk
# names it parser.tab.h, so a copy is made under that name.  The grammar
# is run through this tree's byacc when the port has built it, as
# FreeBSD's build runs it through its own byacc.
T_SRCS=		eval.c expr.c look.c main.c misc.c gnum4.c trace.c \
		parser.y tokenizer.l lib/bm4/libopenbsd/ohash.c
T_CFLAGS+=	-DEXTENDED -I${T_SRCDIR} -I${TOP}/lib/bm4/libopenbsd \
		-I${T_OBJDIR} \
		-include ${TOP}/lib/bm4/compat/reallocarray.h

.if exists(${RELEASE}/${XCTOOLCHAIN}/usr/bin/byacc)
YACC=		${RELEASE}/${XCTOOLCHAIN}/usr/bin/byacc
.endif

${T_OBJDIR}/parser.h: ${T_OBJDIR}/parser.tab.h
	cp -f ${.ALLSRC} ${.TARGET}

${T_OBJDIR}/tokenizer.l.lex.o: ${T_OBJDIR}/parser.h

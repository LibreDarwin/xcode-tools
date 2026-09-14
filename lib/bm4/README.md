# bm4

FreeBSD's `m4`, vendored, for Xcode's `bm4`.

Xcode's toolchain carries two m4s: `gm4`, GNU M4, which Apple publish as
`gm4` in the Developer Tools release, and `bm4`, which reports project
`bm4-8` and which Apple do not publish at all. `bm4` is FreeBSD's
`usr.bin/m4`: its strings carry FreeBSD's `$FreeBSD$` tags, its usage line
and error messages are FreeBSD's, and it has the `-G` option and the long
options FreeBSD added on 2023-06-21 while still carrying the `$FreeBSD$`
tags FreeBSD removed on 2023-08-16. So these files come from the last
FreeBSD commit to touch `usr.bin/m4` inside that window.

The only upstream repository is `freebsd-src`, 3.4 GB, which is a great deal
to check out for one tool; so, like `lib/msun`, the files are vendored.

* Everything here except `libopenbsd/` — from `usr.bin/m4` in
  <https://github.com/freebsd/freebsd-src>, commit `764464af4968`
  (2023-06-23)
* `libopenbsd/ohash.c`, `libopenbsd/ohash.h` — from `lib/libopenbsd` at the
  same commit; FreeBSD's `m4` links them from there
* License: BSD-3-Clause and BSD-2-Clause (the OpenBSD code m4 descends from),
  per each file's header
* Vendored: 2026-09

`tests/` and the build files are not carried: the program is built by
`mk/tool.mk` (see `mk/tool.d/bm4.mk`).

`compat/reallocarray.h` is ours, not FreeBSD's. m4 calls `reallocarray`,
which the macOS SDK does not declare; the header supplies it over `realloc`,
as Xcode's `bm4` evidently does — `realloc` is what it imports — and is
force-included by the build so the vendored files need no edit.

One line is modified: `mimic_gnu` starts at 1 in `gnum4.c`, not 0. Xcode's
`bm4` behaves as FreeBSD's does with `-g` unless it is given `-G` — ranges
in `translit`, GNU regular expressions, `m4wrap` and `undivert` as GNU's.
Update the files by replacing them from the same paths at a newer commit,
making that change again, and changing the commit named above.

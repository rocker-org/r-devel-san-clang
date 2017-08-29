
## R-devel SAN using Clang: R development binaries with Sanitizer support

The [Writing R Extensions manual](http://cran.r-project.org/doc/manuals/r-devel/R-exts.html)
details in [Section 4.3](http://cran.r-project.org/doc/manuals/r-devel/R-exts.html#Checking-memory-access)
how to check memory access.  Two sections are devoted to
[Using the Address Sanitizer](http://cran.r-project.org/doc/manuals/r-devel/R-exts.html#Using-Address-Sanitizer)
and to
[Using the Undefined Behaviour Sanitizer](http://cran.r-project.org/doc/manuals/r-devel/R-exts.html#Using-Undefined-Behaviour-Sanitizer).

Both require a particularly instrumented binary of R.  This repository
provides a Docker container with such a binary, based on the R-devel sources.

This repository uses clang; a [sibling repository](https://github.com/rocker-org/r-devel-san) uses gcc.

**Note**: This container must be run with `docker run --cap-add SYS_PTRACE`, otherwise instrumented processes fail to start due to lacking permissions. Alternatively, an instrumented process can be run with `ASAN_OPTIONS=detect_leaks=0`, but this turns off leak detection.

## Rocker-Org

This repository is part of [Rocker-Org](https://github.com/rocker-org) where
[Rocker](https://github.com/rocker-org/rocker) -- Docker containers of
interest for R users -- is being developed.

All this is work in progress; talk to @eddelbuettel and @cboettig about how
to get involved.

Documentation is being added at the [Rocker Wiki](https://github.com/rocker-org/rocker/wiki).

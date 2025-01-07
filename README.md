
## R-devel SAN using Clang: R development binaries with Sanitizer support

The [Writing R Extensions manual](http://cran.r-project.org/doc/manuals/r-devel/R-exts.html) details
in [Section 4.3](http://cran.r-project.org/doc/manuals/r-devel/R-exts.html#Checking-memory-access)
how to check memory access.  Two sections are devoted to [Using the Address
Sanitizer](http://cran.r-project.org/doc/manuals/r-devel/R-exts.html#Using-Address-Sanitizer) and to
[Using the Undefined Behaviour
Sanitizer](http://cran.r-project.org/doc/manuals/r-devel/R-exts.html#Using-Undefined-Behaviour-Sanitizer).

Both require a particularly instrumented binary of R.  This repository provides a Docker container
with such a binary, based on the R-devel sources.

This repository uses clang; a [sibling repository](https://github.com/rocker-org/r-devel-san) uses
gcc.

**Note**: At least under some Docker versions, this container must be run with `docker run --cap-add
SYS_PTRACE`, otherwise instrumented processes fail to start due to lacking
permissions. Alternatively, an instrumented process can be run with `ASAN_OPTIONS=detect_leaks=0`,
but this turns off leak detection.

Note that the instrumented version of `R` is available on the path as `Rdevel`, symbolically linked
as `RD`, and that the instrumented versions of `Rscript` is `Rscriptdevel` with symbolic link
`RDscript`. Based on the R-devel sources, they use the sanitizer setup that is the focuse here
whereas the `R` and `Rscript` binaries come from the standard binary package and correspond to
R-release *without* any sanitizer instrumentation. So use `RD` and `RDscript` to inspect undefined
behavior.

The [sanitiziers](https://github.com/eddelbuettel/sanitizers) package by
[Dirk](https://github.com/eddelbuettel) (also on CRAN
[here](https://cran.r-project.org/web/packages/sanitizers/index.html)) contains 'known bad' behavior
detected by sanitizers, It can be used to validate the setup as it should detect the errors under
`RD` and `RDscript`---but not under `R` and `Rscript` which are not instrumented. If in doubt, use
this to familiarise yourself with the sanitizer behavior.

The (newer, larger) [r-debug](https://github.com/wch/r-debug) by [Winston](https://github.com/wch/)
is also available with even more build configs and is also recommended.

## Rocker-Org

This repository is part of [Rocker-Org](https://github.com/rocker-org) where
[Rocker](https://github.com/rocker-org/rocker) -- Docker containers of
interest for R users -- is being developed.

All this is work in progress; talk to [Dirk](https://github.com/eddelbuettel) or
[Carl](https://github.com/cboettig) about how to get involved.

Documentation is being added at the [Rocker Wiki](https://github.com/rocker-org/rocker/wiki).

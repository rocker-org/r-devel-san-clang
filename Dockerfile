## Emacs, make this -*- mode: sh; -*-
# start with r-devel, which already contains many dependencies for building LLVM and R-devel
FROM rocker/r-devel:latest

## This handle reaches Carl and Dirk
MAINTAINER "Carl Boettiger and Dirk Eddelbuettel" rocker-maintainers@eddelbuettel.com

## Remain current
RUN apt-get update -qq
RUN apt-get dist-upgrade -y

# pull in build dependencies for llvm-toolchain-3.7
# can't use debian clang because their build with automake doesn't work with sanitizers
RUN apt-get update -qq \
	&& apt-get install -t unstable -y --no-install-recommends \
		cmake flex bison dejagnu tcl expect perl libtool chrpath texinfo sharutils libffi-dev lsb-release patchutils diffstat xz-utils python-dev libedit-dev \
		swig python-sphinx ocaml-nox binutils-dev libjsoncpp-dev lcov procps help2man dh-ocaml zlib1g-dev

## Must build clang with cmake in order to get sanitizers
RUN apt-get install -t unstable -y cmake

## Check out R-devel
RUN cd /tmp \
	&& svn co http://svn.r-project.org/R/trunk R-san 

RUN apt-get install -y git

## Check out LLVM 3.7.0 release
RUN cd /tmp \
	&& svn co https://llvm.org/svn/llvm-project/llvm/tags/RELEASE_370/final llvm \
	&& svn co https://llvm.org/svn/llvm-project/cfe/tags/RELEASE_370/final clang \
	&& svn co https://llvm.org/svn/llvm-project/clang-tools-extra/tags/RELEASE_370/final clang-tools-extra \
	&& svn co https://llvm.org/svn/llvm-project/compiler-rt/tags/RELEASE_370/final compiler-rt \
	&& svn co https://llvm.org/svn/llvm-project/libcxx/tags/RELEASE_370/final libcxx \
	&& svn co https://llvm.org/svn/llvm-project/libcxxabi/tags/RELEASE_370/final libcxxabi \
	&& mv clang llvm/tools \
	&& mv compiler-rt llvm/projects \
	&& mv clang-tools-extra llvm/tools/clang/tools \
	&& mv libcxx llvm/projects \
	&& mv libcxxabi llvm/projects

# build LLVM using gcc from debian unstable
# debian builds of LLVM use autotools, and thus do not contain sanitizers
RUN mkdir /tmp/llvm-build \
	&& cd /tmp/llvm-build && cmake \
	  -DCMAKE_BUILD_TYPE:STRING=Release \
	  -DLLVM_TARGETS_TO_BUILD:STRING=X86 \
	  ../llvm
RUN cd /tmp \
	&& make -j5 -C llvm-build && make -C llvm-build install && rm -rf llvm-build

# Replicating a CRAN maintainer's environment
# ENV ASAN_OPTIONS 'detect_leaks=0:detect_odr_violation=0'

## Build and install according extending the standard 'recipe' I emailed/posted years ago
# potential tweaks here:
#	don't disable openmp (gcc definitely fails without this, not sure yet about clang versions)
#	use clang's libc++ (which is compiled already), instead of libstdc++ (seems to be used by CRAN maintainers in some environments) but introduces a lot of linker and library path issues which are beyond me. Maybe this is sanitizer, not libc++ related...
#       ***Try with and without address,undefined - or just undefined or address
#	CRAN environment seems to use -fno-sanitize=float-divide-by-zero,vptr (i.e. not ignoring 'function') and not to have -fno-sanitize-recover       
#	-O2 is used by CRAN - don't know whether this has implications for ASAN or UBSAN
#	consider --as-cran check, may fail with LD_PRELOAD as it does with gcc

# did drop gnu99 from CFLAGS
# dropped pedantic to try to fix long long problem

#  -DCMAKE_C_COMPILER=clang-3.7 \
#  -DCMAKE_CXX_COMPILER=clang++-3.7 \
RUN cd /tmp/R-san \
	&& R_PAPERSIZE=letter \
	   R_BATCHSAVE="--no-save --no-restore" \
	   R_BROWSER=xdg-open \
	   PAGER=/usr/bin/pager \
	   PERL=/usr/bin/perl \
	   R_UNZIPCMD=/usr/bin/unzip \
	   R_ZIPCMD=/usr/bin/zip \
	   R_PRINTCMD=/usr/bin/lpr \
	   LIBnn=lib \
	   AWK=/usr/bin/awk \
	   CFLAGS="-pipe -Wall -g -mtune=native" \
	   CXXFLAGS="-pipe -Wall -g -mtune=native" \
	   FFLAGS="-pipe -Wall -g -mtune=native" \
	   FCFLAGS="-pipe -Wall -g -mtune=native" \
	   CC="clang-3.7 -fsanitize=address,undefined -fno-sanitize=float-divide-by-zero,function -fno-sanitize-recover=undefined,integer -fno-omit-frame-pointer" \
	   CXX="clang-3.7 -stdlib=stdc++ -fsanitize=address,undefined -fno-sanitize=float-divide-by-zero,vptr,function -fno-sanitize-recover=undefined,integer -fno-omit-frame-pointer" \
	   CXX1X="clang-3.7 -stdlib=stdc++ -fsanitize=address,undefined -fno-sanitize=float-divide-by-zero,vptr,function -fno-sanitize-recover=undefined,integer -fno-omit-frame-pointer" \
	   FC="gfortran" \
	   F77="gfortran" \
	   ./configure --enable-R-shlib \
	       --without-blas \
	       --without-lapack \
	       --with-readline \
	       --without-recommended-packages \
	       --program-suffix=san \
	       --disable-openmp \
	&& make -j5 \
	&& make install \
	&& make clean

## Set Renviron to get libs from base R install
RUN echo "R_LIBS=\${R_LIBS-'/usr/local/lib/R/site-library:/usr/local/lib/R/library:/usr/lib/R/library'}" >> /usr/local/lib/R/etc/Renviron

## it seems that R is building with the right environment without the following:
## RUN mv Makefile.site /usr/local/lib/R/etc

## RUN cat << EOF > /usr/lib/local/R/etc/Makevars.site # just move file instead

## Set default CRAN repo
RUN echo 'options("repos"="https://cran.rstudio.com")' >> /usr/local/lib/R/etc/Rprofile.site

## to also build littler against RD
##   1)	 apt-get install git autotools-dev automake
##   2)	 use CC from RD CMD config CC, ie same as R
##   3)	 use PATH to include RD's bin, ie
## ie 
##   CC="clang-3.5 -fsanitize=undefined -fno-sanitize=float-divide-by-zero,vptr,function -fno-sanitize-recover=undefined,integer" \
##   PATH="/usr/local/lib/R/bin/:$PATH" \
##   ./bootstrap

## Check out littler
RUN cd /tmp \
	&& git clone https://github.com/eddelbuettel/littler.git

# todo move this to top
RUN apt-get install -y automake

RUN cd /tmp/littler \
	&& CC="clang-3.7 -fsanitize=address,undefined -fno-sanitize=float-divide-by-zero,function -fno-sanitize-recover=undefined,integer" PATH="/usr/local/lib/R/bin/:$PATH" ./bootstrap \
	&& ./configure --prefix=/usr \
	&& make \
	&& make install \
	&& cp -vax examples/*.r /usr/local/bin 

#RUN cd /usr/local/bin \
#	&& mv R Rdevelsan \
#	&& mv Rscript Rscriptdevelsan \
#	&& ln -s Rdevelsan RDS \
#	&& ln -s Rscriptdevelsan RDSscript

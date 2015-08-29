## Emacs, make this -*- mode: sh; -*-

## start with the Docker 'base R' Debian-based image
FROM r-base:latest

## This handle reaches Carl and Dirk
MAINTAINER "Carl Boettiger and Dirk Eddelbuettel" rocker-maintainers@eddelbuettel.com

## Remain current
RUN apt-get update -qq
RUN apt-get dist-upgrade -y

## From the Build-Depends of the Debian R package, plus subversion, and clang-3.6
## 
## Also add   git autotools-dev automake  so that we can build littler from source
##
RUN apt-get update -qq \
	&& apt-get install -t unstable -y --no-install-recommends \
		automake \
		autotools-dev \
		bash-completion \
		bison \
		clang-3.5 \
		debhelper \
		default-jdk \
		g++ \
		gcc \
		gfortran \
		git \
		groff-base \
		libblas-dev \
		libbz2-dev \
		libcairo2-dev \
		libcurl4-openssl-dev \
		libjpeg-dev \
		liblapack-dev \
		liblzma-dev \
		libncurses5-dev \
		libpango1.0-dev \
		libpcre3-dev \
		libpng-dev \
		libreadline-dev \
		libtiff5-dev \
		libx11-dev \
		libxt-dev \
		mpack \
		subversion \
		tcl8.5-dev \
		texinfo \
		texlive-base \
		texlive-extra-utils \
		texlive-fonts-extra \
		texlive-fonts-recommended \
		texlive-generic-recommended \
		texlive-latex-base \
		texlive-latex-extra \
		texlive-latex-recommended \
		tk8.5-dev \
		valgrind \
		x11proto-core-dev \
		xauth \
		xdg-utils \
		xfonts-base \
		xvfb \
		zlib1g-dev 

RUN apt-get update -qq \
	&& apt-get dist-upgrade -y \
	&& apt-get install -t unstable -y \
		apt-utils \
		clang-3.6

## Check out R-devel
RUN cd /tmp \
	&& svn co http://svn.r-project.org/R/trunk R-devel 

## RUN ls -l /usr/bin/clang*

## Build and install according extending the standard 'recipe' I emailed/posted years ago.
## JW updated to use clang 3.7, sanitize address. Other discrepancies (compare to Ripley's environment are dropped "function" and "object-size" from no-sanitize

RUN cd /tmp/R-devel \
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
## Ripley appears to use -O2 here, perhaps this is leading to my errors?
	   CFLAGS="-pipe -std=gnu99 -Wall -pedantic -g -mtune=native" \
	   CXXFLAGS="-pipe -Wall -pedantic -g -mtune=native" \
	   FFLAGS="-pipe -Wall -pedantic -g -mtune=native" \
	   FCFLAGS="-pipe -Wall -pedantic -g -mtune=native" \
	   CC="clang-3.6 -fsanitize=address,undefined -fno-sanitize=float-divide-by-zero,vptr,function -fno-sanitize-recover" \
	   CXX="clang++-3.6 -fsanitize=address,undefined -fno-sanitize=float-divide-by-zero,vptr,function -fno-sanitize-recover" \
	   CXX1X="clang++-3.6 -fsanitize=address,undefined -fno-sanitize=float-divide-by-zero,vptr,function -fno-sanitize-recover" \
	   FC="gfortran" \
	   F77="gfortran" \
	   ./configure --enable-R-shlib \
	       --without-blas \
	       --without-lapack \
	       --with-readline \
	       --without-recommended-packages \
	       --program-suffix=dev \
	       --disable-openmp \
	&& make \
	&& make install \
	&& make clean

## Ripley does this: 
## MAIN_LDFLAGS=-fsanitize=address,undefined
## setenv ASAN_OPTIONS 'detect_leaks=0:detect_odr_violation=0'

## Set Renviron to get libs from base R install
RUN echo "R_LIBS=\${R_LIBS-'/usr/local/lib/R/site-library:/usr/local/lib/R/library:/usr/lib/R/library'}" >> /usr/local/lib/R/etc/Renviron

## Set default CRAN repo
RUN echo 'options("repos"="https://cran.rstudio.com")' >> /usr/local/lib/R/etc/Rprofile.site

## to also build littler against RD
##   1)	 apt-get install git autotools-dev automake
##   2)	 use CC from RD CMD config CC, ie same as R
##   3)	 use PATH to include RD's bin, ie
## ie 
##   CC="clang-3.7 -fsanitize=undefined -fno-sanitize=float-divide-by-zero,vptr,function -fno-sanitize-recover" \
##   PATH="/usr/local/lib/R/bin/:$PATH" \
##   ./bootstrap

## Check out littler
RUN cd /tmp \
	&& git clone https://github.com/eddelbuettel/littler.git

RUN cd /tmp/littler \
	&& CC="clang-3.6 -fsanitize=address,undefined -fno-sanitize=float-divide-by-zero,vptr,function -fno-sanitize-recover" PATH="/usr/local/lib/R/bin/:$PATH" ./bootstrap \
	&& ./configure --prefix=/usr \
	&& make \
	&& make install \
	&& cp -vax examples/*.r /usr/local/bin 


## I think that, although this seems like a good idea, once R-dev is installed, it would need many or all of these to be rebuilt, since the debian ones are just built against some debian archive version of R.
## RUN apt-get update -y && apt-get install -y -t unstable libxml2-dev libssl-dev r-base-core r-cran-xml r-cran-ggplot2 r-cran-rcurl r-cran-bitops r-cran-brew r-cran-rcolorbrewer r-cran-rcpp r-cran-dichromat r-cran-munsell r-cran-checkmate r-cran-evaluate r-cran-plyr r-cran-gtable r-cran-reshape2 r-cran-scales r-cran-proto r-cran-catools r-cran-testthat r-cran-memoise r-cran-digest r-cran-xtable

## do install these pesky libraries which must come from unstable (sid), and not the testing repo which is the default.
RUN apt-get update -y && apt-get install -y -t unstable libxml2-dev libssl-dev 

# don't rename R development version to RD, we want 'R' to invoke the development version!
## RUN cd /usr/local/bin \
##	&& mv R Rdevel \
##	&& mv Rscript Rscriptdevel \
##	&& ln -s Rdevel RD \
##	&& ln -s Rscriptdevel RDscript

## now we can pre-install a load of packages we know we'll need
RUN r -e "install.packages(c('devtools', 'XML', 'testthat', 'Rcpp', 'ggplot2', 'brew', \
	'rcolorbrewer', 'dichromat', 'munsell', 'checkmate', 'scales', 'proto', 'catools', \ 
	'evaluate', 'plyr', 'gtable', 'reshape2', 'knitr', 'microbenchmark', 'profr', 'xtable', \
	'rmarkdown'))"


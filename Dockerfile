## Emacs, make this -*- mode: sh; -*-

## start with the Docker 'base R' Debian-based image
FROM r-base:latest

## This handle reaches Carl and Dirk
MAINTAINER "Carl Boettiger and Dirk Eddelbuettel" rocker-maintainers@eddelbuettel.com

## Remain current
RUN apt-get update -qq \
&& apt-get dist-upgrade -y

## From the Build-Depends of the Debian R package, plus subversion, and clang-3.5
RUN apt-get update -qq \
&& apt-get install -y --no-install-recommends \
   bash-completion \
   bison \
   clang-3.5 \
   debhelper \
   default-jdk \
   g++ \
   gcc \
   gfortran \
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
   x11proto-core-dev \
   xauth \
   xdg-utils \
   xfonts-base \
   xvfb \
   zlib1g-dev 

## Check out R-devel
RUN cd /tmp \
&& svn co http://svn.r-project.org/R/trunk R-devel 

## Build and install according extending the standard 'recipe' I emailed/posted years ago
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
   CFLAGS="-pipe -std=gnu99 -Wall -pedantic -g" \
   CXXFLAGS="-pipe -Wall -pedantic -g" \
   FFLAGS="-pipe -Wall -pedantic -g" \
   FCFLAGS="-pipe -Wall -pedantic -g" \
   CC="clang-3.5 -fno-sanitize-recover -fsanitize=undefined,alignment,bounds,bool,enum,float-cast-overflow,float-divide-by-zero,function,integer-divide-by-zero,null,object-size,return,shift,signed-integer-overflow,unreachable,vla-bound" \
   CXX="clang++-3.5 -fno-sanitize-recover -fsanitize=undefined,alignment,bounds,bool,enum,float-cast-overflow,float-divide-by-zero,function,integer-divide-by-zero,null,object-size,return,shift,signed-integer-overflow,unreachable,vla-bound,vptr" \
   CXX1X="clang++-3.5 -fno-sanitize-recover -fsanitize=undefined,alignment,bounds,bool,enum,float-cast-overflow,float-divide-by-zero,function,integer-divide-by-zero,null,object-size,return,shift,signed-integer-overflow,unreachable,vla-bound,vptr" \
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

## Set Renviron to get libs from base R install
RUN echo "R_LIBS=\${R_LIBS-'/usr/local/lib/R/site-library:/usr/local/lib/R/library:/usr/lib/R/library'}" >> /usr/local/lib/R/etc/Renviron

## Set default CRAN repo
RUN echo 'options("repos"="http://cran.rstudio.com")' >> /usr/local/lib/R/etc/Rprofile.site

RUN cd /usr/local/bin \
&& mv R Rdevel \
&& mv Rscript Rscriptdevel \
&& ln -s Rdevel RD \
&& ln -s Rscriptdevel RDscript



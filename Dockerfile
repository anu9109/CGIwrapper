# Set the base image
FROM ubuntu:18.04

# Install R
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  r-base-dev \
  curl \
  libcurl4-openssl-dev \
  libxml2-dev \
  libssl-dev && \
  apt-get clean && \
  apt-get purge && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install R packages
RUN Rscript -e "install.packages('tidyverse', repos='http://cran.rstudio.com/')" && \
  Rscript -e "install.packages('optparse', repos='http://cran.rstudio.com/')" && \
  Rscript -e "install.packages('here', repos='http://cran.rstudio.com/')" 

# Add wrapper script
COPY CGIwrapper.R /

# Maintainer
MAINTAINER Anu Amallraja <anu9109@gmail.com>
###############################################################
# Dockerfile to build container images for DESeq2_PCA
# Based on python 3.11-buster
################################################################

FROM python:3.11-buster

# File Author / Maintainer
LABEL maintainer="Naoto Kubota <naotok@ucr.edu>"

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies first
RUN apt-get -qq update && \
	apt-get -qq -y install \
    build-essential gcc g++ make cmake libtool texinfo dpkg-dev pkg-config \
    libgsl-dev wget locate less vim zlib1g-dev bzip2 lzma curl r-base \
    libboost-dev libcurl4-openssl-dev libboost-all-dev libbz2-dev liblzma-dev \
    libpcre3 libpcre3-dev

# Install R (version 4.1.3)
RUN wget https://cran.r-project.org/src/base/R-4/R-4.1.3.tar.gz && \
    tar -zxvf R-4.1.3.tar.gz && \
    rm -rf R-4.1.3.tar.gz && \
    cd R-4.1.3 && \
	./configure \
    --prefix=/opt/R/4.1.3 \
	--with-pcre1 \
    --enable-R-shlib \
    --enable-memory-profiling \
    --with-blas \
    --with-lapack && \
	make && \
	make install

ENV PATH /opt/R/4.1.3/bin:$PATH

# Install DESeq2
RUN R -e "install.packages('BiocManager', repos = 'http://cran.us.r-project.org')" && \
	R -e 'install.packages("https://cran.r-project.org/src/contrib/Archive/locfit/locfit_1.5-9.4.tar.gz", repos = NULL, type = "source")' && \
    R -e "BiocManager::install('DESeq2')"

# Install python packages
RUN /usr/local/bin/python -m pip install --upgrade pip && \
    pip install pandas==1.5.3 scikit-learn==1.2.2

# Clone github repository
RUN	cd / && \
	git clone https://github.com/NaotoKubota/DESeq2_PCA.git && \
	cd DESeq2_PCA && \
	chmod +x deseq2_pca.bash deseq2.R pca.py

# Set environment variables
ENV PATH /DESeq2_PCA:$PATH

# Set working directory
WORKDIR /home

# bash
CMD ["bash"]

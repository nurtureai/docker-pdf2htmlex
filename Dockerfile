# Based on bwits/pdf2htmlex
# Idea is to wrap pdf2htmlex in a simple web service
#
# Dockerfile to build a pdf2htmlEx image
FROM ubuntu:14.04

ENV REFRESHED_AT 20170418

# thanks to https://github.com/klokoy/pdf2htmlEX_docker
#Install git and all dependencies
#
RUN apt-get update && apt-get install -qq git cmake autotools-dev libjpeg-dev libtiff5-dev libpng12-dev libgif-dev libxt-dev autoconf automake libtool bzip2 libxml2-dev libuninameslist-dev libspiro-dev python-dev libpango1.0-dev libcairo2-dev chrpath uuid-dev uthash-dev
#
#Clone the pdf2htmlEX fork of fontforge
#compile it
#
RUN git clone https://github.com/coolwanglu/fontforge.git fontforge.git
RUN cd /fontforge.git && git checkout pdf2htmlEX && ./autogen.sh && ./configure && make V=1 && make install

RUN apt-get install -qq -y wget pkg-config libopenjpeg-dev libfontconfig1-dev libfontforge-dev poppler-data poppler-utils poppler-dbg
#
#Install poppler utils
#
#RUN apt-get install -qq libpoppler-glib-dev
RUN wget http://poppler.freedesktop.org/poppler-0.33.0.tar.xz && tar -xvf poppler-0.33.0.tar.xz
RUN cd poppler-0.33.0/ && ./configure --enable-xpdf-headers && make && make install
#
#Clone and install the pdf2htmlEX git repo
#
RUN git clone git://github.com/coolwanglu/pdf2htmlEX.git
RUN cd pdf2htmlEX && pwd && git checkout tags/v0.14.6 && cmake . && make && sudo make install

# update debian source list
RUN \
    apt-get -qqy update && \
#    apt-get -qqy install pdf2htmlex && \
    apt-get -qqy install python-dev python-flask gunicorn python-pip && \
    rm -rf /var/lib/apt/lists/*

# clean up
RUN \
	rm -Rf /poppler-0.33.0 /fontforge.git /pdf2htmlEX

RUN \
  pip install gevent


RUN echo 'export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
RUN /bin/bash -c "source ~/.bashrc"

RUN LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH pdf2htmlEX -v

VOLUME /pdf/tmp
WORKDIR /pdf

ADD config.py /pdf/config.py
ADD service.py /pdf/service.py
ADD gunicorn.ini /pdf/gunicorn.ini.py

CMD gunicorn -c gunicorn.ini.py service:app


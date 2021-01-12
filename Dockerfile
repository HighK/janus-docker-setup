#FROM debian:jessie
FROM ubuntu:18.04

RUN apt-get update -y \
    && apt-get upgrade -y

RUN apt-get install -y aptitude \
    && aptitude upgrade

RUN aptitude install -y \
    build-essential \
    libmicrohttpd-dev \
    libjansson-dev \
    libssl-dev \
    libsrtp-dev \
    libsofia-sip-ua-dev \
    libglib2.0-dev \
    libopus-dev \
    libogg-dev \
    libcurl4-openssl-dev \
    liblua5.3-dev \
    libconfig-dev \
    pkg-config \
    gengetopt \
    libtool \
    automake \
    gtk-doc-tools


RUN apt-get install -y sudo \
    make \
    git \
    graphviz \
    cmake \
    wget

#libnice
RUN cd ~ \
    && git clone -b 0.1.17 https://gitlab.freedesktop.org/libnice/libnice --single-branch \
    && cd libnice \
    && ./autogen.sh \
    && ./configure --prefix=/usr \
    && make && sudo make install

#libsrtp
RUN cd ~ \
    && git clone https://github.com/cisco/libsrtp.git \
    && cd libsrtp \
    && git checkout v2.3.0 \
    && ./configure --prefix=/usr --enable-openssl \
    && make shared_library \
    && sudo make install

#doxygen
RUN apt-get install -y flex bison libqt4-dev
RUN cd ~ \
    && wget https://ftp.osuosl.org/pub/blfs/conglomeration/doxygen/doxygen-1.8.11.src.tar.gz \
    && gunzip doxygen-1.8.11.src.tar.gz \
    && tar xf doxygen-1.8.11.src.tar \
    && cd doxygen-1.8.11 \
    && mkdir build \
    && cd build \
    && cmake -G "Unix Makefiles" .. \
    && cmake -Dbuild_wizard=YES .. \
    && cmake -L .. \
    && make \
    && sudo make install


#usrsctp
RUN cd ~ \
   && git clone https://github.com/sctplab/usrsctp \
   && cd usrsctp \
   && ./bootstrap \
   && ./configure --prefix=/usr \
   && make \
   && sudo make install

#libwebsockets
RUN cd ~ \
   && git clone https://github.com/warmcat/libwebsockets.git \
   && cd libwebsockets \
   && mkdir build \
   && cd build \
   && cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr .. \
   && make \
   && sudo make install

RUN cd ~ \
    && git clone https://github.com/meetecho/janus-gateway.git \
    && cd janus-gateway \
    && sh autogen.sh \
    && ./configure --enable-docs --prefix=/opt/janus --disable-rabbitmq --disable-mqtt --enable-javascript-all-module=yes \
    && make CFLAGS='-std=c99' \
    && make install \
    && make configs \
    && ./configure --enable-docs

#RUN cp -rp ~/janus-gateway/certs /opt/janus/share/janus

COPY conf/*.cfg /opt/janus/etc/janus/

RUN apt-get install nginx -y
COPY nginx/nginx.conf /etc/nginx/nginx.conf

EXPOSE 80 7088 8088 8188 8089
EXPOSE 10000-10200/udp

CMD service nginx restart && /opt/janus/bin/janus --nat-1-1=0.0.0.0

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


# dsa

RUN apt-get -y install autoconf libass-dev libfreetype6-dev libgnutls28-dev libsdl2-dev libgpac-dev libsdl1.2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev libx11-dev libxext-dev libxfixes-dev libxcb-xfixes0-dev pkg-config texinfo texi2html yasm zlib1g-dev

RUN mkdir ~/ffmpeg_sources \
    && cd ~/ffmpeg_sources \
    && wget http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz \
    && tar xzvf yasm-1.3.0.tar.gz \
    && cd yasm-1.3.0 \
    && ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" \
    && make \
    && make install

RUN cd ~/ffmpeg_sources \
    && wget http://www.nasm.us/pub/nasm/releasebuilds/2.13.01/nasm-2.13.01.tar.bz2 \
    && tar xjvf nasm-2.13.01.tar.bz2 \
    && cd nasm-2.13.01 \
    && ./autogen.sh \
    && PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" \
    && PATH="$HOME/bin:$PATH" make \
    && make install

RUN apt-get -y install libx264-dev libopus-dev libx265-dev libunistring-dev librtmp-dev libvpx-dev

RUN cd ~/ffmpeg_sources \
    && git clone --depth 1 https://git.ffmpeg.org/ffmpeg.git \
    && cd ffmpeg \
    && PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
        --prefix="$HOME/ffmpeg_build" \
        --pkg-config-flags="--static" \
        --extra-cflags="-I$HOME/ffmpeg_build/include" \
        --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
        --bindir="$HOME/bin" \
        --enable-gpl \
        --enable-librtmp \
        --enable-libopus \
        --enable-libvpx \
        --enable-libx264 \
    && PATH="$HOME/bin:$PATH" make \
    && make install \
    && hash -r

# ss

RUN apt-get -y install unzip

RUN cd ~ \
    && wget https://nginx.org/download/nginx-1.19.6.tar.gz \
    && wget https://github.com/arut/nginx-rtmp-module/archive/master.zip \
    && tar -zxvf nginx-1.19.6.tar.gz \
    && unzip master.zip \
    && cd nginx-1.19.6 \
    && ./configure --with-http_ssl_module --add-module=../nginx-rtmp-module-master \  
    && make -j 1 \
    && sudo make install



RUN wget https://raw.github.com/JasonGiedymin/nginx-init-ubuntu/master/nginx -O /etc/init.d/nginx

RUN sudo chmod +x /etc/init.d/nginx

RUN apt install -y ffmpeg

RUN apt install -y vim

COPY conf/*.jcfg /opt/janus/etc/janus/
# COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/nginx.conf /usr/local/nginx/conf/nginx.conf
RUN sudo update-rc.d nginx defaults



EXPOSE 81 7088 8088 8188 8089
EXPOSE 10000-12000/udp

# export 1935 for rtmp, 8080 for hls or dash
EXPOSE 1935 8080

# RUN service nginx stop

CMD service nginx restart && /opt/janus/bin/janus --nat-1-1=0.0.0.0

FROM ubuntu:18.04

ARG SSDEEP_VERSION=2.14.1
ARG NGINX_VERSION=1.16.1
ARG GEOIPUPDATE_VERSION=4.2.2

# COPY sources.list /etc/apt/sources.list

COPY updateCrs.sh /opt/updateCrs.sh
COPY start.sh /opt/start.sh
COPY nginx /etc/init.d

RUN set -x \
    && buildDeps=" \
        automake \
        cmake \
        doxygen \
        g++ \
        git \
        libcurl4-gnutls-dev \
        libgeoip-dev \
        liblua5.3-dev \
        libpcre++-dev \
        libtool \
        libxml2-dev \
        libssl-dev \
        make \
        ruby \
        wget \
        curl \
        cargo \
        golang \
        cron \
    " \
    && apt-get update \
    && apt-get install -y --no-install-recommends -V $buildDeps \
    && rm -r /var/lib/apt/lists/* \
# 安装其余依赖
    && cd /opt \
    && git clone https://github.com/LMDB/lmdb --branch LMDB_0.9.23 --depth 1 \
    && make -C lmdb/libraries/liblmdb install \
    && git clone https://github.com/lloyd/yajl --branch 2.1.0 --depth 1 \
    && cd yajl \
    && ./configure \
    && make install \
    && cd /opt \
    && wget --quiet https://github.com/ssdeep-project/ssdeep/releases/download/release-${SSDEEP_VERSION}/ssdeep-${SSDEEP_VERSION}.tar.gz \
    && tar -xvzf ssdeep-${SSDEEP_VERSION}.tar.gz \
    && rm ssdeep-${SSDEEP_VERSION}.tar.gz \
    && cd ssdeep-${SSDEEP_VERSION} \
    && ./configure \
    && make install \
    && cd /opt \
# 下载并安装ModSecurity
    && git clone https://github.com/SpiderLabs/ModSecurity.git \
    && cd ModSecurity \
    && ./build.sh \
    && git submodule init \
    && git submodule update \
    && ./configure \
    && make install \
    && cd /opt \
    && wget https://github.com/maxmind/libmaxminddb/releases/download/1.3.2/libmaxminddb-1.3.2.tar.gz \
    && tar -zxvf libmaxminddb-1.3.2.tar.gz \
    && rm libmaxminddb-1.3.2.tar.gz \
    && cd libmaxminddb-1.3.2 \
    && ./configure \
    && make \
    && make install \
    && echo /usr/local/lib  >> /etc/ld.so.conf.d/local.conf \
    && ldconfig \
    && cd /opt \
# 安装nginx    
    && mkdir nginx \
    && git clone --recursive https://github.com/cloudflare/quiche \
    && git clone https://github.com/leev/ngx_http_geoip2_module.git \
    && git clone https://github.com/SpiderLabs/ModSecurity-nginx.git \
    && git clone https://github.com/openresty/headers-more-nginx-module.git \
    && curl -O https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar -zxvf nginx-${NGINX_VERSION}.tar.gz \
    && rm nginx-${NGINX_VERSION}.tar.gz \
    && cd nginx-${NGINX_VERSION} \
    && patch -p01 < /opt/quiche/extras/nginx/nginx-1.16.patch \
    && ./configure --prefix=/opt/nginx --with-http_ssl_module --with-http_v2_module --with-http_v3_module --with-openssl=/opt/quiche/deps/boringssl --with-quiche=/opt/quiche --add-module=/opt/ngx_http_geoip2_module --add-module=/opt/ModSecurity-nginx --add-module=/opt/headers-more-nginx-module \
    && make \
    && make install \
    && cd /opt/nginx \
    && mkdir modsec \
    && mv /opt/ModSecurity/unicode.mapping /opt/nginx/modsec \
    && cd /opt \
    && git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git \
    && mv owasp-modsecurity-crs/rules /opt/nginx/conf \
    && mv owasp-modsecurity-crs/crs-setup.conf.example /opt/nginx/conf/crs-setup.conf \
    && wget https://github.com/maxmind/geoipupdate/releases/download/v${GEOIPUPDATE_VERSION}/geoipupdate_${GEOIPUPDATE_VERSION}_linux_amd64.tar.gz \
    && tar -zxvf geoipupdate_${GEOIPUPDATE_VERSION}_linux_amd64.tar.gz \
    && rm geoipupdate_${GEOIPUPDATE_VERSION}_linux_amd64.tar.gz \
    && mv geoipupdate_${GEOIPUPDATE_VERSION}_linux_amd64/geoipupdate /usr/local/bin/ \
    && echo "* 2    */10 * *   root    /usr/local/bin/geoipupdate > /dev/null 2>&1" >> /etc/crontab \
    && echo "* 2    * * *   root    /opt/updateCrs.sh > /dev/null 2>&1" >> /etc/crontab \
    && chmod +x /opt/updateCrs.sh \
    && chmod +x /opt/start.sh \
    && chmod +x /etc/init.d/nginx \
    && ln -s /opt/nginx/sbin/nginx /usr/bin/nginx \
    && apt-get purge -y --auto-remove automake doxygen g++ make wget curl cargo golang \
# 删除下载的安装文件
    && rm -r ModSecurity owasp-modsecurity-crs geoipupdate_${GEOIPUPDATE_VERSION}_linux_amd64 libmaxminddb-1.3.2 yajl lmdb ssdeep-${SSDEEP_VERSION} quiche ModSecurity-nginx headers-more-nginx-module nginx-${NGINX_VERSION} ngx_http_geoip2_module

COPY GeoLite2-City.mmdb /opt/GeoLite2Databases/GeoLite2-City.mmdb
COPY GeoLite2-Country.mmdb /opt/GeoLite2Databases/GeoLite2-Country.mmdb

COPY modsecurity.conf /opt/nginx/conf/modsecurity.conf
COPY Geoip2.conf /opt/nginx/conf/Geoip2.conf
COPY fastcgi.conf /opt/nginx/conf/fastcgi.conf
COPY GeoIP.conf /usr/local/etc/GeoIP.conf

EXPOSE 80
EXPOSE 443

CMD /opt/start.sh


FROM nginx:1.17.9 as build
LABEL maintainer="Jorge Padron <jpadron1986@gmail.com>"
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update
RUN apt install -y wget tar nano fail2ban tzdata autoconf automake build-essential git libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre++-dev libtool libxml2 libxml2-utils libxml2-dev libssl-dev libyajl-dev pkgconf zlib1g-dev php-fpm php-common php-mbstring php-xmlrpc php-soap php-gd php-xml php-cli php-curl php-zip && \
    git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity && \
    cd ModSecurity/ && \
    git submodule init && git submodule update && \
    ./build.sh && ./configure && \
    make && make install && cd / && \
    git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git && \
	wget http://nginx.org/download/nginx-1.17.9.tar.gz && \
	tar zxvf nginx-1.17.9.tar.gz && \
	cd nginx-1.17.9 && \
	./configure --add-dynamic-module=/ModSecurity-nginx --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-cc-opt='-g -O2 -fdebug-prefix-map=/data/builder/debuild/nginx-1.19.3/debian/debuild-base/nginx-1.19.3=. -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' --with-ld-opt='-Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie' && \
	make modules && \
	make install && \
	cd / && \
    mkdir -p /etc/nginx/modsec && \
	git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git /usr/src/owasp-modsecurity-crs && \
	cp -R /usr/src/owasp-modsecurity-crs/rules/ /etc/nginx/modsec/ && \
	mv /etc/nginx/modsec/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example  /etc/nginx/modsec/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf && \
	mv /etc/nginx/modsec/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example  /etc/nginx/modsec/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
COPY crs-setup.conf /etc/nginx/modsec/crs-setup.conf
COPY modsecurity.conf /etc/nginx/modsec/modsecurity.conf
COPY main.conf /etc/nginx/modsec/main.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /usr/share/nginx/html/index.html
COPY default.conf /etc/nginx/conf.d/default.conf
CMD ["nginx","-g","daemon off;"]
EXPOSE 80 443


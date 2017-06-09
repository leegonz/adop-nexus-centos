FROM centos:7

ENV NGINX_VERSION 1.8.0

############## nginx setup ##############

RUN yum -y update \
    && yum install -y \
        ca-certificates \
        git \
        sudo \
        gcc \
        make \
        pcre-devel \
        libpcre3-dev \
        zlib1g-dev \
        libldap2-dev \
        libssl-dev \
        wget \
        openssl.x86_64 \
        openssl-devel.x86_64 \
        python-devel \
        openldap-devel \
     && yum clean all

# Add nginx user and group
ARG user=www-data
ARG group=www-data
ARG uid=1000
ARG gid=1000

RUN groupadd -g ${gid} ${group} \
    && useradd -d /etc/nginx -u ${uid} -g ${gid} -m -s /bin/bash ${user}

#RUN groupadd -g 1000 www-data \
# && useradd -u 1000 -D -S -G www-data www-data

# See http://wiki.nginx.org/InstallOptions
RUN mkdir /var/log/nginx \
    && mkdir -p /etc/nginx/sites-enabled \
    && cd ~ \
    && git clone https://github.com/kvspb/nginx-auth-ldap.git \
    && git clone https://github.com/nginx/nginx.git \
    && cd nginx \
    && git checkout tags/release-${NGINX_VERSION} \
    && ./auto/configure \
        --add-module=/root/nginx-auth-ldap \
        --with-http_ssl_module \
        --with-debug \
        --conf-path=/etc/nginx/nginx.conf \ 
        --sbin-path=/usr/sbin/nginx \ 
        --pid-path=/var/run/nginx.pid \ 
        --error-log-path=/var/log/nginx/error.log \ 
        --http-log-path=/var/log/nginx/access.log \ 
    && make install \
    && cd .. \
    && rm -rf nginx-auth-ldap \
    && rm -rf nginx

COPY templates/nginx/nginx.init /etc/init.d/nginx
RUN chmod +x /etc/init.d/nginx

EXPOSE 80 443

# Adding base data
RUN mkdir -p /resources/
COPY resources/configuration/ /resources/configuration/
COPY resources/release_note/ /resources/release_note/
COPY resources/scripts/ /resources/scripts/
COPY templates/configuration/ /templates/configuration/
RUN chmod +x /resources/scripts/* 
#    chown -R ${user}:${group} /etc/nginx /etc/init.d/nginx* /usr/share /var/log/nginx /usr/local/nginx

#USER ${user}

CMD ["/resources/scripts/entrypoint.sh"]

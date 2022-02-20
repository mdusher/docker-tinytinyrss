FROM alpine:3.15

ARG S6_OVERLAY_VERSION=3.0.0.2

RUN apk add --no-cache tar xz

# Add S6 Overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch-${S6_OVERLAY_VERSION}.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64-${S6_OVERLAY_VERSION}.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch-${S6_OVERLAY_VERSION}.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64-${S6_OVERLAY_VERSION}.tar.xz

# TinyTinyRSS
RUN apk add --no-cache \
    bash \
    curl \
    nginx \
    openssl \
    shadow \
    sudo \
    php8 \
    php8-fpm \
	php8-curl \
    php8-pdo \
    php8-gd \
    php8-intl \
    php8-xml \
    php8-mbstring \
    php8-pgsql \
    php8-pdo_mysql \
    php8-pdo_pgsql \
    php8-session \
    php8-tokenizer \
    php8-dom \
    php8-fileinfo \
    php8-json \
    php8-iconv \
    php8-pcntl \
    php8-posix \
    php8-zip \
    php8-exif \
    php8-openssl

# Add tt-rss from master and the feedly theme
ADD https://git.tt-rss.org/git/tt-rss/archive/master.tar.gz /tmp/ttrss.tar.gz
ADD https://github.com/levito/tt-rss-feedly-theme/archive/refs/tags/v2.9.1.tar.gz /tmp/ttrss-feedly-theme.tar.gz
RUN mkdir -p /app/www/tt-rss /tmp/ttrss-feedly-theme && \
    tar xf /tmp/ttrss.tar.gz -C /app/www/tt-rss --strip-components=1 && \
    tar xf /tmp/ttrss-feedly-theme.tar.gz -C /tmp/ttrss-feedly-theme --strip-components=1 && \
    cp -r /tmp/ttrss-feedly-theme/feedly* /app/www/tt-rss/themes.local/ && \
    rm /tmp/ttrss-feedly-theme.tar.gz && \
    rm /tmp/ttrss.tar.gz && \
    rm -rf /tmp/ttrss-feedly-theme

ADD files/ /
RUN adduser -D abc && \
    chmod +x /etc/s6-overlay/s6-rc.d/**/* /app/user-setup.sh && \
    sed -i "s#;error_log = log/php8/error.log.*#error_log = /app/log/php/error.log#g" /etc/php8/php-fpm.conf && \
    sed -i "s#user = nobody.*#user = abc#g" /etc/php8/php-fpm.d/www.conf && \
    sed -i "s#group = nobody.*#group = abc#g" /etc/php8/php-fpm.d/www.conf && \
    ln -sf /usr/bin/php8 /usr/bin/php

ENTRYPOINT ["/init"]

ENV S6_KEEP_ENV=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    TTRSS_MYSQL_CHARSET=UTF8 \
    TTRSS_SINGLE_USER_MODE=true \
    TTRSS_SIMPLE_UPDATE_MODE=false \
    TTRSS_PHP_EXECUTABLE=/usr/bin/php \
    TTRSS_LOCK_DIRECTORY=/app/www/tt-rss/lock \
    TTRSS_CACHE_DIR=/app/www/tt-rss/cache \
    TTRSS_ICONS_DIR=/app/www/tt-rss/feed-icons \
    TTRSS_ICONS_URL=feed-icons \
    TTRSS_AUTH_AUTO_CREATE=true \
    TTRSS_AUTH_AUTO_LOGIN=true \
    TTRSS_FORCE_ARTICLE_PURGE=0 \
    TTRSS_SESSION_COOKIE_LIFETIME=86400
#!/usr/bin/env bash

PUID=${PUID:-911}
PGID=${PGID:-911}

/usr/sbin/groupmod -o -g "$PGID" abc
/usr/sbin/usermod -o -u "$PUID" abc

echo "
-------------------------------------
GID/UID
-------------------------------------
User uid:    $(id -u abc)
User gid:    $(id -g abc)
-------------------------------------
"

# create local php.ini if it doesn't exist, set local timezone
#[[ ! -f /config/php/php-local.ini ]] && \
#        printf "; Edit this file to override php.ini directives and restart the container\\n\\ndate.timezone = %s\\n" "$TZ" > /config/php/php-local.ini
# copy user php-local.ini to image
# cp /config/php/php-local.ini /etc/php8/conf.d/php-local.ini

# permissions
echo "creating dirs.."
mkdir -p /app/log/nginx \
         /app/log/php \
         /app/keys \
         /run \
         /var/lib/nginx/tmp/client_body \
         /var/tmp/nginx

echo "creating config.php..."
echo "<?php" > /app/www/tt-rss/config.php
env | grep -E '^TTRSS_' | awk '{print "putenv(\"" $1 "\");"}' >> /app/www/tt-rss/config.php

echo "fixing permissions.."
chown abc:abc /app
chown -R abc:abc \
        /var/lib/nginx \
        /var/tmp/nginx \
        /app/www 
chmod -R g+w \
        /app/nginx \
        /app/www \
        /app/log

if [ "${TTRSS_DB_TYPE}" = "mysql" ]; then
    echo "waiting for mariadb..."
    while ! nc -z ${TTRSS_DB_HOST} ${TTRSS_DB_PORT}; do   
        sleep 1
    done

    echo "running schema migrations.."
    cd /app/www/tt-rss
    sudo -u abc php8 update.php --update-schema=force-yes
fi
# Tiny Tiny RSS, nginx and php-fpm in docker

It's Tiny Tiny RSS, nginx and php-fpm in a container using the s6 overlay. I've built this for myself and it's configured how I like to use it. You'll have to take it as it is and figure it out for yourself.

At a bare minimum you'll need the following environment variables:
- TTRSS_DB_TYPE
- TTRSS_DB_HOST
- TTRSS_DB_USER
- TTRSS_DB_NAME
- TTRSS_DB_PASS
- TTRSS_DB_PORT
- TTRSS_SELF_URL_PATH

There's a `docker-compose.yml` included which is close to the environment I actually use - so give that a go and figure it out from there.

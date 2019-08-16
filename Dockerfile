FROM php:7.1-fpm-alpine

#Install PHP extensions
RUN mkdir -p /tmp/php_packages
COPY phpredis.tgz swoole_source.tgz swoole_loader71.so api_license.txt api.tar.gz /tmp/php_packages/
RUN apk add --no-cache autoconf build-base openssl openssl-dev file linux-headers \
    && cd /tmp/php_packages/ && tar zxvf phpredis.tgz && cd phpredis \
    && phpize && ./configure && make && make install\
    && echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini \
    && cd /tmp/php_packages/ && tar zxvf swoole_source.tgz && cd swoole-src \
    && ./build.sh \
    && echo "extension=swoole.so" > /usr/local/etc/php/conf.d/swoole.ini \
    # && cd /tmp/php_packages/ && cp swoole_loader71.so /usr/local/lib/php/extensions/no-debug-non-zts-20170718 \
    && cd /tmp/php_packages/ && cp swoole_loader71.so /usr/local/lib/php/extensions/no-debug-non-zts-20160303 \
    && echo "extension=swoole_loader71.so" >> /usr/local/etc/php/conf.d/swoole.ini \
    && apk del autoconf build-base openssl-dev file linux-headers 

RUN apk upgrade --update && apk add libpng-dev libjpeg-turbo-dev freetype-dev libbz2 \
    libxml2-dev libxml2 bzip2-dev libxslt libxslt-dev \
    && docker-php-ext-install bcmath calendar gd hash zip pdo_mysql mysqli pcntl sockets \
    soap exif bz2 pdo_mysql soap exif sysvmsg sysvsem sysvshm xsl

FROM php:7.1-fpm-alpine

RUN apk add --no-cache openssl libxml2 libxslt libbz2 
#COPY --from=0 /usr/local/lib/php/extensions/no-debug-non-zts-20170718 /usr/local/lib/php/extensions/no-debug-non-zts-20170718
COPY --from=0 /usr/local/lib/php/extensions/no-debug-non-zts-20160303 /usr/local/lib/php/extensions/no-debug-non-zts-20160303
COPY --from=0 /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d
COPY --from=0  /usr/lib/libhiredis.so.0.13 /usr/lib/libpng16.so.16 /usr/lib/

COPY composer.phar /usr/local/bin/composer
COPY php.ini /usr/local/etc/php/php.ini
COPY php-fpm.conf /usr/local/etc/php-fpm.conf
COPY api_license.txt /etc

##Deploy super_api
#RUN mkdir -p /tmp
#RUN cd /disk/super_api && tar zxvf api.tar.gz

RUN apk update && apk add supervisor
RUN adduser -D -u 2200 nginx && mkdir -p /etc/supervisor.d /disk/log/php-fpm /disk/log/supervisor.d
COPY  supervisord_fpm.ini  /etc/supervisor.d
VOLUME ["/disk/log", "/disk/projects", "/disk/super_projects"]

ENTRYPOINT ["/usr/bin/supervisord", "-n"]


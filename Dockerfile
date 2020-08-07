FROM php:7.3

RUN DEBIAN_FRONTEND=noninteractive apt update
RUN DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
        git \
        iproute2 \
        libcurl4-gnutls-dev \
        libicu-dev \
        libjpeg-dev \
        libmcrypt-dev \
        libpcre3-dev \
        libpng-dev \
        libpq-dev \
        libxml2-dev \
        libzip-dev && \
    apt -y autoremove && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install \
        gd \
        intl \
        opcache \
        pcntl \
        pdo_pgsql \
        zip

RUN pecl install xdebug; \
    pecl install mcrypt; \
    docker-php-ext-enable xdebug


# configure PHP
RUN { \
        echo 'opcache.enable=1'; \
        echo 'opcache.enable_cli=1'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=10000'; \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.save_comments=1'; \
        echo 'opcache.revalidate_freq=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini; \
    echo 'memory_limit=512M' > /usr/local/etc/php/conf.d/memory-limit.ini

ADD bin/bootstrap.sh /usr/local/bin/
RUN /usr/local/bin/bootstrap.sh

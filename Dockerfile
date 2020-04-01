FROM php:7.3
RUN DEBIAN_FRONTEND=noninteractive apt update && \
    apt install -yq --no-install-recommends \
        git libpq-dev libcurl4-gnutls-dev libicu-dev libvpx-dev \
        libjpeg-dev libpng-dev libxpm-dev zlib1g-dev libfreetype6-dev \
        libxml2-dev libexpat1-dev libbz2-dev libgmp3-dev libldap2-dev \
        unixodbc-dev libsqlite3-dev libaspell-dev libsnmp-dev \
        libpcre3-dev libtidy-dev libzip-dev && \
    apt -yq autoremove && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-install \
    mbstring pdo_pgsql curl json intl gd xml zip bz2 opcache
RUN pecl install xdebug && docker-php-ext-enable xdebug
RUN curl -sS https://getcomposer.org/installer | php

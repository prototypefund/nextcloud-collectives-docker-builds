FROM php:7.3-apache

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
        libxml2-dev \
        libzip-dev \
        sudo && \
    apt -y autoremove && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install \
        gd \
        intl \
        opcache \
        pcntl \
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

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
RUN a2enmod rewrite

# Prepare webroot
ENV WEBROOT /var/www/html
WORKDIR /var/www
RUN rmdir /var/www/html && \
    chown www-data:www-data /var/www

# Install Nextcloud
RUN sudo -u www-data git clone --branch stable19 --depth 1 --shallow-submodules \
        https://github.com/nextcloud/server.git /var/www/html && \
    cd /var/www/html && \
    sudo -u www-data git submodule update --init --depth 1 && \
    sudo -u www-data /var/www/html/occ maintenance:install \
        --admin-user=admin --admin-pass=admin

WORKDIR /var/www/html

# Install and enable Nextcloud apps
# TODO: remove `-f` once text app is compatible with stable19 again
RUN for app in circles viewer text; do \
    sudo -u www-data /var/www/html/occ app:enable -f $app; \
    done

# Create Nextcloud users
RUN for user in jane john alice bob; do \
    sudo -u www-data OC_PASS="$user" /var/www/html/occ user:add \
        --password-from-env "$user" || true; \
    done

# Configure Nextcloud
RUN NC_TRUSTED_DOMAIN_IDX=1 && \
    for domain in localhost nextcloud.local; do \
    sudo -u www-data /var/www/html/occ config:system:set trusted_domains \
        "$NC_TRUSTED_DOMAIN_IDX" --value="$domain"; \
    NC_TRUSTED_DOMAIN_IDX="$(($NC_TRUSTED_DOMAIN_IDX+1))"; \
    done && \
    sudo -u www-data /var/www/html/occ config:system:set \
        --value 'http://nextcloud.local' -- overwrite.cli.url && \
    sudo -u www-data /var/www/html/occ config:system:set \
        --type bool --value true -- allow_local_remote_servers

# Configure circles app to accept non-ssl requests
RUN sudo -u www-data /var/www/html/occ config:app:set --value 1 -- circles \
        allow_non_ssl_links && \
    sudo -u www-data /var/www/html/occ config:app:set --value 1 -- circles \
        local_is_non_ssl

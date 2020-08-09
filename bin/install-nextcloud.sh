#!/bin/sh

NEXTCLOUD_APPS="circles viewer text"
NEXTCLOUD_USERS="jane john alice bob"
NEXTCLOUD_TRUSTED_DOMAINS="localhost nextcloud.local"

OCC() {
    sudo -E -u www-data $WEBROOT/occ $@
}

configure_add_user() {
    export OC_PASS="$1"
    OCC user:add --password-from-env "$1"
}

# Prepare webroot
rmdir $WEBROOT
chown www-data:www-data /var/www

# Install Nextcloud
sudo -E -u www-data git clone --branch stable19 --depth 1 --shallow-submodules \
    https://github.com/nextcloud/server.git $WEBROOT
cd $WEBROOT
sudo -E -u www-data git submodule update --init --depth 1
OCC maintenance:install --admin-user=admin --admin-pass=admin

# Install Nextcloud apps
for app in $NEXTCLOUD_APPS; do
    OCC app:enable $app
done

# Create Nextcloud users
for user in $NEXTCLOUD_USERS; do
    configure_add_user $user
done

# Configure Nextcloud
NC_TRUSTED_DOMAIN_IDX=1
for domain in $NEXTCLOUD_TRUSTED_DOMAINS; do
    OCC config:system:set trusted_domains "$NC_TRUSTED_DOMAIN_IDX" --value="$domain"
    NC_TRUSTED_DOMAIN_IDX="$(($NC_TRUSTED_DOMAIN_IDX+1))"
done

# Allow requests from local remote servers
OCC config:system:set --type bool --value true -- allow_local_remote_servers

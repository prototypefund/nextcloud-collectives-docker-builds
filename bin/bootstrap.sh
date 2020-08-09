#!/bin/sh

NEXTCLOUD_APPS="circles viewer text"
NEXTCLOUD_USERS="jane john alice bob"
NEXTCLOUD_TRUSTED_DOMAINS="localhost nextcloud.local"

configure_add_user() {
    export OC_PASS="$1"
    ./occ user:add --password-from-env "$1"
}

mkdir -p /srv/nextcloud
cd /srv/nextcloud
git clone --branch stable19 --depth 1 --shallow-submodules \
    https://github.com/nextcloud/server.git
cd server
git submodule update --init --depth 1
./occ maintenance:install --admin-user=admin --admin-pass=admin
for app in $NEXTCLOUD_APPS; do
    ./occ app:enable $app
done
for user in $NEXTCLOUD_USERS; do
    configure_add_user $user
done
NC_TRUSTED_DOMAIN_IDX=1
for domain in $NEXTCLOUD_TRUSTED_DOMAINS; do
    ./occ config:system:set trusted_domains "$NC_TRUSTED_DOMAIN_IDX" --value="$domain"
    NC_TRUSTED_DOMAIN_IDX="$(($NC_TRUSTED_DOMAIN_IDX+1))"
done
# Allow requests from local remote servers
./occ config:system:set --type bool --value true -- allow_local_remote_servers


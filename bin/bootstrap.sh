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
git clone https://github.com/nextcloud/server.git
cd server
git submodule update --init
./occ maintenance:install --admin-user=admin --admin-pass=admin
for app in $NEXTCLOUD_APPS; do
    ./occ app:enable $app
done
for user in $NEXTCLOUD_USERS; do
    configure_add_user $user
done
INTERNAL_IP_ADDRESS="$(ip a show type veth | grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")"
NC_TRUSTED_DOMAIN_IDX=1
for domain in NEXTCLOUD_TRUSTED_DOMAINS; do
    ./occ config:system:set trusted_domains "$NC_TRUSTED_DOMAIN_IDX" --value="$domain"
    NC_TRUSTED_DOMAIN_IDX="$(($NC_TRUSTED_DOMAIN_IDX+1))"
    # Add domain to /etc/hotss
    if [ "$domain" != "localhost" ]; then
        echo "$INTERNAL_IP_ADDRESS $domain" >>/etc/hosts
    fi
done
# Allow requests from local remote servers
./occ config:system:set --type bool --value true -- allow_local_remote_servers


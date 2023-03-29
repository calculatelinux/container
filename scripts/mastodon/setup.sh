#!/bin/bash

export PATH="/lib/rc/bin:$PATH"
set -ueo pipefail
scriptpath=$(dirname $(readlink -f $0))

. /var/db/repos/calculate/scripts/ini.sh

echo "Mastodon setup"

test -f /run/redis/redis.pid && /etc/init.d/redis start

for script in $scriptpath/stages/*.sh; do
        "$script"
done

/etc/init.d/redis restart
rc-update -u
openrc

echo -e "\nAll is done! Open the link https://${ini[mastodon.local_domain]} on your browser after adding ${ini[mastodon.local_domain]} to dns"

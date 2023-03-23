#!/bin/bash

set -ueo pipefail

test -e /var/lib/rabbitmq/mnesia && exit

export PATH="/lib/rc/bin:$PATH"

. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

/etc/init.d/rabbitmq start

rabbitmqctl add_user ${ini[rabbitmq.taiga_user]} ${ini[rabbitmq.taiga_password]}
rabbitmqctl add_vhost taiga
rabbitmqctl set_permissions -p taiga ${ini[rabbitmq.taiga_user]} ".*" ".*" ".*"


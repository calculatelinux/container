#!/bin/bash

set -ueo pipefail

if [[ -e /var/lib/rabbitmq/mnesia ]]
then
	exit
fi


export PATH="/lib/rc/bin:$PATH"
source /var/db/repos/container/scripts/functions.sh
get_ini

/etc/init.d/rabbitmq start

rabbitmqctl add_user $rabbitmq_taiga_user $rabbitmq_taiga_password
rabbitmqctl add_vhost taiga
rabbitmqctl set_permissions -p taiga $rabbitmq_taiga_user ".*" ".*" ".*"

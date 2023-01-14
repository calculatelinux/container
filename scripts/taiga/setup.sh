#!/bin/bash

export PATH="/lib/rc/bin:$PATH"
set -ueo pipefail

show=
if [[ $# == 1  && $1 == 'show' ]]
then
	show='show'
fi

chown taiga:taiga /var/calculate/ini.env
su - taiga -c '/var/db/repos/container/scripts/taiga/install.sh'

/var/db/repos/container/scripts/taiga/postgresql.sh

/var/db/repos/container/scripts/taiga/rabbitmq.sh

/var/db/repos/container/scripts/taiga/config.sh $show

su - taiga -c '/var/db/repos/container/scripts/taiga/migrate.sh'


if [[ ! -e /etc/runlevels/default/taiga ]]
then
	cl-setup-system
	rc-update -u
fi
openrc

if [[ -z $show ]]
then
	einfo "To display configured options, run 'cl-setup show'."
fi


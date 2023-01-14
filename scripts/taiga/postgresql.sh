#!/bin/bash

set -ueo pipefail
if [[ -e /var/lib/postgresql/12 ]]
then
	exit
fi

export PATH="/lib/rc/bin:$PATH"
. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

emerge --config =dev-db/postgresql-12.12

/etc/init.d/postgresql-12 start

psql -U postgres -c "ALTER USER postgres WITH PASSWORD '${ini[postgresql.postgres_password]}'"

psql -U postgres -c "CREATE ROLE ${ini[postgresql.taiga_user]} WITH login"
psql -U postgres -c "CREATE DATABASE taiga OWNER taiga"
psql -U postgres -c "ALTER USER ${ini[postgresql.taiga_user]} WITH PASSWORD '${ini[postgresql.taiga_password]}'"

cl-core-setup -n postgresql -f
/etc/init.d/postgresql-12 restart

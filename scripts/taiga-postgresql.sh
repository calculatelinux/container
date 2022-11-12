#!/bin/bash

set -ueo pipefail
if [[ -e /var/lib/postgresql/12 ]]
then
	exit
fi

export PATH="/lib/rc/bin:$PATH"
source /var/db/repos/container/scripts/functions.sh
get_ini

emerge --config =dev-db/postgresql-12.12

/etc/init.d/postgresql-12 start

psql -U postgres -c "ALTER USER postgres WITH PASSWORD '$postgresql_postgres_password'"

psql -U postgres -c "CREATE ROLE $postgresql_taiga_user WITH login"
psql -U postgres -c "CREATE DATABASE taiga OWNER taiga"
psql -U postgres -c "ALTER USER $postgresql_taiga_user WITH PASSWORD '$postgresql_taiga_password'"

cl-core-setup -n postgresql -f
/etc/init.d/postgresql-12 restart

#!/bin/bash

set -ueo pipefail

[[ -n "$(ls -A /var/lib/postgresql)" ]] && exit

export PATH="/lib/rc/bin:$PATH"

. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

pgver() {
	local ver=$(ls -d /var/db/pkg/dev-db/postgresql-*)
	ver=${ver#*postgresql-}
	if [[ ${1:-} == 'slot' ]]; then
		echo ${ver%%.*}
	else
		echo ${ver%%-*}
	fi
}

emerge --config =dev-db/postgresql-$(pgver)

/etc/init.d/postgresql-$(pgver slot) start

psql -U postgres -c "ALTER USER postgres WITH PASSWORD '${ini[postgresql.postgres_password]}'"
psql -U postgres -c "CREATE ROLE ${ini[postgresql.homeassistant_user]} WITH login"
psql -U postgres -c "CREATE DATABASE homeassistant OWNER homeassistant"
psql -U postgres -c "ALTER USER ${ini[postgresql.homeassistant_user]} WITH PASSWORD '${ini[postgresql.homeassistant_password]}'"

cl-core-setup -n postgresql -f

/etc/init.d/postgresql-$(pgver slot) restart

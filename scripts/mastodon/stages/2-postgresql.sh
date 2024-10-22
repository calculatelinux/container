#!/bin/bash

set -ueo pipefail

export PATH="/lib/rc/bin:$PATH"

[[ -n "$(ls -A /var/lib/postgresql)" ]] && exit

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

emerge --config dev-db/postgresql

/etc/init.d/postgresql-$(pgver slot) start

psql -U postgres -c "ALTER USER postgres WITH PASSWORD '${ini[postgresql.postgres_password]}'"
psql -U postgres -c "CREATE ROLE ${ini[postgresql.mastodon_user]} WITH login createdb"
psql -U postgres -c "ALTER USER ${ini[postgresql.mastodon_user]} WITH PASSWORD '${ini[postgresql.mastodon_password]}'"

cl-core-setup -n postgresql -f
/etc/init.d/postgresql-$(pgver slot) restart

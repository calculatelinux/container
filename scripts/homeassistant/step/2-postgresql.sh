#
# Функция configure() настраивает PostgreSQL
#
# Параметры:
# $1 = check - пропуск настройки
configure() {
	if [[ -n "$(ls -A /var/lib/postgresql)" ]]; then
		return
	fi

	emerge --config postgresql

	pg_ver=$(ls /etc/init.d/postgresql-*); pg_ver=${pg_ver##*-}

	/etc/init.d/postgresql-$pg_ver start

	psql -U postgres -c "ALTER USER postgres WITH PASSWORD '${ini[postgresql.postgres_password]}'"
	createuser -U postgres ${ini[postgresql.homeassistant_user]}
	createdb -U postgres ${ini[postgresql.homeassistant_database]} -O ${ini[postgresql.homeassistant_user]}
	psql -U postgres -c "ALTER USER ${ini[postgresql.homeassistant_user]} WITH PASSWORD '${ini[postgresql.homeassistant_password]}'"

	cl-core-setup -n postgresql -f

	/etc/init.d/postgresql-$pg_ver restart
}

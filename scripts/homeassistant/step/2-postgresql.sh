#
# Функция configure() настраивает PostgreSQL
#
configure() {
	if [[ -n "$(ls -A /var/lib/postgresql)" ]]; then
		return 0
	fi

	echo 'Setting up PostgreSQL'
	pg_ver=$(ls /etc/init.d/postgresql-*); pg_ver=${pg_ver##*-}

	ebegin "Configuring PostgreSQL ${pg_ver}"
	emerge --config postgresql &>>${log_dir}/postgresql.log
	eend

	ebegin 'Starting PostgreSQL'
	rc-service postgresql-${pg_ver} start >>${log_dir}/postgresql.log
	eend

	ebegin 'Database creation'
	psql -U postgres -c "ALTER USER postgres WITH PASSWORD '${ini[postgresql.postgres_password]}'" >>${log_dir}/postgresql.log
	createuser -U postgres ${ini[postgresql.homeassistant_user]}
	createdb -U postgres ${ini[postgresql.homeassistant_database]} -O ${ini[postgresql.homeassistant_user]}
	psql -U postgres -c "ALTER USER ${ini[postgresql.homeassistant_user]} WITH PASSWORD '${ini[postgresql.homeassistant_password]}'" >>${log_dir}/postgresql.log
	eend

	ebegin 'Updating permissions'
	cl-core-setup -n postgresql -f >>${log_dir}/postgresql.log
	eend

	ebegin 'Restart the server'
	rc-service postgresql-${pg_ver} restart >>${log_dir}/postgresql.log
	eend
}

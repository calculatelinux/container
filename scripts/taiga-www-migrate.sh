#!/bin/bash

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"

source /var/db/repos/container/scripts/functions.sh
get_ini

if [[ $UID == 0 ]]
then
	exit
fi

data=$(PGPASSWORD=$postgresql_taiga_password psql -U $postgresql_taiga_user -d $postgresql_taiga_database -c '\dt' 2>/dev/null)

if [[ -n $data ]]
then
	exit 
fi

migrate_pgsql(){
	cd ~
	cd taiga-back
	source .venv/bin/activate
	DJANGO_SETTINGS_MODULE=settings.config python manage.py migrate --noinput

	clear_buf
	einfo create an administrator with strong password
	CELERY_ENABLED=False DJANGO_SETTINGS_MODULE=settings.config python manage.py createsuperuser
	DJANGO_SETTINGS_MODULE=settings.config python manage.py loaddata initial_project_templates
	DJANGO_SETTINGS_MODULE=settings.config python manage.py compilemessages
	DJANGO_SETTINGS_MODULE=settings.config python manage.py collectstatic --noinput
}

migrate_pgsql

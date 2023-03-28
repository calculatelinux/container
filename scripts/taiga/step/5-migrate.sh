#!/bin/bash

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"
SCRIPT=$(readlink -f $0)
[[ $UID == 0 ]] && exec su - taiga -c "$SCRIPT"

. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

data=$(PGPASSWORD=${ini[postgresql.taiga_password]} psql -U ${ini[postgresql.taiga_user]} -d ${ini[postgresql.taiga_database]} -c '\dt' 2>/dev/null)

if [[ -z $data ]]; then
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
fi

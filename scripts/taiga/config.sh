#!/bin/bash

export PATH="/lib/rc/bin:$PATH"
set -ueo pipefail
. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

cd /var/calculate/www/taiga

configure_conf() {
	local config=$1
	einfo "Setting up $config ..."
	test -f $config.old || cp $config $config.old
	for (( i=0; i < ${#replace[@]}; i += 2 )); do
		var=${replace[$i]}
		val=${replace[$i+1]}
		grep -qE "$var" $config || eerror "Parametr '$var' is not found."

		sed -i -E "s|^(\s*)(['\"]?)(${var})(['\"]?)(\s*)([:=])(\s*)?.*$|\1\2\3\4\5\6\7${val}|g" \
			$config
	done
	eend
}
[[ ${ini[taiga.public_register]} == 'True' ]] && public_register='true' || public_register='false'
replace=(
	USER				\'${ini[postgresql.taiga_user]}\',
	PASSWORD			\'${ini[postgresql.taiga_password]}\',
	SECRET_KEY			\"${ini[taiga.secret_key]}\"
	TAIGA_SITES_SCHEME		\"${ini[taiga.protocol]}\"
	TAIGA_SITES_DOMAIN		\"${ini[taiga.taiga_sites_domain]}\"
	MEDIA_ROOT			'/var/calculate/www/taiga/taiga-back/media'
	DEFAULT_FROM_EMAIL		\'${ini[taiga.from_email]}\'
	EMAIL_USE_TLS			${ini[taiga.smtp_tls]}
	EMAIL_USE_SSL			${ini[taiga.smtp_ssl]}
	EMAIL_HOST			\'${ini[taiga.smtp_host]}\'
	EMAIL_PORT			${ini[taiga.smtp_port]}
	EMAIL_HOST_USER			\'${ini[taiga.smtp_user]}\'
	EMAIL_HOST_PASSWORD		\'${ini[taiga.smtp_password]}\'
	url				\"amqp://${ini[rabbitmq.taiga_user]}:${ini[rabbitmq.taiga_password]}@localhost:5672/taiga\"
	CELERY_BROKER_URL		\"amqp://${ini[rabbitmq.taiga_user]}:${ini[rabbitmq.taiga_password]}@localhost:5672/taiga\"
	CELERY_TIMEZONE			\'${ini[taiga.timezone]}\'
	ENABLE_TELEMETRY		False
	PUBLIC_REGISTER_ENABLED		${ini[taiga.public_register]}
	USER_EMAIL_ALLOWED_DOMAINS	$(arr_to_list ${ini[taiga.user_email_allowed_domains]})
	MAX_PRIVATE_PROJECTS_PER_USER	${ini[taiga.max_private_projects_per_user]}
	MAX_PUBLIC_PROJECTS_PER_USER	${ini[taiga.max_public_projects_per_user]}
)
configure_conf taiga-back/settings/config.py

replace=(
	api				\"${ini[taiga.protocol]}://${ini[taiga.taiga_sites_domain]}/api/v1/\",
	eventsUrl			\"wss://${ini[taiga.taiga_sites_domain]}/events\",
	defaultLanguage			\"${ini[taiga.language]}\",
	publicRegisterEnabled		${public_register},
	feedbackEnabled			false,
	supportUrl			\"${ini[taiga.protocol]}://${ini[taiga.taiga_sites_domain]}\",
	gravatar			false,
)
configure_conf taiga-front-dist/dist/conf.json

replace=(
	RABBITMQ_URL			\"amqp://${ini[rabbitmq.taiga_user]}:${ini[rabbitmq.taiga_password]}@localhost:5672/taiga\"
	SECRET				\"${ini[taiga.secret_key]}\"
)
configure_conf taiga-events/.env

replace=(
	SECRET_KEY			\"${ini[taiga.secret_key]}\"
)
configure_conf taiga-protected/.env

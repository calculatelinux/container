#!/bin/bash

export PATH="/lib/rc/bin:$PATH"
set -ueo pipefail

. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

regular(){
	if [[ ${ini[taiga.public_register]} == 'True' ]]
	then
		local public_register='true'
	else
		local public_register='false'
	fi
	replace=(
	"taiga-back/settings/config.py" ""
	"('USER':).*"				"\1 '${ini[postgresql.taiga_user]}',"
	"('PASSWORD':).*"			"\1 '${ini[postgresql.taiga_password]}',"
	"^.*(SECRET_KEY =).*"			"\1 \"${ini[taiga.secret_key]}\""
	"^.*(TAIGA_SITES_SCHEME =).*"		"\1 \"${ini[taiga.protocol]}\""
	"^.*(TAIGA_SITES_DOMAIN =).*"		"\1 \"${ini[taiga.taiga_sites_domain]}\""
	"^.*(MEDIA_ROOT =).*"			"\1 '/var/calculate/www/taiga/taiga-back/media'"
	"^.*(DEFAULT_FROM_EMAIL =).*"		"\1 '${ini[taiga.from_email]}'"
	"^.*(EMAIL_USE_TLS =).*"		"\1 ${ini[taiga.smtp_tls]}"
	"^.*(EMAIL_USE_SSL =).*"		"\1 ${ini[taiga.smtp_ssl]}"
	"^.*(EMAIL_HOST =).*"			"\1 '${ini[taiga.smtp_host]}'"
	"^.*(EMAIL_PORT =).*"			"\1 ${ini[taiga.smtp_port]}"
	"^.*(EMAIL_HOST_USER =).*"		"\1 '${ini[taiga.smtp_user]}'"
	"^.*(EMAIL_HOST_PASSWORD =).*"		"\1 '${ini[taiga.smtp_password]}'"
	"(\"url\": \"amqp://).*(:5672/taiga\")"	"\1${ini[rabbitmq.taiga_user]}:${ini[rabbitmq.taiga_password]}@localhost\2"
	"^.*(CELERY_BROKER_URL =).*"		"\1 \"amqp://${ini[rabbitmq.taiga_user]}:${ini[rabbitmq.taiga_password]}@localhost:5672/taiga\""
	"^.*(CELERY_TIMEZONE =).*"		"\1 '${ini[taiga.timezone]}'"
	"^.*(ENABLE_TELEMETRY =).*"		"\1 False"
	"^.*(PUBLIC_REGISTER_ENABLED =).*"	"\1 ${ini[taiga.public_register]}"
	"^.*(USER_EMAIL_ALLOWED_DOMAINS =).*"	"\1 $(arr_to_list ${ini[taiga.user_email_allowed_domains]})"
	"^.*(MAX_PRIVATE_PROJECTS_PER_USER =).*" "\1 ${ini[taiga.max_private_projects_per_user]}"
	"^.*(MAX_PUBLIC_PROJECTS_PER_USER =).*" "\1 ${ini[taiga.max_public_projects_per_user]}"

	"taiga-front-dist/dist/conf.json" ""
	"(\"api\":).*"				"\1 \"${ini[taiga.protocol]}://${ini[taiga.taiga_sites_domain]}/api/v1/\","
	"(\"eventsUrl\":).*"			"\1 \"wss://${ini[taiga.taiga_sites_domain]}/events\","
	"(\"defaultLanguage\":).*"		"\1 \"${ini[taiga.language]}\","
	"(\"publicRegisterEnabled\":).*"	"\1 ${public_register},"
	"(\"feedbackEnabled\":).*"		"\1 false,"
	"(\"supportUrl\":).*"			"\1 \"${ini[taiga.protocol]}://${ini[taiga.taiga_sites_domain]}\","
	"(\"gravatar\":).*"			"\1 false,"

	"taiga-events/.env" ""
	"^.*(RABBITMQ_URL=).*"			"\1\"amqp://${ini[rabbitmq.taiga_user]}:${ini[rabbitmq.taiga_password]}@localhost:5672/taiga\""
	"^.*(SECRET=).*"			"\1\"${ini[taiga.secret_key]}\""

	"taiga-protected/.env" ""
	"^.*(SECRET_KEY=).*"			"\1\"${ini[taiga.secret_key]}\""
	)
}

check_conf(){
	conf=
	for (( i=0; i < ${#replace[@]}; i += 2 ))
	do
		from=${replace[$i]}
		to=${replace[$i+1]}

		if [[ $to == '' ]]
		then
			conf=$from
			continue
		fi
		if [[ ! -e $conf ]]
		then
			eerror "~/taiga/$conf not found."
			exit 2
		fi

		grep -qE "$from" $conf || exit 1
	done
}

check_show(){
	conf=
	for (( i=0; i < ${#replace[@]}; i += 2 ))
	do
		from=${replace[$i]}
		to=${replace[$i+1]}
		if [[ $to == '' ]]
		then
			conf=$from
			echo "$conf"
			continue
		fi

		err=0

		grep -qE "$from" $conf || err=1

		if [[ $err == 0 ]]
		then
			einfo $from
		else
			eerror $from || true
		fi
		eend $err || true
	done
}

configure_conf(){
	conf=
	for (( i=0; i < ${#replace[@]}; i += 2 ))
	do
		from=${replace[$i]}
		to=${replace[$i+1]}

		if [[ $to == '' ]]
		then
			if [[ $conf != '' ]]
			then
				eend
			fi
			conf=$from
			ebegin $conf
			continue
		fi

		sed -i -E "s|$from|$to|g" $conf
	done
	eend
}

show_conf(){
	conf=
	for (( i=0; i < ${#replace[@]}; i += 2 ))
	do
		from=${replace[$i]}
		to=${replace[$i+1]}

		if [[ $to == '' ]]
		then
			conf=$from
			echo '#-------------------------------------------------------------------------'
			echo " $conf"
			echo '#-------------------------------------------------------------------------'
			continue
		fi

		grep -E "$from" $conf
	done
}

check_homedir(){
	homedir=/var/calculate/www/taiga
	if [[ -d $homedir ]]
	then
		cd $homedir
	else
		eerror "Missing directory $homedir!"
		exit 1
	fi
}

regular

check_homedir

ebegin 'Checking Custom Variables'
`check_conf` || {
	if [[ $? == 1 ]]
	then
		check_show # отобразим несоответствия
		exit 1
	fi	
	exit
}
eend

einfo 'Setting up configuration files'
configure_conf

if [[ $# == 1 && $1 == 'show' ]]
then
	einfo 'Customized parameters:'
	show_conf
fi

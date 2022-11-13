#!/bin/bash

export PATH="/lib/rc/bin:$PATH"
set -ueo pipefail

source /var/db/repos/container/scripts/functions.sh
get_ini

regular(){
	replace=(
	"taiga-back/settings/config.py" ""
	"('USER':).*"				"\1 '${postgresql_taiga_user}',"
	"('PASSWORD':).*"			"\1 '${postgresql_taiga_password}',"
	"^.*(SECRET_KEY =).*"			"\1 \"${taiga_secret_key}\""
	"^.*(TAIGA_SITES_SCHEME =).*"		"\1 \"${taiga_protocol}\""
	"^.*(TAIGA_SITES_DOMAIN =).*"		"\1 \"${taiga_taiga_sites_domain}\""
	"^.*(MEDIA_ROOT =).*"			"\1 '/var/calculate/www/taiga/taiga-back/media'"
	"^.*(DEFAULT_FROM_EMAIL =).*"		"\1 '${taiga_from_email}'"
	"^.*(EMAIL_USE_TLS =).*"		"\1 '${taiga_smtp_tls}'"
	"^.*(EMAIL_USE_SSL =).*"		"\1 '${taiga_smtp_ssl}'"
	"^.*(EMAIL_HOST =).*"			"\1 '${taiga_smtp_host}'"
	"^.*(EMAIL_PORT =).*"			"\1 ${taiga_smtp_port}"
	"^.*(EMAIL_HOST_USER =).*"		"\1 '${taiga_smtp_user}'"
	"^.*(EMAIL_HOST_PASSWORD =).*"		"\1 '${taiga_smtp_password}'"
	"(\"url\": \"amqp://).*(:5672/taiga\")"	"\1${rabbitmq_taiga_user}:${rabbitmq_taiga_password}@localhost\2"
	"^.*(CELERY_BROKER_URL =).*"		"\1 \"amqp://${rabbitmq_taiga_user}:${rabbitmq_taiga_password}@localhost:5672/taiga\""
	"^.*(CELERY_TIMEZONE =).*"		"\1 '${taiga_timezone}'"
	"^.*(ENABLE_TELEMETRY =).*"		"\1 False"
	"^.*(PUBLIC_REGISTER_ENABLED =).*"	"\1 ${taiga_public_register}"

	"taiga-front-dist/dist/conf.json" ""
	"(\"api\":).*"				"\1 \"${taiga_protocol}://${taiga_taiga_sites_domain}/api/v1/\","
	"(\"eventsUrl\":).*"			"\1 \"wss://${taiga_taiga_sites_domain}/events\","
	"(\"defaultLanguage\":).*"		"\1 \"${taiga_language}\","
	"(\"publicRegisterEnabled\":).*"	"\1 true,"
	"(\"supportUrl\":).*"			"\1 \"${taiga_protocol}://${taiga_taiga_sites_domain}\","
	"(\"gravatar\":).*"			"\1 false,"

	"taiga-events/.env" ""
	"^.*(RABBITMQ_URL=).*"			"\1\"amqp://${rabbitmq_taiga_user}:${rabbitmq_taiga_password}@localhost:5672/taiga\""
	"^.*(SECRET=).*"			"\1\"${taiga_secret_key}\""

	"taiga-protected/.env" ""
	"^.*(SECRET_KEY=).*"			"\1\"${taiga_secret_key}\""
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


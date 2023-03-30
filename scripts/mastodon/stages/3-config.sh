#!/bin/bash

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"

. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

cl-setup-system

cd /var/calculate/www/mastodon
configure_conf() {
	local config=$1
	einfo "Setting up $config ..."
	test -f $config.old || cp $config $config.old
	for (( i=0; i < ${#replace[@]}; i += 2 )); do
		var=${replace[$i]}
		val=${replace[$i+1]}
		grep -qE "^([#;]\s*)?\s*?$var\s*[:=]" $config || eerror "Parametr '$var' is not found."
		sed -i -E "s|^([#;]\s*)?(\s*)(${var})(\s*)([:=])(\s*)?.*$|\2\3\4\5\6${val}|g" \
			$config
	done
	eend
}

replace=(
	LOCAL_DOMAIN			"${ini[mastodon.local_domain]}"
	DB_USER				"${ini[postgresql.mastodon_user]}"
	DB_PASS				"${ini[postgresql.mastodon_password]}"
	SMTP_FROM_ADDRESS		"Mastodon <${ini[mastodon.smtp_from_address]}>"
	SMTP_PORT			"${ini[mastodon.smtp_port]}"
	SMTP_SERVER			"${ini[mastodon.smtp_server]}"

)
configure_conf live/.env.production

/etc/init.d/redis restart

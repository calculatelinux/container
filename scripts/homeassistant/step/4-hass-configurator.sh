#
# Функция configure() устанавливает HASS Configurator
#
# Параметры:
# $1 = check - проверка обновлений, в противном случае установка или обновление
# $2 - возвращает имя модуля для перезагрузки в случае выполненного обновления
# Guide: https://github.com/danielperna84/hass-configurator
configure() {
	local action=$1
	local __result=$2

	local home_dir=/var/calculate/www/hass-configurator
	local last_ver="$(get_last_ver danielperna84/hass-configurator github)"
	local work_dir="$home_dir/versions/hass-configurator-$last_ver"
	local live_dir="$home_dir/hass-configurator-live"
	local live_ver="$(get_live_ver $live_dir)"
	local conf_dir="/var/calculate/hass-configurator"

	if [[ $action == 'check' ]]; then
		if [[ $live_ver == $last_ver ]]; then
			einfo "hass-configurator: the latest version is installed $live_ver"
		else
			einfo "hass-configurator: $last_ver update available, $live_ver installed"
			eval $__result=1 # наличие обновления
		fi
		return
	fi

	# выйдем если все настроено
        if [[ -e $conf_dir/settings.conf ]]; then
		return
	fi

	if [[ ! -e $home_dir ]]; then
		mkdir -p $home_dir/versions
		chmod 700 $home_dir
		chown -R hass-configurator: $home_dir
	fi
	if [[ ! -e $conf_dir ]]; then
		mkdir -p $conf_dir
		chmod 700 $conf_dir
		chown -R hass-configurator: $conf_dir
	fi

	touch ${log_dir}/hass-configurator.log
	chown hass-configurator: ${log_dir}/hass-configurator.log

	if [[ $live_ver != $last_ver ]]; then
		if [[ $live_ver == '' ]]; then
			echo Install HASS Configurator
		else
			echo Update Configurator
		fi

		su - hass-configurator -s /bin/bash -c "$(cat <<- EOF
			set -ueo pipefail
			export PATH="/lib/rc/bin:$PATH"

			ebegin Download hass-configurator ${last_ver}
			wget https://github.com/danielperna84/hass-configurator/archive/refs/tags/${last_ver}.zip \
				-O hass-configurator-${last_ver}.zip &>>${log_dir}/hass-configurator.log
			eend

			ebegin 'Extract the archive'
			unzip -q -d versions hass-configurator-${last_ver}.zip
			rm hass-configurator-${last_ver}.zip
			ln -sf versions/hass-configurator-${last_ver} hass-configurator-live
			eend
			
			ebegin 'Create a virtualenv'
			python -m venv hass-configurator-live/.venv
			eend
			
			ebegin 'Activate environment'
			source hass-configurator-live/.venv/bin/activate
			eend
			
			ebegin 'Upgrade pip and wheel'
			pip install --upgrade pip wheel &>>${log_dir}/hass-configurator.log
			eend
			
			ebegin 'Install HASS Configurator'
			pip install hass-configurator &>>${log_dir}/hass-configurator.log
			eend
		EOF
		)"
	fi

	if [[ $live_ver != '' ]]; then
		eval $__result=hass-assistant # демон который следует перезагрузить
	else
		ebegin 'Setup HASS Configurator'
		cat > $conf_dir/settings.conf << EOF
{
	"LISTENIP": "127.0.0.1",
	"PORT": 3218,
	"GIT": false,
	"BASEPATH": null,
	"ENFORCE_BASEPATH": false,
	"SSL_CERTIFICATE": null,
	"SSL_KEY": null,
	"IGNORE_SSL": false,
	"HASS_API": "http://127.0.0.1:8123/api/",
	"HASS_WS_API": null,
	"HASS_API_PASSWORD": null,
	"USERNAME": null,
	"PASSWORD": null,
	"ALLOWED_NETWORKS": [],
	"ALLOWED_DOMAINS": [],
	"BANNED_IPS": [],
	"BANLIMIT": 0,
	"IGNORE_PATTERN": [],
	"DIRSFIRST": false,
	"SESAME": null,
	"SESAME_TOTP_SECRET": null,
	"VERIFY_HOSTNAME": null,
	"ENV_PREFIX": "HC_",
	"NOTIFY_SERVICE": "persistent_notification.create"
}
EOF
		chown hass-configurator: $conf_dir/settings.conf
		eend
	fi
}


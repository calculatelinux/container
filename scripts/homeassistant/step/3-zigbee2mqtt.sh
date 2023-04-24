#
# Функция configure() устанавливает Zigbee2MQTT
#
# Параметры:
# $1 = check - проверка обновлений, в противном случае установка или обновление
# $2 - возвращает имя модуля для перезагрузки в случае выполненного обновления
#
# Guide: https://www.zigbee2mqtt.io/guide/installation/07_python_virtual_environment.html
configure() {
	local action=$1
	local __result=$2

	local home_dir=/var/calculate/www/zigbee2mqtt
	local last_ver="$(get_last_ver Koenkk/zigbee2mqtt github)"
	local work_dir="$home_dir/versions/zigbee2mqtt-$last_ver"
	local live_dir="$home_dir/zigbee2mqtt-live"
	local live_ver="$(get_live_ver $live_dir)"

	if [[ $action == 'check' ]]; then
		if [[ $live_ver == $last_ver ]]; then
			einfo "zigbee2mqtt: the latest version is installed $live_ver"
		else
			einfo "zigbee2mqtt: $last_ver update available, $live_ver installed"
			eval $__result=1 # наличие обновления
		fi
		return
	fi

	if [[ ! -e $home_dir ]]; then
		mkdir -p $home_dir
		chmod 700 $home_dir/versions
		chown zigbee2mqtt: $home_dir
	fi

	if [[ $live_ver != $last_ver ]]; then
		if [[ $live_ver != '' ]]; then
			echo Update Zigbee2MQTT
		else
			echo Install Zigbee2MQTT
		fi

		su - zigbee2mqtt -s /bin/bash -c "$(cat <<- EOF
			set -ueo pipefail
			export PATH="/lib/rc/bin:$PATH"

			ebegin Download zigbee2mqtt ${last_ver}
			test -e $work_dir && rm -rf $work_dir
			wget -q https://github.com/Koenkk/zigbee2mqtt/archive/refs/tags/${last_ver}.zip \
			     -O zigbee2mqtt-${last_ver}.zip
			eend

			ebegin 'Extract the archive'
			unzip -q -d versions zigbee2mqtt-${last_ver}.zip
			rm zigbee2mqtt-${last_ver}.zip
			ln -sf versions/zigbee2mqtt-${last_ver} zigbee2mqtt-live
			eend

			# вынесем настройки
			if [[ -z "$(ls -A /var/calculate/zigbee2mqtt)" ]]; then
				mv versions/zigbee2mqtt-${last_ver}/data/* /var/calculate/zigbee2mqtt
			fi
			rm -rf versions/zigbee2mqtt-${last_ver}/data
			ln -s /var/calculate/zigbee2mqtt versions/zigbee2mqtt-${last_ver}/data
			
			ebegin 'Create a virtualenv'
			python -m venv zigbee2mqtt-live/.venv
			eend
			
			ebegin 'Activate environment'
			source zigbee2mqtt-live/.venv/bin/activate
			eend
			
			ebegin 'Upgrade pip, wheel and setuptools'
			pip install --upgrade pip wheel setuptools &>>/tmp/zigbee2mqtt.log
			eend
			
			ebegin 'Install node environment'
			pip install nodeenv &>>/tmp/zigbee2mqtt.log
			eend
			
			ebegin 'Init node environment ${ini[zigbee2mqtt.nodeenv]}'
			nodeenv -p -n ${ini[zigbee2mqtt.nodeenv]} &>>/tmp/zigbee2mqtt.log
			eend
			
			einfo 'Install dependencies'
			cd zigbee2mqtt-live
			npm ci &>>/tmp/zigbee2mqtt.log
			cd
		EOF
		)"

		if [[ $live_ver == '' ]]; then
			ebegin 'Setup zigbee2mqtt'
			mv /etc/zigbee2mqtt/configuration.yaml /etc/zigbee2mqtt/configuration.yaml.old
			cat > /etc/zigbee2mqtt/configuration.yaml << EOF
# Home Assistant integration (MQTT discovery)
homeassistant: true

# allow new devices to join
permit_join: false

# MQTT settings
mqtt:
  # MQTT base topic for zigbee2mqtt MQTT messages
  base_topic: zigbee2mqtt
  # MQTT server URL
  server: 'mqtt://localhost'
  # MQTT server authentication, uncomment if required:
  user: ${ini[mosquitto.homeassistant_user]}
  password: '${ini[mosquitto.homeassistant_password]}'

# Serial settings
serial:
  # Location of USB sniffer
  port: ${ini[zigbee2mqtt.dev]}
frontend:
  port: 8080
  host: 127.0.0.1
EOF
			chown zigbee2mqtt: /etc/zigbee2mqtt/configuration.yaml
			eend

			eval $__result=zigbee2mqtt # демон который следует перезагрузить
		fi
	fi
}

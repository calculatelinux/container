#
# Функция configure() настраивает Home Assistant
#
configure() {
	local home_dir=/var/calculate/www/homeassistant
	local last_ver=$ha_ver
	local work_dir="$home_dir/versions/homeassistant-$last_ver"
	local conf_dir="/var/calculate/homeassistant"

	# выйдем если все настроено
	grep -q ^http: ${conf_dir}/configuration.yaml &>/dev/null && return || true

	if [[ ! -e $conf_dir ]]; then
		mkdir -p $conf_dir
		chmod 700 $conf_dir
		chown homeassistant: $conf_dir
	fi

	touch ${log_dir}/config.log
	chown homeassistant: ${log_dir}/config.log

	su - homeassistant -s /bin/bash -c "$(cat <<- EOF
		set -ueo pipefail
		export PATH="/lib/rc/bin:$PATH"

		source ${work_dir}/.venv/bin/activate

		hass --config ${conf_dir} &>>${log_dir}/config.log &
		id_hass=\$!

		echo
		einfon "Waiting for the first start Home Assistant "
		while ! curl http://127.0.0.1:8123 2>/dev/null; do
			echo -n .
			sleep 1
		done
		kill \$id_hass
		eend
	EOF
	)"

	cat >> ${conf_dir}/configuration.yaml << EOF

http:
  server_host: 127.0.0.1
  use_x_forwarded_for: true
  trusted_proxies: 127.0.0.1

recorder:
  db_url: postgresql://${ini[postgresql.homeassistant_user]}:${ini[postgresql.homeassistant_password]}@127.0.0.1/${ini[postgresql.homeassistant_database]}

panel_iframe:
EOF
	if [[ -e /var/calculate/zigbee2mqtt ]]; then
		cat >> /var/calculate/homeassistant/configuration.yaml << EOF
  zigbee:
    title: Zigbee2mqtt
    url: ${ini[homeassistant.protocol]}://${ini[homeassistant.domain]}/${ini[nginx.zigbee2mqtt_subpath]}
    icon: mdi:zigbee
EOF
	fi

	if [[ -e /var/calculate/hass-configurator ]]; then
		cat >> /var/calculate/homeassistant/configuration.yaml << EOF
  configurator:
    title: Configurator
    icon: mdi:wrench
    url: ${ini[homeassistant.protocol]}://${ini[homeassistant.domain]}/${ini[nginx.hass-configurator_subpath]}
EOF
	fi
}

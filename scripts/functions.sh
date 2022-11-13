# Read vars from /var/calculate/ini.env
get_ini(){
	all=
	while IFS= read -r line
	do
	        if [[ $line == *"["* ]]
	        then
	                line=${line#*[}
	                line=${line%%]*}
	                sec=$line
	                continue
	        fi
		if [[ ${line:0:1} == '#' || $line == '' ]]
		then
			continue
		fi
	        com=${sec}_${line// =/=};
	        com=${com//= /=};
	        all="$com; $all"
	done < /var/calculate/ini.env
	eval $all
}

# Clear stdin before reading
clear_buf(){
	while read -r -t 0
		do read -r
	done
	read -t 0.01 -n 10000 || true
}

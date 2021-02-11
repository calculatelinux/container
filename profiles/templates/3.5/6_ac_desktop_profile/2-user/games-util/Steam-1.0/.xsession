# Calculate chmod=0755 path=~
#!/bin/bash

# set blue background
/usr/bin/xsetroot -solid rgb:30/64/8b

# run x11vnc
if [[ -f #-ur_home_path-#/.vnc/passwd ]]
then
	/usr/bin/x11vnc -shared -forever -repeat -dontdisconnect -display :0 -notruecolor -nomodtweak -rfbport 5900 -bg -rfbauth #-ur_home_path-#/.vnc/passwd
fi

/usr/bin/xfce4-panel &
/usr/bin/steam &
/usr/bin/xfwm4 --compositor=off

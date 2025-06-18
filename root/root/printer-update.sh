#!/bin/sh
/usr/bin/inotifywait -m -e close_write,moved_to,create /etc/cups | 
while read -r directory events filename; do
	if [ "$filename" = "printers.conf" ]; then
		rm -rf /services/*.service
		/opt/opt/root/airprint-generate.py -d /opt/services
		cp /etc/cups/printers.conf /opt/config/printers.conf
		rsync -avh /opt/services/ /etc/avahi/services/
	fi
	if [ "$filename" = "cupsd.conf" ]; then
		cp /etc/cups/cupsd.conf /opt/config/cupsd.conf
	fi
done

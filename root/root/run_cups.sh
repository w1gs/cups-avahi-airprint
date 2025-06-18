#!/bin/sh
set -e
set -x

# Is CUPSADMIN set? If not, set to default
if [ -z "$CUPSADMIN" ]; then
    CUPSADMIN="cupsadmin"
fi

# Is CUPSPASSWORD set? If not, set to $CUPSADMIN
if [ -z "$CUPSPASSWORD" ]; then
    CUPSPASSWORD=$CUPSADMIN
fi

if [ $(grep -ci $CUPSADMIN /etc/shadow) -eq 0 ]; then
    useradd -s /bin/bash -G lpadmin --no-create-home $CUPSADMIN
fi
echo $CUPSADMIN:$CUPSPASSWORD | chpasswd

cat /opt/config/cups-pdf.conf | envsubst > /etc/cups/cups-pdf.conf
cat /opt/config/cupsd.conf | envsubst > /etc/cups/cupsd.conf
cat /opt/config/printers.conf | envsubst > /etc/cups/printers.conf

cp /usr/share/ppd/cups-pdf/CUPS-PDF_noopt.ppd /etc/cups/ppd/${PRINTER_ID}.ppd

if [ `ls -l /opt/services/*.service 2>/dev/null | wc -l` -gt 0 ]; then
	cp -f /opt/services/*.service /etc/avahi/services/
fi
if [ `ls -l /opt/config/printers.conf 2>/dev/null | wc -l` -eq 0 ]; then
    touch /opt/config/printers.conf
fi
cp /opt/config/printers.conf /etc/cups/printers.conf

if [ `ls -l /opt/config/cupsd.conf 2>/dev/null | wc -l` -ne 0 ]; then
    cp /opt/config/cupsd.conf /etc/cups/cupsd.conf
else
    cp /etc/cups/cupsd.conf /config/cupsd.conf
fi

# Function to handle cleanup on exit
cleanup() {
    echo "Cleaning up..."
    # Kill any running avahi-daemon processes
    if [ -f /var/run/avahi-daemon/pid ]; then
        PID=$(cat /var/run/avahi-daemon/pid)
        if kill -0 $PID 2>/dev/null; then
            kill $PID
            rm -f /var/run/avahi-daemon/pid
        fi
    fi
    
    # Kill any running printer-update.sh processes
    pkill -f printer-update.sh || true
    
    exit 0
}

# Set up trap for cleanup
#trap cleanup SIGTERM SIGINT

# Ensure any stale PID files are removed before starting
if [ -f /var/run/avahi-daemon/pid ]; then
    rm -f /var/run/avahi-daemon/pid
fi
if [ -f /var/run/avahi-daemon.pid ]; then
    rm -f /var/run/avahi-daemon.pid
fi

# Start avahi-daemon service in the background
/opt/root/root/avahi-service.sh &
AVAHI_SERVICE_PID=$!

# Wait a moment to ensure avahi-daemon has s and created its PID file
sleep 2

# Start CUPS and printer update
/opt/root/root/printer-update.sh &
exec /usr/sbin/cupsd -f

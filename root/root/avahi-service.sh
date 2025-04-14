#!/bin/sh

# Function to start avahi-daemon
start_avahi() {
    echo "Starting avahi-daemon..."
    # Run in foreground to capture logs in container logs
    avahi-daemon --no-drop-root --no-chroot --no-proc-title
}

# Main service loop
while true; do
    # Start avahi-daemon and wait for it to exit
    start_avahi
    
    # If avahi-daemon exits, wait a moment before restarting
    echo "avahi-daemon exited, restarting in 5 seconds..."
    sleep 5
done 
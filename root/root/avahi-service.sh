#!/bin/sh

# Function to clean up existing avahi-daemon processes
cleanup_avahi() {
    echo "Cleaning up existing avahi-daemon processes..."
    if [ -f /var/run/avahi-daemon.pid ]; then
        PID=$(cat /var/run/avahi-daemon.pid)
        if kill -0 $PID 2>/dev/null; then
            kill $PID
            # Wait for process to terminate
            for i in $(seq 1 5); do
                if ! kill -0 $PID 2>/dev/null; then
                    break
                fi
                sleep 1
            done
            # Force kill if still running
            if kill -0 $PID 2>/dev/null; then
                kill -9 $PID
            fi
        fi
        rm -f /var/run/avahi-daemon.pid
    fi
    # Additional cleanup for any stray processes
    pkill -f avahi-daemon || true
    # Clean up any stale socket files
    rm -f /var/run/avahi-daemon/socket
}

# Function to check if network is ready
wait_for_network() {
    echo "Waiting for network interfaces to be ready..."
    for i in $(seq 1 30); do
        if ip addr show | grep -q "inet "; then
            return 0
        fi
        sleep 1
    done
    return 1
}

# Function to start avahi-daemon
start_avahi() {
    echo "Starting avahi-daemon..."
    # Clean up any existing processes first
    cleanup_avahi
    
    # Wait for network to be ready
    if ! wait_for_network; then
        echo "Network not ready after 30 seconds, starting anyway..."
    fi
    
    # Run in foreground to capture logs in container logs
    # Using -D to run as daemon but with proper process management
    # Adding debug flag for more verbose logging
    avahi-daemon --no-drop-root --no-chroot --no-proc-title -D --debug
    
    # Wait for daemon to start
    sleep 2
    
    # Verify daemon is running
    if ! pgrep -f "avahi-daemon" > /dev/null; then
        echo "Failed to start avahi-daemon"
        return 1
    fi
    
    return 0
}

# Main service loop
while true; do
    # Start avahi-daemon and wait for it to exit
    if start_avahi; then
        # Monitor the daemon
        while pgrep -f "avahi-daemon" > /dev/null; do
            sleep 5
        done
    fi
    
    # If avahi-daemon exits, wait a moment before restarting
    echo "avahi-daemon exited, restarting in 5 seconds..."
    sleep 5
done 

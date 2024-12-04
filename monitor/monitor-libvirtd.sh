#!/bin/bash -e

# Configuration
CHECK_INTERVAL=60  # Check every 60 seconds
MAX_FAILURES=15    # 15 checks = 15 minutes
TIMEOUT=10         # Command timeout in seconds
FAILURE_COUNT=0

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

check_libvirtd() {
    # Try to list domains with a timeout
    timeout $TIMEOUT virsh -c qemu:///system list --all >/dev/null 2>&1
    return $?
}

dd_host="10.1.0.1"

function send_metrics() {
	metrics="github.actions.$1:${2:-1}|${3:-c}|#runner_group:${RUNNERGROUP}"
	if [[ ! -z "$4" ]]; then metrics="$metrics,$4"; fi
	echo "Send metrics $metrics to $dd_host"
	echo -n "$metrics" > /dev/udp/$dd_host/8125
}

source /root/self-hosted-kvm.env && echo "Reloaded env vars" || true
export

restart_libvirtd() {
    log_message "Attempting to restart libvirtd service"
    send_metrics runners.anomaly "1" "c" "#type:libvirtd_restarted"

    # systemctl restart libvirtd

    # Wait for service to initialize
    sleep 5

    # Verify service is running
    if systemctl is-active --quiet libvirtd; then
        log_message "Successfully restarted libvirtd service"
        return 0
    else
        log_message "Failed to restart libvirtd service"
        return 1
    fi
}

# Main monitoring loop
while true; do
    if ! check_libvirtd; then
        FAILURE_COUNT=$((FAILURE_COUNT + 1))
        log_message "libvirtd check failed ($FAILURE_COUNT/$MAX_FAILURES)"

        if [ $FAILURE_COUNT -ge $MAX_FAILURES ]; then
            log_message "libvirtd has been unresponsive for 15 minutes"

            if restart_libvirtd; then
                FAILURE_COUNT=0
            fi
        fi
    else
        if [ $FAILURE_COUNT -ne 0 ]; then
            log_message "libvirtd is responding normally again"
            FAILURE_COUNT=0
        fi
    fi

    sleep $CHECK_INTERVAL
done

#!/bin/sh

# Wait for the daemons to start
sleep 2

# Check for linux routing suites
if command -v bird || command -v /usr/lib/frr/zebra || command -v holod; then
    # Setup interfaces
    ifup -a

    if command -v holod; then
    	# Load Holo startup configuration
        holo-cli --file /etc/holo.startup
    elif command -v /usr/lib/frr/zebra; then
    	# Load FRR startup configuration
        vtysh -f /etc/frr/frr.startup
    fi
fi

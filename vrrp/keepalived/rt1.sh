#!/bin/bash 

if command -v /usr/sbin/keepalived; then 
    # Setup interfaces
    
    # loopback
    ip addr add 1.1.1.1/32 dev lo
    ip link set lo up 

    # eth-br1 
    ip addr add 10.0.1.1/24 dev eth-br1 
    ip link set eth-br1 up


    service keepalived start 
fi

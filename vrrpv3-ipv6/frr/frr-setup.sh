#!/bin/sh 

if command -v /usr/lib/frr/zebra; then
  ip link add vrrp6-51 link eth-br1 type macvlan mode bridge
  ip link set dev vrrp6-51 address 00:00:5e:00:02:33
  ip addr add 2001:0db8::0370:7334/64 dev vrrp6-51
  ip addr add 2001:0db8::0370:7335/64 dev vrrp6-51
  ip link set dev vrrp6-51 up
fi

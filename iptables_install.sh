#!/bin/bash

IPTABLES=../iptables

cp ./extensions/libip6t_srh.c $IPTABLES/extensions/libip6t_srh.c
cp ./linux/ip6t_srh.h $IPTABLES/include/linux/netfilter_ipv6/ip6t_srh.h
cd $IPTABLES
./autogen.sh
./configure --disable-nftables
make
make install

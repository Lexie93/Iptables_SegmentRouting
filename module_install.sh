#!/bin/bash

LINUX=../linux

cp ./linux/ip6t_srh.h $LINUX/include/uapi/linux/netfilter_ipv6/ip6t_srh.h
cd ./linux/
make
insmod ip6t_srh.ko

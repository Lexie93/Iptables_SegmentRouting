#!/bin/bash

IPP=ip

# Clean up previous network namespaces
$IPP -all netns delete

# Creates new network namespaces
$IPP netns add h0
$IPP netns add h1
$IPP netns add r0
$IPP netns add r1
$IPP netns add fw0

# Adds veth pairs
$IPP link add veth0 type veth peer name veth1
$IPP link add veth2 type veth peer name veth3
$IPP link add veth4 type veth peer name veth5
$IPP link add veth6 type veth peer name veth7

# Assigns each veth to network namespaces
$IPP link set veth0 netns h0
$IPP link set veth1 netns r0
$IPP link set veth2 netns r0
$IPP link set veth3 netns fw0
$IPP link set veth4 netns fw0
$IPP link set veth5 netns r1
$IPP link set veth6 netns r1
$IPP link set veth7 netns h1

###################
#### Node: h0 #####
###################
echo -e "\nNode: h0"
$IPP netns exec h0 $IPP link set dev lo up
$IPP netns exec h0 $IPP link set dev veth0 up
$IPP netns exec h0 $IPP addr add 10.0.0.1/24 dev veth0
$IPP netns exec h0 $IPP addr add cafe::1/64 dev veth0
$IPP netns exec h0 $IPP -4 route add default via 10.0.0.254 dev veth0
$IPP netns exec h0 $IPP -6 route add cafe::2/128 via cafe::254 dev veth0


###################
#### Node: r0 #####
###################
echo -e "\nNode: r0"
$IPP netns exec r0 sysctl -w net.ipv4.ip_forward=1
$IPP netns exec r0 sysctl -w net.ipv4.conf.all.forwarding=1
$IPP netns exec r0 sysctl -w net.ipv6.conf.all.forwarding=1
# disable also rp_filter on the receiving decap interface that will forward the 
# packet to the right destination (through the nexthop)
$IPP netns exec r0 sysctl -w net.ipv4.conf.all.rp_filter=0
$IPP netns exec r0 sysctl -w net.ipv4.conf.veth1.rp_filter=0
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# NB: it is enough, for this example, to disable rp_filter only for 	#
# interfaces that handle IPv4. veth1 is IPv4 configured but not veth2. 	#
# In IPv6 we do not have any rp_filter feature implemented.		#
# $IPP netns exec r0 sysctl -w net.ipv4.conf.veth2.rp_filter=0		#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Using proxy_arp we can simplify the configuration of clients
$IPP netns exec r0 sysctl -w net.ipv4.conf.all.proxy_arp=1
$IPP netns exec r0 sysctl -w net.ipv4.conf.veth1.proxy_arp=1

$IPP netns exec r0 $IPP link set dev lo up
$IPP netns exec r0 $IPP link set dev veth1 up
$IPP netns exec r0 $IPP link set dev veth2 up
$IPP netns exec r0 $IPP addr add fdff:0:1::1/64 dev veth2
$IPP netns exec r0 $IPP addr add 10.0.0.254/24 dev veth1
$IPP netns exec r0 $IPP addr add cafe::254/64 dev veth1

# Decap DX4
$IPP netns exec r0 $IPP -6 route add fc00:4::1/128 \
	encap seg6local action End.DX4 nh4 10.0.0.1 dev veth1
# Decap DX6
$IPP netns exec r0 $IPP -6 route add fc00:6::1/128 \
	encap seg6local action End.DX6 nh6 cafe::1 dev veth1
# Encap IPv4-in-IPv6
$IPP netns exec r0 $IPP -6 route add fc00:4::2/128 via fdff:0:1::2 dev veth2
$IPP netns exec r0 $IPP -4 route add 10.0.0.2/32 \
		encap seg6 mode encap segs fc00:4::2 dev veth2
# Encap IPv6-in-IPv6
$IPP netns exec r0 $IPP -6 route add fc00:6::2/128 via fdff:0:1::2 dev veth2
$IPP netns exec r0 $IPP -6 route add cafe::2/128 \
		encap seg6 mode encap segs fc00:6::2 dev veth2


####################
#### Node: fw0 #####
####################
echo -e "\nNode: fw0"
$IPP netns exec fw0 sysctl -w net.ipv6.conf.all.forwarding=1
$IPP netns exec fw0 sysctl -w net.ipv6.conf.all.seg6_enabled=1
$IPP netns exec fw0 sysctl -w net.ipv6.conf.veth3.seg6_enabled=1
$IPP netns exec fw0 sysctl -w net.ipv6.conf.veth4.seg6_enabled=1

$IPP netns exec fw0 $IPP link set dev lo up
$IPP netns exec fw0 $IPP link set dev veth3 up
$IPP netns exec fw0 $IPP link set dev veth4 up
$IPP netns exec fw0 $IPP addr add fdff:0:1::2/48 dev veth3
$IPP netns exec fw0 $IPP addr add fdff:1:2::1/48 dev veth4

# Routing
$IPP netns exec fw0 $IPP -6 route add fc00:4::2/128 via fdff:1:2::2 dev veth4
$IPP netns exec fw0 $IPP -6 route add fc00:6::2/128 via fdff:1:2::2 dev veth4
$IPP netns exec fw0 $IPP -6 route add fc00:4::1/128 via fdff:0:1::1 dev veth3
$IPP netns exec fw0 $IPP -6 route add fc00:6::1/128 via fdff:0:1::1 dev veth3

# iptables  >>> Put your iptables command here <<<
$IPP netns exec fw0 ip6tables -N test
$IPP netns exec fw0 ip6tables -A FORWARD -j test
$IPP netns exec fw0 ip6tables -A test -m srh  --srh-sid-list fc00:6::2/128 #LOG --log-level 4
$IPP netns exec fw0 ip6tables -A test -m srh  --srh-sid-list fc00:6::1/128 #LOG --log-level 4
$IPP netns exec fw0 ip6tables -L -v









###################
#### Node: r1 #####
###################
echo -e "\nNode: r1"
$IPP netns exec r1 sysctl -w net.ipv4.ip_forward=1
$IPP netns exec r1 sysctl -w net.ipv4.conf.all.forwarding=1
$IPP netns exec r1 sysctl -w net.ipv6.conf.all.forwarding=1
# disable also rp_filter on the receiving decap interface that will forward the 
# packet to the right destination (through the nexthop)
$IPP netns exec r1 sysctl -w net.ipv4.conf.all.rp_filter=0
$IPP netns exec r1 sysctl -w net.ipv4.conf.veth6.rp_filter=0
# Using proxy_arp we can simplify the configuration of clients
$IPP netns exec r1 sysctl -w net.ipv4.conf.all.proxy_arp=1
$IPP netns exec r1 sysctl -w net.ipv4.conf.veth6.proxy_arp=1

$IPP netns exec r1 $IPP link set dev lo up
$IPP netns exec r1 $IPP link set dev veth5 up
$IPP netns exec r1 $IPP link set dev veth6 up
$IPP netns exec r1 $IPP addr add fdff:1:2::2/64 dev veth5
$IPP netns exec r1 $IPP addr add 10.0.0.254/24 dev veth6
$IPP netns exec r1 $IPP addr add cafe::254/64 dev veth6
# Decap DX4
$IPP netns exec r1 $IPP -6 route add fc00:4::2/128 \
	encap seg6local action End.DX4 nh4 10.0.0.2 dev veth6
# Decap DX6
$IPP netns exec r1 $IPP -6 route add fc00:6::2/128 \
	encap seg6local action End.DX6 nh6 cafe::2 dev veth6
# Encap IPv4-in-IPv6
$IPP netns exec r1 $IPP -6 route add fc00:4::1/128 via fdff:1:2::1 dev veth5
$IPP netns exec r1 $IPP -4 route add 10.0.0.1/32 \
		encap seg6 mode encap segs fc00:4::1 dev veth5
# Encap IPv6-in-IPv6
$IPP netns exec r1 $IPP -6 route add fc00:6::1/128 via fdff:1:2::1 dev veth5
$IPP netns exec r1 $IPP -6 route add cafe::1/128 \
		encap seg6 mode encap segs fc00:6::1 dev veth5

###################
#### Node: h1 #####
###################
echo -e "\nNode: h1"
$IPP netns exec h1 $IPP link set dev lo up
$IPP netns exec h1 $IPP link set dev veth7 up
$IPP netns exec h1 $IPP addr add 10.0.0.2/24 dev veth7
$IPP netns exec h1 $IPP addr add cafe::2/64 dev veth7
$IPP netns exec h1 $IPP -4 route add default via 10.0.0.254 dev veth7
$IPP netns exec h1 $IPP -6 route add cafe::1/128 via cafe::254 dev veth7

#########

$IPP netns exec h0 xterm 2>/dev/null -T h0 &
$IPP netns exec fw0 xterm 2>/dev/null -T fw0 &

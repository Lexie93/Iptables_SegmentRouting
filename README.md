# Iptables_SegmentRouting
### 2019 - project for [ITP](http://netgroup.uniroma2.it/twiki/bin/view/Netgroup/ITP) (Internet Technology and Protocols)

### What is this repository for? ###

* Quick summary

This is a patch to iptables srh module that add support for the match on the segment routing list of addresses.

The rules take an *ordered* list of addresses with optional subnet mask and then search if this list is *contained* on the list of addresses in the 
segment routing header.

Here are some examples of the behavior of the rule for clarity:

Rule list     			| Packet list				| Result
------------------------|---------------------------|----------
cafe::1,cafe::2			| cafe::2,cafe::1			| NOT MATCH
cafe::1,cafe::2			| cafe::1,cafe::2,cafe::3	| MATCH
cafe::1,cafe::2			| cafe::3,cafe::1,cafe::2	| MATCH
cafe::1/128,cafe::2/128	| cafe::1,cafe::2			| MATCH

The list of addresses given to the rules must have a size <= 16 due to buffer fixed size.
	
* Version

This version has been tested by the developers.

### How do I get set up? ###

* Summary of set up

The patch consist of two parts: one should be aplied to iptables and the other to the kernel module.
	
You should download iptables and the repository of this patch, then apply this patch to the iptables source, compiles iptables and finally compile and load 
the kernel module of this patch.   
	
* Configuration

To compile the kernel module could be useful to use a custom kernel due to possible incompatibilities, we used this method ourselves.

* Dependencies
	+ Iptables dependencies : 
	>autogen autoconf libtool libnfnetlink-dev
	+ Iptables: 
	>http://git.netfilter.org/iptables	
	+ Dependencies for compiling kernel modules:
	>make, compiler, etc.
	
* Deployment instructions
Installing iptables dependencies

		sudo apt-get install autogen autoconf libtool libnfnetlink-dev

To compile iptables with the patch use this commands or use the script provided *iptables_install.sh*

		git clone git://git.netfilter.org/iptables	
		cp ./1819-sr-iptables-sl-match/extensions/libip6t_srh.c ./iptables/extensions/libip6t_srh.c
        cp ./1819-sr-iptables-sl-match/linux/ip6t_srh.h ./iptables/include/linux/netfilter_ipv6/ip6t_srh.h
		cd iptables
		./autogen.sh
		./configure --disable-nftables
		make
		sudo make install

To compile and load the module
		
		cp ./1819-sr-iptables-sl-match/linux/ip6t_srh.h ./linux/include/uapi/linux/netfilter_ipv6/ip6t_srh.h
		cd ./1819-sr-iptables-sl-match/linux/
		make
		sudo insmod ip6t_srh.ko
		
* Test Iptables:
	
		sudo ./iptables/tests/shell/run-tests.sh
		
### How and where this is been tested ###
* Platform: 

		Debian 10
		kernel version : Linux debian 5.0.21 (custom kernel)

* How: 

		Using the scripts included in the repository:
		srv6_iptables.sh
		srv6_iptables2.sh

### Contribution guidelines ###

* Writing tests
* Code review
* Other guidelines

### Who do I talk to? ###

* Repo owners and developers

	Pier Francesco Contino pfcontino@gmail.com
	
	Alex Ponzo 	ponzo93@gmail.com

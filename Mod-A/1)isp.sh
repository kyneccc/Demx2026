#!/bin/bash
hostnamectl hostname isp.au-team.irpo && exec bash
mkdir /etc/net/ifaces/enp7s{2,3}
echo "TYPE=eth" | tee /etc/net/ifaces/enp7s{2,3}/options
echo "172.168.1.1/28" >> /etc/net/ifaces/enp7s2/ipv4address
echo "172.168.2.1/28">> /etc/net/ifaces/enp7s3/ipv4address
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/' /etc/net/sysctl.conf
systemctl restart network
apt-get update && apt-get install nftables -y
nft add table ip nat  
nft 'add chain ip nat postrouting { type nat hook postrouting priority 100 ; }'  
nft add rule ip nat postrouting oifname "enp7s1" masquerade
systemctl enable --now nftables

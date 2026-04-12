#!/bin/bash

# WAN
hostnamectl hostname hq-rtr.au-team.irpo && exec bash
rm -rf  /etc/net/ifaces/enp7s{1,2}
mkdir -p /etc/net/ifaces/{enp7s{1,2},vlan{100,200,999},gre1}
echo "TYPE=eth" >> /etc/net/ifaces/enp7s1/options
echo "172.168.2/28" >> /etc/net/ifaces/enp7s1/ipv4address
echo "default via 172.168.1.1" > /etc/net/ifaces/enp7s1/ipv4route
echo "nameserver 8.8.8.8" >> /etc/net/ifaces/enp7s1/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/net/ifaces/enp7s1/resolv.conf


# Vlan 100
echo -e "TYPE=vlan\nHOST=enp7s2\nVID=100" > /etc/net/ifaces/vlan100/options
echo '192.168.100.1/30' > /etc/net/ifaces/vlan100/ipv4address


# Vlan 200
echo -e "TYPE=vlan\nHOST=enp7s2\nVID=200" > /etc/net/ifaces/vlan200/options
echo '10.0.0.1/8' > /etc/net/ifaces/vlan200/ipv4address


# Vlan 999
echo -e "TYPE=vlan\nHOST=enp7s2\nVID=999" > /etc/net/ifaces/vlan999/options
echo '192.168.99.1/30' > /etc/net/ifaces/vlan999/ipv4address


# GRE
echo -e TYPE=iptun\nTUNTYPE=gre\nTUNLOCAL=172.16.1.2\nTUNREMOTE=172.16.2.2\nTUNOPTIONS='ttl 64'" >> /etc/net/ifaces/gre1/options
echo "172.22.0.1/30" >> /etc/net/ifaces/gre1/ipv4address
systemctl restart network 
apt-get update && apt-get install sudo tzdata frr dnsmasq nftables -y

## USER
useradd net_admin
echo "net_admin:P@ssw0rd" | chpasswd
usermod -aG wheel net_admin
sed -i 's/# WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL/WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL/'  /etc/sudoers

## Routing
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/' /etc/net/sysctl.conf
rm -f /etc/net/ifaces/enp7s1/resolv.conf
echo $'search au-team.irpo\nameserver 172.16.0.2' > /etc/net/ifaces/enp7s1/resolv.conf

## NAT 
systemctl enable --now nftables
nft add table ip nat  
nft 'add chain ip nat postrouting { type nat hook postrouting priority 100 ; }'  
nft add rule ip nat postrouting oifname "enp7s1" masquerade

## OSPF
sed -i 's/ospfd=no/ospfd=yes/' /etc/frr/daemons ; grep ospf /etc/frr/daemons
cat <<'EOF' > /etc/frr/frr.conf
interface gre
 no ip ospf passive
exit
!
interface gre1
 ip ospf area 0
 ip ospf authentication
 ip ospf authentication-key P@ssw0rd
 no ip ospf passive
exit
!
interface vlan100
 ip ospf area 0
exit
!
interface vlan200
 ip ospf area 0
exit
!
interface vlan999
 ip ospf area 0
exit
!
router ospf
 passive-interface default
exit
EOF
systemctl enable --now frr

## Timezone
timedatectl set-timezone Europe/Moscow

## DHCP 
cat <<'EOF' > /etc/dnsmasq.conf
port=0
interface=vlan200
listen-address=10.0.0.1
dhcp-authoritative
dhcp-range=interface:vlan200,10.0.0.2,10.0.0.2,255.0.0.0,6h
dhcp-option=3,10.0.0.1
dhcp-option=6,172.16.0.2
leasefile-ro
EOF

systemctl enable --now  dnsmasq ; ss -lun | grep 67

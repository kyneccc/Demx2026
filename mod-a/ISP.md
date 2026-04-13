---
title: ISP-modA
description: Настройка ISP
published: true
date: 2026-04-13T11:53:32.842Z
tags: linux, altlinux, dem2026
editor: markdown
dateCreated: 2026-04-13T11:53:32.842Z
---

### Базовая настройка
1) Задать имя хоста
```
hostnamectl hostname isp.au-team.irpo && exec bash
```

### Настройка сети

1) Создать директории под необходимые интерфейсы 
``` bash
mkdir /etc/net/ifaces/enp7s{2,3}
```
2) Создать options файл
``` bash 
echo "TYPE=eth" | tee /etc/net/ifaces/enp7s{2,3}/options
```
3) Cоздать файл с ip адресами(перед тем как делать нужно узнать какой интерфейс к какому роцтеру идет)
**HQ**
``` bash
echo "172.168.1.1/28" >> /etc/net/ifaces/enp7s2/ipv4address
```
**BR**

``` bash
echo "172.168.2.1/28">> /etc/net/ifaces/enp7s3/ipv4address
```

Включение ip4_forwarding
``` bash
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/' /etc/net/sysctl.conf
```
Рестарт сети 
```  bash
systemctl restart network
```
4)  Настройка нат трансляции
Установка nftables
``` bash
apt-get update && apt-get install nftables -y
```

Настройка nftables
```
nft add table ip nat  
nft 'add chain ip nat postrouting { type nat hook postrouting priority 100 ; }'  
nft add rule ip nat postrouting oifname "enp7s1" masquerade
```

Запуск сервиса
``` bash
 systemctl enable --now nftables
```
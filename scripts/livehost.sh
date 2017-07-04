#!/bin/bash



#nmap --system-dns 10.4.8.1/24
nmap $1 --system-dns | grep report | awk '{print $5}'

echo -e "\033[33;32m MAC Address:" 

#sudo nmap $1  -sP | grep report | awk '{print $5}'  
sudo nmap $1 -sP | grep MAC | awk '{print $3}'



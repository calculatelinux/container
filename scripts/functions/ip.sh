#!/bin/bash
# Define the IP address

interface=$(ip route | grep -m 1 'default via' | awk '{print $5}')
if [[ -z $interface ]]
then
        interface=eth0
fi
IP=$(ifconfig $interface 2>/dev/null | grep 'inet ' | awk '{print $2}')
echo $IP

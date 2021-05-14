#!/usr/bin/env bash

#title           : wireguard-starter.sh
#description     : This script will be used to up or down wireguard vpn by predevined interface/config file, POSIX compatible (bash, sh[dash], zsh)
#author          : Vasiliy Samoilichenko
#date            : 2021-05-14
#version         : 1.0   
#usage           : "bash wireguard-starter.sh"                                       - start wireguard interface, in the end press combination Ctrl+C to down the interface
#                : "bash wireguard-starter.sh down" or "bash wireguard-starter.sh 0" - just down wireguard interface

################ Variables ##############

# your password, or allow command in sudoers file, if empty - native way with password requesting on start
my_password="123"

# wireguard preconfigured link, possible values:
#   - name according to the system configuration file like "/etc/wireguard/wg0.conf" 
#   - custom path to interface configuration file, e.g. "~/soft/wireguard/wg0.conf"
#wg_link=~/soft/wireguard/wg0.conf
wg_link="wg0"


# not a editable param, this is down argument, values to down: "down" or "0", otherwise - up wireguard link
ACTION=${1-"1"}

#########################################


vpn_up() {
    if [ ${my_password} ]; then 
        output=$(echo "${my_password}" | sudo -S wg-quick up ${wg_link} 2>&1)
    else 
        output=$(wg-quick up ${wg_link} 2>&1)
    fi
    
    if [ $? -eq 0 ]; then
        printf "\033[1;32m > WireGurad successfully started \033[0m \n"
    else
        printf "\033[0;31m > WireGurad starting failed with the output: \033[0m \n"
        echo ${output}
        return 1
    fi
}

vpn_down() {
    if [ ${my_password} ]; then 
        output=$(echo "${my_password}" | sudo -S wg-quick down ${wg_link} 2>&1)
    else 
        output=$(wg-quick down ${wg_link} 2>&1)
    fi
    
    if [ $? -eq 0 ]; then
        printf "\033[1;32m > WireGurad successfully stopped \033[0m \n"
		exit 0
    else
        printf "\033[0;31m > WireGurad stopping failed with the output:\033[0m \n"
        echo ${output}
        return 1
    fi
}


if [ -z ${wg_link} ]; then
    printf "\033[0;31m > WireGurad interface can not be empty. Please check script variable 'wg_link'. \033[0m \n"
	exit 1
fi

# check and close permissions if too open
if [ -f ${wg_link} ] && [ $(stat -c "%a" ${wg_link}) != 600 ]; then
    chmod 600 ${wg_link}
fi

# down interface and exit if the corresponding flag given in arguments
if [ "${ACTION}" = "0" ] || [ "${ACTION}" = "down" ]; then 
    vpn_down
    exit 0;
fi


# catch Ctrl+C interruption and down VPN
trap vpn_down INT

# start VPN
vpn_up || exit;

echo "Press [CTRL+C] to down WireGuard interface.."

# the trick to catch interruption signial, as bash does not let to trap 'sleep'ed command directly
sleep infinity &
wait

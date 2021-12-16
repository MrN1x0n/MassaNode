#!/bin/bash
# Functions
main() {
	echo -e "${C_LGn}Port(s) opening...${RES}"
	if sudo ufw status | grep -q "Status: active"; then
		sudo ufw allow 22
		for open_this_port in "$@"; do
			sudo ufw allow "$open_this_port"
		done
	else
		if ! dpkg --get-selections | grep -qP "(?<=iptables-persistent)([^de]+)(?=install)"; then
			echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
			echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
			sudo apt install iptables-persistent -y
		fi
		for open_this_port in "$@"; do
			sudo iptables -I INPUT -p tcp --dport "$open_this_port" -j ACCEPT
		done
		sudo netfilter-persistent save
	fi
	unset open_this_port
	echo -e "${C_LGn}Done!${RES}"
}

# Actions
main

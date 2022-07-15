#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
echo ''
else
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
sleep 1 && curl -s https://raw.githubusercontent.com/MrN1x0n/MrN1x0n/main/logo.sh | bash && sleep 1


if [ ! $MASSA_PASSWORD ]; then
read -p "Enter massa wallet password: " MASSA_PASSWORD
echo 'export MASSA_PASSWORD='\"${MASSA_PASSWORD}\" >> $HOME/.bash_profile
fi
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
. $HOME/.bash_profile
sleep 1
cd $HOME
sudo apt update && sudo apt upgrade -y
sudo apt install wget curl jq unzip git build-essential pkg-config libssl-dev -y < "/dev/null"

# скачиваем бинарник и распаковываем его

version=`wget -qO- https://api.github.com/repos/massalabs/massa/releases/latest | jq -r ".tag_name"`; \
curl -sL "https://github.com/massalabs/massa/releases/download/${version}/massa_${version}_release_linux.tar.gz" > release_linux.tar.gz

tar -xvzf release_linux.tar.gz
rm release_linux.tar.gz

chmod +x $HOME/massa/massa-node/massa-node
chmod +x $HOME/massa/massa-client/massa-client

# Создаем конфигурационный файл
tee <<EOF >/dev/null $HOME/massa/massa-node/config/config.toml
[network]
routable_ip = "$(wget -qO- eth0.me)"
EOF

#Создаем конфиг для ноды
tee $HOME/massad.service > /dev/null <<EOF
[Unit]
Description=Massa Node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/massa/massa-node
ExecStart=$HOME/massa/massa-node/massa-node --pwd ${MASSA_PASSWORD}
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

#переносим конфиг в систему
sudo mv $HOME/massad.service /etc/systemd/system/

#прописываем бутстрапы
write_bootstraps() {
	local config_path="$HOME/massa/massa-node/base_config/config.toml"
	local bootstrap_list=`wget -qO- https://raw.githubusercontent.com/MrN1x0n/MassaNode/main/bootstrap_list.txt | shuf -n42 | awk '{ print "        "$0"," }'`
	local len=`wc -l < "$config_path"`
	local start=`grep -n bootstrap_list "$config_path" | cut -d: -f1`
	local end=`grep -n "\[optionnal\] port on which to listen" "$config_path" | cut -d: -f1`
	local end=$((end-1))
	local first_part=`sed "${start},${len}d" "$config_path"`
	local second_part=`cat <<EOF
    bootstrap_list = [
        ["149.202.86.103:31245", "P12UbyLJDS7zimGWf3LTHe8hYY67RdLke1iDRZqJbQQLHQSKPW8j"],
        ["149.202.89.125:31245", "P12vxrYTQzS5TRzxLfFNYxn6PyEsphKWkdqx2mVfEuvJ9sPF43uq"],
        ["158.69.120.215:31245", "P12rPDBmpnpnbECeAKDjbmeR19dYjAUwyLzsa8wmYJnkXLCNF28E"],
        ["158.69.23.120:31245", "P1XxexKa3XNzvmakNmPawqFrE9Z2NFhfq1AhvV1Qx4zXq5p1Bp9"],
        ["198.27.74.5:31245", "P1qxuqNnx9kyAMYxUfsYiv2gQd5viiBX126SzzexEdbbWd2vQKu"],
        ["198.27.74.52:31245", "P1hdgsVsd4zkNp8cF1rdqqG6JPRQasAmx12QgJaJHBHFU1fRHEH"],
        ["54.36.174.177:31245", "P1gEdBVEbRFbBxBtrjcTDDK9JPbJFDay27uiJRE3vmbFAFDKNh7"],
        ["51.75.60.228:31245", "P13Ykon8Zo73PTKMruLViMMtE2rEG646JQ4sCcee2DnopmVM3P5"],
${bootstrap_list}
    ]
EOF`
	local third_part=`sed "1,${end}d" "$config_path"`
	echo -e "${first_part}\n${second_part}\n${third_part}" > "$config_path"
	sed -i -e "s%retry_delay *=.*%retry_delay = 10000%; " "$config_path"
	printf_n "${C_LGn}Done!${RES}"
	if sudo systemctl status massad 2>&1 | grep -q running; then
		sudo systemctl restart massad
		printf_n "
You can view the node bootstrapping via ${C_LGn}massa_log${RES} command
"
	fi	
}
write_bootstraps

#запускаем службу и перезапускаем "демона", а также вызываем логи
sudo systemctl enable massad
sudo systemctl daemon-reload
sudo systemctl restart massad && journalctl -u massad -f
#Должна запуститься ноды и в логах написать, что подсоединилась к бутстрапу

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

. <(wget -qO- https://raw.githubusercontent.com/MrN1x0n/MrN1x0n/main/insert_variables.sh)
. <(wget -qO- https://github.com/MrN1x0n/MassaNode/raw/main/multi_tool.sh) -op
. <(wget -qO- https://github.com/MrN1x0n/MassaNode/raw/main/multi_tool.sh) -rb


#запускаем службу и перезапускаем "демона", а также вызываем логи
sudo systemctl enable massad
sudo systemctl daemon-reload
sudo systemctl restart massad && journalctl -u massad -f

# скачиваем бинарник и распаковываем его
cd $HOME

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

#запускаем службу и перезапускаем "демона", а также вызываем логи
sudo systemctl enable massad
sudo systemctl daemon-reload
sudo systemctl restart massad && journalctl -u massad -f
#Должна запуститься ноды и в логах написать, что подсоединилась к бутстрапу

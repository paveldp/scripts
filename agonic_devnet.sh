#!/usr/bin/env bash
# wget -q -O agonic_devnet.sh https://github.com/paveldp/scripts/blob/872820f4e879b372ad4dee75a9a29ffab9692e91/agonic_devnet.sh && chmod +x agonic_devnet.sh && sudo /bin/bash agonic_devnet.sh
. ~/.bashrc
if [ ! $AGORIC_NODENAME ]; then
	read -p "Enter node name: " AGORIC_NODENAME
	echo 'export AGORIC_NODENAME='$AGORIC_NODENAME >> $HOME/.bash_profile
	. ~/.bash_profile
fi

echo 'Your node name: ' $AGORIC_NODENAME
sleep 2
sudo dpkg --configure -a
sudo apt update
sudo apt install curl -y < "/dev/null"
sleep 1
wget -O nodesgurulogo https://api.nodes.guru/logo.sh
chmod +x nodesgurulogo
./nodesgurulogo
sleep 3

curl https://deb.nodesource.com/setup_16.x | sudo bash
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update
sudo apt upgrade -y
sudo apt install nodejs=16.* yarn build-essential git jq -y
node --version | grep 16
yarn --version
sleep 1

sudo rm -rf /usr/local/go
curl -L -o /tmp/go1.18.linux-amd64.tar.gz https://go.dev/dl/go1.18.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf /tmp/go1.18.linux-amd64.tar.gz
cat <<'EOF' >>$HOME/.profile
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export GO111MODULE=on
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
EOF
source $HOME/.profile
go version | grep 1.18
git clone https://github.com/Agoric/agoric-sdk
cd agoric-sdk
git fetch --all
git checkout 088b0abf214839326958b9c1109b2d50136636e4
yarn install && yarn build
(cd packages/cosmic-swingset && make)
agd version --long
cd
curl https://devnet.agoric.net/network-config > chain.json
chainName=`jq -r .chainName < chain.json`
echo $chainName
agd init --chain-id $chainName $AGORIC_NODENAME
curl https://devnet.rpc.agoric.net/genesis | jq .result.genesis > $HOME/.agoric/config/genesis.json 
peers=$(jq '.peers | join(",")' < chain.json)
seeds=$(jq '.seeds | join(",")' < chain.json)
echo $peers
echo $seeds
sed -i.bak 's/^log_level/# log_level/' $HOME/.agoric/config/config.toml
sed -i.bak -e "s/^seeds *=.*/seeds = $seeds/; s/^persistent_peers *=.*/persistent_peers = $peers/" $HOME/.agoric/config/config.toml
sudo tee <<EOF >/dev/null /etc/systemd/system/agd.service
[Unit]
Description=Agoric Cosmos daemon
After=network-online.target
[Service]
# OPTIONAL: turn on JS debugging information.
#SLOGFILE=.agoric/data/chain.slog
User=$USER
# OPTIONAL: turn on Cosmos nondeterminism debugging information
#ExecStart=$HOME/go/bin/agd start --log_level=info --trace-store=.agoric/data/kvstore.trace
ExecStart=$HOME/go/bin/agd start --log_level=warn
Restart=on-failure
RestartSec=3
LimitNOFILE=4096
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable agd
sudo systemctl daemon-reload
sudo systemctl start agd
sudo journalctl -u agd -f

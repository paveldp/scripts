sudo systemctl stop suid
cd $HOME/sui

git remote add upstream https://github.com/MystenLabs/sui

git fetch upstream

git checkout -B testnet --track upstream/testnet
cargo build --release -p sui-node -p sui
sudo mv $HOME/sui/target/release/sui-node /usr/local/bin/
sudo mv $HOME/sui/target/release/sui /usr/local/bin/
sui-node --version
sudo systemctl restart suid
sudo journalctl -u suid -f

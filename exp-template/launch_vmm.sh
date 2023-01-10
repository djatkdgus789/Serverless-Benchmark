#!/bin/bash

if [ $# -ne 1 ]; then
	echo "[USAGE] [# of VM]"
	exit 1
fi

# of VM
num_vm=$1

echo "launch ${num_vm} VM"

sudo killall -9 firecracker
sudo setfacl -m u:${USER}:rw /dev/kvm
sudo rm -f /tmp/firecracker*.socket

export FC_PATH="$HOME/firecracker-1.0.0/build/cargo_target/x86_64-unknown-linux-musl/debug/"

for var in `seq 1 ${num_vm}`; do
	sudo /bin/ip netns exec fc$var $FC_PATH/firecracker --api-sock /tmp/firecracker-$var.socket &

done

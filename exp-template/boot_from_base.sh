#/bin/bash

#if [ $# -ne 1 ]; then
#	echo "[USAGE] [Appcation name]"
#	exit 1
#fi

# of VM
#func=$1
index=1

## for control bash
BENCH_PATH="/home/ssl/Serverless-Benchmark"
rootfs_path="$BENCH_PATH/rootfs/debian-rootfs.ext4"
arch=`uname -m`
kernel_path="/home/ssl/vanilla-kernel/vmlinux"
socket_path=/tmp/firecracker-${index}.socket 

echo "setting Base Kernel"
curl --unix-socket $socket_path -i \
  -X PUT 'http://localhost/boot-source'   \
  -H 'Accept: application/json'           \
  -H 'Content-Type: application/json'     \
  -d "{
        \"kernel_image_path\": \"${kernel_path}\",
        \"boot_args\": \"console=ttyS0 reboot=k panic=1 pci=off\"
   }"


echo "setting Resource"
curl --unix-socket $socket_path -i \
    -X PUT "http://localhost/machine-config" \
    -H "accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{
        \"vcpu_count\": 2,
        \"mem_size_mib\": 2048,
        \"track_dirty_pages\": true
    }"

echo "setting Network"
curl --unix-socket $socket_path -i \
  -X PUT 'http://localhost/network-interfaces/eth0' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
      "iface_id": "eth0",
      "guest_mac": "AA:FC:00:00:00:01",
      "host_dev_name": "vmtap0"
    }'


echo "setting  RootFS"
curl --unix-socket $socket_path -i \
  -X PUT 'http://localhost/drives/rootfs' \
  -H 'Accept: application/json'           \
  -H 'Content-Type: application/json'     \
  -d "{
        \"drive_id\": \"rootfs\",
        \"path_on_host\": \"${rootfs_path}\",
        \"is_root_device\": true,
        \"is_read_only\": false
   }"

echo "launch  VM"
curl --unix-socket $socket_path -i \
  -X PUT 'http://localhost/actions'       \
  -H  'Accept: application/json'          \
  -H  'Content-Type: application/json'    \
  -d '{
      "action_type": "InstanceStart"
   }'

echo "graceful leaving"
curl --unix-socket $socket_path -i \
    -X PUT 'http://localhost/actions'       \
    -H  'Accept: application/json'          \
    -H  'Content-Type: application/json'    \
    -d '{
    "action_type": "SendCtrlAltDel"
}'

sleep 1s

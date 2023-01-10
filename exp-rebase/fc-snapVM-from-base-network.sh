#/bin/bash

#if [ $# -ne 1 ]; then
#	echo "[USAGE] [Appcation name]"
#	exit 1
#fi

# of VM
#func=$1
index=1

## for control bash
rootfs_path="/home/ssl/snapshot-serverless/faasnap_delta/rootfs/debian-rootfs.ext4"
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
        \"mem_size_mib\": 1024,
        \"ht_enabled\": false,
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
      "host_dev_name": "tap0"
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

sleep 1s

################# Base image #####################

echo "pause  VM"
curl --unix-socket $socket_path -i \
    -X PATCH 'http://localhost/vm' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
            "state": "Paused"
    }'

export snapshot_path=/home/ssl/snapshot/base/base.snapshot_file
export mem_file_path=/home/ssl/snapshot/base/base.mem_file

echo "snapshot VM"
curl --unix-socket $socket_path -i \
	-X PUT 'http://localhost/snapshot/create' \
	-H  'Accept: application/json' \
	-H  'Content-Type: application/json' \
	-d '{
		"snapshot_type": "Full",
		"snapshot_path": "/home/ssl/snapshot/base/base.snapshot_file",
		"mem_file_path": "/home/ssl/snapshot/base/base.mem_file"
	}'


sleep 1s

echo "resume VM"
curl --unix-socket $socket_path -i \
    -X PATCH 'http://localhost/vm' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
    "state": "Resumed"
}'

sleep 1s

#echo "graceful leaving"
#curl --unix-socket $socket_path -i \
#    -X PUT 'http://localhost/actions'       \
#    -H  'Accept: application/json'          \
#    -H  'Content-Type: application/json'    \
#    -d '{
#    "action_type": "SendCtrlAltDel"
#}'

# exit


################# Torch image #####################

echo -e "\nTorch invocation"
sudo curl --max-time 10 --request POST 'http://192.168.0.3:5000/invoke?function=torch&redishost=10.20.22.48&redispasswd=s$l0407' \
	--header 'Content-Type: application/json' \
	--data-raw '{
}'

sleep 1s

echo "pause  VM"
curl --unix-socket $socket_path -i \
    -X PATCH 'http://localhost/vm' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
            "state": "Paused"
    }'

export snapshot_path=/home/ssl/snapshot/torch/torch.snapshot_file
export mem_file_path=/home/ssl/snapshot/torch/torch.mem_file


echo "snapshot VM"
curl --unix-socket $socket_path -i \
	-X PUT 'http://localhost/snapshot/create' \
	-H  'Accept: application/json' \
	-H  'Content-Type: application/json' \
	-d '{
		"snapshot_type": "Diff",
		"snapshot_path": "/home/ssl/torch_diff.snapshot_file",
		"mem_file_path": "/home/ssl/torch_diff.mem_file",
		"version": "1.0.0"
	}'

echo "resume VM"
curl --unix-socket $socket_path -i \
    -X PATCH 'http://localhost/vm' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
    "state": "Resumed"
}'

########################################################

sleep 1s

echo -e "\n Recognition invocation"
sudo curl --max-time 10 --request POST 'http://192.168.0.3:5000/invoke?function=image&redishost=10.20.22.48&redispasswd=s$l0407' \
	--header 'Content-Type: application/json' \
	--data-raw '{
	"model_object_key":"resnet50-19c8e357.pth",
    	"input_object_key": "100kb.jpg",
        "output_object_key_prefix": "outputimg-"
}'


echo "pause  VM"
curl --unix-socket $socket_path -i \
    -X PATCH 'http://localhost/vm' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
            "state": "Paused"
    }'

export snapshot_path=/home/ssl/snapshot/recognition/recognition.snapshot_file
export mem_file_path=/home/ssl/snapshot/recognition/recognition.mem_file

echo "snapshot VM"
curl --unix-socket $socket_path -i \
	-X PUT 'http://localhost/snapshot/create' \
	-H  'Accept: application/json' \
	-H  'Content-Type: application/json' \
	-d '{
		"snapshot_type": "Diff",
		"snapshot_path": "/home/ssl/snapshot/recognition/recognition_diff.snapshot_file",
		"mem_file_path": "/home/ssl/snapshot/recognition/recognition_diff.mem_file",
		"version": "1.0.0"
	}'
sleep 1s

echo "resume VM"
curl --unix-socket $socket_path -i \
    -X PATCH 'http://localhost/vm' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
    "state": "Resumed"
}'
sleep 1s

echo "graceful leaving"
curl --unix-socket $socket_path -i \
    -X PUT 'http://localhost/actions'       \
    -H  'Accept: application/json'          \
    -H  'Content-Type: application/json'    \
    -d '{
    "action_type": "SendCtrlAltDel"
}'

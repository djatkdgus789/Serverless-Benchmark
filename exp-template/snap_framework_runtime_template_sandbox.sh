#/bin/bash

if [ $# -ne 1 ]; then
	echo "[USAGE] [Appcation name]"
	exit 1
fi

framework=$1
index=1

## for control bash
BENCH_PATH="/home/ssl/Serverless-Benchmark"
HOST_IP=10.20.18.215

# This Should be NVMe SSD
rootfs_path="/mnt/nvme1/rootfs/debian-rootfs.ext4"

arch=`uname -m`
kernel_path="/home/ssl/vanilla-kernel/vmlinux"
socket_path=/tmp/firecracker-${index}.socket 

sudo mkdir -p /mnt/nvme1/snapshot/framework-runtime-template-sandbox/$framework/
snapshot_path=/mnt/nvme1/snapshot/framework-runtime-template-sandbox/$framework/snapshot_file
mem_file_path=/mnt/nvme1/snapshot/framework-runtime-template-sandbox/$framework/mem_file

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

if [ $framework = 'hello' ]
then
    echo -e "\n Hello invocation"
    sudo curl --max-time 10 --request POST "http://192.168.0.3:5000/invoke?function=hello&redishost=$HOST_IP&redispasswd=s\$l0407" \
	    --header 'Content-Type: application/json' \
	    --data-raw '{
                    }'

elif [ $framework = 'numpy' ]
then
    echo -e "\n numpy invocation"
    sudo curl --max-time 10 --request POST "http://192.168.0.3:5000/invoke?function=numpy&redishost=$HOST_IP&redispasswd=s\$l0407" \
	    --header 'Content-Type: application/json' \
	    --data-raw '{
                    }'

elif [ $framework = 'pyaes' ]
then
    echo -e "\n pyaes invocation"
    sudo curl --max-time 10 --request POST "http://192.168.0.3:5000/invoke?function=pyaes&redishost=$HOST_IP&redispasswd=s\$l0407" \
	    --header 'Content-Type: application/json' \
	    --data-raw '{
                    }'

elif [ $framework = 'scikit-learn' ]
then
    echo -e "\n scikit-learn invocation"
    sudo curl --max-time 10 --request POST "http://192.168.0.3:5000/invoke?function=scikit-learn&redishost=$HOST_IP&redispasswd=s\$l0407" \
	    --header 'Content-Type: application/json' \
	    --data-raw '{
                    }'

elif [ $framework = 'chameleon' ]
then
    echo -e "\n chameleon invocation"
    sudo curl --max-time 10 --request POST "http://192.168.0.3:5000/invoke?function=chameleon&redishost=$HOST_IP&redispasswd=s\$l0407" \
	    --header 'Content-Type: application/json' \
	    --data-raw '{
                    }'

elif [ $framework = 'shutil' ]
then
    echo -e "\n shutil invocation"
    sudo curl --max-time 10 --request POST "http://192.168.0.3:5000/invoke?function=shutil&redishost=$HOST_IP&redispasswd=s\$l0407" \
	    --header 'Content-Type: application/json' \
	    --data-raw '{
                    }'

elif [ $framework = 'igraph' ]
then
    echo -e "\n igraph invocation"
    sudo curl --max-time 10 --request POST "http://192.168.0.3:5000/invoke?function=igraph&redishost=$HOST_IP&redispasswd=s\$l0407" \
	    --header 'Content-Type: application/json' \
	    --data-raw '{
                    }'

elif [ $framework = 'torch' ]
then
    echo -e "\nTorch invocation"
    sudo curl --max-time 10 --request POST "http://192.168.0.3:5000/invoke?function=torch&redishost=$HOST_IP&redispasswd=s\$l0407" \
	    --header 'Content-Type: application/json' \
	    --data-raw '{
                    }'

elif [ $framework = 'pillow' ]
then
    echo -e "\nTorch invocation"
    sudo curl --max-time 10 --request POST "http://192.168.0.3:5000/invoke?function=torch&redishost=$HOST_IP&redispasswd=s\$l0407" \
	    --header 'Content-Type: application/json' \
	    --data-raw '{
                    }'

elif [ $framework = 'torchvision' ]
then
    echo -e "\nTorch invocation"
    sudo curl --max-time 10 --request POST "http://192.168.0.3:5000/invoke?function=torch&redishost=$HOST_IP&redispasswd=s\$l0407" \
	    --header 'Content-Type: application/json' \
	    --data-raw '{
                    }'
else
    echo "Unknown Function"
    exit

fi

echo "pause  VM"
curl --unix-socket $socket_path -i \
    -X PATCH 'http://localhost/vm' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
            "state": "Paused"
    }'
    

echo "snapshot VM"
curl --unix-socket $socket_path -i \
	-X PUT 'http://localhost/snapshot/create' \
	-H  'Accept: application/json' \
	-H  'Content-Type: application/json' \
	-d "{
		\"snapshot_type\": \"Full\",
		\"snapshot_path\": \"${snapshot_path}\",
		\"mem_file_path\": \"${mem_file_path}\",
		\"version\": \"1.0.0\"
	}"


sleep 1s

echo "resume VM"
curl --unix-socket $socket_path -i \
    -X PATCH 'http://localhost/vm' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
    "state": "Resumed"
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

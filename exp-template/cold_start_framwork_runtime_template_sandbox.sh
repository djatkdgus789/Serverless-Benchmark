index=1
rootfs_path="/mnt/nvme1/rootfs/debian-rootfs.ext4"
arch=`uname -m`
kernel_path="/home/ssl/vanilla-kernel/vmlinux"
socket_path=/tmp/firecracker-${index}.socket 
snapshot_path=/mnt/nvme1/snapshot/framework-runtime-template-sandbox/torch/snapshot_file
mem_file_path=/mnt/nvme1/snapshot/framework-runtime-template-sandbox/torch/mem_file
HOST_IP=10.20.18.215

sync;
echo 3 > /proc/sys/vm/drop_caches 

echo "load snapshot"
sudo curl --unix-socket $socket_path -i \
    -X PUT "http://localhost/snapshot/load" \
    -H "accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{
    	\"snapshot_path\": \"${snapshot_path}\",
       	\"mem_file_path\":\"${mem_file_path}\",
	\"enable_diff_snapshots\": true,
	\"resume_vm\": false
    }"

echo "resume VM"
sudo curl --unix-socket $socket_path -i \
    -X PATCH 'http://localhost/vm' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
    "state": "Resumed"
}'

echo "\n Recognition invocation"
sudo time curl --max-time 10 --request POST "http://192.168.0.3:5000/invoke?function=resnet50&redishost=$HOST_IP&redispasswd=s\$l0407" \
	--header 'Content-Type: application/json' \
	--data-raw '{
	"model_object_key":"resnet50-19c8e357.pth",
    	"input_object_key": "100kb.jpg",
        "output_object_key_prefix": "outputimg-"
}'

echo "graceful leaving"
curl --unix-socket $socket_path -i \
    -X PUT 'http://localhost/actions'       \
    -H  'Accept: application/json'          \
    -H  'Content-Type: application/json'    \
    -d '{
    "action_type": "SendCtrlAltDel"
}'

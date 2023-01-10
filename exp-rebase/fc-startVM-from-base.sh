#/bin/bash

#if [ $# -ne 2 ]; then
#	echo "[USAGE] [Index of VM] [Func]"
#	exit 1
#fi

# of VM
#index=$1
index=1
#func=$2

## for control bash

arch=`uname -m`
socket_path=/tmp/firecracker-${index}.socket 

export snapshot_path=/home/ssl/snapshot/base/base.snapshot_file
export mem_file_path=/home/ssl/snapshot/base/base.mem_file

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

sleep 1

#echo "graceful leaving"
#curl --unix-socket $socket_path -i \
#    -X PUT 'http://localhost/actions'       \
#    -H  'Accept: application/json'          \
#    -H  'Content-Type: application/json'    \
#    -d '{
#    "action_type": "SendCtrlAltDel"
#}'

################# Torch image #####################

echo -e "\nTorch invocation"
sudo curl --max-time 10 --request POST 'http://192.168.0.3:5000/invoke?function=torch&redishost=10.20.22.48&redispasswd=s$l0407' \
	--header 'Content-Type: application/json' \
	--data-raw '{
}'

echo "pause  VM"
sudo curl --unix-socket $socket_path -i \
    -X PATCH 'http://localhost/vm' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
            "state": "Paused"
    }'


export snapshot_path=/home/ssl/snapshot/torch/torch.snapshot_file
export mem_file_path=/home/ssl/snapshot/torch/torch.mem_file

echo "snapshot VM"
sudo curl --unix-socket $socket_path -i \
    -X PUT 'http://localhost/snapshot/create' \
    -H  'Accept: application/json' \
    -H  'Content-Type: application/json' \
    -d "{
    \"snapshot_type\": \"Diff\",
    \"snapshot_path\": \"${snapshot_path}\",
    \"mem_file_path\": \"${mem_file_path}\",
    \"version\": \"1.0.0\"
}"

echo "resume VM"
sudo curl --unix-socket $socket_path -i \
    -X PATCH 'http://localhost/vm' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
    "state": "Resumed"
}'

########################################################

echo "graceful leaving"
curl --unix-socket $socket_path -i \
    -X PUT 'http://localhost/actions'       \
    -H  'Accept: application/json'          \
    -H  'Content-Type: application/json'    \
    -d '{
    "action_type": "SendCtrlAltDel"
}'

# Serverless-Benchmark

## Firecracker build
Firecracker-1.0.0 build command
```bash
cd firecracker-1.0.0
tools/devtool build
toolchain="$(uname -m)-unknown-linux-musl"
```
The Firecracker binary will be placed at
`build/cargo_target/${toolchain}/debug/firecracker`.

## Build RootFS
it will take a long time...
- Build rootfs image. `pushd rootfs && make debian-rootfs.ext4 && popd`
- Copy `rootfs/debian-rootfs.ext4` to a directory on local SSD.

## Network Setup
- Run `prep.sh`. 

## Setup Redis
## Prepare input data and Redis
1. Download ResNet model [resnet50-19c8e357.pth](https://github.com/fregu856/deeplabv3/blob/master/pretrained_models/resnet/resnet50-19c8e357.pth) to `resources/recognition`.
1. Start a local Redis instance on the default port 6379.
1. Populate Redis with files in `resources` directory and its subdirectory. The keys should be the last parts of filenames (`basename`).


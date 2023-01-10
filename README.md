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
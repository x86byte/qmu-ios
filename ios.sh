#!/bin/bash

NAME="ios-qemu"
IMAGES_DIR="$(cd "$(dirname "$0")" && pwd)/images"
mkdir -p "$IMAGES_DIR"

# download disk images if missing (2.8gb compressed)
if [ ! -f "$IMAGES_DIR/hfs.main" ] || [ ! -f "$IMAGES_DIR/hfs.sec" ]; then
    echo "[*] Downloading iOS 12.1 disk images (~2.8GB)..."
    wget -q --show-progress https://images.sick.codes/hfs.main.zst -O "$IMAGES_DIR/hfs.main.zst"
    wget -q --show-progress https://images.sick.codes/hfs.sec.zst -O "$IMAGES_DIR/hfs.sec.zst"
    zstd -d -q "$IMAGES_DIR/hfs.main.zst" && rm -f "$IMAGES_DIR/hfs.main.zst"
    zstd -d -q "$IMAGES_DIR/hfs.sec.zst" && rm -f "$IMAGES_DIR/hfs.sec.zst"
fi

stop() {
    echo "[*] Stopping..."
    docker rm -f "$NAME" 2>/dev/null
}

run() {
    local gdb="$1"
    stop
    docker run -d --name "$NAME" --privileged \
        --device /dev/kvm \
        -p 2222:2222 -p 5555:5555 -p 1234:1234 \
        -v "$IMAGES_DIR:/home/arch/docker-eyeos/images" \
        --entrypoint /bin/bash \
        sickcodes/docker-eyeos:latest -c "
sudo ssh-keygen -A 2>/dev/null
sudo /usr/bin/sshd -D &
sudo /home/arch/docker-eyeos/xnu-qemu-arm64/aarch64-softmmu/qemu-system-aarch64 \
    -M iPhone6splus-n66-s8000,\
kernel-filename=/home/arch/docker-eyeos/kernelcache.release.n66.out,\
dtb-filename=/home/arch/docker-eyeos/Firmware/all_flash/DeviceTree.n66ap.im4p.out,\
driver-filename=/home/arch/docker-eyeos/aleph_bdev_drv.bin,\
qc-file-0-filename=/home/arch/docker-eyeos/images/hfs.main,\
qc-file-1-filename=/home/arch/docker-eyeos/images/hfs.sec,\
kern-cmd-args=\"debug=0x8 kextlog=0xfff cpus=1 rd=disk0 serial=2\",\
xnu-ramfb=off \
    -cpu max -m 6G \
    -serial tcp:0.0.0.0:5555,server,nowait \
    -display none $gdb"
    echo "[*] Started. Boot takes 3-10 min."
    echo "    SSH:  ssh root@127.0.0.1 -p 2222  (password: alpine)"
    echo "    Logs: docker logs -f $NAME"
}

case "${1:-normal}" in
    stop)   stop ;;
    shell)  docker exec -it "$NAME" /bin/bash 2>/dev/null || echo "Container not running" ;;
    gdb)    run "-s -S" ;;
    logs)   docker logs -f "$NAME" ;;
    normal) run "" ;;
esac

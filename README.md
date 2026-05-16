# qmu-ios - iOS 12.1 in QEMU — Docker Wrapper

Run iPhone 6s Plus (iOS 12.1) inside QEMU on any Linux machine with Docker.

This script pulls the `sickcodes/docker-eyeos` image, downloads the iOS 12.1 disk images, and boots the system with SSH access.

## Requirements

- Linux with Docker installed
- KVM support (`/dev/kvm` available)
- ~8GB free disk space (for disk images + Docker image)
- ~6GB RAM for the VM
- `wget` and `zstd` installed (for downloading disk images)

## Quick Start

```bash
git clone https://github.com/x86byte/qmu-ios.git
cd qmu-ios
./ios.sh normal
```

<img width="1920" height="430" alt="image" src="https://github.com/user-attachments/assets/f767f416-5d6c-4dc6-b27b-85282c68fad8" />

Wait 3-10 minutes for the kernel to boot and SSH to become available, then:

```bash
ssh root@127.0.0.1 -p 2222
```

Password: `alpine`

<img width="1896" height="954" alt="image" src="https://github.com/user-attachments/assets/b8388eb8-437d-4936-bddb-52ede493fe93" />

## Usage

| Command | Description |
|---------|-------------|
| `./ios.sh normal` | Boot iOS 12.1 (default) |
| `./ios.sh stop` | Stop the container and kill QEMU |
| `./ios.sh logs` | Follow boot logs |
| `./ios.sh gdb` | Boot frozen, wait for GDB on port 1234 |
| `./ios.sh shell` | Open a shell inside the container |
| `./ios.sh wait` or `./ios.sh ssh` | Wait for SSH to become ready, then connect |

## What You Get

- iOS 12.1 kernel + launchd + userspace
- Interactive bash shell (Dropbear SSH on port 2222)
- Read/write secondary disk (`hfs.sec`)
- Unsigned code execution (CoreTrust bypassed)
- GDB kernel debugging support
- Serial console on port 5555 (`nc 127.0.0.1 5555`)

## Services Running Inside

- `dropbear` — SSH server (password: alpine)
- `mount_sec` — mounts the secondary block device as writable
- `tcptunnel` — TCP tunnel for SSH over serial
- `sshd` — container SSH (for debugging)

## Edge Cases

### Port already in use

If ports 2222, 5555, or 1234 are taken by a previous run or another process:

```bash
./ios-clean.sh
```

This kills the stale container, frees the ports, and removes leftover QEMU processes.

### Boot takes 3-10 minutes

This is expected. ARM64 emulation on x86_64 is slow. The kernel decompresses, loads kexts, mounts filesystems, and starts launchd services. Wait for the SSH prompt.

Use `./ios.sh logs` to watch progress. Look for:

- `ssh-keygen: generating new host keys` — keys generated, SSH almost ready
- Launchd service messages — boot proceeding normally

### SSH: Connection closed / reset

The VM is still booting. Use the wait command instead of spamming SSH:

```bash
./ios.sh wait
```

This polls SSH every 5 seconds for up to 10 minutes and connects automatically when ready.

<img width="1895" height="322" alt="image" src="https://github.com/user-attachments/assets/069da559-a3ca-4a7c-a4fe-fd164595d9e1" />


### Container stops immediately

Check Docker logs:

```bash
docker logs ios-qemu
```

Common causes: not enough RAM, KVM unavailable, corrupted disk images.

### Running multiple instances

Change the container name to avoid conflicts:

```bash
NAME=ios-qemu-2 ./ios.sh normal
```

### Disk images

The script downloads `hfs.main.zst` (2.7GB) and `hfs.sec.zst` (169MB) from `images.sick.codes` on first run. They are cached in the `images/` directory. Delete them to force re-download.

## Files

| File | Purpose |
|------|---------|
| `ios.sh` | Main launcher script |
| `ios-clean.sh` | Cleanup script for port/container issues |
| `images/` | Cached iOS 12.1 disk images |

## Credits

- [sickcodes/docker-eyeos](https://github.com/sickcodes/docker-eyeos) — Docker image
- [alephsecurity/xnu-qemu-arm64](https://github.com/alephsecurity/xnu-qemu-arm64) — QEMU fork + kernel patches


## Resources

- https://github.com/TrungNguyen1909/qemu-t8030
- https://ipsw.me/product/iPhone/
- https://www.3u.com/firmwares
- http://ipswbeta.dev/ios/26.x/
- https://github.com/34306/vphone-aio
- https://github.com/Lakr233/vphone-cli
- https://github.com/wh1te4ever/super-tart-vphone/

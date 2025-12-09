mkdir -p /root/disks
dd if=/dev/zero of=/root/disks/loop2.img bs=1M count=2048
losetup /dev/loop2 /root/disks/loop2.img
wipefs -a /dev/loop2 || true
dd if=/dev/zero of=/root/disks/loop3.img bs=1M count=2048
losetup /dev/loop3 /root/disks/loop3.img
wipefs -a /dev/loop3 || true


mkdir -p /root/disks
dd if=/dev/zero of=/root/disks/loop1.img bs=1M count=2048
losetup /dev/loop1 /root/disks/loop1.img
wipefs -a /dev/loop1 || true


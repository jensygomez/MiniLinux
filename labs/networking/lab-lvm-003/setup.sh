mkdir -p /root/disks
dd if=/dev/zero of=/root/disks/loop4.img bs=1M count=2048
losetup /dev/loop4 /root/disks/loop4.img
wipefs -a /dev/loop4 || true
dd if=/dev/zero of=/root/disks/loop5.img bs=1M count=2048
losetup /dev/loop5 /root/disks/loop5.img
wipefs -a /dev/loop5 || true
pvcreate /dev/loop4
pvcreate /dev/loop5
vgcreate vg_apps /dev/loop4 /dev/loop5


mkdir -p /root/disks
dd if=/dev/zero of=/root/disks/loop17.img bs=1M count=2048
losetup /dev/loop17 /root/disks/loop17.img
wipefs -a /dev/loop17 || true
dd if=/dev/zero of=/root/disks/loop18.img bs=1M count=2048
losetup /dev/loop18 /root/disks/loop18.img
wipefs -a /dev/loop18 || true
pvcreate /dev/loop17
pvcreate /dev/loop18
vgcreate vg_rapido /dev/loop17 /dev/loop18


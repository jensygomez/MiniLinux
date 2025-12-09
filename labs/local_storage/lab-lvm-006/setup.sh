mkdir -p /root/disks
dd if=/dev/zero of=/root/disks/loop10.img bs=1M count=2048
losetup /dev/loop10 /root/disks/loop10.img
wipefs -a /dev/loop10 || true
pvcreate /dev/loop10
vgcreate vg_main /dev/loop10
dd if=/dev/zero of=/root/disks/loop11.img bs=1M count=2048
losetup /dev/loop11 /root/disks/loop11.img
wipefs -a /dev/loop11 || true


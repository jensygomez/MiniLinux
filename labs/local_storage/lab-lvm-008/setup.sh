mkdir -p /root/disks
dd if=/dev/zero of=/root/disks/loop14.img bs=1M count=2048
losetup /dev/loop14 /root/disks/loop14.img
wipefs -a /dev/loop14 || true
dd if=/dev/zero of=/root/disks/loop15.img bs=1M count=2048
losetup /dev/loop15 /root/disks/loop15.img
wipefs -a /dev/loop15 || true
pvcreate /dev/loop14
pvcreate /dev/loop15
vgcreate vg_full /dev/loop14 /dev/loop15
lvcreate -n lv_full -L 300M vg_full
mkfs.xfs /dev/vg_full/lv_full
mkdir -p /mnt/full
mount /dev/vg_full/lv_full /mnt/full
dd if=/dev/zero of=/mnt/full/bigfile.bin bs=1M || true


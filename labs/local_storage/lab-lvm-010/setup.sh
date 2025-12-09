mkdir -p /root/disks
dd if=/dev/zero of=/root/disks/loop17.img bs=1M count=2048
losetup /dev/loop17 /root/disks/loop17.img
wipefs -a /dev/loop17 || true
dd if=/dev/zero of=/root/disks/loop18.img bs=1M count=2048
losetup /dev/loop18 /root/disks/loop18.img
wipefs -a /dev/loop18 || true
pvcreate /dev/loop17
pvcreate /dev/loop18
vgcreate vg_xfs /dev/loop17 /dev/loop18
lvcreate -n lv_xdata -L 500M vg_xfs
mkfs.xfs /dev/vg_xfs/lv_xdata
mkdir -p /mnt/xdata
mount /dev/vg_xfs/lv_xdata /mnt/xdata


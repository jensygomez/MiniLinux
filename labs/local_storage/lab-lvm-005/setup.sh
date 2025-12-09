mkdir -p /root/disks
dd if=/dev/zero of=/root/disks/loop8.img bs=1M count=2048
losetup /dev/loop8 /root/disks/loop8.img
wipefs -a /dev/loop8 || true
dd if=/dev/zero of=/root/disks/loop9.img bs=1M count=2048
losetup /dev/loop9 /root/disks/loop9.img
wipefs -a /dev/loop9 || true
pvcreate /dev/loop8
pvcreate /dev/loop9
vgcreate vg_logs /dev/loop8 /dev/loop9
lvcreate -n lv_logs -L 600M vg_logs
mkfs.xfs /dev/vg_logs/lv_logs
mkdir -p /mnt/logs
mount /dev/vg_logs/lv_logs /mnt/logs


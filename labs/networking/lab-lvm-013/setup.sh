mkdir -p /root/disks
dd if=/dev/zero of=/root/disks/loop12.img bs=1M count=2048
losetup /dev/loop12 /root/disks/loop12.img
wipefs -a /dev/loop12 || true
dd if=/dev/zero of=/root/disks/loop13.img bs=1M count=2048
losetup /dev/loop13 /root/disks/loop13.img
wipefs -a /dev/loop13 || true
pvcreate /dev/loop12
pvcreate /dev/loop13
vgcreate vg_remocao /dev/loop12 /dev/loop13
lvcreate -n lv_remo -L 500M vg_remocao
mkfs.ext4 /dev/vg_remocao/lv_remo
mkdir -p /mnt/remo
mount /dev/vg_remocao/lv_remo /mnt/remo


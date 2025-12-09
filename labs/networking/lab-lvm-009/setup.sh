mkdir -p /root/disks
dd if=/dev/zero of=/root/disks/loop16.img bs=1M count=2048
losetup /dev/loop16 /root/disks/loop16.img
wipefs -a /dev/loop16 || true
pvcreate /dev/loop16
vgcreate vg_fstab /dev/loop16
lvcreate -n lv_cfg -L 400M vg_fstab
mkfs.ext4 /dev/vg_fstab/lv_cfg
mkdir -p /mnt/cfg
echo "UUID=WRONG-UUID /mnt/cfg ext4 defaults 0 0" >> /etc/fstab


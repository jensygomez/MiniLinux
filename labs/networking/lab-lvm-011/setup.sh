mkdir -p /root/disks
dd if=/dev/zero of=/root/disks/loop19.img bs=1M count=2048
losetup /dev/loop19 /root/disks/loop19.img
wipefs -a /dev/loop19 || true
pvcreate /dev/loop19
vgcreate vg_uuid /dev/loop19
lvcreate -n lv_uuid -L 450M vg_uuid
mkfs.ext4 /dev/vg_uuid/lv_uuid
mkdir -p /mnt/uuidtest
mount /dev/vg_uuid/lv_uuid /mnt/uuidtest
ORIGINAL_UUID=$(blkid -s UUID -o value /dev/vg_uuid/lv_uuid)
mkfs.ext4 -F /dev/vg_uuid/lv_uuid
NEW_UUID=$(blkid -s UUID -o value /dev/vg_uuid/lv_uuid)
echo "UUID=${ORIGINAL_UUID} /mnt/uuidtest ext4 defaults 0 0" >> /etc/fstab


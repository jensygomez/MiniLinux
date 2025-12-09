mkdir -p /root/disks
dd if=/dev/zero of=/root/disks/loop14.img bs=1M count=2048
losetup /dev/loop14 /root/disks/loop14.img
wipefs -a /dev/loop14 || true
dd if=/dev/zero of=/root/disks/loop15.img bs=1M count=2048
losetup /dev/loop15 /root/disks/loop15.img
wipefs -a /dev/loop15 || true
pvcreate /dev/loop14
pvcreate /dev/loop15
vgcreate vg_degradado /dev/loop14 /dev/loop15
lvcreate -n lv_dados -L 600M vg_degradado
mkfs.xfs /dev/vg_degradado/lv_dados
mkdir -p /mnt/dados
mount /dev/vg_degradado/lv_dados /mnt/dados
losetup -d /dev/loop15  # Simular pérdida de disco


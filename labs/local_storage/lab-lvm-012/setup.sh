mkdir -p /root/disks
dd if=/dev/zero of=/root/disks/loop10.img bs=1M count=2048
losetup /dev/loop10 /root/disks/loop10.img
wipefs -a /dev/loop10 || true
dd if=/dev/zero of=/root/disks/loop11.img bs=1M count=2048
losetup /dev/loop11 /root/disks/loop11.img
wipefs -a /dev/loop11 || true
pvcreate /dev/loop10
pvcreate /dev/loop11
vgcreate vg_migracao /dev/loop10 /dev/loop11
lvcreate -n lv_mover -L 800M vg_migracao
mkfs.xfs /dev/vg_migracao/lv_mover
mkdir -p /mnt/mover
mount /dev/vg_migracao/lv_mover /mnt/mover
dd if=/dev/urandom of=/mnt/mover/testfile.bin bs=5M count=20


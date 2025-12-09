mkdir -p /root/disks
dd if=/dev/zero of=/root/disks/loop6.img bs=1M count=2048
losetup /dev/loop6 /root/disks/loop6.img
wipefs -a /dev/loop6 || true
dd if=/dev/zero of=/root/disks/loop7.img bs=1M count=2048
losetup /dev/loop7 /root/disks/loop7.img
wipefs -a /dev/loop7 || true
pvcreate /dev/loop6
pvcreate /dev/loop7
vgcreate vg_storage /dev/loop6 /dev/loop7
lvcreate -n lv_data -L 800M vg_storage


mkdir -p /root/disks
dd if=/dev/zero of=/root/disks/loop16.img bs=1M count=2048
losetup /dev/loop16 /root/disks/loop16.img
wipefs -a /dev/loop16 || true
parted -s /dev/loop16 mklabel gpt
parted -s /dev/loop16 mkpart primary ext4 1MiB 2000MiB
mkfs.ext4 /dev/loop16p1
mkdir -p /mnt/legacy
mount /dev/loop16p1 /mnt/legacy
dd if=/dev/urandom of=/mnt/legacy/data.bin bs=5M count=10


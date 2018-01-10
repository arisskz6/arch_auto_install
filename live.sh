#!/bin/bash
# A script auto install Archlinux
# Author: arisskz6
# Hitstoy: 2018/01/09 First release


# abort the script excute process when the last command not excuted sucessfully.

function error_abort {
	if [ "$?" -ne 0 ];then
		echo "last command failed,aborting..."
		exit 1
	fi
}

#set time sync
timedatectl set-ntp true; error_abort
# make partion table
parted /dev/sda mklabel msdos mkpart primary ext4 start 0 end 20G; error_abort
# format the partion
mkfs.ext4 /dev/sda1; error_abort

# mount the root partion to mnt
mount /dev/sda1 /mnt; error_abort

sed -i 's/^Server/#Server/g' /etc/pacman.d/mirrorlist
echo 'Server = http://mirrors.163.com/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
pacman -Syy; error_abort
pacstrap -i /mnt base base-devel net-tools vim --nocomfirm; error_abort
genfstab -U -p /mnt >> /mnt/etc/fstab; error_abort

chmod +x ./chroot.sh; error_abort
cp ./chroot.sh /mnt; error_abort
arch-chroot /mnt ./chroot.sh; error_abort
umount -R /mnt; error_abort
echo
echo "---------------------------------------"
echo "Install Finished!Enter reboot to exit"
echo "---------------------------------------"
echo

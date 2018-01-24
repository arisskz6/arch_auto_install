#!/bin/bash
# Finsh the auto_install process in chroot

function error_abort {
	if [ "$?" -ne 0 ];then
		echo "Sorry, the last command failed,aborting..."
		exit 1
	fi
}

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen; error_abort

sed -i 's/^#zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/^#zh_CN.GBK GBK/zh_CN.GBK GBK/g' /etc/locale.gen
sed -i 's/^#zh_CN.GB2312/zh_CN.GB2312/g' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc --utc
cat > /etc/vconsole.conf << EOF
KEYMAP=us
FONT=
EOF
error_abort
echo "arch" > /etc/hostname; error_abort
echo "127.0.0.1		localhost.localdomain	arch" > /etc/hosts

# Install important drivers and applications
pacman -S xorg xorg-server xorg-xinit xorg-utils mesa xorg-twm --noconfirm
pacman -S mesa xf86-video-intel alsa-utils xf86-input-synaptics --noconfirm; error_abort
pacman -S plasma-desktop  --noconfirm;error_abort
pacman -S sddm konsole ark dolphin okular --noconfirm
systemctl enable sddm
pacman -S file-roller gedit gpicview openssh unrar unzip p7zip wqy-zenhei firefox  ntfs-3g gvfs  ttf-dejavu --noconfirm
pacman -S networkmanager --noconfirm
systemctl enable NetworkManager.service
#set yaourt soure
cat >> /etc/pacman.conf << EOF
[archlinuxcn]
SigLevel = Optional TrustedOnly
Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch
EOF
pacman -Syy --noconfirm && pacman -S archlinuxcn-keyring --noconfirm
pacman -S yaourt --noconfirm

pacman -S fcitx fcitx-sougoupinyin --noconfirm
cat >> /home/arisskz6/.xinitrc << EOF
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"
EOF

mkinitcpio -p linux; error_abort
pacman -S linux-headers broadcom-wl-dkms --noconfirm 
echo root:0322Qds233 | chpasswd; error_abort

useradd -m -g users -G wheel -s /bin/bash arisskz6
echo arisskz6:0322qds | chpasswd
sed -i 's/# %wheel ALL=(ALL) ALL/  %wheel ALL=(ALL) ALL/g' /etc/sudoers

# Install boot loader

bootctl install; error_abort
cat > /boot/loader/entries/arch.conf << EOF
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=/dev/sda2 rw
EOF
error_abort
rm -r /boot/loader/loader.conf
cat > /boot/loader/loader.conf << EOF
timeout 3
default arch
EOF
error_abort

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
# 该死的颜色
color(){
    case $1 in
        red)
            echo -e "\033[31m$2\033[0m"
        ;;
        green)
            echo -e "\033[32m$2\033[0m"
        ;;
    esac
}

partition(){
    if (echo $1 | grep '/' > /dev/null 2>&1);then
        other=$1
    else
        other=/$1
    fi

    fdisk -l
    color green "Input the partition (/dev/sdaX"
    read OTHER
    color green "Format it ? y)yes ENTER)no"
    read tmp

    if [ "$other" == "/boot" ];then
        boot=$OTHER
    fi

    if [ "$tmp" == y ];then
        umount $OTHER > /dev/null 2>&1
        color green "Input the filesystem's num to format it"
        select type in 'ext2' "ext3" "ext4" "btrfs" "xfs" "jfs" "fat" "swap";do
            case $type in
                "ext2")
                    mkfs.ext2 $OTHER
                    break
                ;;
                "ext3")
                    mkfs.ext3 $OTHER
                    break
                ;;
                "ext4")
                    mkfs.ext4 $OTHER
                    break
                ;;
                "btrfs")
                    mkfs.btrfs $OTHER -f
                    break
                ;;
                "xfs")
                    mkfs.xfs $OTHER -f
                    break
                ;;
                "jfs")
                    mkfs.jfs $OTHER
                    break
                ;;
                "fat")
                    mkfs.fat -F32 $OTHER
                    break
                ;;
                "swap")
                    swapoff $OTHER > /dev/null 2>&1
                    mkswap $OTHER -f
                    break
                ;;
                *)
                    color red "Error ! Please input the num again"
                ;;
            esac
        done
    fi

    if [ "$other" == "/swap" ];then
        swapon $OTHER
    else
        umount $OTHER > /dev/null 2>&1
        mkdir /mnt$other
        mount $OTHER /mnt$other
    fi
}

prepare(){
    fdisk -l
    color green "Do you want to adjust the partition ? y)yes ENTER)no"
    read tmp
    if [ "$tmp" == y ];then
        color green "Input the disk (/dev/sdX"
        read TMP
        cfdisk $TMP
    fi
    color green "Input the ROOT(/) mount point:"
    read ROOT
    color green "Format it ? y)yes ENTER)no"
    read tmp
    if [ "$tmp" == y ];then
        umount $ROOT > /dev/null 2>&1
        color green "Input the filesystem's num to format it"
        select type in "ext4" "btrfs" "xfs" "jfs";do
            umount $ROOT > /dev/null 2>&1
            if [ "$type" == "btrfs" ];then
                mkfs.$type $ROOT -f
            elif [ "$type" == "xfs" ];then
                mkfs.$type $ROOT -f
            else
                mkfs.$type $ROOT
            fi
            break
        done
    fi
    mount $ROOT /mnt
    color green "Do you have another mount point ? if so please input it, such as : /boot /home and swap or just ENTER to skip"
    read other
    while [ "$other" != '' ];do
        partition $other
        color green "Still have another mount point ? input it or just ENTER"
        read other
    done
}

#set time sync
timedatectl set-ntp true; error_abort
# make partion table
#parted -s /dev/sda mklabel msdos mkpart primary ext4 0% 20G; error_abort
# format the partion
#mkfs.ext4 /dev/sda1; error_abort

# mount the root partion to mnt
#mount /dev/sda1 /mnt; error_abort

sed -i 's/^Server/#Server/g' /etc/pacman.d/mirrorlist
echo 'Server = http://mirrors.163.com/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
pacman -Syy; error_abort
pacstrap -i /mnt base base-devel net-tools vim --noconfirm; error_abort
genfstab -U -p /mnt >> /mnt/etc/fstab; error_abort

chmod +x ./chroot.sh; error_abort
cp ./chroot.sh /mnt; error_abort
arch-chroot /mnt ./chroot.sh; error_abort
umount -R /mnt; error_abort
echo
echo "---------------------------------------"
echo "Install Finished!Enter rebooting"
echo "---------------------------------------"
echo
sleep 5
reboot

#!/bin/bash

# vars
DEVICE=""
IFACE=""
ESSID=""
WLANPASS=''
HOSTNAME=""
DOMAIN=""
ROOTPASS=''
USER=""
USERPASS=''


# 01 keyboard layout
loadkeys us

# 02 network
iwctl device list
iwctl station ${IFACE} scan
iwctl station ${IFACE} get-networks
iwctl --password ${WLANPASS} station ${IFACE} connect ${ESSID} psk

# 03 time
timedatectl set-ntp true

# 04 partitions
parted /dev/${DEVICE} mklabel gpt
parted /dev/${DEVICE} mkpart primary btrfs 0% 100%
parted /dev/${DEVICE} set 1 boot on

# 05 filesystem
mkfs.btrfs /dev/${DEVICE}1
mount /dev/${DEVICE}1 /mnt

# 06 mirrors
sed -i 's/^#\[multilib\]/\[multilib\]/' /etc/pacman.conf
sed -i '95s/^#Include/Include/' /etc/pacman.conf

# 07 install base
pacman -Sy --noconfirm
pacstrap /mnt base linux linux-firmware --noconfirm
genfstab -U /mnt >> /mnt/etc/fstab

# 08 chroot
arch-chroot /mnt /bin/bash -c "ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime"
arch-chroot /mnt /bin/bash -c "hwclock --systohc --utc"
arch-chroot /mnt /bin/bash -c "echo \"en_US.UTF-8 UTF-8\" > /etc/locale.gen"
arch-chroot /mnt /bin/bash -c "locale-gen"
arch-chroot /mnt /bin/bash -c "echo \"LANG=en_US.UTF-8\" > /etc/locale.conf"
arch-chroot /mnt /bin/bash -c "echo \"KEYMAP=us\" > /etc/vconsole.conf"
arch-chroot /mnt /bin/bash -c "echo \"${HOSTNAME}\" > /etc/hostname"
arch-chroot /mnt /bin/bash -c "echo \"# IPv4\" > /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo \"127.0.0.1      localhost\" >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo \"127.0.1.1      ${HOSTNAME}.${DOMAIN} ${HOSTNAME}\" >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo \"\" >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo \"# IPv6\" >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo \"::1            localhost ip6-localhost ip6-loopback\" >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo \"ff02::1         ip6-allnodes\" >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo \"ff02::2         ip6-allrouters\" >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "touch /etc/resolv.conf"

arch-chroot /mnt /bin/bash -c "mkinitcpio -p linux"
arch-chroot /mnt /bin/bash -c "echo -e \"${ROOTPASS}\n${ROOTPASS}\n\" | passwd"
arch-chroot /mnt /bin/bash -c "useradd -G users,wheel -m -s /usr/bin/bash -U ${USER}"
arch-chroot /mnt /bin/bash -c "echo -e \"${USERPASS}\n${USERPASS}\n\" | passwd ${USER}"
arch-chroot /mnt /bin/bash -c "pacman -S grub os-prober --noconfirm"
arch-chroot /mnt /bin/bash -c "grub-install --recheck --target=i386-pc /dev/${DEVICE}"
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"

#arch-chroot /mnt /bin/bash -c "echo \"Section "" \" >> /etc/X11/xorg.conf.d/10-keyboard.conf"

arch-chroot /mnt /bin/bash -c "# pacman -S <pkgs> --noconfirm"

alsamixer
alsactl store

#  09 unmount
umount -R /mnt

# 10 restart
clear
echo "Installation complete. The system will reboot in 30 seconds."
sleep 30
systemctl reboot

# ----------------------------------------
# ----------------------------------------

# post install
pacman -S networkmanager
systemctl enable NetworkManager
systemctl start NetworkManager
netctl disable ${IFACE}-*

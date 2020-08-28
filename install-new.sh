#!/bin/bash

# vars
DEVICE="sda"
IFACE="wlan0"
ESSID="skynet"
WLANPASS=''
HOSTNAME=""
ROOTPASS=''
USER=""
USERPASS=''


# 01 keyboard layout
loadkeys us

# 02 network
iwctl device list
iwctl station wlan0 scan
iwctl station wlan0 get-networks
iwctl --password ${WLANPASS} station wlan0 connect ${ESSID} psk

# 03 time
timedatectl set-ntp true

# 04 partitions
parted /dev/${DEVICE} mklabel gpt
parted /dev/${DEVICE} mkpart primary ext4 0% 100%
parted /dev/${DEVICE} set 1 boot on

# 05 filesystem
mkfs.ext -F /dev/${DEVICE}1
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
arch-chroot /mnt /bin/bash -c "hwclock --systohc"
arch-chroot /mnt /bin/bash -c "echo \"en_US.UTF-8 UTF-8\" > /etc/locale.gen"
arch-chroot /mnt /bin/bash -c "locale-gen"
arch-chroot /mnt /bin/bash -c "echo \"LANG=en_US.UTF-8\" > /etc/locale.conf"
arch-chroot /mnt /bin/bash -c "echo \"KEYMAP=us\" > /etc/vconsole.conf"
arch-chroot /mnt /bin/bash -c "echo \"anubis\" > /etc/hostname"
arch-chroot /mnt /bin/bash -c "echo \"127.0.0.1      localhost\" > /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo \"::1            localhost\" >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo \"127.0.0.1      anubis.localdomain anubis\" >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "mkinitcpio -P"
arch-chroot /mnt /bin/bash -c "echo -e \"07031991\n07031991\n\" | passwd"
arch-chroot /mnt /bin/bash -c "useradd -G network,power,users -m -s /usr/bin/bash -U stephen"
arch-chroot /mnt /bin/bash -c "pacman -S grub os-prober --noconfirm"
arch-chroot /mnt /bin/bash -c "grub-install --recheck --target=i386-pc /dev/sda"
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"

arch-chroot /mnt /bin/bash -c "# pacman -S <pkgs> --noconfirm"

#  09 unmount
umount -R /mnt

# 10 restart
clear
echo "Installation complete. The system will reboot in 30 seconds."
sleep 30
systemctl reboot

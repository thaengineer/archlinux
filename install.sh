#!/bin/bash

# vars
DEVICE=""
IFACE=""
ESSID=""
WLANPASS=''
HOSTNAME=""
DOMAIN=""
ROOTPASS=''
USERNAME=""
USERPASS=''


# 01 keyboard layout
loadkeys us

# 02 connect to network
iwctl --passphrase ${WLANPASS} station ${IFACE} connect ${ESSID} psk
sleep 5

# 03 time
timedatectl set-ntp true

# 04 partitions
parted /dev/${DEVICE} mklabel gpt
parted /dev/${DEVICE} mkpart primary ext4 0% 100%
parted /dev/${DEVICE} set 1 boot on

# 05 filesystem
mkfs.ext4 -F /dev/${DEVICE}1
mount /dev/${DEVICE}1 /mnt

# 06 mirrors
sed -i '92s/^#\[multilib\]/\[multilib\]/' /etc/pacman.conf
sed -i '93s/^#Include/Include/' /etc/pacman.conf

# 07 install base
pacman -Sy --noconfirm
pacstrap -i /mnt base base-devel linux linux-firmware git --noconfirm
genfstab -U -p /mnt >> /mnt/etc/fstab
# sed -i '5s/data=ordered/discard/' /mnt/etc/fstab

# 08 configure network
echo -e "# ${ESSID}\nInterface=${IFACE}\nConnection=wireless\nSecurity=wpa\nESSID=${ESSID}\nIP=dhcp\nKey=${WLANPASS}" > /mnt/etc/netctl/${ESSID}
chmod 600 /mnt/etc/netctl/${ESSID}

# 09 chroot
arch-chroot /mnt /bin/bash -c "sed -i '93s/^#\[multilib\]/\[multilib\]/' /etc/pacman.conf"
arch-chroot /mnt /bin/bash -c "sed -i '94s/^#Include/Include/' /etc/pacman.conf"
arch-chroot /mnt /bin/bash -c "ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime"
arch-chroot /mnt /bin/bash -c "hwclock --systohc --utc"
arch-chroot /mnt /bin/bash -c "timedatectl set-timezone America/New_York"
arch-chroot /mnt /bin/bash -c "timedatectl set-ntp true"
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
arch-chroot /mnt /bin/bash -c "useradd -G users,wheel -m -s /usr/bin/bash -U ${USERNAME}"
arch-chroot /mnt /bin/bash -c "echo -e \"${USERPASS}\n${USERPASS}\n\" | passwd ${USERNAME}"
arch-chroot /mnt /bin/bash -c "grub-install --recheck --target=i386-pc /dev/${DEVICE}"
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
chmod 777 postinstall.sh
mv postinstall.sh /mnt/root

# 10 unmount
umount -R /mnt

# 11 restart
echo -e "\nThe installation completed. Please restart the computer."

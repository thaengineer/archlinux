#!/usr/bin/bash

# vars
DEVICE="sda"
PARTSTART=""
PARTEND=""
SWAPSTART="$(expr ${PARTEND} - 8)"
WNIC="$(ip link | grep 'wl' | awk '{ print $2 }' | sed 's/\://')"
NAMESRV1="1.1.1.1"
NAMESRV2="1.0.0.1"
HOSTNAME=""
ROOTPW=""
USERNAME=""
USERPW=""
ESSID=""
WIFIKEY=""


# 01 partitioning
parted /dev/${DEVICE} mklabel msdos
parted /dev/${DEVICE} mkpart primary ext4 $(($PARTSTART))MiB $(($SWAPSTART))GiB
parted /dev/${DEVICE} set 1 boot on
parted /dev/${DEVICE} mkpart primary linux-swap $(($SWAPSTART))GiB $(($PARTEND))GiB


# 02 format partitions
mkfs.ext4 -F /dev/${DEVICE}1
mkswap -c -f /dev/${DEVICE}2
swapon -d /dev/${DEVICE}2


# 03 mount partitions
mount /dev/${DEVICE}1 /mnt


# 04 connect to network
echo -e "# ${ESSID}\nInterface=${WNIC}\nConnection=wireless\nSecurity=wpa\nESSID=${ESSID}\nIP=dhcp\nKey=${WIFIKEY}" > /etc/netctl/${ESSID}
chmod 600 /etc/netctl/${ESSID}
netctl start ${ESSID}


# 05 select pacman mirrors
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist
sed -i 's/^#\[multilib\]/\[multilib\]/' /etc/pacman.conf
sed -i '95s/^#Include/Include/' /etc/pacman.conf


# 06 install base
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist
sed -i 's/^#\[multilib\]/\[multilib\]/' /etc/pacman.conf
sed -i '94s/^#Include/Include/' /etc/pacman.conf
pacman -Sy --noconfirm
pacstrap -i /mnt base base-devel bash-completion bzip2 cronie cups curl dhcpcd dialog gdb git gnupg grub gvfs-mtp gzip htop ifplugd iftop iproute2 iptables iw mesa mtpfs netcat ntfs-3g openssh openvpn os-prober p7zip parted ppp rsync rxvt-unicode screen sudo tar tlp tmux ufw unrar unzip vim wget wireless_tools wpa_supplicant xz zip --noconfirm
genfstab -U -p /mnt > /mnt/etc/fstab
sed -i '5s/data=ordered/discard/' /mnt/etc/fstab


# 08 configure network
echo -e "# ${ESSID}\nInterface=${WNIC}\nConnection=wireless\nSecurity=wpa\nESSID=${ESSID}\nIP=dhcp\nKey=${WIFIKEY}" > /etc/netctl/${ESSID}
chmod 600 /mnt/etc/netctl/${ESSID}


# 09 locale/lang
echo "en_US.UTF-8 UTF-8" > /mnt/etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
arch-chroot /mnt /bin/bash -c "locale-gen"


# 10 pacman mirrors
arch-chroot /mnt /bin/bash -c "sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist"
arch-chroot /mnt /bin/bash -c "sed -i 's/^#\[multilib\]/\[multilib\]/' /etc/pacman.conf"
arch-chroot /mnt /bin/bash -c "sed -i '94s/^#Include/Include/' /etc/pacman.conf"


# 11 time
arch-chroot /mnt /bin/bash -c "ln -f -s /usr/share/zoneinfo/America/New_York /etc/localtime"
arch-chroot /mnt /bin/bash -c "hwclock --systohc --utc"
arch-chroot /mnt /bin/bash -c "timedatectl set-timezone America/New_York"
arch-chroot /mnt /bin/bash -c "timedatectl set-ntp true"


# 12 dns
echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > /mnt/etc/resolvconf.conf


# 13 bootloader
arch-chroot /mnt /bin/bash -c "pacman -S grub os-prober --noconfirm"
arch-chroot /mnt /bin/bash -c "grub-install --recheck --target=i386-pc /dev/sda"
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
arch-chroot /mnt /bin/bash -c "mkinitcpio -p linux"


# 14 hostname
echo "anubis" > /mnt/etc/hostname


# 15 root
arch-chroot /mnt /bin/bash -c "echo -e \"${ROOTPW}\n${ROOTPW}\" | passwd"


# 16 sudoers
arch-chroot /mnt /bin/bash -c "sed -i '82s/^# //' /etc/sudoers"


# 18 create user
arch-chroot /mnt /bin/bash -c "useradd -m -G audio,video,storage,optical,network,users,wheel,rfkill,scanner,power -s /bin/bash ${USERNAME}"
arch-chroot /mnt /bin/bash -c "echo -e \"${USERPW}\n${USERPW}\" | passwd ${USERNAME}"
arch-chroot /mnt /bin/bash -c "mkdir Desktop Documents Downloads Music Pictures Videos"
arch-chroot /mnt /bin/bash -c "cd /home/${USERNAME}; mkdir Desktop Documents Downloads Music Pictures Videos workspace"
arch-chroot /mnt /bin/bash -c "git clone https://gitlab.com/thaengineer/dotfiles"
arch-chroot /mnt /bin/bash -c "mv ~/dots/.bash_profile /home/${USERNAME}"
arch-chroot /mnt /bin/bash -c "mv ~/dots/.bashrc /home/${USERNAME}"
arch-chroot /mnt /bin/bash -c "mv ~/dots/.vimrc /home/${USERNAME}"
arch-chroot /mnt /bin/bash -c "mv ~/dots/.xinitrc /home/${USERNAME}"
arch-chroot /mnt /bin/bash -c "mv ~/dots/.Xresources /home/${USERNAME}"
arch-chroot /mnt /bin/bash -c "mv -r ~/dots/.config /home/${USERNAME}/.config"
arch-chroot /mnt /bin/bash -c "mv -r ~/dots/.git /home/${USERNAME}/.git"
arch-chroot /mnt /bin/bash -c "rm -rf ~/dots"
arch-chroot /mnt /bin/bash -c "chmod -R 755 /home/${USERNAME}/*"
arch-chroot /mnt /bin/bash -c "chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/*"
arch-chroot /mnt /bin/bash -c "sed -i '69s/^#default_user       simone/default_user       ${USERNAME}/' /etc/slim.conf"
arch-chroot /mnt /bin/bash -c "sed -i '77s/^#auto_login          no/^#auto_login          yes/' /etc/slim.conf"
arch-chroot /mnt /bin/bash -c "systemctl enable slim"
mv postinstall.sh /mnt/home/${USERNAME}
chown stephen:stephen /mnt/home/${USERNAME}/postinstall.sh
chmod 755 /mnt/home/${USERNAME}/postinstall.sh


# 19 unmount partitions
umount -R /mnt


# 20 reboot system
echo "The installation is complete. The system will reboot in 10 seconds."
sleep 10
systemctl reboot

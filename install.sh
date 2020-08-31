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
mkfs.btrfs -L root -n 64k /dev/${DEVICE}1
mount /dev/${DEVICE}1 /mnt

# 06 mirrors
sed -i 's/^#\[multilib\]/\[multilib\]/' /etc/pacman.conf
sed -i '95s/^#Include/Include/' /etc/pacman.conf

# 07 install base
pacman -Sy --noconfirm
pacstrap -i /mnt base base-devel linux linux-firmware --noconfirm
genfstab -U -p /mnt >> /mnt/etc/fstab
# sed -i '5s/data=ordered/discard/' /mnt/etc/fstab

# 08 configure network
echo -e "# ${ESSID}\nInterface=${IFACE}\nConnection=wireless\nSecurity=wpa\nESSID=${ESSID}\nIP=dhcp\nKey=${WLANPASS}" > /etc/netctl/${ESSID}
chmod 600 /mnt/etc/netctl/${ESSID}

# 09 chroot
arch-chroot /mnt /bin/bash -c "git clone https://aur.archlinux.org/yay.git && cd yay && makepkg PKGBUILD && pacman -U yay*.zst --noconfirm"
arch-chroot /mnt /bin/bash -c "yay -Sy --noconfirm"
arch-chroot /mnt /bin/bash -c "yay -S aircrack-ng alsa-utils anydesk bash-completion bleachbit blender bless bzip2 compton cronie cups curl dhcpcd dialog docker dsniff file-roller firefox gdb gimp git gnupg gparted grc grub gvfs-mtp gzip hashcat htop ifplugd iftop iproute2 iptables irssi iw jre8-openjdk keepassxc krita libreoffice-fresh mesa mtpfs netcat nitrogen nmap noto-fonts ntfs-3g ntfsfixboot nvidia nvidia-utils lib32-nvidia-utils openbox openssh openvpn os-prober p7zip parted pcmanfm pidgin polybar popcorntime qemu radare2 radare2-cutter redshift rsync rxvt-unicode screen shotwell slim sublime-text-dev sudo tar tcpdump terminus-font tlp tmux tor tor-browser torsocks transmission-gtk ttf-dejavu ttf-droid ttf-fira-mono ttf-font-awesome ttf-inconsolata ufw unrar unzip vim virtualbox virtualbox-host-modules-arch vlc wget wireless_tools wireshark-gtk wpa_supplicant xf86-input-libinput xorg-apps xorg-server xz zip --noconfirm"
arch-chroot /mnt /bin/bash -c "ln -sf /opt/sublime_text_3/sublime_text /usr/bin/subl"
arch-chroot /mnt /bin/bash -c "sed -i 's/^#\[multilib\]/\[multilib\]/' /etc/pacman.conf"
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
arch-chroot /mnt /bin/bash -c "sed -i '69s/^#default_user       simone/default_user       ${USERNAME}/' /etc/slim.conf"
arch-chroot /mnt /bin/bash -c "sed -i '77s/^#auto_login          no/^#auto_login          yes/' /etc/slim.conf"
arch-chroot /mnt /bin/bash -c "systemctl enable slim"
arch-chroot /mnt /bin/bash -c "alsactl store"
arch-chroot /mnt /bin/bash -c "netctl disable dhcpcd"
arch-chroot /mnt /bin/bash -c "netctl enable ${ESSID}"

# 10 unmount
umount -R /mnt

# 11 restart
clear
echo "Installation complete. The system will reboot in 30 seconds."
sleep 30
systemctl reboot

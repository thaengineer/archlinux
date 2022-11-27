#!/usr/bin/env bash
DEVICE=""
IFACE=""
ESSID=""
WLANPASS=''
HOSTNAME=""
ROOTPASS=''
USERNAME=""
USERPASS=''

# 01 network
#iwctl --passphrase ${WLANPASS} station ${IFACE} connect ${ESSID} psk
#sleep 5

# 02 wipe
# dd if=/dev/zero of=/dev/${DEVICE} status=progress

# 03 partition
parted /dev/${DEVICE} mklabel gpt
parted /dev/${DEVICE} mkpart primary fat32 0% 512MiB name 1 boot
parted /dev/${DEVICE} mkpart primary ext4 512MiB 100% name 2 root
parted /dev/${DEVICE} set 1 boot on
# parted /dev/${DEVICE} set 1 esp on

# 04 format
mkfs.fat -F32 /dev/${DEVICE}1
mkfs.ext4 -F /dev/${DEVICE}2

# 05 mount
mount /dev/${DEVICE}2 /mnt
mkdir -p /mnt/boot
mount /dev/${DEVICE}1 /mnt/boot

# 06 mirrors
sed -i '92s/^#\[multilib\]/\[multilib\]/' /etc/pacman.conf
sed -i '93s/^#Include/Include/' /etc/pacman.conf

# 07 install base
pacman -Sy --noconfirm
pacstrap -i /mnt base base-devel linux linux-firmware grub efibootmgr sudo git go --noconfirm

# 08 fstab
genfstab -U -p /mnt >> /mnt/etc/fstab
sed -i 's/rw,relatime/rw,noatime/g' /mnt/etc/fstab

# 09 configure network
# cat > /mnt/etc/netctl/${ESSID} << EOF
${ESSID}
Interface=${IFACE}
Connection=wireless
Security=wpa
ESSID=${ESSID}
IP=dhcp
Key=${WLANPASS}
EOF
# chmod 600 /mnt/etc/netctl/${ESSID}

# 10 chroot
arch-chroot /mnt /bin/bash -c "sed -i '93s/^#\[multilib\]/\[multilib\]/' /etc/pacman.conf"
arch-chroot /mnt /bin/bash -c "sed -i '94s/^#Include/Include/' /etc/pacman.conf"
arch-chroot /mnt /bin/bash -c "ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime"
arch-chroot /mnt /bin/bash -c "hwclock --systohc --utc"
arch-chroot /mnt /bin/bash -c "echo \"en_US.UTF-8 UTF-8\" > /etc/locale.gen"
arch-chroot /mnt /bin/bash -c "locale-gen"
arch-chroot /mnt /bin/bash -c "echo \"LANG=en_US.UTF-8\" > /etc/locale.conf"
arch-chroot /mnt /bin/bash -c "echo \"KEYMAP=us\" > /etc/vconsole.conf"
arch-chroot /mnt /bin/bash -c "echo \"${HOSTNAME}\" > /etc/hostname"
arch-chroot /mnt /bin/bash -c "echo \"# IPv4\" > /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo \"127.0.0.1    localhost\" >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo \"127.0.1.1    ${HOSTNAME}.localdomain ${HOSTNAME}\" >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo \"\" >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo \"# IPv6\" >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo \"::1        localhost\" >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo \"ff02::1    ip6-allnodes\" >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo \"ff02::2    ip6-allrouters\" >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "touch /etc/resolv.conf"
arch-chroot /mnt /bin/bash -c "mkinitcpio -p linux"
arch-chroot /mnt /bin/bash -c "echo -e \"${ROOTPASS}\n${ROOTPASS}\n\" | passwd"
arch-chroot /mnt /bin/bash -c "useradd -G users,wheel -m -p '07031991' -s /usr/bin/bash -U ${USERNAME}"
# arch-chroot /mnt /bin/bash -c "grub-install --recheck --target=i386-pc /dev/${DEVICE}"
arch-chroot /mnt /bin/bash -c "grub-install --target=x86_64-efi --efi-directory /boot --boot-directory /boot"
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"

# 11 post-install
cat > /mnt/home/${USERNAME}/post-install.sh << EOF
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg PKGBUILD
pacman -U yay*.tar.zst --noconfirm
yay -Sy --noconfirm
yay -S alsa-utils bash-completion bleachbit bless bzip2 compton cronie cups curl dhcpcd dialog docker file-roller firefox gimp gnupg gparted grc gvfs-mtp gzip hashcat htop iftop iproute2 iptables irssi iw iwd jre8-openjdk keepassxc krita libreoffice-fresh mesa mtpfs netcat networkmanager-iwd nitrogen nmap noto-fonts ntfs-3g ntfsfixboot nvidia nvidia-utils lib32-nvidia-utils openbox openssh openvpn p7zip parted pcmanfm polybar qemu radare2 radare2-cutter redshift rsync rxvt-unicode screen shotwell slim sublime-text-dev tar tcpdump terminus-font tlp tmux tor tor-browser torsocks transmission-gtk ttf-dejavu ttf-droid ttf-fira-mono ttf-font-awesome ttf-inconsolata ufw unrar unzip virtualbox virtualbox-host-modules-arch vlc wget wireless_tools wireshark-gtk wpa_supplicant xf86-input-libinput xorg-apps xorg-server xz zip --noconfirm
ln -sf /opt/sublime_text_3/sublime_text /usr/bin/subl
sed -i '69s/^#default_user       simone/default_user       ${USERNAME}/' /etc/slim.conf
sed -i '77s/^#auto_login          no/^#auto_login          yes/' /etc/slim.conf
systemctl enable slim
alsactl store
netctl enable skynet
EOF

# 12 unmount
umount -R /mnt

# 13 reboot
echo -e "\n[+] Installation complete. Please restart the computer."

#!/bin/bash

pacman -S go --noconfirm
cd /home/${USERNAME}
git clone https://aur.archlinux.org/yay.git
chown -R ${USERNAME}:${USERNAME} yay
cd yay
sudo -u ${USERNAME} makepkg PKGBUILD
pacman -U yay*.zst --noconfirm

yay -Sy --noconfirm
yay -S aircrack-ng alsa-utils anydesk bash-completion bleachbit blender bless bzip2 compton cronie cups curl dhcpcd dialog docker dsniff file-roller firefox gdb gimp git gnupg gparted grc grub gvfs-mtp gzip hashcat htop ifplugd iftop iproute2 iptables irssi iw iwd jre8-openjdk keepassxc krita libreoffice-fresh mesa mtpfs netcat networkmanager-iwd nitrogen nmap noto-fonts ntfs-3g ntfsfixboot nvidia nvidia-utils lib32-nvidia-utils openbox openssh openvpn os-prober p7zip parted pcmanfm pidgin polybar popcorntime qemu radare2 radare2-cutter redshift rsync rxvt-unicode screen shotwell slim sublime-text-dev sudo tar tcpdump terminus-font tlp tmux tor tor-browser torsocks transmission-gtk ttf-dejavu ttf-droid ttf-fira-mono ttf-font-awesome ttf-inconsolata ufw unrar unzip vim virtualbox virtualbox-host-modules-arch vlc wget wireless_tools wireshark-gtk wpa_supplicant xf86-input-libinput xorg-apps xorg-server xz zip --noconfirm
ln -sf /opt/sublime_text_3/sublime_text /usr/bin/subl
sed -i '69s/^#default_user       simone/default_user       ${USERNAME}/' /etc/slim.conf
sed -i '77s/^#auto_login          no/^#auto_login          yes/' /etc/slim.conf
systemctl enable slim
alsactl store
netctl disable dhcpcd
netctl enable skynet

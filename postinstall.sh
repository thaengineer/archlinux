#!/usr/bin/bash
ESSID=""

arch-chroot /mnt /bin/bash -c "netctl disable dhcpcd"
arch-chroot /mnt /bin/bash -c "netctl enable ${ESSID}"
arch-chroot /mnt /bin/bash -c "netctl start ${ESSID}"

git clone https://aur.archlinux.org/yay.git
cd yay
makepkg PKGBUILD
sudo pacman -U *.xz --noconfirm
arch-chroot /mnt /bin/bash -c "pacman -Sy"
arch-chroot /mnt /bin/bash -c "yay -S aircrack-ng alsa-utils anydesk bash-completion bleachbit blender bless blueman bzip2 compton cronie cups curl dhcpcd dialog docker dsniff file-roller firefox gdb gimp git gnupg gparted grub gvfs-mtp gzip hashcat htop ifplugd iftop iproute2 iptables irssi iw jdk11-openjdk jre11-openjdk keepassxc krita libreoffice-fresh mesa mtpfs netcat nitrogen nmap noto-fonts ntfs-3g ntfsfixboot openbox openssh openvpn os-prober p7zip parted pcmanfm pidgin polybar popcorntime ppp qemu radare2 radare2-cutter redshift rsync rxvt-unicode screen shotwell slim sublime-text-dev sudo tar tcpdump terminus-font tlp tmux tor tor-browser-en-us torguard torsocks transmission-gtk ttf-dejavu ttf-droid ttf-fira-mono ttf-font-awesome ttf-inconsolata ufw unrar unzip vim virtualbox virtualbox-host-modules-arch vlc wget wireless_tools wireshark-gtk wpa_supplicant xf86-input-libinput xf86-input-synaptics xf86-video-intel xorg-apps xorg-server xorg-xinit xz zip --noconfirm"
sudo ln -s /opt/sublime_text_3/sublime_text /usr/bin/subl

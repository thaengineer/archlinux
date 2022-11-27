#!/usr/bin/env python
import sys
import subprocess as s


device    = ''
interface = ''
essid     = ''
wlanpass  = ''
hostname  = ''
rootpass  = ''
username  = ''
userpass  = ''
packages  = [
    'base',
    'base-devel',
    'linux',
    'linux-firmware',
    'grub',
    'efibootmgr',
    'sudo',
    'git',
    'go'
]
help = """
usage: install.py {-i|-p}
  -i, --install             Install base Arch Linux system
  -p, --post-install        Run post-installation tasks
"""


def install():
    print('[+] Connecting to network...')
    s.call(f'iwctl --passphrase {wlanpass} station {interface} connect {essid} psk', shell=True)

    print('[+] Wiping disk...')
    s.call(f'dd if=/dev/zero of=/dev/{device} status=progress', shell=True)

    print('[+] Creating patitions...')
    s.call(f'parted /dev/{device} mklabel gpt', shell=True)
    s.call(f'parted /dev/{device} mkpart primary fat32 0% 512MiB name 1 boot', shell=True)
    s.call(f'parted /dev/{device} mkpart primary ext4 512MiB 100% name 2 root', shell=True)
    s.call(f'parted /dev/{device} set 1 boot on', shell=True)

    print('[+] Formatting partitions...')
    s.call(f'mkfs.fat -F32 /dev/{device}1', shell=True)
    s.call(f'mkfs.ext4 -F /dev/{device}2', shell=True)

    print('[+] Mounting patitions...')
    s.call(f'mount /dev/{device}2 /mnt', shell=True)
    s.call('mkdir -p /mnt/boot', shell=True)
    s.call(f'mount /dev/{device}1 /mnt/boot', shell=True)

    print('[+] Enabling mirrors...')
    s.call("sed -i '92s/^#\[multilib\]/\[multilib\]/' /etc/pacman.conf", shell=True)
    s.call("sed -i '93s/^#Include/Include/' /etc/pacman.conf", shell=True)

    print('[+] Installing base...')
    s.call('pacman -Sy --noconfirm', shell=True)
    for package in packages:
        s.call(f'pacstrap -i /mnt {package} --noconfirm', shell=True)

    print('[+] Generating fstab...')
    s.call('genfstab -U -p /mnt >> /mnt/etc/fstab', shell=True)
    s.call("sed -i 's/rw,relatime/rw,noatime/g' /mnt/etc/fstab", shell=True)

    print('[+] Configuring network...')
    # cat > /mnt/etc/netctl/${ESSID} << EOF
    #${ESSID}
    #Interface=${IFACE}
    #Connection=wireless
    #Security=wpa
    #ESSID=${ESSID}
    #IP=dhcp
    #Key=${WLANPASS}
    #EOF
    # chmod 600 /mnt/etc/netctl/${ESSID}

    print('[+] Running chroot...')
    #arch-chroot /mnt /bin/bash -c "sed -i '93s/^#\[multilib\]/\[multilib\]/' /etc/pacman.conf"
    #arch-chroot /mnt /bin/bash -c "sed -i '94s/^#Include/Include/' /etc/pacman.conf"
    #arch-chroot /mnt /bin/bash -c "ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime"
    #arch-chroot /mnt /bin/bash -c "hwclock --systohc --utc"
    #arch-chroot /mnt /bin/bash -c "echo \"en_US.UTF-8 UTF-8\" > /etc/locale.gen"
    #arch-chroot /mnt /bin/bash -c "locale-gen"
    #arch-chroot /mnt /bin/bash -c "echo \"LANG=en_US.UTF-8\" > /etc/locale.conf"
    #arch-chroot /mnt /bin/bash -c "echo \"KEYMAP=us\" > /etc/vconsole.conf"
    #arch-chroot /mnt /bin/bash -c "echo \"${HOSTNAME}\" > /etc/hostname"
    #arch-chroot /mnt /bin/bash -c "echo \"# IPv4\" > /etc/hosts"
    #arch-chroot /mnt /bin/bash -c "echo \"127.0.0.1    localhost\" >> /etc/hosts"
    #arch-chroot /mnt /bin/bash -c "echo \"127.0.1.1    ${HOSTNAME}.localdomain ${HOSTNAME}\" >> /etc/hosts"
    #arch-chroot /mnt /bin/bash -c "echo \"\" >> /etc/hosts"
    #arch-chroot /mnt /bin/bash -c "echo \"# IPv6\" >> /etc/hosts"
    #arch-chroot /mnt /bin/bash -c "echo \"::1        localhost\" >> /etc/hosts"
    #arch-chroot /mnt /bin/bash -c "echo \"ff02::1    ip6-allnodes\" >> /etc/hosts"
    #arch-chroot /mnt /bin/bash -c "echo \"ff02::2    ip6-allrouters\" >> /etc/hosts"
    #arch-chroot /mnt /bin/bash -c "touch /etc/resolv.conf"
    #arch-chroot /mnt /bin/bash -c "mkinitcpio -p linux"
    #arch-chroot /mnt /bin/bash -c "echo -e \"${ROOTPASS}\n${ROOTPASS}\n\" | passwd"
    #arch-chroot /mnt /bin/bash -c "useradd -G users,wheel -m -p '07031991' -s /usr/bin/bash -U ${USERNAME}"
    #arch-chroot /mnt /bin/bash -c "grub-install --target=x86_64-efi --efi-directory /boot --boot-directory /boot"
    #arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"

    print('[+] Unmounting partitions...')
    s.call('umount -R /mnt', shell=True)

    print('[+] Install complete. Please reboot the system.')


def post_install():
    #cat > /mnt/home/${USERNAME}/post-install.sh << EOF
    #git clone https://aur.archlinux.org/yay.git
    #cd yay
    #makepkg PKGBUILD
    #pacman -U yay*.tar.zst --noconfirm
    #yay -Sy --noconfirm
    #yay -S alsa-utils bash-completion bleachbit bless bzip2 compton cronie cups curl dhcpcd dialog docker file-roller firefox gimp gnupg gparted grc gvfs-mtp gzip hashcat htop iftop iproute2 iptables irssi iw iwd jre8-openjdk keepassxc krita libreoffice-fresh mesa mtpfs netcat networkmanager-iwd nitrogen nmap noto-fonts ntfs-3g ntfsfixboot nvidia nvidia-utils lib32-nvidia-utils openbox openssh openvpn p7zip parted pcmanfm polybar qemu radare2 radare2-cutter redshift rsync rxvt-unicode screen shotwell slim sublime-text-dev tar tcpdump terminus-font tlp tmux tor tor-browser torsocks transmission-gtk ttf-dejavu ttf-droid ttf-fira-mono ttf-font-awesome ttf-inconsolata ufw unrar unzip virtualbox virtualbox-host-modules-arch vlc wget wireless_tools wireshark-gtk wpa_supplicant xf86-input-libinput xorg-apps xorg-server xz zip --noconfirm
    #ln -sf /opt/sublime_text_3/sublime_text /usr/bin/subl
    #sed -i '69s/^#default_user       simone/default_user       ${USERNAME}/' /etc/slim.conf
    #sed -i '77s/^#auto_login          no/^#auto_login          yes/' /etc/slim.conf
    #systemctl enable slim
    #alsactl store
    #netctl enable skynet
    #EOF


def main():
    if '-i' in sys.argv[1]:
        install()
    elif '-p' in sys.argv[1]:
        post_install()
    else:
        print(f'{help}')


if __name__ == '__main__':
    main()

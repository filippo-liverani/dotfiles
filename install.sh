#!/bin/bash

set -e

if (( EUID != 0 )); then
   echo "You must be root to do this." 1>&2
   exit 100
fi

#user

useradd -m -g users -G wheel -s /bin/bash filippo
chown -R filippo.users /home/filippo

#packages

dhcpcd

tee -a /etc/pacman.conf <<< "
[archlinuxfr]
SigLevel = Optional
Server = http://repo.archlinux.fr/\$arch"

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
sed '/^#\S/ s|#||' -i /etc/pacman.d/mirrorlist.backup
rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
rm /etc/pacman.d/mirrorlist.backup

pacman-key --init
pacman-key --populate archlinux
pacman-key --refresh-keys
pacman --noconfirm -Syu
pacman --noconfirm -S sudo yaourt powerpill

sed "s|/usr/bin/pacman|/usr/bin/yaourt|" -i /etc/powerpill/powerpill.json

tee -a /etc/sudoers <<< "
filippo ALL=(ALL) ALL"

BASE_PACKAGES="pacmatic linux-lts base-devel openssh openssl unrar unzip zsh \
              cups parted git htop colordiff dfc cdu wicd dhclient b43-firmware \
              alsa-lib alsa-oss alsa-utils lib32-alsa-lib pulseaudio  pulseaudio-alsa lib32-libpulse lib32-alsa-plugins \
              gstreamer0.10-plugins gstreamer0.10-base-plugins gstreamer0.10-good-plugins gstreamer0.10-bad-plugins \
              xorg-server xorg-apps xorg-xinit xorg-server-utils xf86-video-nouveau xf86-video-intel xf86-video-ati xf86-input-synaptics xclip \
              slim slim-themes archlinux-themes-slim xfce4 xfce4-goodies xfce4-screenshooter xfce4-mixer thunar-volman gvfs gvfs-smb gksu file-roller evince\
              zukitwo-themes faenza-icon-theme faenza-xfce-addon ttf-dejavu artwiz-fonts xcursor-vanilla-dmz lib32-gtk2 \
              wicd-gtk pavucontrol keepassx kupfer simple-scan inkscape gimp gcolor3 gvim python-powerline-git leafpad parole skype hotot-gtk3 \
              chromium google-talkplugin chromium-pepper-flash-stable"
DEV_PACKAGES="tmux ruby ruby-tmuxinator wemux-git vagrant dstat iotop the_silver_searcher subversion eclipse \
              virtualbox virtualbox-host-modules virtualbox-guest-iso virtualbox-ext-oracle"

su - filippo -c "yaourt --noconfirm -Syu"
su - filippo -c "yaourt --noconfirm -S $BASE_PACKAGES"
if [ "$1" == "dev" ]
  then
    su - filippo -c "yaourt --noconfirm -S $DEV_PACKAGES"
fi
  
#wicd

gpasswd -a filippo network
systemctl enable wicd.service

#pacman

tee -a /etc/yaourtrc <<< 'PACMAN="pacmatic"'

#performance

tee -a /etc/sysctl.d/99-sysctl.conf <<< "
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
vm.vfs_cache_pressure = 50
vm.laptop_mode = 1
vm.swappiness = 10
kernel.shmmax=17179869184
kernel.shmall=4194304
fs.inotify.max_user_watches = 524288"

#zsh

chsh -s $(which zsh) filippo

#slim

tee -a /etc/slim.conf <<< "
default_user filippo
auto_login yes"
tee -a /home/filippo/.xinitrc <<< "exec startxfce4"
systemctl enable slim.service

if [ "$1" == "dev" ]
  then
    #virtualbox
   
    gpasswd -a filippo vboxusers
    tee /etc/modules-load.d/virtualbox.conf <<< "vboxdrv"
    modprobe vboxdrv
   
    #ruby
   
    tee /etc/gemrc <<< "
    gem: --no-ri --no-rdoc"
    gem update --system    
fi


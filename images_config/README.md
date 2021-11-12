
# StickSetup Generation

## Contents

1. <a href="#Create Custom ISO File">Create Custom ISO File</a>
2. <a href="#Create Bootable Media">Create Bootable Media</a>
3. <a href="#Cleanup">Cleanup</a>

## Create Custom ISO File <a id="Create Custom ISO File"/>
#### Ubuntu 20.04
Download latest Ubuntu Server 20.04.1 from Ubuntu website (https://ubuntu.com/download/server).
(Currently, the setup only works with [Ubuntu Server 20.04.1](http://old-releases.ubuntu.com/releases/20.04.1/ubuntu-20.04.1-live-server-amd64.iso)!)

Make sure you have `setup_cob4` cloned into `~/git/setup_cob4`.

Then perform the following steps:
```
mkdir -p ~/sticksetup/focal/ubuntu_iso
sudo  mount -r -o loop ~/Downloads/ubuntu-20.04.1-live-server-amd64.iso ~/sticksetup/focal/ubuntu_iso # cancel mount screen
cp -r ~/sticksetup/focal/ubuntu_iso ~/sticksetup/focal/ubuntu_files
chmod +w -R ~/sticksetup/focal/ubuntu_files
git clone https://github.com/ipa320/setup_cob4 ~/sticksetup/focal/ubuntu_files/setup_cob4 #(or copy feature branch via `cp -rf ~/git/setup_cob4 ~/sticksetup/focal/ubuntu_files`)
cp -f ~/sticksetup/focal/ubuntu_files/setup_cob4/images_config/boot/grub/grub.cfg ~/sticksetup/focal/ubuntu_files/boot/grub/grub.cfg
cp -f ~/sticksetup/focal/ubuntu_files/setup_cob4/images_config/isolinux/txt-20.04.cfg ~/sticksetup/focal/ubuntu_files/isolinux/txt.cfg # for legacy boot compatibility
```

## Create Bootable Media <a id="Create Bootable Media"/>
#### Ubuntu 20.04
```
sudo apt-get install syslinux-utils
mkisofs -o ~/sticksetup/ubuntu-20.04-care-o-bot.iso -V "Ubuntu-20.04-Care-O-bot" -r -l -J -ldots -allow-multidot -cache-inodes -d -D -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot ~/sticksetup/focal/ubuntu_files
isohybrid --uefi ~/sticksetup/ubuntu-20.04-care-o-bot.iso
```

Plugin USB Stick and create startup disk, e.g. using `etcher` (see https://etcher.io/).

## Cleanup <a id="Cleanup"/>
#### Ubuntu 20.04
```
sudo umount ~/sticksetup/focal/ubuntu_iso
rm -rf ~/sticksetup/focal/ubuntu_iso
rm -rf ~/sticksetup/focal/ubuntu_files
```

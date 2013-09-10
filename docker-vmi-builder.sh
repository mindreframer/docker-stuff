#!/bin/bash
# Docker VMI (Virtual Machine Image) Builder
# Copyright (c) 2013 Fatih Cetinkaya (http://github.com/cmfatih/docker-vmi-builder)
# For the full copyright and license information, please view the LICENSE.txt file.

# Init reqs
sudo echo "$(date): Begin"

# Init vars
DOCKER_ISO_FILE="docker-vmi-iso.iso"
DOCKER_VMI_FILE="docker-vmi-img.img"
DOCKER_TMP_FOLDER="docker-vmi-temp"
UBUNTU_ISO_FILE="ubuntu-12.04.2-server-amd64.iso"
UBUNTU_ISO_URL="http://releases.ubuntu.com/precise/$UBUNTU_ISO_FILE"
UBUNTU_PKGS="qemu-system rsync genisoimage"

# Check packages
echo "$(date): Checking required packages... ($UBUNTU_PKGS)"
sudo apt-get update -qq && sudo apt-get install -y -qq $UBUNTU_PKGS

# Download Ubuntu
if [ ! -f $UBUNTU_ISO_FILE ]; then
  echo "$(date): Downloading Ubuntu ISO file... ($UBUNTU_ISO_FILE)"
  wget $UBUNTU_ISO_URL
fi

# Init folders and files
echo "$(date): Initializing required folders and files..."
rm -f $DOCKER_ISO_FILE
rm -f $DOCKER_VMI_FILE
rm -rf $DOCKER_TMP_FOLDER
mkdir -p $DOCKER_TMP_FOLDER
mkdir -p $DOCKER_TMP_FOLDER/iso-orig
mkdir -p $DOCKER_TMP_FOLDER/iso-copy
cd $DOCKER_TMP_FOLDER

# Mount and init ISO
echo "$(date): Mounting ISO file... ($UBUNTU_ISO_FILE)"
sudo mount -o loop ../$UBUNTU_ISO_FILE ./iso-orig
echo "$(date): Duplicating files..."
rsync -a ./iso-orig/ ./iso-copy
chmod -R u+w ./iso-copy/isolinux
chmod -R u+w ./iso-copy/preseed

# Update config file (isolinux.cfg)
# References: https://help.ubuntu.com/community/LiveCDCustomizationFromScratch
echo "$(date): Updating isolinux.cfg file..."
cp ./iso-copy/isolinux/isolinux.cfg ./iso-copy/isolinux/isolinux.cfg-default
echo "# Config for unattended installation (docker-vmi-builder)
prompt 0
default install
label install
    menu label ^Install Ubuntu for docker-vmi-builder
    kernel /install/vmlinuz
    append file=/cdrom/preseed/ubuntu-server-minimalvm.seed console-setup/ask_detect=false locale=en_US.UTF-8 keyboard-configuration/layoutcode=us initrd=/install/initrd.gz quiet --
" > ./iso-copy/isolinux/isolinux.cfg

# Update preseed file (ubuntu-server-minimalvm.seed)
# References: https://help.ubuntu.com/lts/installation-guide/amd64/preseed-contents.html
#             https://help.ubuntu.com/12.04/installation-guide/example-preseed.txt
echo "$(date): Updating ubuntu-server-minimalvm.seed file..."
cp ./iso-copy/preseed/ubuntu-server-minimalvm.seed ./iso-copy/preseed/ubuntu-server-minimalvm.seed-default
echo "

# Preseed for unattended installation (docker-vmi-builder)

# User account
d-i passwd/user-fullname string Docker User
d-i passwd/username string docker
d-i passwd/user-password password docker
d-i passwd/user-password-again password docker
d-i user-setup/allow-password-weak boolean true
d-i passwd/user-default-groups string audio cdrom video adm sudo
d-i user-setup/encrypt-home boolean false

# Time zone
d-i clock-setup/utc boolean true
d-i time/zone string US/Eastern

# Partitioning
d-i partman-auto/method string regular
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

# Networking
d-i netcfg/get_hostname string ubuntu

# Mirror
d-i mirror/country string manual
d-i mirror/http/hostname string archive.ubuntu.com
d-i mirror/http/directory string /ubuntu
d-i mirror/http/proxy string

# Apt setup
d-i apt-setup/local0/repository string http://ppa.launchpad.net/dotcloud/lxc-docker/ubuntu precise main
d-i apt-setup/local0/comment string Docker PPA
d-i apt-setup/local0/source boolean true
d-i apt-setup/local0/key string http://keyserver.ubuntu.com:11371/pks/lookup?search=0x086727ee13663dc76ebf7e1fe61d797f63561dc6&op=get

# Packages
tasksel tasksel/first multiselect openssh-server
d-i pkgsel/include string python-software-properties lxc-docker

# Boot loader
d-i grub-installer/only_debian boolean true

# Finishing up the installation
d-i finish-install/reboot_in_progress note
d-i debian-installer/exit/poweroff boolean true

# Misc
d-i pkgsel/update-policy select none
d-i pkgsel/updatedb boolean false

" >> ./iso-copy/preseed/ubuntu-server-minimalvm.seed

# Update permissions
#echo "$(date): Updating permissions..."
#sudo chown -R root:root ./iso-copy/

# Create ISO file
echo "$(date): Creating new ISO file... ($DOCKER_ISO_FILE)"
genisoimage -quiet -r -V "docker-vmi-iso" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o $DOCKER_ISO_FILE iso-copy

# Create VMI
echo "$(date): Creating new VMI file... ($DOCKER_VMI_FILE qcow2 8G)"
qemu-img create -f qcow2 $DOCKER_VMI_FILE 8G

# Unmount ISO and initialize folders and files
echo "$(date): Unmounting ISO... ($UBUNTU_ISO_FILE)"
sudo umount ./iso-orig/
echo "$(date): Moving new ISO ($DOCKER_ISO_FILE) and VMI ($DOCKER_VMI_FILE) files..."
mv ./$DOCKER_ISO_FILE ../$DOCKER_ISO_FILE
mv ./$DOCKER_VMI_FILE ../$DOCKER_VMI_FILE
cd ..
echo "$(date): Removing temporary folder... ($DOCKER_TMP_FOLDER)"
sudo rm -rf $DOCKER_TMP_FOLDER

echo "$(date): Creating VMI... (The process can be monitor with a VNC client. (5/5905))"
sudo qemu-system-x86_64 -enable-kvm -m 1024 -hda $DOCKER_VMI_FILE -cdrom $DOCKER_ISO_FILE -boot d -display none -usbdevice tablet -vnc :5,docker

# Done!
echo "$(date): End"

# for tests
#
# Checking ISO
#   sudo qemu-system-x86_64 -enable-kvm -m 1024 -cdrom docker-vmi-iso.iso -boot d -display none -usbdevice tablet -vnc :5,docker
# Creating VMI
#   qemu-img create -f qcow2 docker-vmi-img.img 8G
#   sudo qemu-system-x86_64 -enable-kvm -m 1024 -hda docker-vmi-img.img -cdrom docker-vmi-iso.iso -boot d -display none -usbdevice tablet -vnc :5,docker
# Running VM
#   Linux:  sudo qemu-system-x86_64 -enable-kvm -m 1024 -hda docker-vmi-img.img -display none -usbdevice tablet -vnc :5,docker -net user,hostfwd=tcp:127.0.0.1:8022-:22 -net nic -daemonize
#   Win:    qemu-system-x86_64w.exe -L Bios -hda docker-vmi-img.img -net user,hostfwd=tcp:127.0.0.1:8022-:22 -net nic

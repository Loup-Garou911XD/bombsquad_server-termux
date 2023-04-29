#! /bin/bash

setup_storage(){
#output isn't getting stored in variable but thats a future me problem
yes|output=$(termux-setup-storage 2>&1) && 
output=$(ln -s /storage/emulated/0 /data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu/root/storage 2>&1)
}

#pkg update &&
#pkg upgrade -y &&
#pkg install proot-distro -y &&

read -p "
This will give termux permission to access your storage and allow you to access it inside proot-distro.

Do you want to Setup storage?(y/n):" setup_storage_yn
case $setup_storage_yn in
    y|Y|yes|Yes|YES) setup_storage;
esac

output=$(proot-distro install ubuntu 2>&1)
if [[ $output == *"is already installed"* ]]
then
    echo
    echo "Ubuntu already installed, skipping!"
else
    echo $output
fi

login_cmd="proot-distro login ubuntu"
bashrc="/data/data/com.termux/files/usr/etc/bash.bashrc"
if grep -Fxq "$login_cmd" $bashrc
then
    echo already there
else
    echo $login_cmd>>$bashrc
fi

#updating ubuntu
proot-distro login ubuntu -- apt update && apt upgrade

read -p "Install python3.10 ?(y/n):" install_python_yn
case $install_python_yn in
    y|Y|yes|Yes|YES) proot-distro login ubuntu -- apt install python3.10-dev -y;
esac


echo 
echo "Finished! Restart termux to login into ubuntu"

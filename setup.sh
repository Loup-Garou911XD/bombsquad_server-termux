#! /bin/bash

log_file="/data/data/com.termux/files/home/bombsquad_setup.log"
echo "beginning">$log_file

setup_storage(){
yes|output=$(termux-setup-storage 2>>/dev/null) && 
output=$(ln -s /storage/emulated/0 /data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu/root/storage 2>>/dev/null)
}

#downloads and extracts the latest bombsquad server build for arm64
get_latest_server_build(){
raw_get_latest_link="https://raw.githubusercontent.com/Loup-Garou911XD/bombsquad_server-termux/main/get_latest_link.py"
curl -so get_latest_link.py $raw_get_latest_link

latest_server_build_link=$(proot-distro login ubuntu --termux-home -- python3 get_latest_link.py 2>/dev/null)
proot-distro login ubuntu -- curl -s $latest_server_build_link -o bs_server.tar.gz
proot-distro login ubuntu -- tar -xzf bs_server.tar.gz
}

$(apt-get update &>>$log_file)
$(apt-get upgrade -y &>>$log_file)
$(apt-get install proot-distro -y &>>$log_file)

#installing proot-distro ubuntu
output=$(proot-distro install ubuntu 2>&1)
if [[ $output == *"is already installed"* ]]
then
    echo
    echo "Ubuntu already installed, skipping!"
else
    echo $output
fi

#setup to access storage in proot-distro
read -p "This will give termux permission to access your storage and allow you to access it inside proot-distro.
Do you want to Setup storage(y/n):" setup_storage_yn
case $setup_storage_yn in
    y|Y|yes|Yes|YES) setup_storage;
esac

#adding ubuntu login cmd to bash.bashrc 
login_cmd="proot-distro login ubuntu"
bashrc="/data/data/com.termux/files/usr/etc/bash.bashrc"
if grep -Fxq "$login_cmd" $bashrc
then
    true
else
    echo $login_cmd>>$bashrc
fi

#updating ubuntu
output=$(proot-distro login ubuntu &>>$log_file -- apt-get update && apt-get upgrade -y)

#install python3.10?
read -p "Install python3.10(y/n):" install_python_yn
case $install_python_yn in
    y|Y|yes|Yes|YES) $(proot-distro login ubuntu -- apt-get install python3.10-dev -y &>>$log_file);
esac
5
#download latest server?
read -p "Get latest bombsquad server(y/n):" get_latest_server_yn
case $install_python_yn in
    y|Y|yes|Yes|YES) get_latest_server_build;
esac


echo "Finished! Restart termux to login into ubuntu"


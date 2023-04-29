#! /bin/bash

termux_home="/data/data/com.termux/files/home/"
download_link_file=".latest_bombsquad_server_download_ln"
log_file="/data/data/com.termux/files/home/bombsquad_setup.log"
root_fs="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu/"
echo "beginning">$log_file
raw_get_latest_link="https://raw.githubusercontent.com/Loup-Garou911XD/bombsquad_server-termux/main/get_latest_link.py"

#colors
clear="\033[0m"
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
purple="\033[35m"
cyan="\033[36m"

update_ssl_certificate(){
$(proot-distro login ubuntu -- apt-get install -y ca-certificates &>/dev/null)
$(proot-distro login ubuntu -- update-ca-certificates &>/dev/null)
}

setup_storage(){
yes|output=$(termux-setup-storage 2>>/dev/null) && 
output=$(ln -s /storage/emulated/0 /data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu/root/storage 2>>/dev/null)
}

#downloads and extracts the latest bombsquad server build for arm64
get_latest_server_build(){
curl -so get_latest_link.py $raw_get_latest_link
proot-distro login ubuntu --termux-home -- python3.10 get_latest_link.py

curl -s $(cat $download_link_file) -o $root_fs/root/bs_server.tar.gz &&
tar -xzf $root_fs/root/bs_server.tar.gz -C $root_fs/root/
}

printf "${green}Installing proot-distro${clear}\n"
$(apt-get update &>>$log_file)
yes|$(apt-get upgrade -y &>>$log_file)
$(apt-get install proot-distro -y &>>$log_file)

#installing proot-distro ubuntu
printf "${green}Installing ubuntu in proot-distro${clear}\n"
$(proot-distro install ubuntu &>$log_file)

#updating ubuntu
printf "${green}Updating ubuntu${clear}\n"
output=$(proot-distro login ubuntu &>>$log_file -- apt-get update && apt-get upgrade -y)

#updating CA certificates
printf "${green}Updating ubuntu CA certificates${clear}\n"
update_ssl_certificate

#writing a valid value to /etc/machine-id
printf "${green}Making /etc/machine-id in ubuntu${clear}\n"
echo "10666fee-0108-3264-1000-beef10de1667">$root_fs/etc/machine-id

#setup to access storage in proot-distro
printf "${blue}Setting up storage will give termux permission to access your storage and allow you to access it inside proot-distro.\nDo you want to Setup storage${clear}(y/n):"-
read setup_storage_yn
case $setup_storage_yn in
    y|Y|yes|Yes|YES) setup_storage;
esac

#adding ubuntu login cmd to bash.bashrc 
printf "${green}Adding login command to termux bashrc${clear}\n"
login_cmd="proot-distro login ubuntu"
bashrc="/data/data/com.termux/files/usr/etc/bash.bashrc"
if grep -Fxq "$login_cmd" $bashrc
then
    true
else
    echo $login_cmd>>$bashrc
fi

#install python3.10?
printf "${blue}Install python3.10${clear}(y/n):" 
read install_python_yn
case $install_python_yn in
    y|Y|yes|Yes|YES) printf "${green}Installing python3.10${clear}\n"; 
		     $(proot-distro login ubuntu -- apt-get install python3.10-dev -y &>>$log_file);
esac

#download latest server?
printf "${blue}Get latest bombsquad server${clear}(y/n):" 
read get_latest_server_yn
case $get_latest_server_yn in
    y|Y|yes|Yes|YES) printf "${green}Downloading bombsquad server${clear}\n" ;
		     get_latest_server_build;
esac

printf "${cyan}Finished!${clear}\n"
proot-distro login ubuntu


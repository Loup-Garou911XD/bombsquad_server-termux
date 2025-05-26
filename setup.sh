#!/bin/bash

python_version="3.13"
python_version_name="python${python_version}"
termux_home="/data/data/com.termux/files/home/"
termux_bashrc="/data/data/com.termux/files/usr/etc/bash.bashrc"
download_link_file=".latest_bombsquad_server_download_ln"
root_fs="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu"
raw_art_link="https://raw.githubusercontent.com/Loup-Garou911XD/bombsquad_server-termux/main/ansi_art.txt"
raw_get_latest_link="https://raw.githubusercontent.com/Loup-Garou911XD/bombsquad_server-termux/main/get_latest_link.py"
log_file="/data/data/com.termux/files/home/bombsquad_setup.log"
echo "beginning">$log_file

#colors
clear="\033[0m"
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
purple="\033[35m"
cyan="\033[36m"

load_animation=( '•....' '.•...' '..•..' '...•.' '....•' '...•.' '..•..' '.•...' '•....' )
load_animation2=( ' ↑↓' ' ↓↑' )
load_animation3=( ' ↑' ' ↓')
load_animation4=(  ' >' ' >>' ' >>>' ' >>>>' ' >>>>>' ' >>>>' ' >>>' ' >>' ' >' ' ' '     <' '    <<' '   <<<' '  <<<<' ' <<<<<' '  <<<<' '   <<<' '    <<' '     <' )

trap interrupt_handler SIGINT
interrupt_handler(){
	kill -KILL $$
}

animate(){
    printf "${purple}"
    while true
    do
        for i in "${load_animation4[@]}"
        do
            echo -ne "$i\033[K\r"
            sleep 0.2
        done
	done
    printf "${clear}"
}

with_animation(){
    animate &
    pid=$!
    eval "$1" &>>$log_file
    kill $pid &>>$log_file
}

run_in_proot(){
    proot-distro login ubuntu -- bash -c "$1"
}

update_ssl_certificate(){
    run_in_proot 'export DEBIAN_FRONTEND=noninteractive && apt-get install -y ca-certificates'
    run_in_proot 'export DEBIAN_FRONTEND=noninteractive && update-ca-certificates'
}
add_deadsnakes(){
    run_in_proot 'export DEBIAN_FRONTEND=noninteractive && apt-get install -y software-properties-common'
    run_in_proot 'export DEBIAN_FRONTEND=noninteractive && add-apt-repository ppa:deadsnakes/ppa -y'
}

proot_install_python(){
    run_in_proot 'export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y ${python_version_name}-dev'
}

setup_storage(){
    yes|termux-setup-storage &>>$log_file
    ln -s /storage/emulated/0 /data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu/root/storage &>>$log_file
}


#downloads and extracts the latest bombsquad server build for arm64
get_latest_server_build(){
    curl -so get_latest_link.py $raw_get_latest_link &&
    proot-distro login ubuntu --termux-home -- ${python_version_name} get_latest_link.py
    curl $(cat $download_link_file) -o $root_fs/root/bs_server.tar.gz &>>$log_file &&
    tar -xzf $root_fs/root/bs_server.tar.gz -C $root_fs/root/
}

check_cpu_architecture(){
    if uname -m | grep -q 'aarch64'
    then
        printf "${green}CPU check succeeded!${clear}\n"
    else
        printf "${red}+-+-Unsupported cpu architecture $(uname -m) ${clear}\n">>$log_file
        printf "${red}Unsupported cpu architecture detected, do you still wish to continue(y/n):${clear}\n"
        read -r continue_unsupported_architecture_yn
        case $continue_unsupported_architecture_yn in
            y|Y|yes|Yes|YES)
            printf "${green}continuing on unsupported architecture...${clear}\n"
                ;;
            * )
            printf "${yellow}Exitting${clear}\n" ;
            exit 0
            ;;
        esac
    fi
}

update_termux(){
    apt update &>>$log_file
    apt upgrade -o Dpkg::Options::="--force-confnew" -y &>>$log_file
    apt update &>>$log_file
}


update_ubuntu(){
    run_in_proot 'export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get upgrade -y'
}

#getting and printing art
echo ""
curl -s $raw_art_link

#cpu architecture check
printf "${red}+-+-Checking CPU architecture${clear}\n">>$log_file
printf "${green}Checking CPU architecture${clear}\n"
check_cpu_architecture

#updating termux
printf "${red}+-+-Updating Termux packages${clear}\n">>$log_file
printf "${green}Updating Termux packages${clear}\n"
with_animation "update_termux"

#installing proot-distro
printf "${red}+-+-Installing proot-distro${clear}\n">>$log_file
printf "${green}Installing proot-distro${clear}\n"
with_animation "\$(apt-get install proot-distro -y)"

#installing proot-distro ubuntu
printf "${red}+-+-Installing proot-distro Ubuntu${clear}\n">>$log_file
printf "${green}Installing proot-distro Ubuntu${clear}\n"
with_animation "\$(proot-distro install ubuntu)"

#updating ubuntu
printf "${red}+-+-Updating ubuntu packages${clear}\n">>$log_file
printf "${green}Updating ubuntu packages${clear}\n"
with_animation "update_ubuntu"

#updating CA certificates
printf "${red}+-+-Updating ubuntu CA certificates${clear}\n">>$log_file
printf "${green}Updating ubuntu CA certificates${clear}\n"
with_animation "update_ssl_certificate" #this is a function,not a command

#add deadsnakes-ppa
printf "${red}+-+-Adding Deadsnakes-ppa${clear}\n">>$log_file
printf "${green}Adding Deadsnakes-ppa${clear}\n"
with_animation "add_deadsnakes"

#writing a valid value to /etc/machine-id
printf "${red}+-+-Making /etc/machine-id in ubuntu${clear}\n">>$log_file
printf "${green}Making /etc/machine-id in ubuntu${clear}\n"
test -f $root_fs/etc/machine-id || proot-distro login ubuntu -- uuidgen>$root_fs/etc/machine-id

#adding ubuntu login cmd to bash.bashrc
printf "${red}+-+-Adding login commands to termux bashrc at ~/../usr/etc/bash.bashrc${clear}\n">>$log_file
printf "${green}Adding login command to termux bashrc\n"
login_cmd="proot-distro login ubuntu"
if grep -Fxq "$login_cmd" $termux_bashrc
then
    true
else
    printf "clear\n$login_cmd">>$termux_bashrc
fi

#setup to access storage in proot-distro
printf "${red}+-+-Setup up storage?${clear}\n">>$log_file
printf "${blue}Setting up storage will give termux permission to access your storage and allow you to access it inside proot-distro.\nDo you want to Setup storage${clear}(y/n):"
read -r setup_storage_yn
case $setup_storage_yn in
    y|Y|yes|Yes|YES )
        with_animation "setup_storage" ;;
    * )
	printf "${yellow}Skipping${clear}\n";
esac

#install python?
printf "${red}+-+-Install ${python_version_name}?${clear}\n">>$log_file
printf "${blue}Install ${python_version_name}${clear}(y/n):"
read -r install_python_yn
case $install_python_yn in
    y|Y|yes|Yes|YES)
	printf "${green}Installing ${python_version_name}${clear}\n" ;
	    with_animation "proot_install_python" ;;
    * )
	printf "${yellow}Skipping${clear}\n";
esac

#download latest server?
printf "${red}+-+-Get latest bs version?${clear}\n">>$log_file
printf "${blue}Get latest bombsquad server${clear}(y/n):"
read -r get_latest_server_yn
case $get_latest_server_yn in
    y|Y|yes|Yes|YES)
	printf "${green}Downloading bombsquad server${clear}\n" ;
        with_animation "get_latest_server_build" ;;
    * )
	printf "${yellow}Skipping${clear}\n";
esac

printf "${cyan}Finished!${clear}\n"
printf "${cyan}Finished!${clear}\n">>$log_file
proot-distro login ubuntu



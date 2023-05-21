#!/bin/bash

# this file shall be copied into workdir during building the docker image

VERBOSE=0
PKGFILE="./include.pkg"
USERFILE="./user.dat"
PIP3FILE="./include.pip3.pkg"

verbose(){
    [ $VERBOSE -eq 1 ] && echo "$1"
}

fexist_or_exit(){
    if [ ! -f "$1" ]; then
    verbose "Error! File $1 is not exist." 
    exit 1; 
    fi
}

create_user(){
    local id=$1
    local pw=$2
    useradd -rm -d /home/$id -s $SHELL -g root -G sudo $id
    local tmpfile=`mktemp`
    echo "$id:$pw" > $tmpfile
    chpasswd -c SHA512 < $tmpfile && rm -f $tmpfile

    mkdir -p /home/$id/.ssh
    mkdir -p /home/$id/.vscode 
    mkdir -p /home/$id/.vscode-server
    chown $id /home/$id/.ssh
    chown $id /home/$id/.vscode
    chown $id /home/$id/.vscode-server
}



while getopts "v" opt
do
    case $opt in 
        "v")
            VERBOSE=1
            ;;
        ?)
            echo "$0 [-v]"
            exit 1
            ;;
    esac
done

fexist_or_exit $PKGFILE
fexist_or_exit $USERFILE

cat $USERFILE | while read -r line; do
    verbose "parsing $USERFILE where $line"
    user=($(echo $line|tr ":" "\n"))
    if [ ${#user[@]} -ne 2 ]; then 
        verbose "Warnning! Syntax error: $line"
    else
        create_user ${user[0]} ${user[1]}
        if [ -f "/ssh_key_busydocker.pub" ]; then
            cat /ssh_key_busydocker.pub >> /home/${user[0]}/.ssh/authorized_keys
        fi
    fi
done

cat $PKGFILE | uniq | while read line; do 
    DEBIAN_FRONTEND=noninteractive apt-get install -yq $line
done

if [ -f $PIP3FILE ]; then
    cat $PIP3FILE | uniq | while read line; do 
        pip3 install $line
    done
fi

#allow remote ssh login
sed -i "s/#Port.*/Port 22/" /etc/ssh/sshd_config && \
sed -i "s/#X11UseLocalhost.*/X11UseLocalhost no/" /etc/ssh/sshd_config && \
sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config && \
sed -i "s/#PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config


mkdir /var/run/sshd


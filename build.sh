#!/bin/bash

VERBOSE=false
CMDCOUNT=0
BUILD=false
RUN=false
PRUNE=false

verbose(){
     $VERBOSE && echo "$1"
}


usage(){
    echo "$0 [--build|--help|--run|--prune] [--verbose]"
    exit 1
}

check_yesNo(){
    local _key
    local _opt
    echo -n $1
    read _key
    _opt=$(tr '[:lower:]' '[:upper:]' <<< "$_key")
    _opt="${_opt:0:1}"
    if [ "$_opt" == "Y" ]; then return 1; 
    else return 0; fi
}

gen_key_ifneeded(){
    check_yesNo "Do you want no-password login?[y/N]"
    if [ "$?" == "1" ]; then
        verbose "Creating ssh key for no-password login"
        ssh-keygen -f ssh_key_busydocker -N ''
        cp ssh_key_busydocker* ~/.ssh/
    fi
}
del_gen_key(){
    if [ -f ssh_key_busydocker.pub ]; then 
        rm -f ssh_key_busydocker*
    fi
}

while true; do
  case "$1" in
    --verbose ) VERBOSE=true;  shift ;;
    --build ) BUILD=true; ((CMDCOUNT++)); shift ;;
    --run ) RUN=true; ((CMDCOUNT++)); shift ;;
    --prune ) PRUNE=true; ((CMDCOUNT++)); shift ;;
    --help ) usage; break ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

if [ $CMDCOUNT -gt 1 ]; then
    echo "Error! More than one command is assigned"
    exit 1
elif [ $CMDCOUNT -eq 0 ]; then usage;
fi



if $BUILD ; then
    verbose "Start building docker image..."
    gen_key_ifneeded

    docker build . -f Dockerfile.ssh -t busydocker:latest
    
    del_gen_key
    
elif  $RUN ; then
    verbose "Run docker image as busydocker_inst"
    docker run -p 22:22 --name busydocker_inst -e DISPLAY=docker.for.mac.host.internal:0 -v vscode-server:/home/$WHOAMI/.vscode-server -d busydocker:latest
else # do prune
    docker container stop busydocker_inst
    docker container prune
    docker image rm busydocker:latest
fi


#!/bin/bash

########################
# VARIABLES
########################
SYS="ACTORFLASKS"
HOMEDIR=$PWD
if [[ "$HOMEDIR" == */scripts* ]]; then
    HOMEDIR="$(dirname "$PWD")"
fi
echo "Home folder: $HOMEDIR"
PEERSFILE=$HOMEDIR/config/peer_list

#VARIABLES FOR REMOTE INSTALLATION


########################
# INSTALLATION MODES
#   "-r" for installing the code in GSD remote machines
#   "-l" for installing the code in the local machine
########################

while getopts "rl" opt; do
    case "$opt" in

    r)
    echo "====================================="
    echo "INSTALLING ${SYS} REMOTELLY"
    echo "====================================="
    DEPLOYDIR=""
    key=""
    SSHCMDNODE="ssh -l gsd -i ${key}"
    SCPCMDNODEDIR="scp -r -i ${key}"
    SCPCMDNODEFILE="scp -i ${key}"
    SCPREMOTEUSER=""
    ;;

    l)
    echo "====================================="
    echo "INSTALLING ${SYS} LOCALLY"
    echo "====================================="
    DEPLOYDIR="${HOMEDIR}/deploy"
    mkdir $DEPLOYDIR;
    cd $DEPLOYDIR

    # READ LIST OF PEERS
    echo "Reading list of peers from $PEERSFILE"
    while IFS='' read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^#.*$ ]] && continue
        a=( $line )
        id=${a[0]}
        ip=${a[1]}
        port=${a[2]}
        printf "\n>> CONFIGURING PEER ${id} (${ip}:${port})\n"
        mkdir $id
    done < "$PEERSFILE"

    # INSTALL MAVEN
    printf "\n>> INSTALLING SBT\n"
    if hash sbt 2>/dev/null; then
        echo "SBT already installed!"
    else
        # This only works for linux
        sudo apt-get install -y sbt
    fi

    # INSTALL SCREEN
    printf "\n>> INSTALLING SCREEN\n"
    if hash screen 2>/dev/null; then
        echo "screen already installed!"
    else
        # This only works for linux
        sudo apt-get install -y screen
    fi

    # BUILDING CODE
    printf "\n>> BUILDING $SYS\n"
    cd $HOMEDIR
    sbt clean package
    ;;
    esac
done


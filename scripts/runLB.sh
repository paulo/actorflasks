#!/bin/bash

########################
# VARIABLES
########################
SYS="ACTORFLASKS"
HOMEDIR=$PWD

if [[ "$HOMEDIR" == */scripts* ]]; then
HOMEDIR="$(dirname "$PWD")"
fi

if [ ! -f peer_list ]; then
#    echo "peers.Peer list not found at directory ${HOMEDIR}"
    HOMEDIR=""
#    echo "Changing Home folder to ${HOMEDIR}"
else
    echo "Home folder: $HOMEDIR"
fi
PEERSFILE=$HOMEDIR/config/peer_list
LBFILE=$HOMEDIR/config/lb_list

#VARIABLES FOR REMOTE INSTALLATION
DEPLOYDIR="/home/gsd/deploy/"

#VARIABLES FOR LOCAL INSTALLATION
DEPLOYDIR=$HOMEDIR/deploy

########################
# DEPLOYMENT MODES
#   "-r" for deploying and running the code in GSD remote machines
#   "-l" for deploying and running the code in the local machine
########################

while getopts "rl" opt; do
    case "$opt" in

    r)
    echo "====================================="
    echo "RUNNING ${SYS} REMOTELLY"
    echo "====================================="
    ;;

    l)
    echo "====================================="
    echo "RUNNING ${SYS} LOCALLY"
    echo "====================================="
    #echo "Rebuild $SYS"
    cd $HOMEDIR
    sbt assembly

    # CREATE LIST OF PEERS
    echo "Obtaining list of peers from $PEERSFILE"
    
    input=""
    while IFS='' read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^#.*$ ]] && continue
        input+=$line" "
    done < "$PEERSFILE"

    echo "Starting Load Balancer..."

    while IFS='' read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^#.*$ ]] && continue
        a=( $line )
        lb_id=${a[0]}
        lb_ip=${a[1]}
        lb_port=${a[2]}
        printf "\n>> RUNNING LOAD BALANCER ${id} (${ip}:${port})\n"
        
        mkdir ${DEPLOYDIR}/lb_${lb_id}
        cd ${DEPLOYDIR}/lb_${lb_id}
        
        JAVA_OPTS="-Xmx1024m" # alternatively, set this -J-Xmx1024m on the command to pass argument to JVM
        mycommand="screen -dmSL LoadBalancer.${lb_id} scala -cp .:${HOMEDIR}/target/scala-2.12/actorflasks-assembly-1.0.jar ServerMain ${lb_id} ${lb_ip} ${lb_port} ${input}"
        echo $mycommand
        $mycommand &
    done < "$LBFILE"
    ;;
    esac
done

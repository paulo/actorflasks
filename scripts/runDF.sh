#!/bin/bash

########################
# VARIABLES
########################
SYS="ACTORFLASKS"

#VARIABLES FOR REMOTE INSTALLATION
# REMOTE_IP="$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')" 
REMOTE_IP="$(awk 'END{print $1}' /etc/hosts)"
REMOTE_PORT=50000
REMOTE_HOMEDIR=/flasks
REMOTE_DEPLOYDIR=$HOMEDIR/log
REMOTE_CONFIGDIR=$HOMEDIR/config

#VARIABLES FOR LOCAL INSTALLATION
HOMEDIR=""
DEPLOYDIR=$HOMEDIR/deploy
CONFIGDIR=$HOMEDIR/src/main/resources

PEERSFILE=$HOMEDIR/config/peer_list
REMOTE_PEERSFILE=$REMOTE_HOMEDIR/config/peer_list

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

    cd ${REMOTE_HOMEDIR}
    
    # CREATE LIST OF PEERS
    echo "Obtaining list of peers from $REMOTE_PEERSFILE"
    
    input=""
    while IFS='' read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^#.*$ ]] && continue
        input+=$line" "
    done < "$REMOTE_PEERSFILE"

    echo "Creating akka configuration for peer"
       
    cd ${REMOTE_HOMEDIR}
    source scripts/createConf.sh ${id} ${REMOTE_IP} ${REMOTE_PORT} ${REMOTE_CONFIGDIR}
        
    JAVA_OPTS="-Xmx1024m" # alternatively, set this -J-Xmx1024m on the command to pass argument to JVM
    
    mycommand="scala -cp .:${REMOTE_HOMEDIR}/actorflasks-assembly-1.0.jar DataFlasks ${id} ${ip} ${port} 1 ${REMOTE_CONFIGDIR} ${input}" # Fix: Capacity not being considered yet. Read local configs from file, including port
    # Fix location for log output
    echo $mycommand
    
    $mycommand &
    ;;

    l)
    echo "====================================="
    echo "RUNNING ${SYS} LOCALLY"
    echo "====================================="
    
    cd $HOMEDIR
    sbt assembly

    # CREATE LIST OF PEERS
    echo "Obtaining list of peers from $PEERSFILE"
    
    input=""
    while IFS='' read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^#.*$ ]] && continue
        input+=$line" "
    done < "$PEERSFILE"

    echo "Starting peers..."
    while IFS='' read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^#.*$ ]] && continue
        a=( $line )
        id=${a[0]}
        ip=${a[1]}
        port=${a[2]}
        capacity=${a[3]}
        printf "\n>> RUNNING PEER ${id} (${ip}:${port})\n"
        
        echo "Creating akka configuration for peer ${id}"
       
        cd ${HOMEDIR}
        source scripts/createConf.sh ${id} ${ip} ${port} ${CONFIGDIR}

        mkdir ${DEPLOYDIR}/${id}
        cd ${DEPLOYDIR}/${id}
        
        #set screen log (multiplexes a physical terminal between several processes)
        JAVA_OPTS="-Xmx128m" # alternatively, set this -J-Xmx1024m on the command to pass argument to JVM
        mycommand="screen -dmSL Peer.${id} scala -cp .:${HOMEDIR}/target/scala-2.12/actorflasks-assembly-1.0.jar DataFlasks ${id} ${ip} ${port} ${capacity} ${CONFIGDIR} ${input}"
        # cd ${HOMEDIR}
        # mycommand="screen -dmSL peers.Peer.${id} sbt \"run ${id} ${ip} ${port}\""
        # echo $mycommand
        ulimit -v 64000
        $mycommand &
    done < "$PEERSFILE"
    ;;
    esac
done

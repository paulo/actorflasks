#!/bin/bash

########################
# VARIABLES
########################
SYS="ACTORFLASKS"
HOMEDIR=$PWD
if [[ "$HOMEDIR" == */scripts* ]]; then
HOMEDIR="$(dirname "$PWD")"
fi

#VARIABLES FOR REMOTE INSTALLATION
DEPLOYDIR=$2

#VARIABLES FOR LOCAL INSTALLATION
DEPLOYDIR=$HOMEDIR/deploy
########################
# EXECUTION MODES
#   "-r" for installing the code in GSD remote machines
#   "-l" for installing the code in the local machine
########################
REMOTE=0
LOCAL=0
ALL=0
LOGS=0

while true; do
    case "$1" in
        -l )
        if(("$REMOTE" == 1)); then
            LOCAL=0
            echo "Invalid arguments: you can only run the script with either -r (for remote cleaning) or -l (for local cleaning). Running with option -r"
            shift ;
        elif(("$LOCAL" == 0)); then
            LOCAL=1
            shift;
        else
            shift;
        fi
        ;;

        -r )
         if(("$LOCAL" == 1)); then
            REMOTE=0
            echo "Invalid arguments: you can only run the script with either -r (for remote cleaning) or -l (for local cleaning). Running with option -l"
            shift ;
        elif(("$REMOTE" == 0)); then
            REMOTE=1
            echo "==============================="
            echo "CLEANING ${SYS} REMOTELY"
            echo "==============================="
            shift;
        else
            shift;
        fi
        ;;
        --all )
        if [ "$LOCAL" == 0 ] && [ "$REMOTE" == 0 ]; then
            echo "Invalid arguments: must specify whether to clean locally (-l) or remotely (-r). Usage: cleanDF (-r | -l) (--logs | --all)";
            shift ;
        elif(("$LOGS" == 1)); then
            echo "Invalid arguments: you can only run the script with either --all (for removing both execution subfolders and logs) or --logs (for removing just the execution logs). Running with option --logs";
            shift;
        elif(("$LOCAL" == 1)); then
            ALL=1
            echo "====================================="
            echo "CLEANING ${SYS} LOCALLY (ALL)"
            echo "====================================="
            cd ${DEPLOYDIR}
            if [ $? -eq 0 ]; then
                for d in */ ; do
                    rm -r "$d"
                done
            fi
            break;
        fi
        ;;
        --logs )
                if [ "$LOCAL" == 0 ] && [ "$REMOTE" == 0 ]; then
            echo "Invalid arguments: must specify whether to clean locally (-l) or remotely (-r). Usage: cleanDF (-r | -l) (--logs | --all)";
            shift ;
        elif(("$ALL" == 1)); then
            echo "Invalid arguments: you can only run the script with either --all (for removing both execution subfolders and logs) or --logs (for removing just the execution logs). Running with option --all";
            shift;
        elif(("$LOCAL" == 1)); then
            LOGS=1
            echo "===================================="
            echo "CLEANING ${SYS} LOCALLY (LOGS)"
            echo "===================================="
            cd ${DEPLOYDIR}
            if [ $? -eq 0 ]; then
                for d in */ ; do
                    echo "HERE"
                    cd ${DEPLOYDIR}/$d
                    rm .*log.[0-9]*
                done
            fi
            break;
        fi
        ;;
        * ) if(( "$#" == 0)); then
                break ;
            else
                shift ;
            fi
            ;;
    esac
done

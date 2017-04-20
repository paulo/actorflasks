#!/bin/bash

######################
# ARGUMENTS
######################

ID=$1
IP=$2
PORT=$3
CONFIGDIR=$4

######################################
# BUILD NEW CYCLONMANAGER CONFIG FILE
######################################

echo "akka {
  actor {
    provider = "akka.remote.RemoteActorRefProvider"
  }
  remote {
    enabled-transports = ["akka.remote.netty.tcp"]
    netty.tcp {
      hostname = \"${IP}\"
      port = ${PORT}
    }
 }
}" > $CONFIGDIR/app${ID}.conf

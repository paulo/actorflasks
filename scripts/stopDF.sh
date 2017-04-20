#!/usr/bin/env bash

#Print ip-port from peers that is going to kill
# ps -A | grep Peer | grep -v 'grep' | awk '{print $13 " - " $14}' | sort | uniq | xargs -L 1 echo 'Killing peer @'

ps -A | grep actorflasks-assembly-1.0.jar | grep -v 'grep' | grep 'Peer' | awk '{print $1 " - " $6}' | sort | uniq | xargs -L 1 echo 'Killing peer @'

#Kill peers (processes)
ps -A | grep actorflasks-assembly-1.0.jar | grep -v 'grep' | awk '{print $1}' | xargs kill

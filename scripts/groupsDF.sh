#!/bin/bash

output=$1
# fix prints
for node_dir in "$output"/*
do
    node_id=$(basename $node_dir)
    printf "Node $node_id : "
    for log_file in "$node_dir"/*
    do
        info=$(awk 'NF{p=$0}END{print p}' $log_file)
        IFS=' ' read -r -a array <<< "$info"
        echo "${array[3]}"
    done
done

#!/bin/bash

# source from mq-golang-jms20-project 

runCmd(){
    _job="${1}"
    shift 1
    _cmd="${*}"
    printf "\n-i- ----------------------------------------------------------------------------"
    printf "\n-i- ___${_job}"
    printf "\n-i- ${_cmd} => $(eval echo ${_cmd})"
    printf "\n-i- ----------------------------------------------------------------------------\n"
    ${_cmd}
}

printf "\n-i- ============================================================================"
cd /go
printf "\n-i- === current WorkDir is [${PWD}]...loading [.profile]\n"
. .profile

printf "\n-i- ============================================================================"
runCmd "Write 1.Message to Conix-Consumer-Queue" bin/mqio -config ./config/queue.config.consumer.host.json 
runCmd "Write 2.Message to Conix-Consumer-Queue" bin/mqio -config ./config/queue.config.consumer.host.json 
runCmd "Write 3.Message to Conix-Consumer-Queue" bin/mqio -config ./config/queue.config.consumer.host.json 

printf "\n-i- ============================================================================"
runCmd "Read 1.Message from Conix-Consumer-Queue" bin/mqio -config ./config/queue.config.consumer.host.json -consume
runCmd "Read 2.Message from Conix-Consumer-Queue" bin/mqio -config ./config/queue.config.consumer.host.json -consume
runCmd "Read 3.Message from Conix-Consumer-Queue" bin/mqio -config ./config/queue.config.consumer.host.json -consume

printf "\n-i- ============================================================================"
runCmd "Write 1.Message to Conix-Producer-Queue" bin/mqio -config ./config/queue.config.producer.host.json 
runCmd "Write 2.Message to Conix-Producer-Queue" bin/mqio -config ./config/queue.config.producer.host.json 
runCmd "Write 3.Message to Conix-Producer-Queue" bin/mqio -config ./config/queue.config.producer.host.json 

printf "\n-i- ============================================================================"
runCmd "Read all Messages from Conix-Producer-Queue" bin/mqio -config ./config/queue.config.producer.host.json -consume -loop

printf "\n-i- ============================================================================"
printf "\n"

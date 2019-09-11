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
runCmd "Write 3.Messages to Conix-Consumer-Queue"    bin/mqio -config ./config/queue.config.consumer.ctx.json -loop -limit 3 -delay 1
printf "\n-i- ============================================================================"
runCmd "Read all Messages from Conix-Consumer-Queue" bin/mqio -config ./config/queue.config.consumer.ctx.json -loop -consume 


printf "\n-i- ============================================================================"
runCmd "Write 5.Messages to Conix-Producer-Queue"    bin/mqio -config ./config/queue.config.producer.ctx.json -loop -limit 5 -delay 1
printf "\n-i- ============================================================================"
runCmd "Read all Messages from Conix-Producer-Queue" bin/mqio -config ./config/queue.config.producer.ctx.json -loop -consume 

printf "\n-i- ============================================================================"
printf "\n"

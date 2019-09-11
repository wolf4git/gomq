#!/bin/bash
declare _Env="./env.sh"

if [ -e ${_Env} ]; then
    printf "\n___ Found and use env from current folder\n"
    . ${_Env}
else
    printf "\n+++ Missing ${_Env} on current folder"
    printf "\n+++ Please create a ${_Env} on current folder in advance\n"
    exit 42
fi
printf "\n... Working in ${PWD}"

runCmd(){
    _job="${1}"
    shift 1
    _cmd="${*}"
    printf "\n-i- "
    printf "\n-i- "
    printf "\n-i- "
    printf "\n-i- ----------------------------------------------------------------------------"
    printf "\n-i- ----------------------------------------------------------------------------"
    printf "\n-i- ___${_job}"
    printf "\n-i- ${_cmd} => $(eval echo ${_cmd})"
    printf "\n-i- ----------------------------------------------------------------------------\n"
    printf "\n-i- ----------------------------------------------------------------------------"
    ${_cmd}
}

runCmd "MQ-Server Mq-Golang (selfmade)" docker exec -it ${PROJ_SERVICE}_mqs_1 ./mq-test.sh    
runCmd "MQ-Client Mq-Golang (selfmade)" docker exec -it ${PROJ_SERVICE}_mqc_1 ./mq-io-test.sh 
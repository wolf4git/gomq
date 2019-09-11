#!/bin/bash

export MQ_MANAGER=${CONIXMQM_MQMGR}
export MQ_HOST="localhost(1414)"    #...for use within container

export MQ_CHANNEL_APP="DEV.APP.SVRCONN"
export MQ_CHANNEL_ADMIN="DEV.ADMIN.SVRCONN"


export MQ_SERVER_APP="${MQ_CHANNEL_APP}/TCP/${MQ_HOST}"
export MQ_SERVER_ADMIN="${MQ_CHANNEL_ADMIN}/TCP/${MQ_HOST}"
export MQ_PQ_CONIX="CONIX.PRODUCE.QUEUE"
export MQ_CQ_CONIX="CONIX.CONSUME.QUEUE"

# -----------------------------------------------------------------------------
runCmd(){
    _job="${1}"
    shift 1
    _cmd="${*}"
    printf "\n-i- ----------------------------------------------------------------------------"
    printf "\n-i- ___${_job}"
    printf "\n-i- ___current MQSERVER ...........as [${MQSERVER}]"
    printf "\n-i- ___current MQSAMP_USER_ID .....as [${MQSAMP_USER_ID}]"
    printf "\n-i- ${_cmd} => $(eval echo ${_cmd})"
    printf "\n-i- ----------------------------------------------------------------------------\n"
    ${_cmd}
}
# -----------------------------------------------------------------------------
# --- main --- main --- main --- main --- main --- main --- main --- main --- 
# -----------------------------------------------------------------------------
export MQSERVER="${MQ_SERVER_APP}"
export MQSAMP_USER_ID=admin
printf "\n-i- ============================================================================"
printf "\n-i- ___using MQ_MANAGER .........as [${MQ_MANAGER}]"
printf "\n-i- ___using MQ_CONNECT_TYPE ....as [${MQ_CONNECT_TYPE}]"
printf "\n-i- ----------------------------------------------------------------------------"
printf "\n-i- ___using MQ_CHANNEL_APP .....as [${MQ_CHANNEL_APP}]"
printf "\n-i- ___using MQ_CHANNEL_ADMIN ...as [${MQ_CHANNEL_ADMIN}]"
printf "\n-i- ----------------------------------------------------------------------------"
printf "\n-i- ___using MQ_SERVER_APP ......as [${MQ_SERVER_APP}]"
printf "\n-i- ___using MQ_SERVER_ADMIN ....as [${MQ_SERVER_ADMIN}]"
printf "\n-i- ----------------------------------------------------------------------------"
printf "\n-i- ___using MQ_PQ_CONIX ........as [${MQ_PQ_CONIX}]"
printf "\n-i- ___using MQ_CQ_CONIX ........as [${MQ_CQ_CONIX}]"
printf "\n-i- ----------------------------------------------------------------------------"
printf "\n-i- ___using MQSAMP_USER_ID .....as [${MQSAMP_USER_ID}]"
printf "\n-i- ============================================================================"
printf "\n"

# -----------------------------------------------------------------------------
# --- test connect --- test connect --- test connect --- test connect --- test 
# -----------------------------------------------------------------------------
printf "\n-i- ============================================================================"
printf "\n-i- ----------------------------------------------------------------------------"
printf "\n--- ./amqsconn \$MQ_MANAGER \$MQ_CHANNEL_ADMIN \$MQ_HOST ==> ./amqsconn $MQ_MANAGER $MQ_CHANNEL_ADMIN $MQ_HOST"
printf "\n-i- ----------------------------------------------------------------------------"
printf "\n"
echo "${CONIXMQM_ADPWD}" | ./amqsconn $MQ_MANAGER $MQ_CHANNEL_ADMIN $MQ_HOST #mq-test.admin.pwd
# --------------------------------------
# Output...
#    Enter password for qmgr QM1: 
#    passw0rd
#    Connection to QM1 succeeded.
#    Done.
# --------------------------------------
export MQSAMP_USER_ID=app
printf "\n-i- ----------------------------------------------------------------------------"
printf "\n-i- ___using MQSAMP_USER_ID .....as [${MQSAMP_USER_ID}]"
printf "\n--- ./amqsconn \$MQ_MANAGER \$MQ_CHANNEL_APP \$MQ_HOST ==> ./amqsconn $MQ_MANAGER $MQ_CHANNEL_APP $MQ_HOST"
printf "\n-i- ----------------------------------------------------------------------------"
printf "\n"
echo "${CONIXMQM_APPWD}" | ./amqsconn $MQ_MANAGER $MQ_CHANNEL_APP $MQ_HOST

export MQSAMP_USER_ID=conix
printf "\n-i- ----------------------------------------------------------------------------"
printf "\n-i- ___using MQSAMP_USER_ID .....as [${MQSAMP_USER_ID}]"
printf "\n--- ./amqsconn \$MQ_MANAGER \$MQ_CHANNEL_APP \$MQ_HOST ==> ./amqsconn $MQ_MANAGER $MQ_CHANNEL_APP $MQ_HOST"
printf "\n-i- ----------------------------------------------------------------------------"
printf "\n"
echo "xinoc" | ./amqsconn $MQ_MANAGER $MQ_CHANNEL_APP $MQ_HOST

# -----------------------------------------------------------------------------
# --- test put/get --- test put/get --- test put/get --- test put/get --- test 
# -----------------------------------------------------------------------------
printf "\n-i- ============================================================================"
runCmd "Put 1. Message to Conix-Producer-Queue" ./amqsput $MQ_PQ_CONIX $MQ_MANAGER
runCmd "Put 2. Message to Conix-Producer-Queue" ./amqsput $MQ_PQ_CONIX $MQ_MANAGER
# --------------------------------------
# Output...
#    Sample AMQSPUT.GO start
#    Connected to queue manager QM1
#    Opened queue DEV.QUEUE.1
#    Put message to DEV.QUEUE.1
#    MsgId:414d5120514d31202020202020202020e5676f5d021f6221
#    Closed queue
#    Disconnected from queue manager QM1
# --------------------------------------

runCmd "Get all Messages from Conix-Producer-Queue, Should fail after 2 Messages are read" ./amqsget $MQ_PQ_CONIX $MQ_MANAGER
# --------------------------------------
# Output...
#    Sample AMQSGET.GO start
#    Connected to queue manager QM1
#    Opened queue DEV.QUEUE.1
#    Got message of length 42: Hello from Go at 2019-09-04T11:12:48+02:00
#    Got message of length 42: Hello from Go at 2019-09-04T11:21:20+02:00
#    MQGET: MQCC = MQCC_FAILED [2] MQRC = MQRC_NO_MSG_AVAILABLE [2033]
#    Closed queue
#    Disconnected from queue manager QM1
# --------------------------------------

printf "\n-i- ============================================================================"
runCmd "Put 1. Message to Conix-Producer-Queue" ./amqsput $MQ_CQ_CONIX $MQ_MANAGER
runCmd "Put 2. Message to Conix-Producer-Queue" ./amqsput $MQ_CQ_CONIX $MQ_MANAGER
runCmd "Get all Messages from Conix-Producer-Queue, Should fail after 2 Messages are read" ./amqsget $MQ_CQ_CONIX $MQ_MANAGER

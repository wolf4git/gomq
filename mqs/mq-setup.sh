#!/bin/sh
scriptName="$(basename ${0})"
logFile="/${MQ_CONIX_PATH}/${scriptName}.log"
logFileTmp="/${MQ_CONIX_PATH}/${scriptName}.temp.log"

sleepTime=${1}

# -----------------------------------------------------------------------------
mecho(){
    echo "[`date +%F_%T_%z` ${scriptName}] ${*}" 
}
# -----------------------------------------------------------------------------
decho(){
    echo "[`date +%F_%T_%z` ${scriptName} Direct] ${*}" 
}
# -----------------------------------------------------------------------------
lecho(){
    mecho ${*} >> ${logFile}
}
# -----------------------------------------------------------------------------
dlecho(){
    decho ${*}
    lecho ${*} >> ${logFile}
}

# -----------------------------------------------------------------------------
mcall(){
    lecho "-c- -------------------------------------------------------------------------------" 
    lecho "-c- ${*}" 
    lecho "-c- -------------------------------------------------------------------------------" 
    lecho ""
    ${*} 1>${logFileTmp}
    while read line; do 
     lecho "${line}"
    done < ${logFileTmp}
}
# -----------------------------------------------------------------------------
lecho "................................................................................."
lecho "--- this is log [${logFile}] from [${scriptName}]"
lecho "................................................................................."
lecho "................................................................................."
dlecho "Hallo from ${scriptName}, wait ${sleepTime} Seconds on mqserver-startup"
lecho "................................................................................."
lecho "..."
sleep ${sleepTime}

lecho "................................................................................."
lecho "...sleep to mqserver-startup done"
lecho "..."

# links to docs
# - [MQSC ./runmqsc](https://www.ibm.com/support/knowledgecenter/en/SSFKSJ_9.1.0/com.ibm.mq.adm.doc/q020660_.htm) from running mq-server-container
# - [commands on MQSC](https://www.ibm.com/support/knowledgecenter/en/SSFKSJ_9.0.0/com.ibm.mq.ref.adm.doc/q085130_.htm)
# - [MQSC Examples-01](https://www.ibm.com/support/knowledgecenter/en/SSFKSJ_7.5.0/com.ibm.mq.adm.doc/q020670_.htm)

# get user for MQ-Server via...
lecho "................................................................................."
lecho "Lookup MQ-Related Groups on container "
lecho "................................................................................."
lecho "..."

# response should include: "mqm" "mqclient"
vg=$(grep ^mq /etc/group |cut -d':' -f1,4)
echo "${vg}" |while read vx; do 
    lecho "${vx}"
 done
lecho "................................................................................."
lecho "Lookup MQ-Related Users on container "
lecho "................................................................................."
lecho "..."
echo "${vg}" \
 |cut -d':' -f2 \
 |sed 's/,/ /g' \
 |tr ' ' '\n' \
 |while read vu; do 
    vp=$(grep -e^"${vu}:" /etc/passwd)
    lecho "${vu} ==> ${vp}"
   #printf "\n%20.20s ==> %s" "${vu}" "${vp}"
 done

dlecho "................................................................................."
dlecho "...current MQ_QMGR_NAME is [${MQ_QMGR_NAME}]"
dlecho "................................................................................."
cd /opt/mqm/bin
#...add queue CONIX
mcall ./runmqsc  ${CONIXMQM_MQMGR} < /${MQ_CONIX_PATH}/mq.create.conix.queue #...copied into docker-container
#... show permission on new queue
mcall ./dspmqaut -m ${CONIXMQM_MQMGR} -t queue -n CONIX.LOCAL.QUEUE -g mqclient
mcall ./dspmqaut -m ${CONIXMQM_MQMGR} -t queue -n CONIX.PRODUCE.QUEUE -g mqclient
mcall ./dspmqaut -m ${CONIXMQM_MQMGR} -t queue -n CONIX.CONSUME.QUEUE -g mqclient
# ...shows no permission on mqclient, so we apply needed permission
mcall ./setmqaut -m ${CONIXMQM_MQMGR} -t queue -n CONIX.LOCAL.QUEUE -g mqclient +get +put +inq +browse
mcall ./setmqaut -m ${CONIXMQM_MQMGR} -t queue -n CONIX.PRODUCE.QUEUE -g mqclient +get +put +inq +browse
mcall ./setmqaut -m ${CONIXMQM_MQMGR} -t queue -n CONIX.CONSUME.QUEUE -g mqclient +get +put +inq +browse
#... show permission on new queue
mcall ./dspmqaut -m ${CONIXMQM_MQMGR} -t queue -n CONIX.LOCAL.QUEUE -g mqclient
mcall ./dspmqaut -m ${CONIXMQM_MQMGR} -t queue -n CONIX.PRODUCE.QUEUE -g mqclient
mcall ./dspmqaut -m ${CONIXMQM_MQMGR} -t queue -n CONIX.CONSUME.QUEUE -g mqclient

lecho "....................................................................."
dlecho "...${scriptName} done"
dlecho "Display finally the complete log from ${scriptName}"
lecho "....................................................................."
lecho "..."

cat ${logFile}

# -----------------------------------------------------------------------------
# dlecho "Enable REST-Interface "
# -----------------------------------------------------------------------------
# curl --insecure https://admin:admin@localhost:9443/ibmmq/rest/v1/messaging/qmgr/QM1/queue/DEV.QUEUE.1/message
# set -xv
#     /opt/mqm/bin/setmqweb properties -k httpHost -v "*"
#     cd /var/mqm/web/installations/Installation1/servers/mqweb
#     cp mqwebuser.xml mqwebuser.xml.bakByWvo 
#     cp /opt/mqm/web/mq/samp/configuration/basic_registry.xml mqwebuser.xml
# set -
#   /opt/mqm/bin/endmqweb
#   /opt/mqm/bin/strmqweb

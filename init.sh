# invoke via: . ./init.sh
# this is loaded as commands in your current shell, because
# otherwise your environmanet vars are gone ;-(

#declare -l _choice
#_choice="n"; printf "\n...choose Read(mqr) or Write(mqw) or Sample(mqc)"; read _choice    
#if [ "${_choice}_xX" = "q_xX" ]; then exit 0; fi
#if [ "${_choice}_xX" = "r_xX" ]; then export GOPATH=${PWD}/mqr; fi
#if [ "${_choice}_xX" = "w_xX" ]; then export GOPATH=${PWD}/mqw; fi
#if [ "${_choice}_xX" = "c_xX" ]; then export GOPATH=${PWD}/mqc; fi
#

export GOPATH=${PWD}/gopath
_pwd=${PWD}


runCmd(){
    _job="${1}"
    shift 1
    _cmd="${*}"
    printf "\n-i- ----------------------------------------------------------------------------"
    printf "\n-i- ___${_job}"
    printf "\n-i- ${_cmd}"
    #rintf "\n-i- $(eval echo ${_cmd})"
    printf "\n-i- ----------------------------------------------------------------------------\n"
    ${_cmd}
}

# ---------------------------------------------------------------------------
runCmd "" git clone https://github.com/ibm-messaging/mq-golang-jms20.git ${GOPATH}/src/github.com/ibm-messaging/mq-golang-jms20

# ---------------------------------------------------------------------------
cd ${GOPATH}/src/github.com/ibm-messaging/mq-golang-jms20/
runCmd "on /mq-golang-jms20" dep ensure
cd ${_pwd}

# ---------------------------------------------------------------------------
cd ${GOPATH}/src/github.com/ibm-messaging/mq-golang-jms20/mqjms/
runCmd "on /mq-golang-jms20/mqjms" go build

# ---------------------------------------------------------------------------
cd ${_pwd}
printf "\n...done\n"

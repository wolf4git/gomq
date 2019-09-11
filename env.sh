# invoke via: . ./env
# this is loaded as commands in your current shell, because
# otherwise your environment vars are gone ;-(

export _pCONFIG_BASE="./_config.base"
export _pCONFIG_KEYS="./_config.generated.keys"
export _pCONFIG_DOCK="./_config.generated.docker"
declare _verbose=true
declare _debug=false
declare -l _arg=${1}
declare    _cwd=${PWD}
declare _homePath=$(dirname ${0})


if [ ! -e ${_pCONFIG_BASE} ]; then
    cd ${_homePath}
fi

if [ ! -e ${_pCONFIG_BASE} ]; then
    printf "\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    printf "\n!!!...this looks some how wrong!!!!                 !!!"
    printf "\n!!!...Are you starting me within my homefolder ???  !!!"
    printf "\n!!!...missing expected file [${_pCONFIG_BASE}]     !!!"
    printf "\n!!!...Please start me only in my homefolder         !!!"
    printf "\n!!!...call was [${0}]"
    printf "\n!!!...base was [$(basename ${0})]"
    printf "\n!!!...path was [$(dirname ${0})]"
    printf "\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    printf "\n!!! STOP PROCESSING !!! STOP PROCESSING !!! STOPPED !!!"
    printf "\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    printf "\n"
    cd ${_cwd}
    return
fi

if [ "${_arg}_xX" = "silent_xX" ]; then
   _verbose=false; shift 1; _arg=${1}
fi

echo "--------------------------------------------------------"
echo "--- working-directory is [${PWD}]"
${_verbose} && { 
    echo "--- expected shell is [/bin/bash] current shell is"
    echo "--- $SHELL / ${0}"
    ps -p "$$"  1> env.sh.$$ 2>&1 
    while read _osLine; do 
        echo "    ...${_osLine}"
    done < env.sh.$$
    rm -f env.sh.$$
    echo "--------------------------------------------------------"
    echo "--- current OS is (determind via: lsb_release -a )"
    lsb_release -a 1> env.sh.$$ 2>&1 
    while read _osLine; do 
        echo "   ...${_osLine}"
    done < env.sh.$$
    echo "--- Architecture: determind via: dpkg --print-architecture"
    echo "   ...Architecture: `dpkg --print-architecture`"
    rm -f env.sh.$$
}

declare    _eKey
declare -i _eKeyCnt
declare -u _eKeyTyp
unset _aKeys; declare -A _aKeys

# -----------------------------------------------------
function _addKeys {
# -----------------------------------------------------
    declare    _conf=${1}
    declare -i _lNum=0
    declare -i  _cSep
    if [ ! -e ${_conf} ]; then
        printf "%s" "-!- INTERNAL-FAILURE@_addKeys() could not find [${_conf}]"
        return
    fi

    cat ${_conf} |grep -v ^# > ${_conf}.$$
    while read _confLine; do
        _lNum+=1
        _eKey=$(echo ${_confLine} |cut -d':' -f1)
        _cSep=$(echo ${_confLine} |grep -c ':')
        if [ ${_cSep} -le 0 ]; then
            printf "\n-!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!"
            printf "\n-!- you have to use \":\" as seperator "
            printf "\n-!- ...e.g. PROJ_CUSTOMER:mcc"
            printf "\n-!- found no expected field-seperator "
            printf "\n-!- ...at line-number [${_lNum}]"
            printf "\n-!- ...with content [${_confLine}]"
            printf "\n-!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!"
            continue
        fi
        if [ "${_eKey}_xX" = "_xX" ]; then
            printf "\n-!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!"
            printf "\n-!- you should awoid empty lines"
            printf "\n-!- found in [${_conf}] at line-number [${_lNum}]"
            printf "\n-!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!--!"
            continue
        fi
        _eKeyCnt=$(cat ${_conf}.$$ |grep -c ${_eKey})
        _eKeyTyp="M"
        if [ ${_eKeyCnt} -eq 1 ]; then _eKeyTyp="S"; fi
        
        _aKeys["${_eKeyTyp}:${_eKey}:${_conf}:"]="${_eKeyTyp}"
        ${_debug} && { 
            printf "\n...Created Key:[${_eKeyTyp}:${_eKey}:${_conf}:]";
        }
    done < ${_conf}.$$
    rm -f ${_conf}.$$ 2>/dev/null
}
# -----------------------------------------------------
function _storeKeys {
# -----------------------------------------------------
    # ...place all key to the project-config-keyfile
    rm -f ${_pCONFIG_KEYS}.$$ 2>/dev/null
    rm -f ${_pCONFIG_KEYS} 2>/dev/null
    for _eKey in "${!_aKeys[@]}"; do 
        echo "${_eKey}" >> ${_pCONFIG_KEYS}.$$  
        ${_debug} && { 
            printf "\n...Added Key:[${_eKey}]";
        }
    done
    sort --key=2 --field-separator=: ${_pCONFIG_KEYS}.$$ > ${_pCONFIG_KEYS}
    rm -f ${_pCONFIG_KEYS}.$$ 2>/dev/null
    ${_debug} && { printf "\n...done _storeKey()"; }
}
# -----------------------------------------------------
function _publishKeys {    
# -----------------------------------------------------
    declare    _display=true
    declare    _eTyp
    declare    _pKey
    declare    _pVal
    declare    _fKey
    declare -i _lKey
    declare    _bKey="--------------------------------------------------------"
    #                 0...+....1...+....2...+....3...+....4...+....
    declare -i _dKey

    if [ "${1}_xX" != "_xX" ]; then _display=${1}; fi
    ${_display} && {
        printf "\n--------------------------------------------------------"
        printf "\n--- PROJECT-SETTINGS -----------------------------------"
        printf "\n--------------------------------------------------------"
    }

    rm -f ${_pCONFIG_KEYS}.$$ 2>/dev/null
    echo ${!_aKeys[@]} |tr " " "\n" |sort >> ${_pCONFIG_KEYS}.$$
    readarray _sKeys < ${_pCONFIG_KEYS}.$$
    rm -f ${_pCONFIG_KEYS}.$$ 2>/dev/null

    for _eKey in "${_sKeys[@]}"; do 
  # for _eKey in "${!_aKeys[@]}"; do 
        _eTyp=$(echo ${_eKey} |cut -d':' -f1)
        _pKey=$(echo ${_eKey} |cut -d':' -f2)
        _fKey=$(echo ${_eKey} |cut -d':' -f3)
        if [ "${_eTyp}_xX" = "M_xX" ]; then continue; fi
        
        _pVal=$(cat ${_fKey} |grep ^${_pKey}: |cut -d':' -f2-)
        _eVal=$(eval echo ${_pVal})
        ${_debug} && { 
            printf "\n...Lookup Key:[${_eTyp}:${_pKey}:${_fKey}] with [${_pKey}=${_pVal}] eval=[${_eVal}]";
        }
        export ${_pKey}="${_eVal}"
        _lKey=${#_pKey}
        _dKey=40-${_lKey}
        ${_display} && { 
            printf "\n... ${_pKey} %${_dKey}.${_dKey}s [${_eVal}]" "${_bKey}"; 
        }
    done
}
# -----------------------------------------------------
function _addDockerKeys {    
# -----------------------------------------------------
    declare _uid=$(id -u)
    declare _gid=$(id -g)
    declare _run=$(id -run)
    
    declare _img="${PROJ_VERTICAL}-${PROJ_SERVICE}"
    if [ "${PROJ_VERTICAL}_xX" = "_xX" ]; then
        printf "\n+++ no project-definition found"
        printf "\n+++ expect file [${_pCONFIG_BASE}]"
        _dockerVolPath="./"
    else
        _dockerVolPath="/home/docker-volume/${PROJ_VERTICAL}"
    fi
    # ...place docker keys to the project.docker.conf
    rm -f ${_pCONFIG_DOCK} 2>/dev/null
    echo "DOCKER_VOL:${_dockerVolPath}"   >> ${_pCONFIG_DOCK}
    echo "DOCKER_NET:${PROJ_VERTICAL}net" >> ${_pCONFIG_DOCK}
    echo "DOCKER_IMG:${_img}"             >> ${_pCONFIG_DOCK}
    echo "DOCKER_UUID:${_uid}"            >> ${_pCONFIG_DOCK}
    echo "DOCKER_UGID:${_gid}"            >> ${_pCONFIG_DOCK}
    echo "DOCKER_UNAME:${_run}"           >> ${_pCONFIG_DOCK}
  # echo ""                               >> ${_pCONFIG_DOCK}

    _addKeys ${_pCONFIG_DOCK}
}

# =====================================================
# --- MAIN --- MAIN --- MAIN --- MAIN --- MAIN --- MAIN 
# =====================================================

# -----------------------------------------------------
# ...load base project-config-keys
# ...create docker project-config-keys
# -----------------------------------------------------
echo "--------------------------------------------------------"
printf "%s" "--- main -----------------------------------------------"

${_verbose} && { printf "\n   ...Add Keys from [${_pCONFIG_BASE}]"; }
_addKeys ${_pCONFIG_BASE}
_publishKeys false
# -----------------------------------------------------
${_verbose} && { printf "\n   ...Add Keys from [${_pCONFIG_DOCK}]"; }
_addDockerKeys
${_verbose} && { printf "\n   ...Store Keys to [${_pCONFIG_KEYS}]"; }
_storeKeys
${_verbose} && { printf "\n   ...Publish Keys"; }
_publishKeys

# -----------------------------------------------------
# ...we explicitly do not define DRP_CF_STAGE
#    with this construction we can identify that we are on our local container
#    and not in the pipeLine, as here DRP_CF_STAGE is defined
# -----------------------------------------------------
cd ${_cwd}
export PROJECT_STAGE="loc"
export LOG_LEVEL="info"

printf "\n--------------------------------------------------------"
printf "\n--- LOCALE-SETTINGS ------------------------------------"
printf "\n... defined PROJECT_STAGE..........as [${PROJECT_STAGE}]"
printf "\n... defined LOG_LEVEL..............as [${LOG_LEVEL}]"
#rintf "\n--------------------------------------------------------"
#rintf "\n... exported Path to include node_modules/.bin.........."
printf "\n"

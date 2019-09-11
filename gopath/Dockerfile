# -----------------------------------------------------------------------------
ARG _BASE_IMAGE=ubuntu:18.04
FROM ${_BASE_IMAGE}
# -----------------------------------------------------------------------------
ARG _PROJ_VERTICAL
ARG INSTALL=/install
ARG GOPATH=/go
ARG GO_INI_DIR=/usr/local 
ARG VERSION_GO=1.12.9 
ARG VERSION_MQ=9.1.3.0 
ARG MQ_OS_LIBPATH=/opt/mqm 
#RG MQ_GO_URL=https://github.com/ibm-messaging/mq-golang-jms20.git 
ARG MQ_GO_URL=https://github.com/ibm-messaging/mq-golang.git 
ARG GO_DEP_INS=install.sh 
# ...see https://docs.docker.com/engine/reference/builder/ ENV
#    to get to know why we do ARG, ENV and a second ENV 
#
#   CGO_LDFLAGS="-Wl,-rpath.*"...with default path on MQ_OS_LIBPATH as /opt/mqm 
#
#   MQ_GO_DIR=${GOPATH}/src/github.com/ibm-messaging/mq-golang-jms20 \
ENV APP_USER=${_PROJ_VERTICAL} \
    GO_INI_TAR=go${VERSION_GO}.linux-amd64.tar.gz \
    GO_PROFILE=${GOPATH}/.profile \
    GO_DEP_INI=https://raw.githubusercontent.com/golang/dep/master/${GO_DEP_INS} \
    GOROOT=${GO_INI_DIR}/go \
    CGO_CFLAGS="-I${MQ_OS_LIBPATH}/inc" \
    CGO_LDFLAGS="-L${MQ_OS_LIBPATH}/lib64 -Wl,-rpath,${MQ_OS_LIBPATH}/lib64" \
    MQ_GO_DIR=${GOPATH}/src/github.com/ibm-messaging/mq-golang \
    MQ_RD_TAR=${VERSION_MQ}-IBM-MQC-Redist-LinuxX64.tar.gz  
#    related to predefined ENV-Vars-Evaluation
ENV GO_INI_URL=https://dl.google.com/go/${GO_INI_TAR} \
    MQ_RD_URL=https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqdev/redist/${MQ_RD_TAR} 
# -----------------------------------------------------------------------------
# Install needed tools on os-level
RUN apt-get update && apt-get install -y --no-install-recommends \
 build-essential \
 ca-certificates \
 curl \
 git \
 && rm -rf /var/lib/apt/lists/* 
# =============================================================================
# -----------------------------------------------------------------------------
# Install GoLang ...see https://tecadmin.net/install-go-on-ubuntu/
# no need to create folders like ${GOROOT}. It's created via used tar-command, 
#  as tar includes sub-folder "go" and ${GOROOT} is ${GO_INI_DIR}/go
WORKDIR ${INSTALL}
RUN printf "\n-i-" \
 && printf "\n-i- Internal GO_INI_URL:${GO_INI_URL}" \
 && printf "\n-i- internal GO_INI_TAR:${GO_INI_TAR}" \
 && printf "\n\n" \
 && curl -LO ${GO_INI_URL} \
 && tar -zxf ${GO_INI_TAR} -C ${GO_INI_DIR} \
 && mkdir -p ${GOPATH}/bin ${GOPATH}/pkg ${GOPATH}/config
# -----------------------------------------------------------------------------
# Config and load GoLang-Environment-Settings
RUN echo "#...extend by WVo on GoLang-Installation"        >> ${GO_PROFILE} \
 && echo "export GOROOT=${GOROOT}"                         >> ${GO_PROFILE} \
 && echo "export GOPATH=${GOPATH}"                         >> ${GO_PROFILE} \
 && echo "export PATH=${GOPATH}/bin:${GOROOT}/bin:${PATH}" >> ${GO_PROFILE} \
 && echo "echo Go-Env-Origin from ${GO_PROFILE}"           >> ${GO_PROFILE} \
 && echo "echo ...current CGO_CFLAGS [${CGO_CFLAGS}]"      >> ${GO_PROFILE} \
 && echo "echo ...current CGO_LDFLAGS [${CGO_LDFLAGS}]"    >> ${GO_PROFILE} \
 && . ${GO_PROFILE} \
 && go version \
 && go env
# -----------------------------------------------------------------------------
# Install GoLang DEP-prog (...${GOPATH}/bin needed here) ...see https://golang.github.io/dep/docs/installation.html
# ....${GO_PROFILE} has to be reloaded to access go, as we are in a new intermediate container 
RUN printf "\n-i-" \
 && printf "\n-i- internal GO_DEP_INI:${GO_DEP_INI}" \
 && printf "\n-i- internal GO_DEP_INS:${GO_DEP_INS}" \
 && printf "\n\n" \
 && curl -LO ${GO_DEP_INI} \
 && . ${GO_PROFILE} \
 && sh ./${GO_DEP_INS} \
 && dep version
# -----------------------------------------------------------------------------
# Install the MQ client from the Redistributable package. This also contains the
# header files we need to compile against.
RUN printf "\n-i-" \
 && printf "\n-i- Internal MQ_OS_LIBPATH:${MQ_OS_LIBPATH}" \
 && printf "\n-i- internal MQ_RD_URL:${MQ_RD_URL}" \
 && printf "\n-i- internal MQ_RD_TAR:${MQ_RD_TAR}" \
 && printf "\n\n" \
 && curl -LO "${MQ_RD_URL}" \
 && mkdir -p ${MQ_OS_LIBPATH} \
 && tar -zxf ./${MQ_RD_TAR} -C ${MQ_OS_LIBPATH} 
# -----------------------------------------------------------------------------
# Remove all temp-files (downloads in workdir)
# RUN rm -f ./*.tar.gz
#  && rm -f install.sh
#  && rm -f go${VERSION_GO}.linux-amd64.tar.gz
# -----------------------------------------------------------------------------
# Install Git Go-Repo-Sources 
# ....${GO_PROFILE} has to be reloaded to access go, as we are in a new intermediate container 
RUN printf "\n-i-" \
 && printf "\n-i- Internal MQ_GO_URL:${MQ_GO_URL}" \
 && printf "\n-i- internal MQ_GO_DIR:${MQ_GO_DIR}" \
 && printf "\n\n" \
 && git clone ${MQ_GO_URL} ${MQ_GO_DIR} \
 && cd ${MQ_GO_DIR} 
#&& . ${GO_PROFILE} \
#&& dep ensure \
#&& dep status
# -----------------------------------------------------------------------------
# If your client install is not located on default folder, then you also need to set
# ....${GO_PROFILE} has to be reloaded to access go, as we are in a new intermediate container 
RUN printf "\n-i-" \
 && printf "\n-i- Internal CGO_CFLAGS:${CGO_CFLAGS}" \
 && printf "\n-i- internal CGO_LDFLAGS:${CGO_LDFLAGS}" \
 && printf "\n\n" 

RUN . ${GO_PROFILE} \
 && cd ${MQ_GO_DIR}/ibmmq \
 && printf "\n-i-" \
 && printf "\n-i- Build MQ-GO on :${MQ_GO_DIR}/ibmmq" \ 
 && go install 

RUN . ${GO_PROFILE} \
 && cd ${MQ_GO_DIR}/mqmetric \
 && printf "\n-i-" \
 && printf "\n-i- Build MQ-GO on :${MQ_GO_DIR}/mqmetric" \ 
 && go install 

#go build -o bin/mqitest ./src/github.com/ibm-messaging/mq-golang/samples/mqitest/*.go
RUN . ${GO_PROFILE} \
 && cd ${MQ_GO_DIR}/samples/mqitest \
 && printf "\n-i-" \
 && printf "\n-i- Build MQ-GO on :${MQ_GO_DIR}//samples/mqitest" \ 
 && go install 
# =============================================================================
# -----------------------------------------------------------------------------
RUN printf "\n-i-" \
 && printf "\n-i- Create and Setup Runtime-User" \
 && printf "\n\n" \
 && groupadd -g 1000 ${APP_USER} \
 && adduser --disabled-password --gecos '' --uid 1000 --gid 1000 ${APP_USER} \
 && adduser ${APP_USER} sudo \
 && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
 && cat ${GO_PROFILE} >> /home/${APP_USER}/.profile \
 && echo "echo used /home/${APP_USER}/.profile as source of Go-Env" >> /home/${APP_USER}/.profile \
 && cat ${GO_PROFILE} >> /home/${APP_USER}/.bashrc \
 && echo "echo used /home/${APP_USER}/.bashrc as source of Go-Env" >> /home/${APP_USER}/.bashrc 
# =============================================================================
RUN printf "\n-i-" \
 && printf "\n-i- Final Runtime-User processing" \
 && printf "\n\n" 

WORKDIR ${GOPATH}
ADD . .

# ...this is how it's used from the testing-Applications 
ADD ./config/* /home/${APP_USER}/Downloads/

# ....${GO_PROFILE} has to be reloaded to access go, as we are in a new intermediate container 
RUN chown -R ${APP_USER}:${APP_USER} /home/${APP_USER} \
 && . ${GO_PROFILE} \
 && cd ${GOPATH}/src/github.com/conix/sample && go install \
 && cd ${GOPATH}/src/github.com/conix/mqio && go install

USER ${APP_USER}
CMD ["./bin/sample"]

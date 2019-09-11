# -----------------------------------------------------------------------------
ARG _VERSION_MQ=9.1.3.0 
FROM ibmcom/mq:${_VERSION_MQ}-amd64
# -----------------------------------------------------------------------------
# Default conix password
ARG _PROJ_VERTICAL=conix
ARG _CONIX_USER_PWD=xinoc
ENV MQ_CONIX_USER=${_PROJ_VERTICAL} \
    MQ_CONIX_USER_PWD=${_CONIX_USER_PWD} \
    MQ_CONIX_PATH=${_PROJ_VERTICAL}
RUN echo "Running initally as User " `id`
# -----------------------------------------------------------------------------------
# change to root to make additional settings
USER 0

## Add conix users, and set a default password for admin
## So we can use this user to work with the newly created queues
RUN useradd ${MQ_CONIX_USER} -G mqclient \
 && echo ${MQ_CONIX_USER}:${MQ_CONIX_USER_PWD} |chpasswd 

## Add Conix-Scripts to create conix-queues and re-call origin startup
WORKDIR /${MQ_CONIX_PATH}
COPY . .
RUN chown -R 888:888 /${MQ_CONIX_PATH}

# change back to User from origin image
USER 888
#...origin ENTRYPOINT ["runmqdevserver"]
ENTRYPOINT ["./mq-entry.sh"] 
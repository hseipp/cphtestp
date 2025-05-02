podman run \
       -it \
       --rm \
       -e LICENSE=accept \
       -e MQ_TLS_SNI_HOSTNAME="TRUE" \
       -e MQ_TLS_CIPHER=TLS_RSA_WITH_AES_256_GCM_SHA384 \
       -e MQ_AUTORECONNECT=MQCNO_RECONNECT \
       -e MQ_RESPONDER_THREADS="1" \
       -e MQ_RUNLENGTH="5" \
       -e MQ_NON_PERSISTENT="0" \
       -e MQ_CCDT=ccdt-appqmgr2-1 \
       -e MQ_QMGR_NAME=APPQMGR2 \
       -v cphdata:/var/cph \
       --name cphtest-backup \
       localhost/cphtestp:amd64

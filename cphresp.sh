#!/bin/bash
export BINDINGS=mqc

threads="${1:-200}"
host="${MQ_QMGR_HOSTNAME:-localhost}"
qmname="${MQ_QMGR_NAME:-PERF0}"
port="${MQ_QMGR_PORT:-1420}"
channel="${MQ_QMGR_CHANNEL:-SYSTEM.DEF.SVRCONN}"
requestq="${MQ_QMGR_QREQUEST_PREFIX:-REQUEST}"
replyq="${MQ_QMGR_QREPLY_PREFIX:-REPLY}"
extra="${MQ_CPH_EXTRA}"
userid="${MQ_USERID}"
password="${MQ_PASSWORD}"
nonpersistent="${MQ_NON_PERSISTENT:-0}"
reconnect="${MQ_AUTORECONNECT:-MQCNO_RECONNECT_DISABLED}"
ccdt="${MQ_CCDT}"

echo "${ccdt}"
echo "URL = file:///home/mqperf/cph/ccdt/${ccdt}.json"

if [ "${nonpersistent}" -eq 1 ]; then
  persistent_flags="-tx false -pp false" 
else
  persistent_flags="-tx true -pp true" 
fi

if [ -n "${MQ_USERID}" ]; then
  ./cph -ccdt "file:///home/mqperf/cph/ccdt/${ccdt}.json" -nt $threads -ms 204800 -vo 4 -ve 4 -rl 0 -id 1 -tc Responder -ss 0 -iq $requestq -oq $replyq -db 1 -dx 2 -jb $qmname -jt $BINDINGS -wi 10 -wt 30 -to -1 $persistent_flags -ar $reconnect -tc ReconnectTimer -us $userid -pw $password $extra -jw ${MQ_TLS_CERTLABEL}
else
  ./cph -ccdt "file:///home/mqperf/cph/ccdt/${ccdt}.json" -nt $threads -ms 204800 -vo 4 -ve 4 -rl 0 -id 1 -tc Responder -ss 0 -iq $requestq -oq $replyq -db 1 -dx 2 -jb $qmname -jt $BINDINGS -wi 10 -wt 30 -to -1 $persistent_flags -ar $reconnect -tc ReconnectTimer $extra -jl ${MQ_TLS_CIPHER} -jw ${MQ_TLS_CERTLABEL}
fi


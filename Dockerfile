# © Copyright IBM Corporation 2015, 2019
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM --platform=$TARGETPLATFORM docker.io/ubuntu:22.04 as build-stage

ARG TARGETPLATFORM
RUN export TARGET=`echo ${TARGETPLATFORM} | awk '{print substr($0, 7)}'` && echo "Target Platform:" $TARGETPLATFORM "- short:" $TARGET

RUN export DEBIAN_FRONTEND=noninteractive \
  # Install additional packages - do we need/want them all
  && apt-get update -y \
  && apt-get install -y --no-install-recommends \
    build-essential \
    g++ \
    git \
    ca-certificates

COPY *.deb /
COPY mqlicense.sh /
COPY lap /lap

# Install runtime and SDK for building cph
# Install gskit to create the certificate database
#   see https://www.ibm.com/docs/en/ibm-mq/9.3?topic=windows-setting-up-key-repository-aix-linux
RUN export DEBIAN_FRONTEND=noninteractive \
  && export TARGET=`echo ${TARGETPLATFORM} | awk '{print substr($0, 7)}'` \
  && echo "Target Platform:" $TARGETPLATFORM "- short:" $TARGET \
  && ./mqlicense.sh -accept \
  && dpkg -i ibmmq-runtime_9.3.5.0_${TARGET}.deb \
  && dpkg -i ibmmq-gskit_9.3.5.0_${TARGET}.deb \
  && dpkg -i ibmmq-sdk_9.3.5.0_${TARGET}.deb

RUN git clone https://github.com/ibm-messaging/mq-cph.git

# The cphtestp project uses an April 5, 2022 cph build
RUN cd /mq-cph && git checkout -b 20220405 f00f1a83f06717ccaaa50def332ae26a8d601404 && export installdir=/mq-cph && make

FROM --platform=$TARGETPLATFORM docker.io/ubuntu:22.04 as production-stage

LABEL maintainer "Sam Massey <smassey@uk.ibm.com>"

ARG TARGETPLATFORM
RUN export TARGET=`echo ${TARGETPLATFORM} | awk '{print substr($0, 7)}'` && echo "Target Platform:" $TARGETPLATFORM "- short:" $TARGET

COPY *.deb /
COPY mqlicense.sh /
COPY lap /lap

RUN export DEBIAN_FRONTEND=noninteractive \
  # Install additional packages - do we need/want them all
  && apt-get update -y \
  && apt-get install -y --no-install-recommends \
    bash \
    bc \
    ca-certificates \
    coreutils \
    curl \
    debianutils \
    file \
    findutils \
    gawk \
    grep \
    libc-bin \
    lsb-release \
    mount \
    passwd \
    procps \
    sed \
    tar \
    util-linux \
    iputils-ping \
    sysstat \
    procps \
    apt-utils \
    pcp \
    vim \
    iproute2 \
  # Apply any bug fixes not included in base Ubuntu or MQ image.
  # Don't upgrade everything based on Docker best practices https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#run
  && apt-get upgrade -y libkrb5-26-heimdal \
  && apt-get upgrade -y libexpat1 \
  # End of bug fixes
  && rm -rf /var/lib/apt/lists/* \
  # Optional: Update the command prompt 
  && echo "cph" > /etc/debian_chroot \
  && sed -i 's/password\t\[success=1 default=ignore\]\tpam_unix\.so obscure sha512/password\t[success=1 default=ignore]\tpam_unix.so obscure sha512 minlen=8/' /etc/pam.d/common-password \
  && groupadd --system --gid 1000 mqm \
  && useradd --system --uid 1000 --gid mqm mqperf \
  && usermod -a -G root mqperf \
  && echo mqperf:orland02 | chpasswd \
  && mkdir -p /home/mqperf/cph/ccdt \
  && chown -R mqperf:root /home/mqperf/cph \
  && chmod -R g+w /home/mqperf/cph \
  && echo "cd ~/cph" >> /home/mqperf/.bashrc \
  && service pmcd start

RUN export DEBIAN_FRONTEND=noninteractive \
  && export TARGET=`echo ${TARGETPLATFORM} | awk '{print substr($0, 7)}'` \
  && ./mqlicense.sh -accept \
  && dpkg -i ibmmq-runtime_9.3.5.0_${TARGET}.deb \
  && dpkg -i ibmmq-gskit_9.3.5.0_${TARGET}.deb \
  && dpkg -i ibmmq-client_9.3.5.0_${TARGET}.deb

COPY cph/* /home/mqperf/cph/
COPY --from=build-stage /mq-cph/cph /home/mqperf/cph/cph
COPY ssl/* /opt/mqm/ssl/
COPY *.sh /home/mqperf/cph/
COPY *.mqsc /home/mqperf/cph/
COPY qmmonitor2 /home/mqperf/cph/
COPY ccdt/* /home/mqperf/cph/ccdt/

RUN chown -R mqperf:root /opt/mqm/* \
  && chown -R mqperf:root /var/mqm/* \
  && chown -R mqperf:root /opt/mqm/ssl \
  && chmod o+w /var/mqm

USER mqperf
WORKDIR /home/mqperf/cph

ENV MQ_QMGR_NAME=PERF0
ENV MQ_QMGR_PORT=1420
ENV MQ_QMGR_CHANNEL=SYSTEM.DEF.SVRCONN
ENV MQ_QMGR_QREQUEST_PREFIX=REQUEST
ENV MQ_QMGR_QREPLY_PREFIX=REPLY
ENV MQ_NON_PERSISTENT=
ENV MQ_CPH_EXTRA=
ENV MQ_USERID=
ENV MQ_CCDT=
ENV MQ_RESPONDER_THREADS=2

ENTRYPOINT ["./cphTest.sh"]

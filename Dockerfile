# START STAGE 1
FROM openjdk:8-jdk-slim as builder

USER root

ENV ANT_VERSION 1.10.12
ENV ANT_HOME /etc/ant-${ANT_VERSION}

WORKDIR /tmp

RUN apt-get update && apt-get install -y \
    git \
    curl

RUN curl -L -o apache-ant-${ANT_VERSION}-bin.tar.gz http://www.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz \
    && mkdir ant-${ANT_VERSION} \
    && tar -zxvf apache-ant-${ANT_VERSION}-bin.tar.gz \
    && mv apache-ant-${ANT_VERSION} ${ANT_HOME} \
    && rm apache-ant-${ANT_VERSION}-bin.tar.gz \
    && rm -rf ant-${ANT_VERSION} \
    && rm -rf ${ANT_HOME}/manual \
    && unset ANT_VERSION

ENV PATH ${PATH}:${ANT_HOME}/bin

# RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
#     && apt-get install -y nodejs \
#     && curl -L https://www.npmjs.com/install.sh | sh

FROM builder as tei

ARG TEMPLATING_VERSION=1.0.4
ARG PUBLISHER_LIB_VERSION=2.10.0
ARG ROUTER_VERSION=0.5.1
ARG PUBLISHER_VERSION=master
ARG SHARED_RESOURCES_VERSION=0.9.1
ARG SHAKESPEARE_VERSION=1.1.2
ARG VANGOGH_VERSION=1.0.6

# add key
RUN  mkdir -p ~/.ssh && ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

# Build shakespeare
RUN  git clone https://github.com/eeditiones/shakespeare.git \
    && cd shakespeare \
    && git checkout ${SHAKESPEARE_VERSION} \
    && ant

# Build vangogh
RUN  git clone https://github.com/eeditiones/vangogh.git \
    && cd vangogh \
    && git checkout ${VANGOGH_VERSION} \
    && ant

# Build tei-publisher-app
RUN  git clone https://github.com/eeditiones/tei-publisher-app.git \
    && cd tei-publisher-app \
    && echo Checking out ${PUBLISHER_VERSION} \
    && git checkout ${PUBLISHER_VERSION} \
    && ant

RUN curl -L -o /tmp/oas-router-${ROUTER_VERSION}.xar http://exist-db.org/exist/apps/public-repo/public/oas-router-${ROUTER_VERSION}.xar
RUN curl -L -o /tmp/tei-publisher-lib-${PUBLISHER_LIB_VERSION}.xar http://exist-db.org/exist/apps/public-repo/public/tei-publisher-lib-${PUBLISHER_LIB_VERSION}.xar
RUN curl -L -o /tmp/templating-${TEMPLATING_VERSION}.xar http://exist-db.org/exist/apps/public-repo/public/templating-${TEMPLATING_VERSION}.xar
RUN curl -L -o /tmp/shared-resources-${SHARED_RESOURCES_VERSION}.xar http://exist-db.org/exist/apps/public-repo/public/shared-resources-${SHARED_RESOURCES_VERSION}.xar

FROM eclipse-temurin:11-jre-alpine

ARG EXIST_VERSION=5.3.1

RUN apk add curl

RUN curl -L -o /tmp/exist-distribution-${EXIST_VERSION}-unix.tar.bz2 https://github.com/eXist-db/exist/releases/download/eXist-${EXIST_VERSION}/exist-distribution-${EXIST_VERSION}-unix.tar.bz2 \
    && tar xfj /tmp/exist-distribution-${EXIST_VERSION}-unix.tar.bz2 -C /tmp \
    && rm /tmp/exist-distribution-${EXIST_VERSION}-unix.tar.bz2 \
    && mv /tmp/exist-distribution-${EXIST_VERSION} /exist

COPY --from=tei /tmp/tei-publisher-app/build/*.xar /exist/autodeploy/
COPY --from=tei /tmp/shakespeare/build/*.xar /exist/autodeploy/
COPY --from=tei /tmp/vangogh/build/*.xar /exist/autodeploy/
COPY --from=tei /tmp/*.xar /exist/autodeploy/

WORKDIR /exist

ARG ADMIN_PASS=none

ARG HTTP_PORT=8080
ARG HTTPS_PORT=8443

ENV NER_ENDPOINT=http://localhost:8001
ENV CONTEXT_PATH=auto
ENV PROXY_CACHING=false

ENV JAVA_OPTS \
    -Djetty.port=${HTTP_PORT} \
    -Djetty.ssl.port=${HTTPS_PORT} \
    -Dfile.encoding=UTF8 \
    -Dsun.jnu.encoding=UTF-8 \
    -XX:+UseG1GC \
    -XX:+UseStringDeduplication \
    -XX:+UseContainerSupport \
    -XX:MaxRAMPercentage=${JVM_MAX_RAM_PERCENTAGE:-75.0} \ 
    -XX:+ExitOnOutOfMemoryError

# pre-populate the database by launching it once
RUN bin/client.sh -l --no-gui --xpath "system:get-version()"

RUN if [ "${ADMIN_PASS}" != "none" ]; then bin/client.sh -l --no-gui --xpath "sm:passwd('admin', '${ADMIN_PASS}')"; fi

EXPOSE ${HTTP_PORT}

ENTRYPOINT JAVA_OPTS="${JAVA_OPTS} -Dteipublisher.ner-endpoint=${NER_ENDPOINT} -Dteipublisher.context-path=${CONTEXT_PATH} -Dteipublisher.proxy-caching=${PROXY_CACHING}" /exist/bin/startup.sh
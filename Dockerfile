# START STAGE 1
FROM openjdk:8-jdk-slim as builder

USER root

ENV ANT_VERSION 1.10.13
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

# RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - \
#     && apt-get install -y nodejs \
#     && curl -L https://www.npmjs.com/install.sh | sh

FROM builder as tei

# TODO(DP): Demo App Versions need updating
ARG TEMPLATING_VERSION=1.1.0
ARG PUBLISHER_LIB_VERSION=3.0.0
ARG ROUTER_VERSION=1.8.0
ARG SHAKESPEARE_VERSION=migrate-to-tp8
ARG VANGOGH_VERSION=migrate-to-TP8

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

# Build tei-publisher-lib
RUN if [ "${PUBLISHER_LIB_VERSION}" = "master" ]; then \
        git clone https://github.com/eeditiones/tei-publisher-lib.git \
        && cd tei-publisher-lib \
        && ant \
        && cp build/*.xar /tmp; \
    else \
        curl -L -o /tmp/tei-publisher-lib-${PUBLISHER_LIB_VERSION}.xar https://exist-db.org/exist/apps/public-repo/public/tei-publisher-lib-${PUBLISHER_LIB_VERSION}.xar; \
    fi

# Build tei-publisher-app
COPY . tei-publisher-app/
RUN  cd tei-publisher-app \
    && ant

RUN curl -L -o /tmp/roaster-${ROUTER_VERSION}.xar http://exist-db.org/exist/apps/public-repo/public/roaster-${ROUTER_VERSION}.xar
RUN curl -L -o /tmp/templating-${TEMPLATING_VERSION}.xar http://exist-db.org/exist/apps/public-repo/public/templating-${TEMPLATING_VERSION}.xar

FROM duncdrum/existdb:6.2.0-j8

COPY --from=tei /tmp/tei-publisher-app/build/*.xar /exist/autodeploy/
COPY --from=tei /tmp/shakespeare/build/*.xar /exist/autodeploy/
COPY --from=tei /tmp/vangogh/build/*.xar /exist/autodeploy/
COPY --from=tei /tmp/*.xar /exist/autodeploy/

WORKDIR /exist

# ARG ADMIN_PASS=none

ARG HTTP_PORT=8080
ARG HTTPS_PORT=8443

ENV NER_ENDPOINT=http://localhost:8001
ENV CONTEXT_PATH=auto
ENV PROXY_CACHING=false

ENV JAVA_TOOL_OPTIONS \
  -Dfile.encoding=UTF8 \
  -Dsun.jnu.encoding=UTF-8 \
  -Djava.awt.headless=true \
  -Dorg.exist.db-connection.cacheSize=${CACHE_MEM:-256}M \
  -Dorg.exist.db-connection.pool.max=${MAX_BROKER:-20} \
  -Dlog4j.configurationFile=/exist/etc/log4j2.xml \
  -Dexist.home=/exist \
  -Dexist.configurationFile=/exist/etc/conf.xml \
  -Djetty.home=/exist \
  -Dexist.jetty.config=/exist/etc/jetty/standard.enabled-jetty-configs \
  -Dteipublisher.ner-endpoint=${NER_ENDPOINT} \
  -Dteipublisher.context-path=${CONTEXT_PATH} \
  -Dteipublisher.proxy-caching=${PROXY_CACHING} \
  -XX:+UseG1GC \
  -XX:+UseStringDeduplication \
  -XX:+UseContainerSupport \
  -XX:MaxRAMPercentage=${JVM_MAX_RAM_PERCENTAGE:-75.0} \
  -XX:+ExitOnOutOfMemoryError

# pre-populate the database by launching it once and change default pw
RUN [ "java", "org.exist.start.Main", "client", "--no-gui",  "-l", "-u", "admin", "-P", "", "-x", "sm:passwd('admin','none')" ]

EXPOSE ${HTTP_PORT}
ARG EXIST_VERSION=release
ARG BUILD=local
ARG PUBLISHER_VERSION=9.1.0

FROM ghcr.io/eeditiones/builder:latest AS builder

ARG ROUTER_VERSION=1.10.0

WORKDIR /tmp

# # Build shakespeare
RUN git clone https://github.com/eeditiones/shakespeare.git \
    && cd shakespeare \
    && sed -i 's/$config:webcomponents :=.*;/$config:webcomponents := "local";/' modules/config.xqm \
    && ant xar-local


# # Build vangogh
RUN git clone https://github.com/eeditiones/vangogh.git \
    && cd vangogh \
    && sed -i 's/$config:webcomponents :=.*;/$config:webcomponents := "local";/' modules/config.xqm \
    && ant xar-local


# # Build tei-publisher-lib
RUN git clone https://github.com/eeditiones/tei-publisher-lib.git \
    && cd tei-publisher-lib \
    && ant 


# # Build tei-publisher-app
COPY . tei-publisher-app
RUN cd tei-publisher-app \
    && sed -i 's/$config:webcomponents :=.*;/$config:webcomponents := "local";/' modules/config.xqm \
    && ant xar-local


ADD http://exist-db.org/exist/apps/public-repo/public/roaster-${ROUTER_VERSION}.xar 001.xar

FROM duncdrum/existdb:${EXIST_VERSION} AS build_local

ARG USR=root
USER ${USR}

ONBUILD COPY --from=builder /tmp/tei-publisher-app/build/*.xar /exist/autodeploy/
ONBUILD COPY --from=builder /tmp/tei-publisher-lib/build/*.xar /exist/autodeploy/
ONBUILD COPY --from=builder /tmp/shakespeare/build/*.xar /exist/autodeploy/
ONBUILD COPY --from=builder /tmp/vangogh/build/*.xar /exist/autodeploy/
ONBUILD COPY --from=builder /tmp/*.xar /exist/autodeploy/

# TODO(DP): Tagging scheme add EXIST_VERSION to the tag
FROM  ghcr.io/jinntec/base:main AS build_prod

# NOTE the start URL http://localhost:8080/exist/apps/tei-publisher/index.html 
ARG PUBLISHER_VERSION
# 2.0.2 is not in public repo?
ARG SHAKESPEARE_VERSION=2.0.1 
ARG VANGOGH_VERSION=3.0.0

ARG USR=nonroot
USER ${USR}

# Copy EXPATH dependencies
ONBUILD ADD --chown=${USR} http://exist-db.org/exist/apps/public-repo/public/tei-publisher-${PUBLISHER_VERSION}.xar /exist/autodeploy
ONBUILD ADD --chown=${USR} http://exist-db.org/exist/apps/public-repo/public/shakespeare-pm-${SHAKESPEARE_VERSION}.xar /exist/autodeploy
ONBUILD ADD --chown=${USR} http://exist-db.org/exist/apps/public-repo/public/vangogh-${VANGOGH_VERSION}.xar /exist/autodeploy


FROM build_${BUILD}

ARG USR
USER ${USR}

WORKDIR /exist

# ARG ADMIN_PASS=none

ARG CACHE_MEM
ARG MAX_BROKER
ARG JVM_MAX_RAM_PERCENTAGE
ARG HTTP_PORT=8080
ARG HTTPS_PORT=8443

ARG NER_ENDPOINT=http://localhost:8001
ARG CONTEXT_PATH=auto
ARG PROXY_CACHING=false

ENV JDK_JAVA_OPTIONS="\
    -Dteipublisher.ner-endpoint=${NER_ENDPOINT} \
    -Dteipublisher.context-path=${CONTEXT_PATH} \
    -Dteipublisher.proxy-caching=${PROXY_CACHING}"

# ENV JAVA_TOOL_OPTIONS="\
#   -Dfile.encoding=UTF8 \
#   -Dsun.jnu.encoding=UTF-8 \
#   -Djava.awt.headless=true \
#   -Dorg.exist.db-connection.cacheSize=${CACHE_MEM:-256}M \
#   -Dorg.exist.db-connection.pool.max=${MAX_BROKER:-20} \
#   -Dlog4j.configurationFile=/exist/etc/log4j2.xml \
#   -Dexist.home=/exist \
#   -Dexist.configurationFile=/exist/etc/conf.xml \
#   -Djetty.home=/exist \
#   -Dexist.jetty.config=/exist/etc/jetty/standard.enabled-jetty-configs \
#   -Dteipublisher.ner-endpoint=${NER_ENDPOINT} \
#   -Dteipublisher.context-path=${CONTEXT_PATH} \
#   -Dteipublisher.proxy-caching=${PROXY_CACHING} \
#   -XX:+UseG1GC \
#   -XX:+UseStringDeduplication \
#   -XX:+UseContainerSupport \
#   -XX:MaxRAMPercentage=${JVM_MAX_RAM_PERCENTAGE:-75.0} \
#   -XX:+ExitOnOutOfMemoryError"

# pre-populate the database by launching it once and change default pw
RUN [ "java", "org.exist.start.Main", "client", "--no-gui",  "-l", "-u", "admin", "-P", "" ]

EXPOSE ${HTTP_PORT} ${HTTPS_PORT}

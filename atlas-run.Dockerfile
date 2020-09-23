FROM ubuntu:18.04

MAINTAINER Ribaldo

# install curl and wget
RUN apt update \
  && apt install -y curl wget

# install java 8
RUN apt install -y openjdk-8-jdk
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/

WORKDIR /opt

# install python2
RUN apt install -y software-properties-common \
  && add-apt-repository -y ppa:deadsnakes/ppa \
  && apt install -y python python-pip

# download hbase
ENV HBASE_VERSION 2.3.1
ENV HBASE_URL http://www.apache.org/dist/hbase/$HBASE_VERSION/hbase-$HBASE_VERSION-bin.tar.gz
RUN set -x \
    && curl -fSL "$HBASE_URL" -o /tmp/hbase.tar.gz \
    && curl -fSL "$HBASE_URL.asc" -o /tmp/hbase.tar.gz.asc \
    && tar -xvf /tmp/hbase.tar.gz -C . \
    && rm /tmp/hbase.tar.gz*

RUN ln -s /opt/hbase-$HBASE_VERSION/conf /etc/hbase
RUN mkdir hbase-$HBASE_VERSION/logs

RUN mkdir /hadoop-data

ENV HBASE_PREFIX=/opt/hbase-$HBASE_VERSION
ENV HBASE_CONF_DIR=/etc/hbase

ENV PATH $HBASE_PREFIX/bin/:$PATH

RUN hbase-$HBASE_VERSION/bin/start-hbase.sh

# install solr for querying and logging
ENV SOLR_VERSION=8.6.2
RUN wget https://archive.apache.org/dist/lucene/solr/$SOLR_VERSION/solr-$SOLR_VERSION.tgz \
  && tar xzf solr-$SOLR_VERSION.tgz \
  && rm solr-$SOLR_VERSION.tgz \
  && ./install_solr_service.sh solr-8.6.2.tgz \
  && solr-$SOLR_VERSION/bin/solr start -force -e cloud -z localhost:2181 -noprompt \
  && solr-$SOLR_VERSION/bin/solr create -force -c vertex_index \
  && solr-$SOLR_VERSION/bin/solr create -force -c edge_index \
  && solr-$SOLR_VERSION/bin/solr create -force -c fulltext_index

ADD apache-atlas-2.1.0 atlas
RUN atlas/bin/atlas_start.py

EXPOSE 21000 8983

ENTRYPOINT ["/bin/bash"]
~                         

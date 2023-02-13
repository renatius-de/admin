FROM alpine:latest

MAINTAINER René Six <dev@renatius.de>

ADD --chown=root:root ./*.lua /root/.imapfilter/config.lua

RUN \
    apk add --no-cache \
      lua \
      openssl \
      pcre2 \
    && apk add --no-cache --virtual build-dependencies \
      alpine-sdk \
      lua-dev \
      openssl-dev \
      pcre2-dev \
    && git clone https://github.com/lefcha/imapfilter.git /tmp/imapfilter \
    && cd /tmp/imapfilter \
    && make clean all install \
    && apk del build-dependencies \
    && rm -rf /tmp/*

CMD ["imapfilter", "-v"]

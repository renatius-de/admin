# hadolint ignore=DL3007
FROM alpine:latest

COPY --chown=root:root ./*.lua /root/.imapfilter/config.lua

# hadolint ignore=DL3003,DL3018
RUN \
    apk add --no-cache \
      lua \
      openssl=3.0.8-r0 \
      pcre2=10.42-r0 \
    && apk add --no-cache --virtual build-dependencies \
      alpine-sdk=1.0-r1 \
      lua-dev \
      openssl-dev=3.0.8-r0 \
      pcre2-dev=10.42-r0 \
    && git clone https://github.com/lefcha/imapfilter.git /tmp/imapfilter \
    && cd /tmp/imapfilter \
    && make clean all install \
    && apk del build-dependencies \
    && rm -rf /tmp/*

CMD ["imapfilter", "-v"]

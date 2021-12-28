FROM alpine

MAINTAINER René Six <docker@renatius.de>
WORKDIR /root

RUN apk add --update-cache --no-cache \
      ca-certificates \
      lua \
      pcre2 \
    && apk add --update-cache --no-cache --virtual build-dependencies \
      build-base \
      git \
      lua-dev \
      openssl-dev \
      pcre2-dev \
    && git clone https://github.com/lefcha/imapfilter.git /tmp/imapfilter \
    && cd /tmp/imapfilter \
    && make all install \
    && apk del build-dependencies \
    && rm -rf /var/cache/apk/* /tmp/*

CMD ["imapfilter"]

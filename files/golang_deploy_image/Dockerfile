ARG GO_VERSION=1.17.13

FROM golang:$GO_VERSION-alpine3.16

ENV GO111MODULE=on

#ARG HTTP_PROXY
#ENV HTTP_PROXY=$HTTP_PROXY
#ENV HTTPS_PROXY=$HTTP_PROXY

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
  && apk update --no-cache \
  && export PKGS="docker git curl wget bash openssl rsync openssh-client make gcc g++ python3 linux-headers paxctl libgcc libstdc++ cyrus-sasl-dev perl" \
  && apk add --no-cache $PKGS

ARG KUBECTL_VERSION=1.19.9
RUN wget --no-check-certificate -O /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
  && chmod +x /usr/local/bin/kubectl

ARG HELM_VERSION=3.7.2
COPY helm /usr/local/bin/helm
RUN chmod +x /usr/local/bin/helm
RUN helm repo add stable https://charts.helm.sh/stable

RUN apk add bazel=4.2.2-r2 --update-cache --repository http://nl.alpinelinux.org/alpine/edge/testing --allow-untrusted

RUN mkdir -p $GOPATH/src/golang.org/x \
  && cd $GOPATH/src/golang.org/x \
  && git clone https://github.com/golang/tools.git \
  && git clone https://github.com/golang/lint.git

RUN wget -O - -q https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh| sh -s v1.45.1

RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2


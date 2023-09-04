## gitlab-runner deploy

`gitlab-runner`借助于`helm`和`bazel`，实现go项目的自动化构建，发布到k8s中。

项目只是为了学习，`docker`镜像目前推送到`docker-hub`中。  

### 前置条件

**gitlab-runner**

找一台服务器安装`gitlab-runner`，并且配置好，同时对应的`gitlab`项目，配置好变量  

这里使用到的变量  

<img src="/img/gitlab-runner_4.jpg" alt="gitlab-runner" align=center />

**k8s** 

首先需要一套k8s环境  

### gitlab-runner 的机器中，安装项目依赖的环境

可以在 gitlab-runner 对应的机器中，安装部署需要的环境，这样就能直接利用对应的资源进行项目的部署。  

比如项目部署需要用到 go 环境，helm 环境，bazel 环境。    

**helm**

需要配置好`helm`，这里使用的`helm`的v3版本，配置好`helm`对`k8s`的访问，`gitlab-runner`所在的机器需要安装`helm`

**bazel**

通过`bazel`构建go项目，至于它的优点这里就不啰嗦，`gitlab-runner`所在的机器需要安装`bazel`

最后放上效果截图

`test,build`

<img src="/img/gitlab-runner_7.jpg" alt="gitlab-runner" align=center />

`deploy`

<img src="/img/gitlab-runner_8.jpg" alt="gitlab-runner" align=center />

### 进阶，使用 docker 构建 runner 的依赖环境

gitlab-runner 在注册的时候提供了一个命令的执行环境，有一个选项就是 docker   

选择这个执行命令，我们可以将部署中 gitlab-runner 所依赖的环境，例如 go 环境，helm 环境，bazel 环境 都集成到一个镜像中。  

```
ARG GO_VERSION=1.17.13

FROM golang:$GO_VERSION-alpine3.16

ENV GO111MODULE=on

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
```

然后 gitlab-ci 中指定这个基础镜像就行了，runner 就能使用这个 docker 镜像中的环境来进行项目的编译，打包和部署，这样更加方便。   

```
image: liz2019/dev-golang:1.17

stages:
  - test
  - build
  - deploy

variables:
  GOPROXY: https://goproxy.cn
```
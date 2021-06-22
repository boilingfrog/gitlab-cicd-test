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

**helm**

需要配置好`helm`，这里使用的`helm`的v3版本，配置好`helm`对`k8s`的访问，`gitlab-runner`所在的机器需要安装`helm`

**bazel**

通过`bazel`构建go项目，至于它的优点这里就不啰嗦，`gitlab-runner`所在的机器需要安装`bazel`

最后放上效果截图

`test,build`

<img src="/img/gitlab-runner_7.jpg" alt="gitlab-runner" align=center />

`deploy`

<img src="/img/gitlab-runner_8.jpg" alt="gitlab-runner" align=center />

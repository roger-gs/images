# docker镜像

## 手动制作yum版的nginx镜像

### 获取基础镜像

```shell
docker pull centos:7.7
```

### 进入容器

```shell
docker run -it -p 80:80 centos:7.7 bash
```

### 在容器中安装nginx并运行

```shell
# 在容器中执行
yum install epel-release &&　yum install nginx
nginx "-g daemon off;"" 
```

### 在另外一个终端提交

```SHELL
docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]] # 将容器提交为一个镜像
```

## Dockerfile的方式制作镜像

### Dockerfile命令

- FROM  IMAGE_NAME[:TAG]：指定基础镜像
- LABEL KEY=VALUE：后面可以写作者信息等相关的
- MAINTAINER  string：指定Dockerfile的维护者信息
- USER <USER|UID>[:<GROUP|GID>]：指定容器运行时的用户名和UID
- WORKDIR PATH：指定工作目录
- ENV KEY VALUE：设置容器环境变量
- RUN COMMAND：执行非交付式的shell命令
- VOLUME [“path1”,”path2”,…]：创建挂载点，用于挂载外部存储
- ADD FILE DEST-PATH：将宿主机的文件加到容器指定的目录，如果文件是tar.gz的文件，会自动将其解压
- COPY FILE DEST-PATH：和ADD的作用一样，但是不会将tar.gz的文件自动解压
- EXPOSE PORT1 PORT2：容器暴露的端口
- CMD [“COMMAND”,”ARG1”,”ARG2”…]：容器启动时执行的命令
- ENTRYPOINT [“/PATH/TO/ENTRYPOINT_FILE_or_COMMAND”,”ARG1”,ARG2,…]： 和CMD的功能相似，为容器执行服务，和CMD混用时，后面的CMD的内容将作为参数传递给ENTRYPOINT指令

## 基于alpine制作业务镜像

### 下载alpine镜像

```SHELL
docker pull alpine
```

### 编写Dockerfile

```dockerfile
FROM alpine
LABEL Maintainer="roger" E-main="70924692@qq.com"
ADD repositories /etc/apk
# cat repositories
# https://mirrors.aliyun.com/alpine/v3.14/main
# https://mirrors.aliyun.com/alpine/v3.14/community

#RUN apk update && apk add iotop gcc libgcc libc-dev libcurl libc-utils pcre-dev zlib-dev libnfs make pcre pcre2 net-tools pstree wget libevent libevent-dev iproute2 nginx
RUN apk update && apk add nginx && mkdir /var/www/html && chmod 755 /var/www/html
ADD default.conf /etc/nginx/http.d
ADD index.html /var/www/html
EXPOSE 80
CMD ["nginx", "-g daemon off;"]
```

```shell
# default.cong
# This is a default site configuration which will simply return 404, preventing
# chance access to any other virtualhost.

server {
        listen 80 default_server;
        listen [::]:80 default_server;
        root /var/www/html;
        # Everything is a 404
        #location / {
        #       return 404;
        #}

        # You may need this to prevent return 404 recursion.
        location = /404.html {
                internal;
        }
}

```





# Docker registry

厂库地址：**github.com/docker/distribution**

## 搭建

```shell
docker pull registry
#mkdir /docker/auth  # 创建一个授权使用目录
#cd /docker
#docker run --entrypoint htpasswd registry -Bbn jack 123456 > auth/htpasswd
#docker run -d -p 5000:5000 --restart=always --name registry -v /docker/auth:/auth -e "REGISTRY_AUTH=htpasswd" -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" -e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" registry
docker run -d -it -p 5000:5000 --restart=always --name registry registry
```

新版的registry不需要创建账号密码就可以使用，由于这个是私有的镜像厂库，有些docker在上传、下载镜像时会报错：

```
Error response from daemon: Get http://172.31.6.102:5000/v2/: dial tcp 172.31.6.102:5000: http: server gave HTTP response HTTPS client
```

这个时候需要在**dockerd**的启动选项中增加选项**--insecure-registry 172.31.6.102:5000**，编辑**/lib/systemd/system/docker.service**

```shell
。。。
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --insecure-registry 172.31.6.102:5000
。。。

systemctl daemon-reload
systemctl restart docker
```

# Harbor

可视化的镜像仓库

## 安装

下载离线安装包，解压后配置harbor.yml.tmpl中的hostname、port、https相关配置以及admin的登录密码后，然后安装docker-compose。

```
tar -xf harbor-offline-installer-v2.3.2.tgz
cd harbor
mv harbor.yml.tmpl harbor.yml
vim harbor.yml  # 修改port、hostname、admin密码、如果不使用https的话，将https的相关配置注释掉
apt install docker-compose
./install.sh
```

如上安装完成后，就可以使用使用ip:port的方式访问harbor仓库了。

在使用docker-compose安装harbor时，会重新创建一个bridge设备，如果ip地址和主机其他网路地址有冲突，会影响harbor的正常使用，可以通过一下的方法修改bridge设备的网络地址段：

```json
#在/etc/docker/daemon.json中添加一下内容,然后重启docker-compose
{
  ...
  "default-address-pools": [
    {
      "base": "192.168.0.0/16",
      "size": 24
    }
  ]
}
docker-compose stop
docker-compose down
docker-compose up -d
docker-compose start         
```


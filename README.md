# nginx http3 quic

- Nginx版本：1.16.1
- 测试操作系统：Ubuntu 18.04.4 LTS
- 测试docker版本：19.03.8
- 测试docker-compose版本：1.24.1

# 如何搭建
**以阿里云购买的域名为例子，你首先需要在阿里云的RAM访问控制获取用户AccessKey。**

## 1.拉取docker镜像

```
docker pull registry.cn-chengdu.aliyuncs.com/guoshi_waf/nginx:latest  # nginx http3 quic
docker pull neilpang/acme.sh:latest # 证书签发
```

## 2.下载配置文件

```
cd /opt
git clone https://github.com/guoshikeji/nginx-http3.git
cd nginx-http3
```

## 3.配置域名信息
编辑docker-compose.yml，将其中的example.com全部替换为自己的域名:
![image](https://raw.githubusercontent.com/guoshikeji/nginx-http3/master/imgs/configDomain2.png)

如果有多个域名，则需要给每一个域名都添加配置。在web结点的volumes处添加一行配置，然后在acme.sh结点的comman处添加两行配置，如图所示：
![image](https://raw.githubusercontent.com/guoshikeji/nginx-http3/master/imgs/configDomain.jpg)

## 4.配置用户AccessKey
编辑docker-compose.yml，在Ali_Key和Ali_Secret处分别填写上自己的AccessKey:

```
- Ali_Key=你的key
- Ali_Secret=你的Secret
```

## 5.配置证书目录
编辑nginx.conf，将example.com全部替换为你自己的域名，如果有多个域名，证书路径请参考例子中的格式书写。

**cer路径：/opt/ssl/域名/域名.cer**

**key路径：/opt/ssl/域名/域名.key**

```
ssl_certificate      /opt/ssl/example.com/example.com.cer;
ssl_certificate_key  /opt/ssl/example.com/example.com.key;
```

## 6.启动项目

```
docker-compose up -d
```

## 7.查看证书状态
项目启动之后需要时间来签发证书，如果只有一个域名，则等待大约一分钟之后，查看证书签发情况：

```
docker-compose logs
```
如果出现如下信息，则表示证签发成功：
![image](https://raw.githubusercontent.com/guoshikeji/nginx-http3/master/imgs/ssl.png)

这时候项目才正常启动完成。

# Nginx配置
**Nginx的一些配置可以根据需求自行扩展。**

## 1.限制地区访问
示例配置文件中，给出了Geoip2的相关配置，并在HTTP结点里面，有一个限制地区访问的例子，更多的地区限制可以查阅Geoip的相关网站。

```
# geoip2 conf
map $geoip2_country_code $is_china {
    default no;
    HK no;
    CN yes;
}
....
# Geoip2
if ($is_china = no) {
    return 403;  # 在上面限制里，返回no的地区来访问，nginx将返回403状态码
}
```

## 2.攻击拦截
示例配置里面，默认打开了攻击拦截：

```
modsecurity on;
modsecurity_rules_file /opt/nginx/conf/modsecurity.conf;
```

## 3.http3
在示例配置里面，默认打开了HTTP3协议。打开http3的时候需要注意添加配置"add_header alt-svc"

```
server {
    modsecurity on;
    modsecurity_rules_file /opt/nginx/conf/modsecurity.conf;

    # Enable QUIC and HTTP/3.
    listen 443 quic reuseport; #default_server sndbuf=1048576 rcvbuf=1048576 reuseport;

    listen 443 ssl http2;

    ssl_certificate      /opt/ssl/example.com/example.com.cer;
    ssl_certificate_key  /opt/ssl/example.com/example.com.key;

    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    add_header alt-svc 'quic=":443"; ma=2592000; v="43,46", h3-Q043=":443"; ma=2592000, h3-Q046=":443"; ma=2592000, h3-Q050=":443"; ma=2592000, h3-24=":443"; ma=2592000, h3-25=":443"; ma=2592000';

    location / {
        # root   /opt/html;
        root   html;
        index  index.html index.htm;
    }
}
```

## 4.日志
如果没有修改docker-compose.yml的日志挂载信息，那么Nginx的所有日志都在docker-compose.yml所在目录下的logs里。

- modsec_audit.log是防火墙的日志
- nginx_analytics_access.log是访问日志
- error.log是Nginx的错误日志。

## 5.证书
如果没有修改docker-compose.yml的证书挂载信息，那么生成的所有证书都在docker-compose.yml所在目录下的acmeout里。

容器内部每个域名的证书都有单独文件夹来保存，示例：/opt/ssl/baidu.com，在这个目录下就是 baidu.com 这个域名的证书。

**cer路径：/opt/ssl/域名/域名.cer**

**key路径：/opt/ssl/域名/域名.key**

## 6.修改头部信息
用户可以自行修改相应时候的头部信息，比如修改server字段：

```
#more_clear_headers 'Server';
more_set_headers 'Server: Guoshi  Server';
```
其余参数修改示例：

```
more_set_headers 用于添加、修改、清除响应头
more_clear_headers 用于清除响应头
more_set_input_headers 用于添加、修改、清除请求头
more_clear_input_headers 用于清除请求头
```

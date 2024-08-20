# Docker Web Service应用模板

此应用模板帮助您在阿里云上快捷部署一个遵循最佳实践的Docker Web Service应用，支持部署高可用的生产级别应用和单实例的日常测试应用。

##  提供Docker Web Service应用源代码
此应用模板支持两种方式来上传您的应用源代码：
1. 上传本地的zip文件到应用管理OSS bucket。
2. 指定一个Git仓库。如果是私有仓库需要先授权应用管理访问您的Git仓库。

您的Docker Web Service应用的源代码项目需要满足以下条件：
1. 包含一个docker-compose.yaml文件。
2. 如果docker-compose.yaml中依赖本地build的docker镜像，需要将build相关的文件一并包含在项目中，比如DockerFile
   
应用将使用`docker compose up -d`命令在ECS实例上启动您的Docker应用。

### Docker compose介绍
Docker compose是一种容器编排工具，可以支持启动多个容器。如果您的应用原先是使用单容器运行的，改成使用Docker compose运行也非常简单。您可以参考以下文档了解docker compose：
- [Docker compose官方指南(英文)](https://docs.docker.com/compose/)
- [Compose file reference(英文)](https://docs.docker.com/compose/compose-file/)

### 一个单容器的docker-compose.yaml示例
```yaml
services:
  # 服务名，可以有多个服务
  webapp:
    # docker镜像
    image: "aliyun-computenest-opensource-registry.cn-hangzhou.cr.aliyuncs.com/default/nginx:20240625"
    # 端口映射，容器内80端口映射到主机的5000端口
    ports:
      - "5000:80"
    # 存储卷挂载，将主机的./static目录挂载到容器/usr/share/nginx/html
    volumes:
      - ./static:/usr/share/nginx/html
```

将此文件保存为/root/docker-compose.yaml; 执行echo "Hello World" > /root/static/index.html，然后在/root目录执行`docker compose up -d`启动应用。(/root可以换成您的工作目录)
打开http://localhost:5000访问应用服务。


### 多容器的docker-compose.yaml示例
您可以参考此示例应用：https://gitee.com/betabao/docker-web-app
此应用中包含一个本地Dockerfile构建出的Python flask web容器和一个redis容器。启动后，每次访问网页会将redis中存储的计数加一，并打印次数到网页。


## 部署架构
此应用模板支持两种部署架构，单实例模式和高可用模式。
1. 单实例模式会创建一台带公网IP的ECS，在此ECS实例上部署docker web service应用。可选部署一个RDS数据库。用户通过公网IP访问web服务。单实例模式适合作为开发测试环境。
2. 高可用模式会创建一台或多台ECS实例并加入到弹性伸缩组，并将弹性伸缩组作为应用负载均衡器ALB实例的后端服务器。可选部署一个RDS数据库。用户通过ALB实例的域名访问web服务。高可用模式适合作为生产环境。

RDS数据库的信息（用户名、密码、数据库连接串）会保存到一个环境变量文件中，您可以在docker-compose.yaml中引入环境变量文件，就可以在应用代码中读取环境变量了。

### 单实例模式的架构图

### 高可用模式的架构图

## 更新应用程序
### 应用采用上传zip文件的形式
通过重新上传源代码zip包来更新应用。
### 应用采用Git仓库形式
更换代码分支或者原分支有新的更新（最新commit必须变化）

示例应用不支持更新。
更新应用时支持指定每批

2. 应用管理支持修改资源的配置，比如

## 修改部署设置
1. 应用管理支持通过重新上传源代码zip包或者指定Git代码仓库（如果分支没有变化，分支的最新commit必须已变化）来更新应用。
2. 应用管理支持修改资源的配置，比如


## 计费说明
应用模板本身不收取费用。但因为部署应用创建的资源会产生费用：
- 用户上传的zip源代码包，会存储在应用管理专用的OSS bucket中（bucket名称：applicationmanager-地域-账户id），在OSS保存文件会产生存储费用。对于不再使用的zip包，您可以在OSS控制台手动删除。
- 应用部署创建的云资源会产生费用，包括：
    - ECS实例费用（包括ECS实例规格、磁盘容量、公网带宽）
    - 应用负载均衡器ALB费用（包括实例费、性能容量单位LCU费和公网网络费）
    - RDS数据库费用（包括计算资源费用和存储资源费用）
  
部署应用时支持选择付费类型，包括按量付费和包年包月（ALB只支持按量付费）。
预估费用在部署前可实时看到。

## RAM账号所需权限

此服务模板构建出的服务需要对ECS、VPC等资源进行访问和创建操作，若使用RAM用户创建服务实例，需要在创建服务实例前，对使用的RAM用户的账号添加相应资源的权限。添加RAM权限的详细操作，请参见[为RAM用户授权](https://help.aliyun.com/document_detail/121945.html)。所需权限如下表所示：

| 权限策略名称                              | 备注                            |
|-------------------------------------|-------------------------------|
| AliyunECSFullAccess                 | 管理云服务器服务（ECS）的权限              |
| AliyunVPCFullAccess                 | 管理专有网络（VPC）的权限                |
| AliyunOOSFullAccess                 | 管理系统运维管理服务（OOS）的权限              |
| AliyunROSFullAccess                 | 管理资源编排服务（ROS）的权限              |
| AliyunComputeNestUserFullAccess     | 管理计算巢服务（ComputeNest）的用户侧权限    |
| AliyunRDSFullAccess                 | 管理数据库服务（RDS）的权限              |
| AliyunALBFullAccess                 | 管理应用负载均衡服务（ALB）的权限              |
| AliyunESSFullAccess                 | 管理弹性伸缩服务（ESS）的权限              |
| AliyunRAMFullAccess                 | 管理访问控制（RAM）的权限, 用来创建实例角色并附加到ECS实例，以便可以从ECS实例上下载OSS文件          |


## 部署入口
1. 从应用管理首页->创建应用->快捷创建->过应用模板创建，选择Docker Web Service应用模板，点击正式创建。将会创建一个新应用，包含一个应用分组。
2. 在已有应用里，点击右上角“创建应用分组”->快捷创建->通过应用模板创建,选择Docker Web Service应用模板。将会创建一个新应用分组。

### 部署步骤和输出
请参照页面提示填入参数，点击创建后，应用分组进入部署中状态。在部署成功后，可以查看应用分组的输出信息，包括：
1. 应用域名：点击从浏览器访问您的web服务
2. 应用安装位置：如果您想查看您的源代码，可以登录ECS实例，找到应用安装目录查看
3. 数据库环境变量文件位置：此文件中保存了数据库账号的用户名、密码以及数据库的地址。

[图片]

## 如何在Docker应用中访问数据库
如果您选择部署了数据库，数据库的访问信息会存储到环境变量文件中：/opt/applicationmanager/env/database.env

此环境变量文件的格式入下：
```
DATABASE_HOST=rm-xxxxxxx.mysql.rds.aliyuncs.com
DATABASE_PORT=3306
DATABASE_USERNAME=username
DATABASE_PASSWORD=password
```
在docker-compose.yaml中，可以通过env_file属性，设置容器的环境变量。

```yaml
services:
  webapp:
    image: "you-web-app-image"
    # 将数据库环境变量文件导入到容器，代码中可以读取环境变量获取数据库的地址和账户、密码
    env_file:
      - ../env/database.env
```
然后您的应用程序代码就可以读取环境变量获取数据库的地址和账户、密码，访问数据库。
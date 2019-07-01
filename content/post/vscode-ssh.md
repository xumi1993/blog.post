---
title: "在VSCode中使用Remote-SSH进行远程开发"
date: 2019-06-18T12:30:12+08:00
categories:
- Linux
- subcategory
tags:
- vscode
- SSH
- Linux
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
![](https://microsoft.github.io/vscode-remote-release/images/ssh-readme.gif)
动图来自[官网](https://microsoft.github.io/vscode-remote-release/images/ssh-readme.gif)
<!--more-->

## Overview
远程开发对于开发者尤其是Linux开发者来说是一种迫切的需求，我们所需求的远程开发工具通常需要具备以下几个功能：

- **在本地对服务器端代码进行编辑**
- **能在本地对服务器端代码用服务器端环境进行编译和调试**
- **代码高亮和补全要满足服务器端环境**
- **较低的成本**

那么现有的解决方案有以下几种：

| 方式 | 优点 | 缺点 |
:-: | :-: | :-: 
|通过终端远程登录，用***Vim***、***Emacs***等编辑。| 直接在服务器端运行易于编译调试，通过插件和配置可以获得代码高亮和补全| Vim 没有图形化，在开发大型项目时难以使用|
|使用[JetBrains](http://www.jetbrains.com/)套件中的远程开发功能|可以满足前三个功能|太贵了，对个人用户是一个负担。而社区版则没有这个功能|
|使用VSCode中`rmate`插件|在VSCode中编辑服务器端文件|只能编辑，不能编译和调试。而且使用不便。代码补全也是基于本地环境的|

## 安装
好在最近有***Microsoft***发布的VSCode插件[Remote Development](https://aka.ms/vscode-remote/download/extension)解决了这些问题。首先我们做一些准备工作：

1. 一台开启`open-ssh`的Linux服务器，一台可以远程登录的客户端。
2. 客户端需要版本高于`1.35`的VSCode。
3. 在VSCode中安装[Remote Development](https://aka.ms/vscode-remote/download/extension)

## 配置
我们需要对客户端和服务器端（不需要管理员权限）进行一些配置：

1. 客户端和服务器端需要进行公私要配对，Remote Development不支持单纯的密码登录，但密码可以作为两步认证的密码登录。
2. 在`$HOME/.ssh/config`或者`/etc/ssh/ssh_config`中配置服务器名称和登录信息。在VSCode的命令板中输入`Remote-SSH: Open Configuration File...`，选择要修改的文件，打开文件后输入服务器名称和登录信息。例如：

 ```
Host example-remote-linux-machine
    User your-user-name-here
    HostName host-fqdn-or-ip-goes-here

Host example-remote-linux-machine-with-identity-file
    User your-user-name-on-host
    HostName another-host-fqdn-or-ip-goes-here
    IdentityFile ~/.ssh/id_rsa-remote-ssh
```
> 只在自己的Mac上测试过，详细安装方法见[官方文档](https://code.visualstudio.com/docs/remote/ssh#_getting-started)

## 连接服务器
在命令板中输入`Remote-SSH: Connect to Host...`，然后选择配置过的服务器名就可以链接服务器。
![](/img/vscode-ssh/connect-cmd.png)

或者在左侧工具栏中找到配置过的服务器名就，右键点击连接服务器。
![](/img/vscode-ssh/connect-ui.png)

## 安装远程插件
现在我们还没有安装远程插件，也就是说编译、调试等功能还不能在远程使用。Remote Development提供了远程插件，为SSH主机上的给定工作区安装任何所需的扩展。例如
![](/img/vscode-ssh/ssh-installed-remote-indicator.png)

## 使用
连接服务器之后，再打开文件，这时会询问你服务器上的路径，如图
![](/img/vscode-ssh/enter-path.png)

打开项目后和本地一样设置编译器调试即可。 
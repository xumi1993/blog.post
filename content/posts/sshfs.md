---
title: "用sshfs远程挂载路径到本地"
date: 2019-03-21T13:54:42+08:00
categories:
- Linux
tags:
- SSH
- Linux
- 文件系统
---

**ssh**是常用的远程登陆服务，我们经常使用**scp**、**sftp**等工具与远程服务器进行文件交互。如果是常用的服务器这样工具相对麻烦，如果我们可以像打开本地文件一样打开服务器上的文件就十分方便了。**sshfs可以将远程服务器上的路径作为文件系统挂载到本地。**

<!--more-->
## 1. 安装sshfs
先安装**sshfs**和**fuse**
```
sudo dnf install fuse sshfs
```

## 2. 临时挂载
### 设置本地挂载路径
在本地新建一个路径用于挂载，按照Linux的规则挂载路径通常在`/mnt`下。同时我们还要对新建的路径赋予用户可操作的权限。为了防止其他用户访问我们挂载的路径，这里最好选择修改权限所有者或修改ACL权限。
```
sudo mkdir /mnt/xxx
sudo setfacl -m u:user:rwx /mnt/xxx
```

### 挂载远程路径
下面就可以用sshfs进行挂载
```
sudo sshfs -o allow_other -o reconnect -o transform_symlinks -o follow_symlinks -o cache=yes remote_user@server:/path/to/mount /mnt/xxx
```

- `allow_other` 允许userid与服务器上userid不同的用户访问（**非常重要**）
- `reconnect` 断线重联
- `transform_symlinks` 表示转换绝对链接符号为相对链接符号
- `follow_symlinks` 沿用服务器上的链接符号

### 使用公私钥对登陆
这里和ssh有些不一样，我在配置了公私钥对的情况下，在尝试挂载时还是要求输入密码。所与需要在挂载时使用选项`-o IdentityFile=/path/to/id_rsa`

### 卸载路径
和普通的硬盘卸载一样使用
```
sudo umount /mnt/xxx
```

## 3. 开机自动挂载
开机自动挂载的方式和普通的硬盘一样在`/etc/fstab`中添加
```fstab
sshfs#xu_mijian@114.212.112.63:/path/to/mount /mnt/xxx	fuse	defaults,auto,IdentityFile=/home/user/.ssh/id_rsa,allow_other,reconnect,transform_symlinks,follow_symlinks	0	0
```
然后在命令行中挂载
```
sudo mount -a
```
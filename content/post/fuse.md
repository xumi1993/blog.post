---
title: "用FUSE和ntfs-3g在MacOS下打造免费的NTFS解决方案"
date: 2019-03-25T20:55:03+08:00
categories:
- Mac
tags:
- 文件系统
- Fuse
---
[Paragon NTFS for Mac](https://www.paragon-software.com/home/ntfs-mac/)和[Tuxera](https://www.tuxera.com/products/tuxera-ntfs-for-mac/)是MacOS下常用的NTFS解决方案，但这些软件都是商业软件，而且价格不菲。这些软件除了实现NTFS的读写功能外，还有一些磁盘监测、卸载快捷键等功能，也有很好看的图形界面。但是这些额外功能对我来说都不是必须的，那么有没有一种解决方案可以免费实现最简单的NTFS读写功能呢？

那么这里将介绍通过FUSE和ntfs-3g实现NTFS读写功能
<!--more-->
## FUSE
FUSE源于Linux中的[FUSE API](http://fuse.sourceforge.net/)，它提供了一个用户文件系统的超集，文件系统可以通过FUSE实现。FUSE For MacOS则是FUSE的Mac版本。ntfs-3g也基于FUSE开发，所以要先安装FUSE。
在[FUSE For MacOS](https://osxfuse.github.io/)网站下载***.pkg***安装包，然后图形化安装即可。

## ntfs-3g
ntfs-3g需要在Homebrew下安装，所以要先安装[Homebrew](https://brew.sh/)。然后用`brew`进行安装
```
brew install ntfs-3g
```
安装完成后重启电脑。这时我们已经可以手动挂在NTFS格式文件系统的分区了。假设想要挂在的分区为`/dev/disk2s1`，下面的命令可以把该分区以读写方式挂在到`/Volumes/NTFS`下。
```
sudo mkdir /Volumes/NTFS
sudo /usr/local/bin/ntfs-3g /dev/disk1s1 /Volumes/NTFS -olocal -oallow_other
```

## 自动以读写方式挂载NTFS分区
虽然我们已经可以挂载NTFS分区了，但是当我们插入一块NTFS分区的硬盘，依然只能以只读方式自动挂载。这时因为自动挂载时使用的是Mac默认的NTFS挂载命令，即`/sbin/mount_ntfs`，所以我们要将它替换成ntfs-3g的自动挂载命令。
### 关闭SIP
Mac对操作系统下的文件采取的保护机制SIP (System Integrity Protection)，这样我们无法修改`/sbin`下的文件，所以我们要先关闭SIP。

1. 重启，按住`command+R`，进入保护模式

2. 在菜单栏中打开终端，输入
```
csrutil disable
```

3. 重启操作系统

这时就可以修改`/sbin/mount_ntfs`

### 替换自动挂载命令
- 备份之前的命令

```
sudo mv "/Volumes/Macintosh HD/sbin/mount_ntfs" "/Volumes/Macintosh HD/sbin/mount_ntfs.orig"
```
- 将ntfs-3g中的自动挂载命令替换为自动

```
sudo ln -s /usr/local/sbin/mount_ntfs "/Volumes/Macintosh HD/sbin/mount_ntfs"
```
再次重启电脑，插入NTFS文件系统的磁盘后就可以自动读写挂载了。

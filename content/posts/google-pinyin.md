---
title: "Fedora26中安装Google拼音输入法"
date: 2017-10-27T12:26:29+08:00
categories:
- Linux
tags:
- Tools
- Fedora
- Linux
---

在Fedora25的时候sogou拼音出现了一些不兼容的情况，从而使我转而使用Google拼音。如今操作系统已经换成了Fedora26，这里就记录下安装Google拼音的过程。

<!--more-->
## 输入法和输入源
在Linux系统中，常用的输入源有ibus和fcitx两种，输入法又会被安装在输入源中（Google拼音在fcitx里）。这两种输入源也是不可以同时使用的。Fedora26默认的输入源是ibus（大部分Linux都是），这里带有拼音输入法，但是非常难用。所以要安装Google拼音就需要安装fcitx，并且能停用ibus。这里需要安装的主要工具有：\\
- fcitx
- Googlepinyin
- im-chooser

## 安装软件源
[FZUG](https://repo.fdzh.org/)是fedora的中文源，其中提供了Google拼音，详细信息如下

```
名称         : fcitx-googlepinyin
版本         : 0.1.6
发布         : 3.git6536e18.fc26
架构         : x86_64
大小         : 133 k
Source       : fcitx-googlepinyin-0.1.6-3.git6536e18.fc26.src.rpm
仓库         : @System
来自仓库     : fzug-free
小结         : Googlepinyin module for fcitx
URL          : https://fcitx-im.org/wiki/Googlepinyin
协议         : GPLv3
描述         : fcitx-googlepinyin is a Googlepinyin module for fcitx.

```
所以先使用如下命令安装FZUG源
```
dnf install https://repo.fdzh.org/FZUG/free/26/x86_64/fzug-release-26-0.2.noarch.rpm
```

## 安装Google拼音
直接用`dnf`安装会同时安装Google拼音的依赖，比如fcitx。但是装好之后会发现没办法在fcitx和ibus直接切换，所以还需要安装im-chooser。

```
sudo dnf install fcitx-googlepinyin im-chooser
```

## 切换输入源
im-chooser的功能是切换系统的输入源，这时我们要停用ibus，启用fcitx，在终端输入：

```
im-chooser
```

出现输入法选择器窗口，选择fcitx，**注销后即可生效**
![](/img/google-pinyin/im-chooser.png)

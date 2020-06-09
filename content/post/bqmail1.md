---
title: "BQMail2.0: 向IRIS DMC发送数据请求的Python模块（数据查询）"
date: 2020-06-09T16:58:02+08:00
# draft: true
categories:
- Seismology
tags:
- Python
- BQMail
---

BQMail是用于向IRIS申请数据的Python模块。2016年我们完成了BQMail 1.0版本，但受限于当时IRIS服务的欠缺，随着时间的发展软件出现了以下不足：
- 发送命令繁琐
- 需要本地地震目录
- 可拓展性差

因此我们重写了BQMail的源码，结合了[IRIS DMC Web Services](http://service.iris.edu/fdsnws/)和[ObsPy](http://docs.obspy.org/)，实现了地震和台站的快速查询，并能够以Python模块的方式调用来发送数据请求。
<!--more-->
## 安装
新版的BQMail除了可以源码安装还可以通过PyPI安装
### 通过PyPI安装
对于普通用户我们推荐这种安装方式：
```
pip install bqmail
```
### 通过源码安装
BQMail的源码目前托管在南京大学的Git服务器上，先克隆该项目：
```
git clone https://git.nju.edu.cn/xumi1993/bqmail2.0.git bqmail
```
然后进入目录并安装
```
cd bqmail
pip install .
```

## 地震事件查询
我们调用ObsPy中的IRIS客户端实现了命令行下的地震时间快速查询，安装BQMail后在命令行输入
```
get_events -h
```
获取详细的帮助信息。
```
usage: get_events [-h] [-b B] [-e E] [-d D] [-r R] [-m M] [-p P] [-c C]

Get seismic events from IRIS WS

optional arguments:
  -h, --help  show this help message and exit
  -b B        Start time
  -e E        End time
  -d D        Radial geographic constraints with
              <lat>/<lon>/<minradius>/<maxradius>
  -r R        Box range with <lon1>/<lon2>/<lat1>/<lat2>
  -m M        Magnitude <minmagnitude>[/<maxmagnitude>]
  -p P        Focal depth <mindepth>[/<maxdepth>]
  -c C        Catalog
```
- `-b <starttime>`：地震目录的开始时间，格式与[`obspy.UTCDateTime`](http://docs.obspy.org/packages/autogen/obspy.core.utcdatetime.UTCDateTime.html#obspy.core.utcdatetime.UTCDateTime)的一致。
- `-e <endtime>`：地震目录的结束时间，格式同上。
- `-d <lat>/<lon>/<minradius>/<maxradius>`：以中心点个半径限制发震位置
  - `lat`：中心点纬度
  - `lon`：中心点经度
  - `minradius`：距中心点的最小半径
  - `maxradius`：距中心点的最大半径
- `-r <lon1>/<lon2>/<lat1>/<lat2>`：以矩形范围限制发震位置
  - `lon1`：最小经度
  - `lon2`：最大经度
  - `lat1`：最小纬度
  - `lat2`：最大纬度
- `-m <minmagnitude>[/<maxmagnitude>]`：震级范围，如果只有一个参数则只指定最小震级。
- `-p <mindepth>[/<maxdepth>]`：震源深度范围，如果只有一个参数只指定最小震源深度。
- `-c <catalog>`：地震目录的提供者，可选`GCMT|PDE|ISC`。

### 实例
#### 1. 查询2019年发生的大于7级的地震
```
get_events -b 20190101 -m 7
```
#### 2. 查询发震时刻在2014-1-1至2019-1-1，中心点为23˚E 114˚N，震中距在30˚-90˚之间，震级大于5.5级的地震
```
get_events -b 20140101 -e 20190101 -d 23/114/30/90 -m 5.5
```

## 台站查询
同样的方式实现了命令行下对IRIS DMC台站的查询，在命令行输入
```
get_stations -h
```
可以获取帮助
```
usage: get_stations [-h] [-n N] [-s S] [-r R] [-d D] [-b B] [-e E] [-c C]

Get stations from IRIS WS

optional arguments:
  -h, --help  show this help message and exit
  -n N        Network
  -s S        Station
  -r R        Box range with <lon1>/<lon2>/<lat1>/<lat2>
  -d D        Radial geographic constraints with
              <lat>/<lon>/<minradius>/<maxradius>
  -b B        Start time
  -e E        End time
  -c C        Channel
```

- `-n <network>`：台网名
- `-s <station>`：台站名
- `-r <lon1>/<lon2>/<lat1>/<lat2>`：以矩形范围限制台站位置，用法与`get_events`相同。
- `-d <lat>/<lon>/<minradius>/<maxradius>`：以中心点和半径限制台站位置，用法与`get_events`相同
- `-b <starttime>`： 数据记录的开始时间，用法与`get_events`相同。
- `-e <endtime>`：数据记录的结束时间，用法与`get_events`相同。
- `-c <channel>`：通道名

>⚠️注意：台网名、台站名和通道名支持通配符。

### 实例
#### 1. 查询CB台网下的所有台站
```
get_stations -n CB
```
#### 2. 查询位置在经度98-110，纬度21-36，2003-1-1至今的宽频带台站
```
get_stations -r 98/110/21/36 -b 20030101 -c BHZ
```

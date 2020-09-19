---
title: "BQMail2.0: 向IRIS DMC发送数据请求的Python模块（2. 发送申请）"
date: 2020-08-26T11:31:38+08:00
draft: false
categories:
- Seismology
tags:
- Python
- BQMail
---

在发送数据之前我们需要先查询所需台站和事件。BQMail将根据这些信息发送数据申请。

<!--more-->
BQMail将采用调用Python模块的形式，查询和发送数据
## 导入模块
首先需要导入bqmail和可能用到的模块。

```Python
from bqmail.mail import BQMail
from obspy import UTCDateTime
```

- BQMail中所有的时间信息全部遵循[`obspy.UTCDateTime`](https://docs.obspy.org/tutorial/code_snippets/utc_date_time.html)格式

## 创建BQMail实例
我们首先创建一个BQMail实例。
```Python
bq = BQMail('xxx@xxx.com', server='smtp.xxx.com', password='xxx', username='bqmail')
```

- `'xxx@xxx.com'`是发送邮件和接受邮件信息的邮箱
- `server`是发送邮件所用的smtp服务器。默认为`localhost`。
  > 163邮箱在发送大数据量邮件时可能会被退信，目前测试qq企业邮箱可用。
- `password`是该smtp服务器的密码。
- `username`是IRIS ftp站的用户名。

## 查询台站信息
在发送申请之前我们先查询所需要申请的台站，查询获得台站将全部用于发送数据申请。我们建议先用`get_stations`命令选择合适的限制条件预先查询，再将准确的限制条件写入脚本中。例如

```Python
bq.query_stations(network='CB', station='LZH')
```
**这里所有的参数信息与[FDSN Client Usage](https://service.iris.edu/irisws/fedcatalog/1/)中相同。**

## 发送连续数据申请
部分研究需要发送连续数据申请，即从默一时刻到另一时，以隔固定的时间间隔作为SAC文件的时长。

```Python
bq.send_mail(arrange='continue', starttime=UTCDateTime(2018, 1, 1), 
             endtime=UTCDateTime(2018, 2, 1), time_val_in_hours=24, 
             channel='BH?', location='00')
```
- `arrange='continue'`表示发送连续数据申请。
- `starttime`和`endtime`分别为数据申请的起止时刻。
- `time_val_in_hours`为单位文件的时间长度（时间单位为小时）。
- `channel`和`location`分别为所申请的通道名和位置名，详见[BREQ_FAST Manuals](http://ds.iris.edu/ds/nodes/dmc/manuals/breq_fast/)。

## 发送事件数据申请
另一种申请方式为事件数据申请，即根据搜索的地震事件信息，以某一参考时刻为标准发送数据申请。

### 查询事件信息
在发送申请前需要以一定的限制条件获取事件信息，例如

```Python
bq.query_events(starttime=UTCDateTime(2010, 1, 1), endtime=UTCDateTime(2010, 3, 1),
                minmagnitude=5.5, catalog='GCMT')
```
**这里所有的参数信息与[fdsnws-event web service](https://service.iris.edu/fdsnws/event/1/)中相同。**

### 发送数据申请
获取所需事件信息后，设置截取时窗的标准，即可根据台站和事件发送数据申请。
```python
bq.send_mail(arrange='events', mark="P", time_before=-100, time_after=300)
```
- `arrange='events'`表示发送事件数据申请。
- `mark`表示参考时刻，这里可以选择以发震时刻作为标准，或以某一震相的到时作为标准。
  - `o`: 以发震时刻作为标准。
  - `P`, `S`, `...`: 以指定震相到时作为标准，震相名于Taup相同。
- `time_before`和`time_after`分别表示相对参考时刻前后截取的时长。

## 小结
相对于老版本，新版本可以在Python脚本中修改设置，更加灵活。如果有新的建议和意见请在[项目主页](https://github.com/xumi1993/bqmail/)中提交Issue。
---
title: "发布代码到PyPI"
date: 2017-10-23T21:51:29+08:00
categories:
- Python
tags:
- Development
- Python
---

作为开发者我们希望自己开发的Python模块可以被更多人使用，为了方便使用，[PyPI](https://pypi.python.org/pypi)是管理Python模块最好用的工具之一。所以我们也希望把自己的代码放到PyPI上，以后就可以通过`pip install module`的方式安装模块了。

<!--more-->

## 生成一个本地的 Python 包
- 在本地python目录中新建`setup.py`文件。\\
- 将源码放置在一个新建的目录中，目录名为模块名。\\
- 在`setup.py`中写入包的配置信息。

```python
from setuptools import setup, find_packages

setup(
    name = "sft",
    version = "0.1",
    url = 'https://github.com/xumi1993/SFT',
    author = 'Mijian Xu',
    author_email = 'gomijianxu@gmail.com',
    packages = find_packages(), 
    package_dir = {'sft':'sft'},
    entry_points = {'console_scripts':[
            'get_events = sft.get_events:main',
            'get_resp = sft.get_resp:main',
            'get_stations = sft.get_stations:main',
            'get_synthetics = sft.get_synthetics:main',
            'get_timeseries = sft.get_timeseries:main',
            'get_traveltime = sft.get_traveltime:main'
            ], # 将模块中的函数当作shell命令
            },
    include_package_data=True,
    zip_safe=False
)
```

- 完成后其目录结构\\
`SFT` ------ `sft` ------ `get_events.py`\\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | --- `get_resp.py` \\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | --- ……\\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | --- `setup.py`\\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | ---  ……\\
- 由于这个例子只依赖Python标准库，所以如果需要依赖其他第三方模块需要在`setup.py`中加一个字段：
```python
install_requires=[
        'Twisted>=13.1.0',
        'w3lib>=1.17.0',
        'queuelib',
        'lxml',
        'pyOpenSSL',
        'cssselect>=0.9',
        'six>=1.5.2',
        'parsel>=1.1',
        'PyDispatcher>=2.0.5',
        'service_identity',
    ]
```

## 编译Python包
使用下面命令打包一个源代码的包
```python
python setup.py sdist build
```
这样在当前目录的dist文件夹下，就会多出一个以tar.gz结尾的包了。

## 注册PyPI
打开[PyPI](https://pypi.python.org/pypi)官网点击**Register**注册一个账户，记住用户名和密码后面要用。

## 发布至PyPI
官方推荐的方式是用`twine`模块（我在试用`python setup.py sdist upload`时没有成功）:

- 安装`twine`

    ```python
sudo pip install twine
```
- 上传包

    ```python
twine upload dist/*
```
命令行中会提示输入用户名密码，输入PyPI的用户名密码就发布成功了。

---
title: "判断地理坐标点是否在多边形内的Python实现"
date: 2019-10-08T21:05:16+08:00
categories:
- 地震学技术
tags:
- Geophysics
- Python
keywords:
---

<!--more-->

在地学问题中经常会遇到判断点是否在多边形内的问题，例如成像问题中射线是否穿过某个网格即为此类问题。在Python中我们对处理这样的问题需要满足以下条件：

- 输入多边形经纬度坐标和待判断点的经纬度坐标，输出`True`/`False`
- 能与numpy完美衔接
- 输入为多个点也可以处理

## 用 Shapely 定义多边形

```Python
from shapely.geometry import Point
from shapely.geometry.polygon import Polygon
from io import StringIO
import numpy as np

poly = '''
98.2 27
101 27
102.8 29.2
98.2 29.2
''' # 我们先定义多边形


def points(lats, lons):
    pg = Polygon(np.genfromtxt(StringIO(poly))) # 生成Polygon实例
    return np.array([pg.contains(Point(lo, la)) for lo, la in zip(lons, lats)]) # 判断所有输入的点是否在poly内，返回np.array
```

下面进行一个测试，我们定义两个点分别是`(28, 100)`和`(44, 120)`
```Python
p = np.array([[28, 100], [44, 120]])
print(points(p[:, 0], p[:, 1]))
```
结果为：
```
[ True False]
```
这样结合`np.where`函数可以获取原先列表里在或不再多边形内的点。
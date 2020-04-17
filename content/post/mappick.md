---
title: "用Python交互界面在地图上选取测线位置"
date: 2020-04-17T19:23:46+08:00
categories:
- Python
tags:
- GMT
- Map
---
![](/img/mappick/mappick.gif)
虽然GMT有强大的绘图功能，但是只能生成静态图像。在地震学研究中通常需要在地图上选取测线，获得测线端点的坐标。我们利用Matplotlib的交互界面实现了这一功能。
<!--more-->

## 依赖
- [Matplotlib](https://matplotlib.org/index.html) 图形界面框架
- [Cartopy](https://scitools.org.uk/cartopy/docs/latest/) 绘制地图
- [pyproj](https://pyproj4.github.io/pyproj/stable/) 地理坐标投影

## 功能
- 绘制墨卡托投影下的地图
- 绘制地形数据
- 绘制断层、边界等线段数据（格式与GMT psxy相同）
- 交互选择地图上的两点，并获取其坐标

## 安装
### 通过Pypi安装
```
pip install mapclick
```
### 通过源码安装
```
git clone https://github.com/xumi1993/mapclick.git
cd mapclick
pip install .
```

## 示例
```Python
from mapclick import MapPoint

mp = MapPoint()
mp.generate_map(100, 106, 21.5, 24.5, elev=True, resolution=8, nation=False, xa=0.5, ya=0.5)
mp.plot_line('/path/to/province.cn', linewidth=0.5, color='k')
mp.plot_line('/path/to/faults.ftd', linewidth=1, color=(0/255, 105/255, 167/255))
mp.plot_station('/path/to/stations.lst')
plt.show()
```
弹出图像后用鼠标点击即可。
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
- Matplotlib
- Cartopy
- pyproj
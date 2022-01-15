---
title: "数据切片与绘制的PyGMT实现"
date: 2021-11-30T20:13:09+08:00
draft: false
---
在GMT绘图前经常需要计算数据并保存到本地，再用GMT调用本地数据文件进行绘图。对数据可视化造成了不便。随着[PyGMT](https://www.pygmt.org/latest/index.html)的出现，我们可以在Python脚本中先进行数据计算，后进行绘图。这不仅提高了数据可视化的效率，也解决了Python对地图绘制能力弱的问题。

这里我们介绍用Python从3D数据结构体中进行数据切片，同时用PyGMT绘图的实例。

<!--more-->

## 绘图需求

[FWEA18](http://ds.iris.edu/ds/products/emc-fwea18/)是通过全波形反演获得的东亚3D速度模型，我们将选取一条测线，从模型中切片并绘制该测线的P波速度。

我们用到的Python模块包括

- [scipy](https://scipy.org/)
- [numpy](https://numpy.org/)
- [xarray](http://xarray.pydata.org/)
- [pygmt](https://www.pygmt.org/)

首先在Python脚本中导入这些模块

```python
import pygmt
import numpy as np
import xarray as xr
from scipy.interpolate import interpn
```

## 绘制测线位置

我们选取了经过日本岛弧、朝鲜半岛、渤海湾-华北盆地的测线，首先需要在地图上绘制测线位置。

### 初始化测线

PyGMT继承了GMT中`project`命令，通过定义测线端点位置来初始化测线，这个函数的返回值为`pandas.DataFrame`类型。

```python
lon1, lon2, lat1, lat2 = 111, 142, 39, 35
points = pygmt.project(center='{}/{}'.format(lon1, lat1),
                       endpoint='{}/{}'.format(lon2, lat2),
                       generate=20, unit=True)
```

### 绘制地形图和测线位置

首先下载高程数据，在PyGMT中可以将高程数据保持在一个Python变量中，这样可以减少中间文件的生成也方便后续计算。

```python
grid_topo = pygmt.datasets.load_earth_relief(resolution="05m", region=[108, 150, 24, 53])
```

然后绘制底图和测线，这里用到，`coast`、`grdimage`和`plot`，`coast`绘制的海岸线被地形图覆盖了，这里只做备忘录功能。

```python
fig_map = pygmt.Figure()
fig_map.coast(
    region=[108, 150, 24, 53],
    projection="M15c",
    frame=True,
    borders=1,
    area_thresh=4000,
    shorelines="0.25p,black",
    land=255, water="skyblue"
)
fig_map.grdimage(grid=grid_topo, cmap='globe')
fig_map.plot(data=points.values[:, 0:2], pen='2p,255/23/23')
fig_map.show()
```

<td><center><img src="/img/pygmt/region.png" width=70%/></center></td>

## 根据测线位置进行数据切片

### 读取模型数据

模型可以在[这里](http://ds.iris.edu/files/products/emc/emc-files/FWEA18_kmps.nc)下载，模型为netcdf格式这里可以用`xarray.open_dataset`读取。

```python
raw_data = xr.open_dataset('FWEA18_kmps.nc')
```

### 生成插值所需的网格点坐标

先前我们用`pygmt.project`生成了测线的经纬度，先在需要延展到深度维度，形成一个2D切片。这一步将生产`points2d`，定义了切片上每个经纬度点的坐标 (`lon`, `lat`, `distance`, `depth`)。

```python
depth = np.arange(0, 800+5, 5)
points2d = np.empty([0, 4])
for i, x in enumerate(points.values):
    for j,d in enumerate(depth):
        points2d = np.vstack((points2d, np.append(x, d)))
```

### 线性插值与网格化

先用生成的数据点在三维速度模型中插值，返回一系列散点，再用`pygmt.surface`进行网格化。我们选用经度作为横坐标，所以`surface`中设置`x=points2d[:, 0], y=points2d[:, 3]`。

```python
points_value = interpn((raw_data.depth.values, raw_data.latitude.values, raw_data.longitude.values),
                       raw_data.vpv.values, points2d[:, [3, 1, 0]])
grid = pygmt.surface(x=points2d[:, 0], y=points2d[:, 3], z=points_value,
              region=[lon1, lon2, depth[0], depth[-1]], spacing='0.2/2')
```

## 绘制速度切片

```python
fig_sec = pygmt.Figure()
fig_sec.basemap(frame=["WSne", 'xaf+l"Longitude (\\260)"', 'yaf+l"Depth (km)"'],
                region=[111, 142, 0, 800],
                projection='X15c/-8c')
pygmt.grd2cpt(grid, cmap='seis', continuous=True)
fig_sec.colorbar(position="JMR+o0.5c/0c+w7c/0.5c", frame=["xaf+l\"Vp (km/s)\""])
fig_sec.grdimage(grid, cmap=True)
# 将下一张图的锚点上移8.25cm
fig_sec.shift_origin(yshift="8.25c")
```

{{% admonition type="note" title="⚠️注意" details="false" %}}
引号、反斜杠等需要转义。
{{% /admonition %}}

### 绘制剖面的地形起伏

`grdtrack` 从高程文件中截取地形数据，与GMT不同，这里均可以使用先前生成的Python变量作为输入，而不需要调用本地文件。

```python
ele = pygmt.grdtrack(points=points.values[:, 0:2], grid=grid_topo)
ele.values[:, 2] /= 1000
fig_sec.basemap(frame=['W', 'yaf+l"Elev. (km)"'],
                region=[lon1, lon2, -7, 3],
                projection='X15c/2c')
fig_sec.plot(x=ele.values[:, 0], y=ele.values[:, 2], pen='0.1p',
             close='+y0', color='gray')
fig_sec.show()
```

![](/img/pygmt/sec.png)

## [下载Jupyter-notebook](/source/plot_section.ipynb)
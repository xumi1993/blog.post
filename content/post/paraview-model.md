---
title: "用GMT、PyVista和Paraview对速度模型、地形起伏、Moho面起伏进行三维可视化"
date: 2021-03-07T05:12:28+08:00
draft: false
---
![](/img/paraview/model_NW.png)
我们通过计算获得了地壳三维速度模型、Moho面起伏，为例对比壳内低速区与Moho面起伏的关系，可以将这些结果用Paraview进行三维可视化。由于数据格式的不同，我们需要借助GMT和PyVista辅助绘制。
<!--more-->

# 准备工作
原材料包括三维速度模型、Moho面起伏数据以及地形数据、断层数据等，我们需要将这些不同格式的文件转换成Paraview识别的`.vtk`文件，这里主要用到的工具是[PyVista](https://www.pyvista.org/)，这是一个Python与[Visualization Toolkit (VTK)](https://vtk.org/)的接口，通过这个模块我们可以将Python常用的`np.ndarray`数据转换成VTK文件格式。

## 定义一个类
我们先定义一个Python类，初始化一些每种数据共用的参数，如经纬度范围，深度范围等。
```python
import numpy as np
from scipy.interpolate import griddata
from scipy import ndimage
import scipy.signal as signal
import pyvista as pv
from netCDF4 import Dataset

class XYZ2VTK():
    def __init__(self, lat1=25, lon1=99, lat2=33, lon2=106, val=0.1, maxdep=80):
        self.lat1 = lat1
        self.lat2 = lat2
        self.lon1 = lon1
        self.lon2 = lon2
        self.lats = np.arange(lat1, lat2, 0.1)
        self.lons = np.arange(lon1, lon2, 0.1)
        self.real_dep = np.arange(-maxdep, 2, 2)
        self.dep = self.real_dep / 10
        self.vs_file = 'ETvs.xyz'
        self.moho_file = '../ccp3d/good_moho_ET2020_repick.dat'
        self.topo_file = '../figures/topo_resample.grd'
```
对于深度范围需要做一些说明，我们需要的深度范围是0-80 km，但水平范围分别是7（`lon2-lon1`）和8（`lat2-lat1`）度，两者单位不匹配，但是如果将经纬度换算成大地坐标，深度范围又将远小于水平范围导致图像纵向很扁，难以达到我们想要的效果，这时有两种选择
- 第一种是将经纬度换算成大地坐标，然后将深度范围人为放大，这时水平方向单位是km。
- 第二种是直接将深度范围缩小10倍，这样水平范围是7和8，深度范围也是8，比例较合适。

这里经纬度更符合我们的习惯，因此选择类第二种方法。`self.real_dep`是实际的深度范围，`self.dep`是缩小10倍后绘图用的深度范围。

## 三维速度模型转VTK网格
原始的三维速度模型是`.xyz`数据表文件，包括4列：经度、纬度、深度和速度大小，我们现将其转换为VTK文件，共分为以下几步：

### 将数据表文件网格化为Numpy矩阵
```python
    def read_xyz(self):
        lat, lon, dep, vs = np.loadtxt(self.vs_file, comments='>', unpack=True)
        dep /= -1
        new_lon, new_lat, new_dep = np.meshgrid(self.lons, self.lats, self.real_dep, indexing='ij')
        grid_data = griddata((lon, lat, dep), vs, (new_lon, new_lat, new_dep))
        return grid_data
```
- `lat`, `lon`, `dep`, `vs`是数据文件每列的内容。
- `grid_data`是网格后的的三维矩阵。

### 生成三维速度模型的VTK文件
这一步将速度模型的三维矩阵转换为VTK文件并保存。
```python
    def create_vtk(self):
        grid = pv.UniformGrid()
        grid_vs = self.read_xyz()
        grid.dimensions = grid_vs.shape
        grid.origin = (self.lon1, self.lat1, self.dep[0])
        grid.spacing = (0.1, 0.1, 0.2)
        grid.point_arrays["values"] = grid_vs.flatten(order="F")
        grid.save('ETvs.vtk')
```
- 首先通过`pv.UniformGrid()`定义一个用于可视化的三维网格。
- `grid_vs.shape`、`grid.origin`和`grid.spacing`分别定义了网格的个数，起始点坐标和网格间隔。
- 最后将速度值赋给`grid.point_arrays["values"]`并保存至文件`ETvs.vtk`。


## 将Moho面起伏转换为VTK多边形
Moho文件也是`.xyz`文件，包括经度、纬度和深度三列，Paraview中可以通过多边形数据展示界面起伏。

### 将Moho面起伏网格化为二维矩阵
```Python
    def read_moho(self):
        lat, lon, moho, _ = np.loadtxt(self.moho_file, comments='>', unpack=True)
        idx = np.where(np.logical_not(np.isnan(moho)))[0]
        lat = lat[idx]
        lon = lon[idx]
        moho = -moho[idx]
        new_lon, new_lat = np.meshgrid(self.lons, self.lats)
        grid_data = griddata((lon, lat), moho, (new_lon, new_lat))
        grid_data = ndimage.gaussian_filter(grid_data, sigma=2)
        return new_lon, new_lat, grid_data
```
与速度模型类似，先从`.xyz`文件中读取Moho面深度数据，再将其网格话为二维矩阵。为了更好地可视化，我们将数据进行了高斯滤波，高斯系数为2。

### 将Moho面二维矩阵转换为多边形网格
```Python
    def create_moho_vtk(self):
        xx, yy, moho = self.read_moho()
        points = np.empty([0, 3])
        for i, ix in enumerate(self.lons):
            for j, jy in enumerate(self.lats):
                points = np.vstack((points, [ix, jy, moho[j, i]]))
        grid = pv.PolyData(points)
        grid['values'] = points[:, 2]
        surf = grid.delaunay_2d()
        surf.save('moho_real.vtk')
```
首先将二维矩阵的Moho面起伏转写为三列数据点格式，分别为经度、纬度和Moho面深度。然后用`pv.PolyData(points)`定义一个包含这些数据点的多边形实例，再将数值定义为Moho面深度，这时多边形数据只在网格点中有数据，而网格点间的多边形内没有数据，这时我们用PyVista自带的三角剖分算法`delaunay_2d`，对多边形进行数据填充，最后保存该VTK文件。

## 制作地形起伏数据
### 通过GMT生成地形起伏数据

1. 首先用GMT中`grdcut`截取研究区域的地形起伏。
2. 由于通常地形数据经度较高，反映大范围的地形变化时可能不直观，因此我们用`grdsample`命令对生成的网格文件进行减采样。最后保存为`netCDF`格式文件。

### 将地形数据转换为多边形网格
```python
    def create_topo_vtk(self):
        ds = Dataset(self.topo_file)
        z = ds.variables['z'][:].data / 10
        points = np.empty([0, 3])
        for i, ix in enumerate(self.lons):
            for j, jy in enumerate(self.lats):
                points = np.vstack((points, [ix, jy, z[j, i]]))
        grid = pv.PolyData(points)
        grid['values'] = points[:, 2]
        surf = grid.delaunay_2d()
        surf.save('topo.vtk')
```
首先用`netcdf4`模块读取减采样后的地形数据文件，然后同Moho面起伏，将其转换为多边形网格并保存。

将以上三种数据的VTK文件导入Paraview，即可绘制他们之间的关系。

## TODO
- 用Pavaview取速度等值面
- 用Pavaview将断层投影至地形
- 用Pavaview绘制真实深度刻度
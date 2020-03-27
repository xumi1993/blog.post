---
title: "VTK数据的重采样与三维矩阵化"
date: 2020-03-26T15:17:48+08:00
categories:
- Seismology
tags:
- VTK
- Grid
---
![](/img/vtk2npz/structured_cube.png)

VTK是用于三维可视化的重要格式。如果我们要对三维可视化数据进行更多自定义的计算，则需要将其转化为适用与科学计算的数据格式。
（此图由[*PyVista*](https://docs.pyvista.org/)生成）

<!--more-->
## 1. 读取并拼合所有VTK文件
VTK文件通常生成与大型并行计算程序，程序有时会将整个网格区域划分为多个子区域进行分布式计算。所以在读取网格同时也要将所有网格拼合在一起，组成完整的网格。我们使用[*PyVista*](https://docs.pyvista.org/)模块来进行该处理。首先导入所需模块


```python
import numpy as np
import glob
import pyvista as pv
```

### 循环读取每个VTK文件
我们用列表生成器循环读取每个VTK文件，将其赋给`blocks`
```python
blocks = [pv.read(fname) for fname in sorted(glob.glob('*.vtk'))]
```
### 拼合所有区块

PyVista提供了`MultiBlock`用于拼合不同区块，输出的`mesh`为`UnstructuredGrid`类型，可以用于后续处理
```python
points_vtk = pv.MultiBlock(blocks)
mesh = points_vtk.combine()
```

## 2. 对数据网格化并重采样
由于网格设计的不同这些网格可能是非均匀的，这样就无法将其赋予一个规则矩阵。PyVista提供了通过重采样进行网格话的方式。
```python
grid = pv.create_grid(mesh, dimensions=(600, 60, 100))
image = grid.sample(mesh)
```
- `dimensions`定义了在X、Y和Z方向的采样点个数，点数越多重采样的精度越接近原始网格。
  
这时`image`还是`UnstructuredGrid`类型，但是每个网格已经是均匀的了。我们只需要用`np.reshape`就可以将其转换成矩阵形式（`np.ndarray`）
```python
mat = image.point_arrays['values'].reshape((image.dimensions[::-1]))
```

- `'values'`取决于原始数据的键名，如Specfsem3D生成的网格，数值名为`gll_data`。
  
同时我们可以定义将每个坐标轴也转化为`np.ndarray`格式
```python
x = np.linspace(image.bounds[0], image.bounds[1], image.dimensions[0])
y = np.linspace(image.bounds[2], image.bounds[3], image.dimensions[1])
z = np.linspace(image.bounds[4], image.bounds[5], image.dimensions[2])
```

## 3. 预览重采样后的结果
我们从`mat`中沿XZ方向切一条剖面，用`matplotlib`绘制其结果。
```python
import matplotlib.pyplot as plt
plt.pcolor(x, z, mat[:, 15, :])
plt.colorbar()
plt.ylabel('Z (m)')
plt.xlabel('X (m)')
plt.show()
```
![](/img/vtk2npz/sec.png)
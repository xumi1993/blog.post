---
title: "在直角坐标系中旋转检测版"
date: 2023-08-30T15:06:47+08:00
draft: false
---

最近遇到一个需求，需要在检测版测试中将检测版旋转一定角度，来避免射线方向的Smearing。

<!--more-->

## 定义研究区域和网格点
首先定义研究区域范围为x方向\\(0 - 1000m\\)，y方向\\(0 - 800m\\), 间隔为\\(12m\\)，并生成网格点坐标为`xgrid`和`ygrid`
```Python
import numpy as np
import matplotlib.pyplot as plt
from scipy.interpolate import RegularGridInterpolator

xmin, xmax = 0, 1000    
ymin, ymax = 0, 800    
x0 = (xmin+xmax)/2
y0 = (ymin+ymax)/2
dx = 12
dy = 12
x = np.arange(xmin, xmax, dx)
y = np.arange(ymin, ymax, dy)
ygrid, xgrid = np.meshgrid(y, x, indexing='ij')
```

## 网格点坐标旋转

我们以在原坐标中定义了规则网格\\(x, y\\)即`xgrid`和`ygrid`，选择中心位置\\(x_0, y_0\\)（也可以是任意位置）和角度\\(\theta\\)，进行坐标旋转，获得新的坐标系中对应点的坐标\\(x_1, y_1\\)：

$$ 
\begin{pmatrix} x_1 \\\\ y_1 \end{pmatrix} =
\begin{pmatrix} \cos\theta & \sin\theta \\\\ -\sin\theta & \cos\theta \end{pmatrix}
\begin{pmatrix} x - x_0 \\\\ y - y_0 \end{pmatrix} $$

代码如下

```python
def rotate(x, y, x0, y0, theta):
    x1grid = np.zeros([y.size, x.size])
    y1grid = np.zeros([y.size, x.size])
    rad = np.deg2rad(theta)
    rotmat = np.array([[np.cos(rad), np.sin(rad)],
                       [-np.sin(rad), np.cos(rad)]])
    for i, xx in enumerate(x):
        for j, yy in enumerate(y):
            x1grid[j, i], y1grid[j, i] = rotmat @ np.array([xx-x0, yy-y0])
    return x1grid, y1grid
```

这里定义\\(\theta=60^\circ\\)，并绘制出坐标旋转后新坐标系下\\(x, y\\)对应的坐标\\(x_1, y_1\\)

```python
theta=60
x1grid, y1grid = rotate(x, y, x0, y0, theta)
plt.scatter(x1grid, y1grid, s=2, color='C1')
```
![](/img/rot_checker/grid1.png)


## 在新坐标系中设置检测版
我们在新坐标系下x方向\\(-500 \sim 500m\\)和y方向\\(-600 \sim 600m\\)范围内设置检测版，其中x方向设置6个异常体，y方向设置7个异常体，异常大小为12%

```python
x_lim_cb = [-500, 500]
y_lim_cb = [-600, 600]
hx = 2
hz = 2
x_cb = np.arange(*x_lim_cb, hx)
x_pert = np.zeros_like(x_cb)
y_cb = np.arange(*y_lim_cb, hx)
y_pert = np.zeros_like(y_cb)
pert=0.12
num_per_x = 6
num_per_y = 7
x_pert = np.sin(num_per_x*np.pi*np.arange(x_cb.size)/x_cb.size)
y_pert = np.sin(num_per_y*np.pi*np.arange(y_cb.size)/y_cb.size)
yy, xx = np.meshgrid(y_pert, x_pert, indexing='ij')
xy_pert = xx*yy*pert

plt.pcolor(x_cb, y_cb, xy_pert)
plt.gca().set_aspect('equal')
```
![](/img/rot_checker/checker.png)


## 二维插值获得旋转后的检测版
我们用\\(x_1, y_1\\)在`xy_pert`中插值，即可获得原坐标（\\(x, y\\)）中每个点对应的异常体大小。
```python
interp = RegularGridInterpolator((y_cb, x_cb), xy_pert, bounds_error=False, fill_value=0.)
xy_pert_inter = interp(( y1grid, x1grid))
plt.pcolor(xgrid, ygrid, xy_pert_inter)
plt.gca().set_aspect('equal')
```
![](/img/rot_checker/rot_checker.png)
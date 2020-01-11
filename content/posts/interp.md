---
title: "三维数据体生成与切片"
date: 2020-01-11T21:17:48+08:00
categories:
- Seismology
tags:
- Geophysics
- 差值
- 网格化
---
我们在计算得到的数据通常是非等间隔网格，为了用GMT进行2D可视化，需要将数据网格化后进行差值。

<!--more--> 

## 1. 将文本文件转换为三维数据体
我们拿到的原始文件是包含经度、纬度、深度、和每个数据点的数据（速度、温度、密度等）组成的文本格式文件，以这次的数据为例，我将Excel文件直接复制到文本中形成了以空格为分隔符的文本文件，以下列出部分行：
```
10.55467676	108.4399258	175.207137	0.01217283	-0.015367995	-9.20E-05	1681.16272	3291.964844	5848311808	1.00E+21
10.55113868	107.7219827	175.2071289	0.012363088	-0.01525117	-0.00010885	1675.885254	3292.487305	5847836672	1.00E+21
10.25584183	108.1032219	146.0060139	0.012991064	-0.014229504	-9.73E-05	1679.978882	3292.082031	4886236672	1.00E+21
9.998090145	108.4349265	146.030284	0.01289901	-0.014223722	-8.98E-05	1681.883859	3291.893512	4886096558	1.00E+21
9.998090145	107.8137658	146.0285942	0.013020781	-0.014152945	-0.000117022	1675.698183	3292.505842	4885533575	1.00E+21
10.55468488	108.439848	146.0060673	0.012965109	-0.014302315	-7.66E-05	1684.43457	3291.640869	4887052800	1.00E+21
10.5511462	107.7219104	146.0062614	0.013087932	-0.014204981	-0.000102527	1677.521362	3292.325439	4886397440	1.00E+21
10.25585045	108.1031426	116.804997	0.013968474	-0.01280891	-1.20E-05	1596.835083	3300.313232	3924829952	1.00E+21
9.998090145	108.4348529	116.8293289	0.013916044	-0.012845078	-5.31E-06	1600.383762	3299.961929	3924717946	1.00E+21
```
## 网格化说明
由于这样的数据点是非等间隔的，没有办法进行切片时所需要的差值操作，所以我先将数据进行了三维网格化。这里我选用了Python语言和它的科学计算模块Numpy、Scipy进行网格化。Matlab也可以实现类似功能，核心函数也叫`griddata`。
 ``` Python
import numpy as np
from scipy.interpolate import griddata

def  read_dat(fname):
	data = np.loadtxt(fname)
	data[:, 3] *=  100
	data[:, 4] *=  100
	data[:, 5] *=  100
	return data

def dat2npz(fname='data', latmin=10, latmax=60, lonmin=70, lonmax=140, depmin=0, depmax=700):
	# 在三个纬度上设置研究区域和网格间隔，网格间隔根据需要选取。
	lat = np.arange(latmin, latmax+0.1, 0.1)
	lon = np.arange(lonmin, lonmax+0.1, 0.1)
	dep = np.arange(depmin, depmax+5, 5)
	new_dep, new_lat, new_lon = np.meshgrid(dep, lat, lon, indexing='ij')
	# 读取数据列表
	data =  read_dat(fname)
	# 设置原始数据点位置
	points = np.array([data[:, 2], data[:, 0], data[:, 1]]).T
	# 对每一种数据进行网格化
	vew =  griddata(points, data[:, 3], (new_dep, new_lat, new_lon), method='linear')
	vns =  griddata(points, data[:, 4], (new_dep, new_lat, new_lon), method='linear')
	vrad =  griddata(points, data[:, 5], (new_dep, new_lat, new_lon), method='linear')
	t =  griddata(points, data[:, 6], (new_dep, new_lat, new_lon), method='linear')
	dens =  griddata(points, data[:, 7], (new_dep, new_lat, new_lon), method='linear')
	# 将网格化后每个维度坐标和数据保存在一个.npz文件中
	np.savez('data_0.1.npz', dep=dep, lat=lat, lon=lon, vew=vew, vns=vns, vrad=vrad, t=t, dens=dens)
 ```

## 2. 平面和剖面的切片
用GMT绘制二维图像需要从上一步网格好的数据文件中对某个平面或剖面进行切片。对平面的切片简单一些，对剖面的切片则需要先对大圆弧路径进行差值，生成数据点坐标，再用这些坐标对三维数据体进行差值。
### 2.1 对数据的平面切片  (`cut_plane.py`)
```Python
import numpy as np
from scipy.interpolate import interpn

# 在指定的区域内生成数据点坐标，理论上说这些点也可以是不等间隔的，但是GMT绘图时依旧需要网格化，所以这里还是使用等间隔差值。
def init_plane(lat1=15, lon1=65, lat2=55, lon2=140, val=2, depth=200):
    lat = np.arange(lat1, lat2, val)
    lon = np.arange(lon1, lon2, val)
    points = []
    for la in lat:
        for lo in lon:
            points.append([depth, la, lo])
    return np.array(points)

# 生成的数据点对三维数据体差值
def interall(data, points):
    inter_data = np.zeros([points.shape[0], 2])
    inter_data[:, 0] = interpn((data['dep'], data['lat'], data['lon']), data['vew'], points, bounds_error=False, fill_value=None)
    inter_data[:, 1] = interpn((data['dep'], data['lat'], data['lon']), data['vns'], points, bounds_error=False, fill_value=None)
    # 返回时同时将数据点坐标那三列于差值得到的数据拼贴后一起输出
    return np.hstack((points[:, 1:3], inter_data))


def cut_plane(fname='data_0.1.npz'):
    data=np.load(fname)
    points = init_plane()
    inter_data = interall(data, points)
    # 最后输出到一个文本文本文件
    np.savetxt('vel_200.dat', inter_data)
```
那么这时输出的数据包括了4列，依次为经度，纬度，南北方向的速度和东西方向的速度。

### 2.2 对数据的剖面切片 (`cut_sec.py`)
虽热都是对数据体的切片，但是剖面的切片要更复杂一些。主要的难点是：

- 对大圆弧路径的等距离划分。其中要考虑球面三角函数和椭球矫正（有现成[代码](http://www.seis.sc.edu/software/distaz/)）。但是这里为了方便直接调用了GMT里的[`project`](https://docs.gmt-china.org/5.4/module/project/)命令，直接生成横向网格，更加方便。
- 对原先的南北和东西分量进行坐标旋转，旋转角度是剖面两个端点之间的方位角（请参考[IRIS 的一个教程](http://service.iris.edu/irisws/rotation/docs/1/help/)）。

那么先导入函数库
```python
import numpy as np
from scipy.interpolate import interpn
import subprocess
import re
import sys
from seispy_distaz import *
```

#### 生成数据点
以下是生成据点的函数。需要说明的是`gmt project`是GMT内一个用于投影点的命令，这里直接在Python中调用了，这条命令的具体说明请参考[GMT中文手册](https://docs.gmt-china.org/5.4/module/project/)。所以如果系统中没有GMT，就只能尝试用别的方法了。
```Python
def gen_points(lat1, lon1, lat2, lon2, val=10, depmax=700):
	# 生成GMT命令字符串
    cmd = 'gmt project -C{}/{} -E{}/{} -G{} -Q'.format(lon1, lat1, lon2, lat2, val)
	# 开启一个命令行子进程，并将cmd传入
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
	# 读取网格点经纬度和相对第一个点的距离
    line_pos = np.loadtxt(p.stdout)
    points = []
	# 对深度进行网格有depth和val确定最大深度和间隔
    for dep in np.arange(0, depmax+val, val):
        for row in line_pos:
			# 生成数据列表，这里/111是将千米转化为度
            points.append([dep, row[1], row[0], row[2]/111])
    return np.array(points)
```

#### 对矢量数据进行坐标系旋转
大部分都是标准公式。需要一提的是`distaz`来自`seispy_distaz.py`，一个在原版`distaz`基础上改进过的版本，说不定以后做其他处理还能用的上。
```Python
def rotate(vew, vns, baz):
    angle = np.mod(baz+180, 360)
    vr = vns*cosd(angle) + vew*sind(angle)
    vt = vew*cosd(angle) - vns*sind(angle)
    return vr, vt


def velproj(vew, vns, lat1, lon1, lat2, lon2):
    baz = distaz(lat1, lon1, lat2, lon2).baz
    vr, vt = rotate(vew, vns, baz)
    return vr, vt
```

#### 数据差值
差值和平面切片是类似的。只有以下几点不同：

- 速度为坐标系转化后的速度。
- 需要对垂直方向速度，温度和密度等进行差值。

```Python
def interall(data, vr, vt, points):
    inter_data = np.zeros([points.shape[0], 5])
    inter_data[:, 0] = interpn((data['dep'], data['lat'], data['lon']), vr, points[:, 0:3], bounds_error=False, fill_value=None)
    inter_data[:, 1] = interpn((data['dep'], data['lat'], data['lon']), vt, points[:, 0:3], bounds_error=False, fill_value=None)
    inter_data[:, 2] = interpn((data['dep'], data['lat'], data['lon']), data['vrad'], points[:, 0:3], bounds_error=False, fill_value=None)
    inter_data[:, 3] = interpn((data['dep'], data['lat'], data['lon']), data['t'], points[:, 0:3], bounds_error=False, fill_value=None)
    inter_data[:, 4] = interpn((data['dep'], data['lat'], data['lon']), data['dens'], points[:, 0:3], bounds_error=False, fill_value=None)
    return np.hstack((points, inter_data))
```

#### 这个脚本中一些其他小技巧
由于剖面不止一条，所以我按照我在地震学上的处理方式做了一个剖面列表，给每个剖面编上序号，切剖面和画剖面时只需要改动剖面编号。剖面列表`lines.lst`内容如下：

```
25 80 45 87 a
24 85 25 113 b
25 80 40 118 c

```
> 最后最好空一行，否则有的语言读取可能会有bug。

所以在剖面切片的脚本中就加入了输入剖面编号，剖面切片的功能。以下是输入编号输出对应剖面经纬度的函数：
```Python
def load_line(line_name, line_file='lines.lst'):
    with open(line_file) as f:
        line_content = f.readlines()
    for line_str in line_content:
        line_str = line_str.strip()
        if line_str[-1] == line_name:
            return [float(value) for value in line_str.split()[:-1]]
```


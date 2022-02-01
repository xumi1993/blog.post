---
title: "用GMT绘制中国及周边构造分区与GPS速度场"
date: 2020-01-30T23:18:20+08:00
categories:
- Mapping
tags:
- GMT
---
GMT对地图的处理十分优秀，而且只需要短短几行代码。本文介绍了如何用等距圆锥投影绘制不同范围大小的地形图，以及如何在地形图上绘制断层、文字和矢量等。

![](/img/gmt-map/region.png)
<!--more-->

这种图像通常出现在论文的第一幅图。主要介绍区域构造背景，根据不同的研究需要，可以叠加不同的信息。上图展示了最终图像，其包括了以下几个图层：

- 等距圆锥投影底图
- 地形起伏
- 海岸线和国界
- 带有三角标示的汇聚板块边界
- 汇聚方向回汇聚速率标示
- 中国大陆构造分区
- 中国大陆GPS速度场

以上每一条都是一句或几句GMT命令，将他们按顺序写入脚本即可。

### 1. 绘制等距圆锥投影底图
[等距圆锥投影](https://docs.gmt-china.org/5.4/proj/Jd/)在所有经纬线的比例尺上都不会畸变，因此在绘制高纬度地图时通常选用这种投影方式。
其参数为：
```
-JD<lon>/<lat>/<lat1>/<lat2>/<width>
```

- `<lon>/<lat>` 投影中心位置
- `<lat1>/<lat2>` 两条标准纬线
- `<width>` 图像宽度，后面可以跟单位`i`（英寸）、`c`（厘米）等

在这个例子中我们用`-R`选定绘图范围为
```
R=65/140/10/60
```
这时投影中心位置应设为

$$
lon = (65+140)/2 = 102.5
$$
$$
lat = (10+60)/2 = 35
$$

两条标准纬线决定了圆锥的角度，这个可以根据自己的喜好修改，只需要保证他们的值不超过绘图范围即可。所以投影参数应该设置为
```
J=D102.5/35/36/42/7.5i
```
然后我们用`psbasemap`绘制底图。
```bash
gmt psbasemap -R$R -J$J -Bxa10f5 -Bya10f5 -BWSne -K > $ps
```

### 2. 绘制地形起伏
#### 截取地形数据
绘制地形起伏需要用到地形起伏数据，[GMT中文社区的数据集](https://gmt-china.org/data/)提供了不同分辨率的地形区起伏数据链接。由于地形起伏数据是通常是全球范围的，我们需要用到[`grdcut`](https://docs.gmt-china.org/5.4/module/grdcut/)先将绘图范围内的地形起伏截取出来。
```bash
etopo=$data_dir/etopo1.grd #确定数据的位置
gmt grdcut $etopo -Gtopo.grd -R
```

- `-G`选项指定了截取出来的文件路径。
- `-R`表示截取范围继承上一个命令中的范围，在这里则继承`psbasemap`中的`-R$R`

#### 绘制地形起伏
这一步最重要的是选择一个好看的色标，图中色标是我自定义的一个全球色标，更多色标可以参考[cpt-city](http://soliton.vm.bytemark.co.uk/pub/cpt-city/)。有色标之后就可以用[`grdimage`](https://docs.gmt-china.org/5.4/module/grdimage/)命令绘制地形起伏

```bash
topocpt=$data_dir/cpt/china.cpt #确定色标文件的位置
gmt grdimage topo.grd -R -J -C$topocpt -O -K >> $ps
```

#### 添加光照效果
有时为了使图像更加立体，尤其是为了更好地反应造山带或海沟的特征这是一种很好的方式。这时我们需要先生成一个光照文件，在数学上其实是计算网格文件的方向梯度，所以使用[`grdgradient`](https://docs.generic-mapping-tools.org/5.4/grdgradient.html)命令。
```bash
gmt grdgradient topo.grd -Ne0.7 -A50 -Gtopo_i.grd
```

- `topo.grd`是之前截取出的地形起伏文件
- `-A50`表示方向差分沿方位角50˚
- `-Ne0.7`表示对计算后的梯度值做归一化。其归一化公式如下
  $$
  g_n = A(1.0 - e^{\sqrt{2}})
  $$
  这里$A=0.7$为归一化振幅
- `-Gtopo_i.grd`表示输出文件`topo_i.grd`

现在需要修改上面的`grdimage`命令，在其中加入生成的光照文件，这时绘制地形起伏命令可以写为
```bash
gmt grdimage topo.grd -R -J -C$topocpt -O -K -Itopo_i.grd >> $ps
```

### 3. 绘制海岸线和国界
GMT提供了全球的海岸线数据。也包括了国界，通过[`pscoast`](https://docs.gmt-china.org/5.4/module/pscoast/)绘制它们。
```bash
gmt pscoast -R -J -O -K -A100000 -Dl -W0.3p -N1 >> $ps
```
- `-A`指定了绘制湖泊和岛屿的最小面积，数值越小湖泊越密。这里的数值很大则忽略了绝大部分湖泊
- `-Dl`指定了海岸线的精度为`l`（low），GMT提供了5个不同精度的版本，从高到低依次为：full、high、intermediate、low和crude对应`f|h|i|l|c`
- `-W0.3p`指定了海岸线的粗细
- `-N1`表示绘制国界（不可作为发表使用）。

### 4. 绘制板块边界和构造分区
用[`psxy`](https://docs.gmt-china.org/5.4/module/psxy/)可以绘制这些信息，类似的数据集可以在[GMT中文社区](https://gmt-china.org/data/)中找到
```bash
block=$data_dir/cntectonic.gmt
phpb=$data_dir/PlateBoundary/Philippine.plate
indianbp=$data_dir/PlateBoundary/Indian.plate

# tectonics
gmt psxy $block -R -J -O -K -W1.2p,255,-  >> $ps

# plate boundary
gmt psxy $phpb -R -J -O -K -W1.5p,0/105/167 -Sf0.5c/0.1c+r+t+o0.1 >> $ps
gmt psxy $indianbp -R -J -O -K -W1.5p,0/105/167 -Sf0.5c/0.1c+r+t+o0.1 >> $ps
```

- 绘制构造分区时`-W1.2p,255,-`指定了线型：`1.2p`粗、白色和虚线
- 绘制板块边界时`-W1.5p,0/105/167`中`0/105/167`表示用RGB方式指定颜色。
- `-Sf0.5c/0.1c+r+t+o0.1`定义了表示俯冲方向的三角的位置和大小
  - `0.5c/0.1c`分别表示相邻符号之间的距离和符号的大小，单位是厘米
  - `+r`表示符号绘制在线段右侧
  - `+t`表示符号为三角，更多断层符号请参考[`psxy`说明](https://docs.gmt-china.org/5.4/module/psxy/)
  - `+o0.1`表示线段上的第一个符号距离线段起始偏移0.1

### 5. 绘制GPS速度场
GPS数据来源于 Zhao et al. (2015)，分别有以下几列
```
#  Velocities of campaign stations with respective to EURASIA plate from 2009-2014
#  Lon.— Longitude in angle degree
#  Lat.— Latitude in angle degree
#  Ve  — Velocity(mm/a) in east component
#  Vn  — Velocity(mm/a) in north component
#  sVe — Velocity error(mm/a) in east component
#  Vn  — Velocity error(mm/a) in north component
#  Site— station code
#  Lon.     Lat.    Ve     Vn       sVe     sVn     Site
   112.6    40.9    4.25   -0.12    0.19    0.21    A002
   112.4    40.2    4.85   -0.77    0.28    0.17    A004
   113.1    41.0    5.77   -2.54    0.88    0.70    A005
   113.2    40.8    3.49   -1.10    0.28    0.27    A006
......
```
对于这样的数据格式我们可以用[`psvelo`](https://docs.gmt-china.org/5.4/module/psvelo/)并配合`awk`绘制

```bash
gps=$data_dir/gps_campagin.txt

awk '{print $1,$2,$3,$4,$5,$6,0}' $gps | gmt psvelo -J -R -Se0.02c/0.95/0 -A0.15c+e+p0.75p -G255/23/23 -W0.1p,255/23/23 -K -O >> $ps
```
- `psvelo`中如果要绘制矢量则需要指定`-Se`，其要求输入有7列，前6列与数据中的前6列一致分别是经度、纬度、东西方向速度、南北方向速度、东西方向速度误差和南北方向速度误差（误差用于绘制置信椭圆）。第7列为两个方向的相关性。所以这里用`awk`输出数据表的前6列并将第7列设为0
- `-Se0.02c/0.95/0`表示绘制矢量，`0.02c`表示矢量的缩放比例，即速度为1时矢量长度为0.02厘米；`0.95`表示绘制95%的置信椭圆；`0`设置文本大小，这里没有文本即为0
- `-A0.15c+e+p0.75p`设置了箭头的大小、方向和粗细
- `-G255/23/23`表示矢量填充的颜色


### 6. 绘制板块汇聚方向和回汇聚速率标示
#### 绘制板块汇聚方向示意
本质上这是画了一个很粗的箭头。这里画单一箭头用`psxy`中的绘制矢量标示即可
```bash
echo 80 23 15 1c | gmt psxy -R -J -O -K -SV0.5c+e -W4p -G0 >> $ps
echo 133 22 310 1c | gmt psxy -R -J -O -K -SV0.5c+e -W4p -G0 >> $ps
```
- 我们用`echo`命令为`psxy`输入了4列分别为经度、纬度、方向和矢量长度
- `-SV0.5c+e`表示箭头大小为0.5厘米，箭头绘制在矢量尾端
- `-W4p`矢量粗细为4p
- `-G0`填充黑色

#### 绘制汇聚速率文字标示
GMT中[`pstext`](https://docs.gmt-china.org/5.4/module/pstext/)用于在图上添加文字。
```bash
echo 80 22 ~4 cm/yr | gmt pstext -A -R -J -O -K -F+f10p+a105 -G255 >> $ps
echo 134 21.8 ~8 cm/yr | gmt pstext -A -R -J -O -K -F+f10p+a40 -G255 >> $ps
```

- 输入为三列分别是经度、纬度和文字内容
- `-A`标示旋转角度为水平方向逆时针旋转的角度
- `-F+f10p+a105`用于控制文字的属性
  - `+f10p`表示字体大小为10p
  - `a105`表示旋转105˚


### 7. 一些注意事项
把这些命令按顺序写在脚本里就可以绘制出完整的图像，但为了脚本的规范我们还需注意
- 所有的变量都应该在脚本开头定义，文中为了方便说明才分别定义了每一个变量。
- 设置一些GMT参数来美化图像，GMT默认的边框我个人感觉有点粗可以设定其粗细和刻度文字大小
  
    ```bash
    gmt set FONT_ANNOT_PRIMARY 10 
    gmt set MAP_FRAME_WIDTH 0.08 
    gmt set MAP_TICK_LENGTH_PRIMARY 0.08 
    ```
  
- 在所有绘图命令后加一句结尾语句。
    ```bash
    gmt psxy -R -J -O -T >> $ps
    ```
- 转换图像格式，建议最后将图像转化成一些通用的图像格式如jpg、png、pdf等
    ```bash
    gmt psconvert -A -P -Tg $ps
    ```
- 在脚本结尾删除中间文件。文中生成的 `topo.grd`、`topo_i.grd` 都属于中间文件，要在最后删除。如果进行来图像格式转化，ps文件也要删除。

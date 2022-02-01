---
title: "用GMT绘制极坐标剖面"
date: 2020-01-19T14:42:33+08:00
categories:
- Mapping
tags:
- GMT
---
![](/img/gmt-section/sample.png)

<!--more-->

本文展示了在极坐标系下绘制地理剖面的示例。对于大尺度的地理剖面非常实用。本实例中GMT的难点主要在：

- 极坐标投影与剖面长度的计算。
- 在极坐标系下绘制410 km和600 km弧线。
- 彩色图像绘制。
- 速度矢量的求和与绘制。

## 1. 读取剖面经纬度
剖面列表如下：
```
la1 lo1 la2 lo2 a
-- -- -- -- b
-- -- -- --  c

```
我们可以输入测线编号让脚本获取测线位置。
```Bash
la1=`grep $line_name $lines|awk '{print $1}'`
lo1=`grep $line_name $lines|awk '{print $2}'`
la2=`grep $line_name $lines|awk '{print $3}'`
lo2=`grep $line_name $lines|awk '{print $4}'`
```
其中

- `line_name`为测线编号
- `lines`为剖面列表的路径名（相对或绝对路径）

## 2. 计算剖面长度
由于每条剖面的长度不一样，我们通常指定剖面两个端点来确定剖面位置。在这个脚本的开始我们先通过[`project`](https://docs.gmt-china.org/5.4/module/project/)命令生成测线上的一系列网格点。
```
gmt project -C$lo1/$la1 -E$lo2/$la2 -G10 -Q > great_circle_points.xyp
```
其中

- `-C`, `-E`分别表示测线起始点和终点坐标。
- `-G`后的参数表示相邻两个点的距离（这里设置10 km）
- `-Q`表示使用地图单位
  
生成的数据重定向到`great_circle_points.xyp`，后面还会用到:
```
-50     10      0
-49.9243897556  10.0504392132   10
-49.8487559173  10.1008612754   20
......
-10.1812240988  29.9436088093   4680
-10.08354655    29.974041736    4690
-10     30      4698.54844803
```
输出内容有三列，分别是每个点的经纬度和与第一个点的距离。最后一行的最后一列即为测线的总长（km）。

由于在极坐标投影时单位必须是度，我们要将上述测线单位转换为度，为了简化我们直接将公里数除以111。以下三行命令分别计算了剖面长度（设置绘图范围时使用）、剖面半长度（设置旋转角度是使用）和图幅大小（为了让不同长度剖面等比例）。由于在Shell语言中没有浮点型计算，所以我们用到了awk工具辅助
```Bash
length=`awk '{print $NF/111}' great_circle_points.xyp|tail -1`
half_length=`awk 'BEGIN {print "'$length'"/2}'`
size=`awk 'BEGIN {print "'$length'"*2/3}'`
```

## 3. 根据计算的范围绘制极坐标底图
绘制底图时最重要的两个参数是`-R`和`-J`，他们分别指定了绘制范围和投影方式。
### 绘制范围
```
R=0/$length/5671/6371
```
其中

- `length`表示上面我们计算的测线总长，单位是度。
- `5671/6371`表示上下两个边界的半径，`5671`意为下边界为700 km深

### 极坐标投影
极坐标投影在GMT中用[`-JP`](https://docs.gmt-china.org/5.4/proj/Jp/)表示。其标准格式为
```
-JP[a]<width>[/<theta0>][r][z]
```
其中

- `width`表示图像的宽度
- `theta0`表示旋转角度
- 如果在`P`后面加`a`表示逆时针旋转，否则顺时针旋转
- `z` 表示将 `r` 轴标记为深度而不是半径
- `r` 表示将径向方向反转，此时r轴范围应在0到90之间

这里我们将投影方式设置为
```
J=Pa${size}c/${half_length}z
```
- `size`为上面计算的图幅大小
- `half_length`为旋转角度。

### 绘制底图
有了`-R`和`-J`控制绘图范围和投影方式就可以绘制底图
```Bash
gmt psbasemap -R$R -J$J -Bxa0f5 -Bya200f100 -BWSne -K -O -Yf7.7c >> $ps
```
需要说明的是

- `-Bx`表示X轴的刻度，`a0`表示不画主刻度，`f5`表示没5度画一格副刻度。
- `-By`表示Y轴刻度，每200 km画一格主刻度，每100 km画一格副刻度。
- `-BWSne`表示只有左侧和下侧画刻度，上侧和右侧只画边框。
- `-O`和`-K`在[中文手册`-K`和`-O`选项的说明](https://docs.gmt-china.org/5.4/option/KO/)。
- `-Y`表示相对与纸张的偏移量，也可以参见[中文手册`-X`和`-Y`选项的说明](https://docs.gmt-china.org/5.4/option/XY/).

## 4. 绘制彩色的网格文件
下面需要在底图上绘制我们的数据内容（温度，速度等）

### 数据网格化
虽然我们的数据已经是等间隔的网格数据，但是并不符合GMT绘图的格式标准。GMT要求网格文件是netCDF格式。所以这里使用`xyz2grd`命令只是将文本格式的数据转换成netCDF格式。当然如果想改变网格间隔或者输入数据是非等间隔的也可以`surface`、`greenspline`、`nearneighbor` 或 `triangulate`进行插值。
```Bash
awk '{print $4,6371-$1,$8}' $sec_data | gmt xyz2grd -R -I0.1/10 -Gout.grd
```

- 由于`xyz2grd`要求输入数据为三列（x,y,z 值）所以我们用`awk`命令从数据表里提取出绘图的三列
  - 第一列是横坐标，距离起始点的长度，单位是度。
  - 第二列是半径，所以用地球半径减去深度。
  - 第三列是数值。
- `-R`选项表示继承上个命令设定的范围。
- `-I`表示网格之间的间隔。`0.1`表示横向间隔为0.1度，`10`表示纵向间隔10 km。单位与数据表中的单位相同。
- `-G`后面跟一个输出网格文件的文件名

### 生成一个色标文件
这是所有脚本绘图工具的弱点，我们没有办法用GMT像ParaView一样拖动色块来自定义色标。所以有两种方式去生成色标。

- 用GMT中的`makecpt`或`grd2cpt`命令生成等间隔色标文件。
- 色标文件本质是一个文本文件，所以也可以手动修改文件中的数值来生成色标。
  
如果不需要刻意突出某个范围的数值，而且数值变化偏线性，那么使用`makecpt`命令即可
```Bash
gmt makecpt -Crainbow -T200/1700/50 -Z > tmp.cpt
```

- `-C`选项后跟输入的色标文件（CPT文件）。GMT提供了一些内置的色标（参见[GMT中文手册内置CPT](https://docs.gmt-china.org/5.4/cpt/builtin-cpt/)），在`-C`后加上这些内置色标名即可。色标也可以是一个自定义的色标文件，这时在`-C`后面加上文件的路径名即可。自定义色标可以在[cpt-city](http://soliton.vm.bytemark.co.uk/pub/cpt-city/)中获取。
- `-T`表示色标相对于数值的取值范围。`200/1700/50`意为从200至1700每50在输入色标中取一个值。
- `-Z`表示使用连续色标。
- 最后输出重定向至一个`cpt`文件

### 绘制网格文件
有了网格文件和色标文件，就可以绘制图像了。
```Bash
gmt grdimage out.grd -R -J -O -K -Ctmp.cpt >> $ps
```

- `out.grd`是之前生成的网格文件名。
- `-C`后加之前生成的色标文件名。

**这时一副图的主体就画完了！**

## 5. 在极坐标下画弧线
这里我们想标注410 km和660 km的深度，在极坐标投影下是弧线，所以不能直接指定两个端点坐标，这样画出来是一条直线（在笛卡尔投影下这样做是没问题的）。我们的做法是利用之前生成的测线文件`great_circle_points.xyp`的点，把这些点连起来，来生成弧线。
```Bash
awk '{print $3/111, 5961}' great_circle_points.xyp|gmt psxy -R -J -O -K -W0.7p,-+s  >> $ps
awk '{print $3/111, 5711}' great_circle_points.xyp|gmt psxy -R -J -O -K -W0.7p,-+s  >> $ps
```

- `awk`用来生成每个点的坐标。`$3/111`是将每个点距起始点距离转化为度，`5961`和`5711`分别表示410 km和660 km对应的半径。
- `-W`选项指定了线型。`0.7p`表示线的粗细，`-`表示虚线，`+s`表示两点之间以弧线连接（如果点数够密则影响不大，可以去掉）。

## 6. 绘制色标
现在用刚才生成的色标文件绘制色标，用到[`psscale`](https://docs.gmt-china.org/5.4/module/psscale/)命令。
```Bash
gmt psscale -DjML+w4c/0.4c+o`awk 'BEGIN {print "'$size'"+1}'`c/-0.5c -Ctmp.cpt -Bxafg+l"Temperature (K)" -R -J -O -K >> $ps
```

- `-D`选项控制了色标的长宽和位置。
  - `jML`指定色标的锚点在中间左侧，参考[绘制修饰物](https://docs.gmt-china.org/5.4/basis/embellishment/)。
  - `+w4c/0.4c`表示色标的长为4厘米，宽为0.4厘米。
  - `+o`指定了色标相对于底图的位置。
    - `` `awk 'BEGIN {print "'$size'"+1}'`c``表示向右偏移的距离为`$size+1`厘米。
    - `-0.5c`表示向下偏移1厘米
- `-C`后面跟要绘制的色标文件
- `-Bx`指定色标的刻度
  - `afg`表示自动绘制主刻度、副刻度和网格线。
  - `+l"Temperature (K)"`表示添加标注为Temperature (K)

## 7. 绘制另一个子图
现在要在同一个文件中绘制另一个子图，所以要先画一个一样的底图
```Bash
gmt psbasemap -R$R -J$J -Bxa0f5 -Bya200f100 -BWSne -K -O -Yf7.7c >> $ps
```
与上一个子图不同的是通过`-Y`对底图进行偏移，以免与之前的子图重叠，具体的偏移量只能手动慢慢调试。

## 8. 绘制速度矢量的模。
在数据表里速度有垂直和水平两个分量，我们要先求两个分量矢量和的模，然后绘制成彩色图像。
### 分别将两个分量网格化
```Bash
awk '{print $4,6371-$1,$5}' $sec_data | gmt xyz2grd -R -I0.1/10 -Gvr.grd
awk '{print $4,6371-$1,-1*$7}' $sec_data | gmt xyz2grd -R -I0.1/10 -Gvz.grd
```

### 用两个分量的网格文件求矢量和的模
这里用GMT内置的`grdmath`命令，对两个分量的网格文件求矢量和的模。
$$
|vel|=\sqrt{vx^2+vz^2}
$$
```Bash
gmt grdmath vr.grd vz.grd HYPOT = vel.grd
```

- `HYPOT`表示运算符为上述公式
- `vel.grd`为输出的网格文件名

下面用`grdimage`命令绘制网格文件即可。
```Bash
gmt grdimage vel.grd -R -J -O -K -Cvel.cpt >> $ps
```
这里经过尝试`makecpt`和`grd2cpt`生成的色标都没办法满足我的要求。所以`vel.cpt`只能通过漫长的调试手动生成，其实没什么难度只是过程漫长。

## 9. 绘制矢量
现在我们要将矢量方向以箭头的方式绘制在上一个图层上，同时箭头的长短表示大小。这里我们用到之前生成的两个分量的网格文件，以及[`grdvector`](https://docs.gmt-china.org/5.4/module/grdvector/)命令。
```Bash
gmt grdvector -R -J -O -K vr.grd vz.grd -W0.8p -Si9p -Ix10 -Q0.3c+b+jb+h1+p- -G0 >> $ps
```

- `-W`指定矢量轮廓的粗细为`0.8p`
- `-S`指定每个矢量数据单位在地图上为`9p`
- `-Q`指定箭头的属性，参考[绘制矢量/箭头](https://docs.gmt-china.org/5.4/basis/vector/)
- `-Ix10`表示每个每10个网格画一个箭头，以免箭头太密影响美观。
- `-G`指定箭头填充颜色，`0`表示黑色

### 将箭头填充为渐变色
为了突出数值大小，箭头填充的颜色可以按照其渐变，我们这里使用灰度渐变的色标。我们不知道具体数值的大小范围，所以先生成一个标准色标，在用`grd2cpt`命令自动生成。

- 生成灰度值从0-200的连续色标（黑色至灰度值为200的灰色）
    ```Bash
    cat>tmp.cpt<<eof
    0   200  200  200  1  0   0   0
    eof
    ```
- 按照数值大小自动生成色标文件
  ```Bash
  gmt grd2cpt vel.grd -Ctmp.cpt -Z > tmp.cpt1
  ```

- 将上述`grdvector`中`-G`选项换成`-C`选项就可以把填充色改为渐变色。
  ```Bash
  gmt grdvector -R -J -O -K vr.grd vz.grd -W0.8p -Si9p -Ix10 -Q0.3c+b+jb+h1+p- -Ctmp.cpt1 >> $ps
  ```

### 只绘制部分箭头
有时我们只想绘制部分数值较大的箭头，而省略数值较小的箭头。这是我们需要对数据表做一些筛选判断，并且重新网格化两个分量。
```Bash
awk 'sqrt($5*$5+$7*$7)>0.9{print $4,6371-$1,$5}' $sec_data | gmt xyz2grd -R -I0.1/10 -Gvr.grd
awk 'sqrt($5*$5+$7*$7)>0.9{print $4,6371-$1,-1*$7}' $sec_data | gmt xyz2grd -R -I0.1/10 -Gvz.grd
```
与之前网格化命令不同的是我们在`awk`中多加了一行判断`sqrt($5*$5+$7*$7)>0.9`，来筛选出矢量和大小大于0.9的网格点。然后再用`grdvector`绘制矢量时则只绘制矢量和大小大于0.9的网格。

## 10. 绘制剖面的地形起伏
我们还要在上幅图上方绘制地形起伏。由于地形的变化相对地球半径的尺度非常小，所以需要将地形起伏进行适当放大。

### 重新定义绘图范围
```Bash
R=0/$length/6371/6561
```
长度不变，高度进行放大。
```bash
gmt psbasemap -R$R -JPa${size}c/${half_length} -K -O -Bws -Yf12.3c >> $ps
```
- 只标注`-Bws`可以去除四周的边框和刻度。

### 截取地形起伏数据
这里使用[`grdtrack`](https://docs.generic-mapping-tools.org/5.4/grdtrack.html)命令从地形起伏数据中截取该剖面的地形起伏。这条命令的输出有四列分别为经、纬度、距起始点的距离和高程。
```Bash
gmt grdtrack great_circle_points.xyp -G$etopo | awk '{print $3/111,6371+($4/1000)*40}' > elev
```
在绘制地形时只需要横纵两个坐标，即距离和高程。我们对高程放大了40倍。

### 绘制地形起伏并填充颜色
这时已经可以利用`elev`文件绘制高程了，但是要想填充颜色需要让图形闭合
```bash
tail -r great_circle_points.xyp | awk '{print $3/111,6371}' >> elev
```
这行命令中我们将测线上的点倒序追加到`elev`后面来形成闭合曲线。我们用下面的示意图来表述这一过程
![](/img/gmt-section/elev.jpeg)

最后我们用`psxy`命令绘制地形起伏
```Bash
gmt psxy elev -R -J -W -Ggray -N -K -O>> $ps
```
- `-G`表示填充颜色
- `-N`表示超出`$R`范围的数据仍然绘制。

## 总结和问题
1. 同样是绘制剖面在极坐标下绘制比在笛卡尔坐标下绘制难得多。所以如果剖面不是很长就别用极坐标。
2. 极坐标下没办法绘制Y轴的标签，通常情况下在`-By`选项后加`+l"Depth (km)"`即可，但是极坐标不行。需要的话只能用其他方式画了。
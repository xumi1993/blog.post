---
title: "用GMT绘制中国大陆及邻区地质年代图"
date: 2021-05-14T16:34:22+08:00
draft: False
---

![](/img/gmt-map/geo3al.png)
用GMT绘制绘制地质图一直是一个难题，此前[Po-Chin Tseng的博客](https://jimmytseng79.github.io/GMT5_tutorials/geology_map.html)详细介绍了制作和绘制地质图的过程，并成功绘制了东南亚的地质图。本文将介绍用相似的方法绘制中国大陆及临区的地质图。

<!--more-->
## 数据来源与格式转换
地质图的数据来自美国USGS（[Generalized Geology of the Far East (geo3al)](https://catalog.data.gov/dataset/generalized-geology-of-the-far-east-geo3al)）其分辨率为1:4,000,000。

### 原始数据下载
我们所需要的文件可以从[这里](https://certmapper.cr.usgs.gov/data/we/ofr97470f/spatial/shape/geo3al.zip)下载，
解压该文件后，获得`.shp`, `.dbf`, `.prj` 和 `.shx`文件。

### 格式转换
GMT提供了命令[`ogr2ogr`](https://docs.gmt-china.org/latest/table/ogr2ogr/)来进行地理矢量数据格式之间的转换，也包括这里的`.shp`格式。解压后的坐标不是我们希望的经纬度坐标，而是大地坐标，这里需要使用`ogr2ogr`中的`-t_srs`参数进行坐标转换。

```
ogr2ogr -f GMT geo2al.gmt geo3al.shp -t_srs EPSG:4326
```

这一步需要注意一下几点

- 其中`.dbf`, `.prj` 和 `.shx`文件路径需要与该命令的运行路径为同一路径。
- 确保在安装GMT后所添加的环境变量中包含`PROJ_LIB`这个变量，请参考[GMT安装说明](https://docs.gmt-china.org/latest/install/macOS/#gmt)

### 修改文件头段
格式转换后`geo2al.gmt`文件的头段为
```
# @D21315149832.578|1546682.830|v|J|J
# @P
123.121278084975 53.3084236387908
123.230414901407 53.3161680969698
123.288482121838 53.3166334127133
123.328886980316 53.3062394894715
......
```
我们所需要头段的是岩性`v`（火山岩）和年代`J`（侏罗系），这里我们用`sed`和正则表达式修改文件头段
```bash
sed 's/#[[:space:]]@D[[:digit:]]*.[[:digit:]]*|[[:digit:]]*.[[:digit:]]*|\(.*\)|\(.*\)|\(.*\)/> -Z\2 |\1|\2/g; /^#/d' geo3al.gmt > geo3al.xy2
```
这时`geo3al.xy2`文件头段被修改为
```
> -ZJ |v|J
123.121278084975 53.3084236387908
123.230414901407 53.3161680969698
123.288482121838 53.3166334127133
123.328886980316 53.3062394894715
....
```
这里通过`-Z`指定年代，配合CPT文件和`plot -L`可以为闭合图形填充颜色，来达到绘制地质图的目的。其中CPT文件格式为
```
JK   179/227/238 ; Jurassic-Cretaceous
J     52/178/201 ; Jurassic
```

## 下载链接：
这里我们提供了已经完成上述步骤的地质年代文件和地质年代色标文件，可以在GMT中直接使用。

- [地质年代文件](/source/geo3al.xy2)
- [地质年代色标文件（GTS2012_periods）](/source/geoage.cpt)

## GMT脚本
```shell
data=geo3al.xy2
cpt=geoage.cpt
rocksize=500
lengsize=0.15i

function shp2xyz(){
    ogr2ogr -f GMT geo2al.gmt geo3al.shp -t_srs EPSG:4326
    sed 's/#[[:space:]]@D[[:digit:]]*.[[:digit:]]*|[[:digit:]]*.[[:digit:]]*|\(.*\)|\(.*\)|\(.*\)/> -Z\2 |\1|\2/g; /^#/d' geo3al.gmt > $data
}

function plot_age_legend(){
    cat > tmp << EOF
H 10 3 Age of rock units
G 1p
N 3
EOF
    awk '!/^($|B|F|#)/{print $0}' $cpt | while read label color period
    do
        if [ $label == "N" ]; then period=Neogene; fi
        if [ $label == "MZT" ]; then continue; fi
        echo "S 0.3c r $lengsize $color 0.3p 0.7c $period" >> tmp
    done
    gmt legend tmp -DJBR+w300p/157p+jBR+o0c/-100p+l1.3 -F+p0.7p+g255 -C3p/3p

    gmt legend -DJBR+w150p/50p+jBR+o0c/57p+l1.9 -F+p0.7p+g255 -C3p/1p <<EOF
H 10 3 Rock type

N 2
S 0.3c r 0.2i p400/28:B255 0.3p 0.7c Volcanic rocks
S 0.3c r 0.2i p400/29:B255 0.3p 0.7c Intrusive rocks
S 0.3c r 0.2i p400/44:B255 0.3p 0.7c Ultrabasic igneous rock or ophiolites 
EOF
}

shp2xyz
gmt begin geo3al png
    gmt set FONT_ANNOT_PRIMARY 10
    gmt set MAP_FRAME_WIDTH 0.08
    gmt set MAP_TICK_LENGTH_PRIMARY 0.08

    gmt coast -R70/150/13/55 -JM8.6i -Baf -Df -G255 -BWsNe
    gmt plot $data -C$cpt -L

    gmt gmtconvert $data -S"|v|" > tmp
    awk '!/^($|B|F|#)/{print $1,"p'$rocksize'/28:F100B"$2}' $cpt > tmp.cpt
    gmt plot tmp -Ctmp.cpt -L

    gmt gmtconvert $data -S"|i|" > tmp
    awk '!/^($|B|F|#)/{print $1,"p'$rocksize'/29:F100B"$2}' $cpt > tmp.cpt
    gmt plot tmp -Ctmp.cpt -L

    gmt gmtconvert $data -S"|w|" > tmp
    awk '!/^($|B|F|#)/{print $1,"p'$rocksize'/44:F100B"$2}' $cpt > tmp.cpt
    gmt plot tmp -Ctmp.cpt -L

    gmt coast -SCADETBLUE1

    gmt set FONT_ANNOT_PRIMARY 7p
    plot_age_legend 

    rm tmp  tmp.cpt
gmt end show
 
```

## 特别鸣谢
这次脚本做了大量的修改，非常感谢[田冬冬博士](https://me.seisman.info/)、[姚家园博士](https://core-man.github.io/academic-homepage/)和[GMT中文社区](https://docs.gmt-china.org/)的其他小伙伴的建议和努力，在和他们的讨论中也使我受益匪浅。
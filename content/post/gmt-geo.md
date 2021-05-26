---
title: "用GMT绘制中国大陆及临区地质图"
date: 2021-05-14T16:34:22+08:00
draft: False
---

![](/img/gmt-map/geo3al.png)
用GMT绘制绘制地质图一直是一个难题，此前[Po-Chin Tseng的博客](https://jimmytseng79.github.io/GMT5_tutorials/geology_map.html)详细介绍了制作和绘制地质图的过程，并成功绘制了东南亚的地质图。本文将介绍用相似的方法绘制中国大陆及临区的地质图。

<!--more-->
## 数据来源
地质图的数据来自美国USGS（[Generalized Geology of the Far East (geo3al)](https://catalog.data.gov/dataset/generalized-geology-of-the-far-east-geo3al)）其分辨率为1:4,000,000。

本文已采用与[Po-Chin Tseng的博客](https://jimmytseng79.github.io/GMT5_tutorials/geology_map.html)相同的方法将原始的`.shp`格式文件转换成了GMT可用的`.xyz`格式。另外可以从[cpt-city](http://soliton.vm.bytemark.co.uk/pub/cpt-city/heine/index.html)下载不同的色标为地质图填色。

### 下载链接：
- [地质年代文件](/source/geo3al.xy2)
- [地质年代色标文件（GTS2012_periods）](/source/geoage.cpt)

本文提供的地质年代色标文件最小单位是“纪”，因此在绘制小区域时可能精度较低，有兴趣的读者可以尝试在最小精度为“世”的色标([GTS2012_epochs](http://soliton.vm.bytemark.co.uk/pub/cpt-city/heine/GTS2012_epochs.cpt))中进行修改，来绘制更精细的图像，但这时图注则需要自行修改。
## GMT脚本
```shell
#!/bin/bash
ps=geo3al.ps
data=geo3al.xy2
# cpt=GTS2012_epochs.cpt
cpt=geoage.cpt
rocksize=400

gmt set FONT_ANNOT_PRIMARY 10
gmt set MAP_FRAME_WIDTH 0.08
gmt set MAP_TICK_LENGTH_PRIMARY 0.08

gmt pscoast -R70/150/15/55 -JM8i -Baf -Dl -G255 -Wthinnest -EAS -K -BWSne > $ps
gmt psxy $data -R -J -C$cpt -L -K -O >> $ps

gmt gmtconvert $data -S"|v|" > tmp
awk '/^[0-9]/{print $1,"p'$rocksize'/28:F100B"$2,$3,"p'$rocksize'/28:F100B"$4}' $cpt > tmp.cpt
gmt psxy tmp -R -J -Ctmp.cpt -L -K -O >> $ps

gmt gmtconvert $data -S"|i|" > tmp
awk '/^[0-9]/{print $1,"p'$rocksize'/29:F100B"$2,$3,"p'$rocksize'/29:F100B"$4}' $cpt > tmp.cpt
gmt psxy tmp -R -J -Ctmp.cpt -L -K -O >> $ps

gmt gmtconvert $data -S"|w|" > tmp
awk '/^[0-9]/{print $1,"p'$rocksize'/44:F100B"$2,$3,"p'$rocksize'/44:F100B"$4}' $cpt > tmp.cpt
gmt psxy tmp -R -J -Ctmp.cpt -L -K -O >> $ps

gmt pscoast -R -J -E=AS -O -K -SCADETBLUE1 >> $ps

lengsize=0.15i
gmt set FONT_ANNOT_PRIMARY 7p
gmt pslegend -R -J -O -DJBR+w200p/57p+jBR+l1.3 -F+p0.7p+g255 -C3p/3p -K >> $ps<<eof
H 10 3 Age of rock units
G 1p
N 3
S 0.3c r $lengsize 229/204/132 0.3p 0.7c Cambrian
S 0.3c r $lengsize 102/192/146 0.3p 0.7c Ordovician
S 0.3c r $lengsize 179/225/194 0.3p 0.7c Silurian
S 0.3c r $lengsize 241/213/118 0.3p 0.7c Devonian
S 0.3c r $lengsize 153/194/181 0.3p 0.7c Carboniferous
S 0.3c r $lengsize 251/141/118 0.3p 0.7c Permian
S 0.3c r $lengsize 227/185/219 0.3p 0.7c Triassic
S 0.3c r $lengsize 166/221/224 0.3p 0.7c Jurassic
S 0.3c r $lengsize 191/227/93 0.3p 0.7c Cretaceous
S 0.3c r $lengsize 253/192/145 0.3p 0.7c Paleogene
S 0.3c r $lengsize 255/255/115 0.3p 0.7c Neogene
eof
gmt pslegend -R -J -O -DJBR+w75p/57p+jBR+l1.3+o200p/0p -F+p0.7p+g255 -C3p/3p -K >> $ps<<eof
H 10 3 Rock type
G 5p
S 0.3c r 0.2i p400/28:B255 0.3p 0.7c Volcanic rocks
G 5p
S 0.3c r 0.2i p400/29:B255 0.3p 0.7c Intrusive rocks
eof

gmt psxy -R -J -O -T >> $ps
gmt psconvert -A -P -TG $ps
rm gmt* $ps tmp tmp.cpt 
```

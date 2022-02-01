---
title: "将Fortran中的数组与矩阵保存为numpy中的.npz文件"
date: 2022-02-01T20:34:54+08:00
lastmod: 2022-02-01T20:34:54+08:00
draft: false
keywords: []
description: ""
tags: ["Python", "Fortran"]
categories: ["Python"]
author: "Mijian Xu"

# You can also close(false) or open(true) something for this content.
# P.S. comment can only be closed
comment: false
toc: false
autoCollapseToc: false
postMetaInFooter: false
hiddenFromHomePage: false
# You can also define another contentCopyright. e.g. contentCopyright: "This is another copyright."
contentCopyright: false
reward: false
mathjax: false
mathjaxEnableSingleDollar: false
mathjaxEnableAutoNumber: false

# You unlisted posts you might want not want the header or footer to show
hideHeaderAndFooter: false

# You can enable or disable out-of-date content warning for individual post.
# Comment this out to use the global config.
#enableOutdatedInfoWarning: false

flowchartDiagrams:
  enable: false
  options: ""

sequenceDiagrams: 
  enable: false
  options: ""

---

我们之前讨论过如何用python在三维矩阵中切片，在Python中保存三维矩阵和它的三个坐标轴的方法有用`numpy.savez`将数组和矩阵用不同的键值对保存至一个`.npz`文件。这里将讨论如何用Fortran实现这一过程。

<!--more-->

# NPY-for-Fortran：`npy`文件的Fortran接口
[NPY-for-Fortran](https://github.com/MRedies/NPY-for-Fortran)为Fortran提供了`npy`和`npz`的接口模块。我们在Fortran中将多种精度的`intger`、`real`和`cmplx`的一维或多维数组保存至`npy`或`npz`文件。

# 对NPY-for-Fortran的修改
原版的[NPY-for-Fortran](https://github.com/MRedies/NPY-for-Fortran)不支持将三维矩阵写入`npz`文件，因此我在此基础上加入了对各种不同精度三维数组的支持，参考[xumi1993/NPY-for-Fortran](https://github.com/xumi1993/NPY-for-Fortran.git)。

先将仓库克隆至本地

```
git clone https://github.com/xumi1993/NPY-for-Fortran.git
```
然后复制`src/npy.f90`到任意可调用的路径。

# 调用NPY-for-Fortran

## Fortran程序实例

这里我们定义一个三维矩阵`mtx`，和它的三个坐标轴`x`、`y`和`z`，然后将他们保存在一个`npz`文件里

``` Fortran
program main
    use m_npy

    integer     :: i,j,k
    real(8)     :: mtx(9,10,11), z(9), y(10), x(11)
    character(len=10) :: fname

    fname = 'test.npz'
    do i=1,9
        z(i) = i*0.3
        do j=1,10
            y(i) = i*0.4
            do k=1,11
                x(j) = j *0.5
                mtx(i,j,k) = 20*i**2 + 100*j + k
            enddo
        enddo
    enddo
    

    call add_npz(fname, 'x', x)
    call add_npz(fname, 'y', y)
    call add_npz(fname, 'z', z)
    call add_npz(fname, 'mtx', mtx)

end program
```

## 编译
由于`npy.f90`是一个Fortran模块，所以要先编译这个模块，生成`.mod`文件，再编译上面这个主程序

```
gfortran npy.f90 -c
gfortran example.f90 npy.f90 -o example_npz
```
其中`example.f90`是上述主程序。

# 在Python中查看

用`numpy.load`即可打开`npz`文件并在Python脚本中调用其数值。

```python
import numpy as np
data = np.load('test.npz')
print(data.__dict__)
```

结果为
```
{'_files': ['x.npy', 'y.npy', 'z.npy', 'mtx.npy'],
 'files': ['x', 'y', 'z', 'mtx'],
 'allow_pickle': False,
 'pickle_kwargs': {'encoding': 'ASCII', 'fix_imports': True},
 'zip': <zipfile.ZipFile file=<_io.BufferedReader name='test.npz'> mode='r'>,
 'f': <numpy.lib.npyio.BagObj at 0x7fc3b819c4c0>,
 'fid': <_io.BufferedReader name='test.npz'>}
```

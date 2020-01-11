---
title: "Mpipool Mpi4py"
date: 2019-01-03T13:31:58+08:00
categories:
- Python
tags:
- Python
- Mpi
#thumbnailImage: //example.com/image.jpg
---

[mpi4py](http://mpi4py.readthedocs.io/en/stable/index.html) is a python API for MPI. **MPIPoolExecutor** is a subclass of `mpi4py.futures` to create MPI processes to execute calls asynchronously
<!--more-->

> The **MPIPoolExecutor** class uses a pool of MPI processes to execute calls asynchronously. By performing computations in separate processes, it allows to side-step the [Global Interpreter Lock](https://docs.python.org/3/glossary.html#term-global-interpreter-lock) but also means that only picklable objects can be executed and returned. The `__main__` module must be importable by worker processes

## Test Script
The test script shows a way to calculate $2^{x}$ in a loop

```python
from mpi4py.futures import MPIPoolExecutor

executor = MPIPoolExecutor(max_workers=100)
for result in executor.map(pow, [2]*32, range(32)):
    print(result)
```

- `executor` is an instance of `MPIPoolExecutor` with `max_workers` of 100
- Calculate $2^x$ in a `map` where $x$ set from 0 to 31

## Time length running
```python
starttime = time.time()
......
endtime = time.time()
print('Running for %6.3fs' % endtime - starttime)
```

## Run this script via mpiexec
script for MPIPoolExecutor could run via mpiexec in [command line](http://mpi4py.readthedocs.io/en/stable/mpi4py.futures.html#command-line)

```bash
mpiexec -n 100 python -m mpi4py.futures MpiPool.py
```
the script would be execute with 100 cores

## Comparision
- **2.7007s** running with 1 core
- **0.1527s** running with 100 core

## Test script
```Python
from mpi4py.futures import MPIPoolExecutor
import time

if __name__ == '__main__':
    executor = MPIPoolExecutor(max_workers=100)
    starttime = time.time()
    for result in executor.map(pow, [2]*32, range(32)):
        print(result)
    endtime = time.time()
    print('Running for %6.3fs' % endtime - starttime)

```
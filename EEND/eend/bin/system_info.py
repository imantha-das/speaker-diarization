# Copyright 2019 Hitachi, Ltd. (author: Yusuke Fujita)
# Licensed under the MIT license.

import sys
import chainer

if chainer.backends.cuda.available:
    import cupy
    import cupy.cuda
    from cupy.cuda import cudnn

def print_system_info():
    pyver = sys.version.replace('\n', ' ')
    print(f"python version: {pyver}")
    print(f"chainer version: {chainer.__version__}")
    if chainer.backends.cuda.available:
        try:
            print(f"cupy version: {cupy.__version__}")
            print(f"cuda version: {cupy.cuda.runtime.runtimeGetVersion()}")
            print(f"cudnn version: {cudnn.getVersion()}")
        except:
            print("CUDA not found!")
    else:
        print("CUDA not found!")

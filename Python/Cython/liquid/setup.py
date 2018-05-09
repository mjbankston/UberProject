from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

EXTENSIONS = [
    Extension('liquid', ['liquid.pyx'],
              include_dirs=[],
              library_dirs=['/usr/local/lib'],
              extra_compile_args=['-fPIC'],
              extra_link_args=['-fPIC'],
              libraries=['fftw3f-3', 'm', 'c', 'liquid'])
]

setup(
    ext_modules=cythonize(EXTENSIONS)
)

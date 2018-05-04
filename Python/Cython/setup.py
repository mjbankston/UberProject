from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

EXTENSIONS = [
    Extension("cliquid", ["src/cliquid.pyx"],
              include_dirs=['include'],
              extra_compile_args=[],
              extra_link_args=['lib/libliquid.a'],
              libraries=['fftw3f', 'm', 'c'],
              library_dirs=['lib']),
    Extension("liquid", ["src/liquid.pyx"],
              include_dirs=[],
              library_dirs=[])
]

setup(
    ext_modules=cythonize(EXTENSIONS)
)

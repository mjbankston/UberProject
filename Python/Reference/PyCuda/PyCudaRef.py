import pycuda.driver as cuda
import pycuda.autoinit
from pycuda.compiler import SourceModule
import numpy

SIZE = 10

FUNC = """
    __global__ void doublify(float *a)
    {{
      int idx = threadIdx.x + threadIdx.y*{0};
      a[idx] *= 2;
    }}
    """.format(SIZE)


def main():
    a_matrix = numpy.random.randn(SIZE, SIZE)
    a_matrix = a_matrix.astype(numpy.float32)
    a_gpu = cuda.mem_alloc(a_matrix.nbytes)
    cuda.memcpy_htod(a_gpu, a_matrix)

    mod = SourceModule(FUNC)

    func = mod.get_function("doublify")
    func(a_gpu, block=(SIZE, SIZE, 1))

    a_doubled = numpy.empty_like(a_matrix)
    cuda.memcpy_dtoh(a_doubled, a_gpu)
    print('Original Matrix:')
    print(a_matrix)
    print()
    print('Doubled Matrix:')
    print(a_doubled)


if __name__ == '__main__':
    print(FUNC)
    main()

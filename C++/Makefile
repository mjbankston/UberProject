default: build

build: src/DemodPLL.c
	gcc -O3 -Wall -fPIC -Iinclude -c src/DemodPLL.c -o src/DemodPLL.o
	gcc -O3 -Wall -fPIC src/DemodPLL.o lib/libliquid.a -o bin/DemodPLL -lfftw3f -lm -lc
	rm src/DemodPLL.o
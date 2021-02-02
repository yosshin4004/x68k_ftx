all: main.X


main.X: \
	main.o \
	..\..\FTX\FTX2lib.o

	HLK $^ -o$@ -l BASLIB.L CLIB.L DOSLIB.L IOCSLIB.L FLOATFNC.L GNULIB.A
	dir $@


%.o::%.c
	gcc -c $< -O


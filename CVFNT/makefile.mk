all: CVFNT.X


CVFNT.X: \
	CVFNT.o \
	..\FTX\FTX2lib.o

	LK $^ -o$@ -l BASLIB.L CLIB.L DOSLIB.L IOCSLIB.L FLOATFNC.L GNULIB.A
	dir $@

%.o::%.c
	gcc -c $< -O


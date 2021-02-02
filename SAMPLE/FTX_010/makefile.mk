all: main.X FONT.FNT


main.X: \
	main.o \
	..\..\FTX\FTX2lib.o

	HLK $^ -o$@ -l BASLIB.L CLIB.L DOSLIB.L IOCSLIB.L FLOATFNC.L GNULIB.A
	dir $@


FONT.FNT: \
	FONT.SP

	..\..\CVFNT\CVFNT.X -i FONT.SP -o FONT.FNT


%.o::%.c
	gcc -c $< -O


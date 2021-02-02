all: FTX2lib.o

FTX2lib.o: FTXlib.s
	HAS -o $@ $^ > log.txt || type log.txt


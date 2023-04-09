CFLAGS = -O -Wall
LIBS =

all:: test

test: test.o driftGenerator.o
	cc -o $@ test.o driftGenerator.o $(LIBS) $(CFLAGS)
	strip $@

test.o: test.c driftGenerator.h
	cc -c test.c -o $@ $(CFLAGS)

driftGenerator.o: driftGenerator.c driftGenerator.h
	cc -c driftGenerator.c -o $@ $(CFLAGS)


clean::
	/bin/rm -f test test.o driftGenerator.o


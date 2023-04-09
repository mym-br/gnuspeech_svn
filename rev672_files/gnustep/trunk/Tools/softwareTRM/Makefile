
CC = gcc
SHELL = /bin/sh
PROGRAM = tube
CFLAGS = -O3 -DGNUSTEP -Wall
#CFLAGS = -g -DGNUSTEP -Wall
LDFLAGS = -lm
.SUFFIXES: .c .o

OBJ = fir.o \
input.o \
main.o \
output.o \
ring_buffer.o \
tube.o \
util.o \
wavetable.o

all: $(PROGRAM)

$(PROGRAM): $(OBJ)
	$(CC) $(CFLAGS) $(LDFLAGS) $(OBJ) -o $(PROGRAM)

clean:
	-rm -f $(PROGRAM) *.o

dep:
	rm -f dep.make;
	for foo in *.c; do \
		gcc -MM $$foo >> dep.make; \
	done

fir.o: fir.c fir.h tube.h input.h structs.h ring_buffer.h wavetable.h
input.o: input.c input.h structs.h ring_buffer.h wavetable.h fir.h
main.o: main.c tube.h input.h structs.h ring_buffer.h wavetable.h fir.h \
  output.h
output.o: output.c output.h structs.h ring_buffer.h wavetable.h fir.h \
  main.h tube.h input.h util.h
ring_buffer.o: ring_buffer.c ring_buffer.h
tube.o: tube.c main.h tube.h input.h structs.h ring_buffer.h wavetable.h \
  fir.h util.h
util.o: util.c util.h
wavetable.o: wavetable.c fir.h tube.h input.h structs.h ring_buffer.h \
  wavetable.h

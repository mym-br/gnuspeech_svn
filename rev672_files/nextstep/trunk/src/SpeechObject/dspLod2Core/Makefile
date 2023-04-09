#  name of executable
DSPLOD2CORE= dspLod2Core

#  compiler flags
CFLAGS= -O -Wall

#  rules to generate executable
all:: $(DSPLOD2CORE)

$(DSPLOD2CORE): $(DSPLOD2CORE).c
	cc $(DSPLOD2CORE).c -o $@ $(CFLAGS)
	strip $@

#  rule to clean directory
clean::
	/bin/rm -f $(DSPLOD2CORE)

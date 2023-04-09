#  REVISION INFORMATION  ######################################################
#
#  $Author: rao $
#  $Date: 2002-03-21 16:49:54 $
#  $Revision: 1.1 $
#  $Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/dspLod2Core/Makefile,v $
#  $State: Exp $
#
#
#  $Log: not supported by cvs2svn $
# Revision 1.1.1.1  1995/01/09  22:41:42  len
# Initial archive of dspLod2Core.
#
#
###############################################################################

#  name of executable
DSPLOD2CORE= dspLod2Core

#  compiler flags
CFLAGS= -O -Wall
ARCHS= -arch m68k -arch i386

#  rules to generate executable
all:: $(DSPLOD2CORE)

$(DSPLOD2CORE): $(DSPLOD2CORE).c
	cc $(DSPLOD2CORE).c -o $@ $(ARCHS) $(CFLAGS)
	strip $@

#  rule to clean directory
clean::
	/bin/rm -f $(DSPLOD2CORE)


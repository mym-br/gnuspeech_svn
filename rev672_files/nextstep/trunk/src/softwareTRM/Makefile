#  REVISION INFORMATION  ######################################################
#
#  $Author: rao $
#  $Date: 2002-03-21 16:49:54 $
#  $Revision: 1.1 $
#  $Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/softwareTRM/Makefile,v $
#  $State: Exp $
#
#
#  $Log: not supported by cvs2svn $
# Revision 1.3  1995/03/21  04:52:33  len
# Now compiles FAT.  Also adjusted mono and stereo output volume to match
# approximately the output volume of the DSP.
#
# Revision 1.2  1994/08/05  03:12:46  len
# Resectioned tube so that it more closely conforms the the DRM proportions.
# Also changed frication injection so now allowed from S3 to S10.
#
# Revision 1.1.1.1  1994/07/07  03:48:52  len
# Initial archived version.
#
#
##############################################################################


# program name
PROGRAM = tube


# compiler flags
# use -g -DDEBUG if debugging desired, comment out strip
CFLAGS = -Wall
OPTIMIZATION_CFLAGS = -O4
ARCHS = -arch m68k -arch i386


all:: $(PROGRAM)

$(PROGRAM): $(PROGRAM).c
	cc $(PROGRAM).c -o $@ $(ARCHS) $(CFLAGS) $(OPTIMIZATION_CFLAGS)
	strip $@

clean::
	/bin/rm -rf $(PROGRAM)

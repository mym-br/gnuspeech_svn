
include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = libGnuSpeechTube
libGnuSpeechTube_HEADER_FILES_INSTALL_DIR = /Tube

libGnuSpeechTube_INCLUDE_DIRS = -I.

libGnuSpeechTube_HEADER_FILES = \
fir.h \
input.h \
output.h \
ring_buffer.h \
structs.h \
tube.h \
TubeModel.h \
util.h \
wavetable.h

libGnuSpeechTube_C_FILES = \
fir.c \
input.c \
output.c \
ring_buffer.c \
tube.c \
util.c \
wavetable.c

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble

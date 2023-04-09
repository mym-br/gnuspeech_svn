#
# GNUmakefile
# Written by Gregory John Casamento <greg_casamento@yahoo.com>
#
# NOTE: Do NOT change this file -- ProjectCenter maintains it!
#
# Put all of your customisations in GNUmakefile.preamble and
# GNUmakefile.postamble
#

include $(GNUSTEP_MAKEFILES)/common.make

#
# Subprojects
#

#
# Library
#

#PACKAGE_NAME=MonetExtensions
#LIBRARY_VAR=MonetExtensions
LIBRARY_NAME=libMonetExtensions
#libMonetExtensions_HEADER_FILES_DIR=.
libMonetExtensions_HEADER_FILES_INSTALL_DIR=/MonetExtensions
#ADDITIONAL_INCLUDE_DIRS = -I..
#srcdir = .

#
# Additional libraries
#

libMonetExtensions_LIBRARIES_DEPEND_UPON += -lgnustep-gui -l$(FOUNDATION_LIBRARY_NAME)

#
# Header files
#

libMonetExtensions_HEADER_FILES= \
NSBezierPath-Extensions.h \
NSColor-STExtensions.h \
NSNumberFormatter-Extensions.h \
NSOutlineView-Extensions.h \
NSPopUpButton-Extensions.h

#
# Class files
#

libMonetExtensions_OBJC_FILES= \
NSBezierPath-Extensions.m \
NSColor-STExtensions.m \
NSNumberFormatter-Extensions.m \
NSOutlineView-Extensions.m \
NSPopUpButton-Extensions.m

#
# C files
#

#libMonetExtensions_C_FILES =

#HEADERS_INSTALL = $(libMonetExtensions_HEADER_FILES)

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble

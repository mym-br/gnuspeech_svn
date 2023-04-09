#  REVISION INFORMATION  ######################################################
#
#  $Author: rao $
#  $Date: 2002-03-21 16:49:54 $
#  $Revision: 1.1 $
#  $Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/SpeechObject/preMonet/server/synthesizer_module/Makefile,v $
#  $State: Exp $
#
#
#  $Log: not supported by cvs2svn $
# Revision 1.1.1.1  1993/11/25  23:00:46  len
# Initial archive of production code for the 1.0 TTS_Server (tag v5).
#
#
###############################################################################
#  Makefile to create test_synth.
#
#  Do "make" or "make all" to create the complete test suite.
#  Do "make dsp" to create just the dsp-related files.
#  Do "make module" to create just the synthesizer module files.
#  Do "make clean" to clean up the directory
#  Do "make help" to list the available make targets.
#
###############################################################################

#  names of source files
TEST_NAME = test_synth
MODULE_NAME = synthesizer_module
DSP_NAME = synthesizer


#  name of dsp core file
DSPCORE = dspcore.h

#  put object files in these subdirectories
OBJ_DIR = m68k_obj
DSP_OBJ_DIR = dsp_obj

#  object files are in object subdirectory
TEST_OBJ = $(OBJ_DIR)/$(TEST_NAME).o
MODULE_OBJ = $(OBJ_DIR)/$(MODULE_NAME).o
DSP_OBJ = $(DSP_OBJ_DIR)/$(DSP_NAME).lod


#  command which converts the .lod file to dspcore.h
DSPLOD2CORE = /usr/local/bin/dspLod2Core

#  path where dsp equate files are stored
INCLUDE_PATH = /LocalDeveloper/Headers/DSPEquates

#  flags and libraries
#  Add -DDEBUG and -g to FLAGS if debugging desired, and comment out
#  the "strip" below.
DFLAGS =
CFLAGS = -O -Wall $(DFLAGS)
LIBS = -ldsp -lNeXT_s



all:: $(TEST_NAME)

$(TEST_NAME): $(TEST_OBJ) $(MODULE_OBJ)
	cc -o $@ $(TEST_OBJ) $(MODULE_OBJ) $(LIBS) $(CFLAGS)
	strip $@

$(TEST_OBJ): $(OBJ_DIR) $(TEST_NAME).c $(MODULE_NAME).h
	cc -c $(TEST_NAME).c -o $@ $(CFLAGS)


$(MODULE_OBJ): $(OBJ_DIR) $(MODULE_NAME).c $(MODULE_NAME).h $(DSPCORE)
	cc -c $(MODULE_NAME).c -o $@ $(CFLAGS)

$(DSPCORE): $(DSP_OBJ)
	$(DSPLOD2CORE) $(DSP_OBJ)


$(DSP_OBJ): $(DSP_OBJ_DIR) $(DSP_NAME).asm
	asm56000 -a -b$@ -os,so -I$(INCLUDE_PATH) -l$(DSP_NAME).lst \
		$(DSP_NAME).asm

$(DSP_OBJ_DIR):
	mkdirs $@

$(OBJ_DIR):
	mkdirs $@



#  target to create just the DSP-related files
dsp:: $(DSP_OBJ)


#  target to create just the module
module:: $(MODULE_OBJ)


#  target to clean up all files in directory
clean::
	/bin/rm -Rf $(OBJ_DIR) $(DSP_OBJ_DIR) $(DSPCORE) $(DSP_NAME).lst 


#  target to list all target options
help::
	@ echo "'make all' (or just 'make') - makes the complete test suite"
	@ echo "'make dsp' - makes just the dsp-related files"
	@ echo "'make module' - makes just the synthesizer module files"
	@ echo "'make clean' - cleans unnecessary files from the directory"
	@ echo "'make help' - prints this message to screen\n"

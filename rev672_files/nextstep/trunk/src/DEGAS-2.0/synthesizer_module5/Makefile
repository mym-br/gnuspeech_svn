#  makefile to create synth_test

#  executable name
EXECUTABLE= test_synth

# executable which converts .lod file to dspcore.h file
DSPLOD2CORE= dspLod2Core

#  names of source files
SRC1_NAME= test_synth
SRC2_NAME= synthesizer_module
DSP_NAME= synthesizer
IOEQU= ioequ.asm
DSPCORE= dspcore.h

#  put .o and .lod files in this subdirectory
OBJ_DIR= obj

#  flags and libraries (add -DDEBUG to CFLAGS if debugging desired)
CFLAGS= -g -O -Wall
LIBS=  -ldsp_s -lsys_s

#  object files are in object subdirectory
SRC1_OBJ= $(OBJ_DIR)/$(SRC1_NAME).o
SRC2_OBJ= $(OBJ_DIR)/$(SRC2_NAME).o
DSP_OBJ= $(OBJ_DIR)/$(DSP_NAME).lod


all:  $(OBJ_DIR) $(DSPLOD2CORE) $(EXECUTABLE) $(DSP_OBJ)

$(OBJ_DIR):
	mkdirs $@

$(DSPLOD2CORE): $(DSPLOD2CORE).c
	cc $(DSPLOD2CORE).c -o $@ $(CFLAGS) $(LIBS)
	strip $@

$(EXECUTABLE): $(SRC1_OBJ) $(SRC2_OBJ)
	cc -o $@ $(SRC1_OBJ) $(SRC2_OBJ) $(LIBS) $(CFLAGS)
#	strip $@
	chmod go+rx $@

$(SRC1_OBJ): $(SRC1_NAME).c $(SRC2_NAME).h
	cc -c $(SRC1_NAME).c -o $@ $(CFLAGS)

$(SRC2_OBJ): $(SRC2_NAME).c $(SRC2_NAME).h $(DSPCORE)
	cc -c $(SRC2_NAME).c -o $@ $(CFLAGS)

$(DSPCORE): $(DSP_OBJ)
	$(DSPLOD2CORE) $(DSP_OBJ)

$(DSP_OBJ): $(DSP_NAME).asm $(IOEQU)
	asm56000 -a -b$@ -os,so -l$(DSP_NAME).lst $(DSP_NAME).asm
	rm $(DSP_NAME).lst



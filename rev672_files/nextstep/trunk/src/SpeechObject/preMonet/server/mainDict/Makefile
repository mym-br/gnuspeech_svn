#  name of object module
MODULE_NAME= mainDict.a

#  names of source files
SRC1_NAME= mainDict
SRC2_NAME= augmented_search
SRC3_NAME= search
#DICTIONARY_INDEX= Dictionary_Index1.o
DICTIONARY_INDEX= /Accounts/schock/.speechlibrary/IndexA-DL-R.o

#  additional header files
HEADER1_NAME= suffix_list.h
HEADER2_NAME= buffer.h

#  put .o files in this subdirectory
OBJ_DIR= obj

#  flags and libraries (add -DDEBUG and -g to CFLAGS if debugging desired)
CFLAGS= -O -Wall -g -DDEBUG
LIBS=   -lsys_s -lNeXT_s

#  object files are in object subdirectory
SRC1_OBJ= $(OBJ_DIR)/$(SRC1_NAME).o
SRC2_OBJ= $(OBJ_DIR)/$(SRC2_NAME).o
SRC3_OBJ= $(OBJ_DIR)/$(SRC3_NAME).o


#  main targets
all::  $(OBJ_DIR) $(MODULE_NAME)

clean::
	rm -R $(OBJ_DIR) $(MODULE_NAME)


#  dependencies and rules
$(OBJ_DIR):
	mkdirs $@

$(MODULE_NAME): $(SRC1_OBJ) $(SRC2_OBJ) $(SRC3_OBJ) $(DICTIONARY_INDEX)
	ld -r $(SRC1_OBJ) $(SRC2_OBJ) $(SRC3_OBJ) $(DICTIONARY_INDEX) -o $@

$(SRC1_OBJ): $(SRC1_NAME).c $(SRC1_NAME).h $(SRC2_NAME).h
	cc -c $(SRC1_NAME).c $(CFLAGS) -o $@

$(SRC2_OBJ): $(SRC2_NAME).c $(SRC2_NAME).h $(SRC3_NAME).h $(HEADER1_NAME)
	cc -c $(SRC2_NAME).c $(CFLAGS) -o $@

$(SRC3_OBJ): $(SRC3_NAME).c $(SRC3_NAME).h $(HEADER2_NAME)
	cc -c $(SRC3_NAME).c $(CFLAGS) -o $@

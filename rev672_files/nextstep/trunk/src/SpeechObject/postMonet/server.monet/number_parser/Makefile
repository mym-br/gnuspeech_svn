#  name of object module
MODULE_NAME= number_parser.a

#  name of test program
TEST_PROGRAM= test_number_parser

#  names of source files
SRC1_NAME= number_parser

#  additional header files
#  (Use number_pronunciations_english.h for non-phonetic output.)
HEADER1_NAME= number_pronunciations.h

#  put .o files in this subdirectory
OBJ_DIR= obj

#  flags and libraries (add -DDEBUG and -g to CFLAGS if debugging desired)
CFLAGS= -O -Wall -g -DDEBUG
LIBS=   -lsys_s -lNeXT_s

#  object files are in object subdirectory
TEST_PROGRAM_OBJ= $(OBJ_DIR)/$(TEST_PROGRAM).o
SRC1_OBJ= $(OBJ_DIR)/$(SRC1_NAME).o


#  main targets
all::  $(OBJ_DIR) $(MODULE_NAME) $(TEST_PROGRAM)

clean::
	rm -R $(OBJ_DIR) $(MODULE_NAME) $(TEST_PROGRAM)


#  dependencies and rules
$(OBJ_DIR):
	mkdirs $@

$(TEST_PROGRAM): $(TEST_PROGRAM_OBJ) $(MODULE_NAME)
	cc $(TEST_PROGRAM_OBJ) $(MODULE_NAME) $(LIBS) -o $@
	strip $(TEST_PROGRAM)

$(MODULE_NAME): $(SRC1_OBJ) $(HEADER1_NAME)
	ld -r $(SRC1_OBJ) -o $@

$(TEST_PROGRAM_OBJ): $(TEST_PROGRAM).c $(SRC1_NAME).h
	cc -c $(TEST_PROGRAM).c $(CFLAGS) -o $@ 

$(SRC1_OBJ): $(SRC1_NAME).c $(SRC1_NAME).h $(HEADER1_NAME)
	cc -c $(SRC1_NAME).c $(CFLAGS) -o $@



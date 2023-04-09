#  name of object module
MODULE_NAME= diphone_module.a

#  name of test program
TEST_PROGRAM= test_diphone_module

#  names of source files
SRC1_NAME= diphone_module
SRC2_NAME= template
SRC3_NAME= categories
SRC4_NAME= phoneDescription
SRC5_NAME= rule
SRC6_NAME= evaluate

#  additional header files


#  put .o files in this subdirectory
OBJ_DIR= obj

#  flags and libraries (add -DDEBUG and -g to CFLAGS if debugging desired)
CFLAGS= -O -Wall
LIBS=  -lsys_s

#  object files are in object subdirectory
TEST_PROGRAM_OBJ= $(OBJ_DIR)/$(TEST_PROGRAM).o
SRC1_OBJ= $(OBJ_DIR)/$(SRC1_NAME).o
SRC2_OBJ= $(OBJ_DIR)/$(SRC2_NAME).o
SRC3_OBJ= $(OBJ_DIR)/$(SRC3_NAME).o
SRC4_OBJ= $(OBJ_DIR)/$(SRC4_NAME).o
SRC5_OBJ= $(OBJ_DIR)/$(SRC5_NAME).o
SRC6_OBJ= $(OBJ_DIR)/$(SRC6_NAME).o


#  main targets
all::  $(OBJ_DIR) $(MODULE_NAME) $(TEST_PROGRAM)

clean::
	rm -R $(OBJ_DIR) $(MODULE_NAME)


#  dependencies and rules
$(OBJ_DIR):
	mkdirs $@

$(MODULE_NAME): $(SRC1_OBJ) $(SRC2_OBJ) $(SRC3_OBJ) $(SRC4_OBJ) $(SRC5_OBJ) $(SRC6_OBJ)
	ld -r $(SRC1_OBJ) $(SRC2_OBJ) $(SRC3_OBJ) $(SRC4_OBJ) $(SRC5_OBJ) $(SRC6_OBJ) -o $@

$(TEST_PROGRAM): $(TEST_PROGRAM_OBJ) $(MODULE_NAME)
	cc $(TEST_PROGRAM_OBJ) $(MODULE_NAME) -o $@
	strip $@

$(TEST_PROGRAM_OBJ): $(SRC1_NAME).h
	cc -c $(TEST_PROGRAM).c $(CFLAGS) -o $@

$(SRC1_OBJ): $(SRC1_NAME).c $(SRC1_NAME).h $(SRC2_NAME).h $(SRC3_NAME).h \
		$(SRC4_NAME).h $(SRC5_NAME).h
	cc -c $(SRC1_NAME).c $(CFLAGS) -o $@

$(SRC2_OBJ): $(SRC2_NAME).c $(SRC2_NAME).h
	cc -c $(SRC2_NAME).c $(CFLAGS) -o $@

$(SRC3_OBJ): $(SRC3_NAME).c $(SRC3_NAME).h $(SRC2_NAME).h
	cc -c $(SRC3_NAME).c $(CFLAGS) -o $@

$(SRC4_OBJ): $(SRC4_NAME).c $(SRC4_NAME).h $(SRC2_NAME).h
	cc -c $(SRC4_NAME).c $(CFLAGS) -o $@

$(SRC5_OBJ): $(SRC5_NAME).c $(SRC5_NAME).h $(SRC2_NAME).h \
		$(SRC3_NAME).h $(SRC4_NAME).h $(SRC6_NAME).h
	cc -c $(SRC5_NAME).c $(CFLAGS) -o $@

$(SRC6_OBJ): $(SRC6_NAME).c $(SRC6_NAME).h $(SRC4_NAME).h
	cc -c $(SRC6_NAME).c $(CFLAGS) -o $@

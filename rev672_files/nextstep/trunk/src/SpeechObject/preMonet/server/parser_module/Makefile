#  makefile to create parser_module.a and test_parser_module

#  name of object module
MODULE_NAME= parser_module.a

#  test program name
TEST_PROGRAM= test_parser_module

#  names of source files
SRC1_NAME= parser_module

#  names of modules to link with
MOD1_NAME= number_parser
MOD2_NAME= preditorDict
MOD3_NAME= mainDict
MOD4_NAME= letter_to_sound
MOD5_NAME= diphone_module

#  additional header files
HEADER1_NAME= abbreviations.h
HEADER2_NAME= special_acronyms.h

#  put .o files in this subdirectory
OBJ_DIR= obj

#  flags and libraries (add -DDEBUG and -g to CFLAGS if debugging desired)
CFLAGS= -O -Wall -g -DDEBUG
LIBS=   -lsys_s -lNeXT_s

#  object files are in object subdirectory
TEST_PROGRAM_OBJ= $(OBJ_DIR)/$(TEST_PROGRAM).o
SRC1_OBJ= $(OBJ_DIR)/$(SRC1_NAME).o



#  main targets
all::  $(OBJ_DIR) $(MODULE_NAME) $(TEST_PROGRAM) $(MOD1_NAME).a $(MOD2_NAME).a $(MOD3_NAME).a \
	  $(MOD4_NAME).a $(MOD5_NAME).a

clean::
	rm -R $(OBJ_DIR) $(MODULE_NAME) $(TEST_PROGRAM)



#  dependencies and rules
$(OBJ_DIR):
	mkdirs $@

$(MOD1_NAME).a:
	( cd $(MOD1_NAME); $(MAKE))

$(MOD2_NAME).a:
	( cd PrEditor/$(MOD2_NAME); $(MAKE))

$(MOD3_NAME).a:
	( cd $(MOD3_NAME); $(MAKE))

$(MOD4_NAME).a:
	( cd $(MOD4_NAME); $(MAKE))

$(MOD5_NAME).a:
	( cd ../$(MOD5_NAME); $(MAKE))

$(TEST_PROGRAM): $(TEST_PROGRAM_OBJ) $(MODULE_NAME)
	cc $(TEST_PROGRAM_OBJ) $(MODULE_NAME) $(LIBS) -o $@ 
#	strip $@

$(MODULE_NAME): $(SRC1_OBJ) $(MOD1_NAME).a $(MOD2_NAME).a $(MOD3_NAME).a \
	  $(MOD4_NAME).a $(MOD5_NAME).a $(MOD1_NAME).h $(MOD2_NAME).h $(MOD3_NAME).h \
	  $(MOD4_NAME).h $(MOD5_NAME).h
	ld -r $(SRC1_OBJ) $(MOD1_NAME).a $(MOD2_NAME).a $(MOD3_NAME).a \
	  $(MOD4_NAME).a $(MOD5_NAME).a -o $@

$(TEST_PROGRAM_OBJ): $(TEST_PROGRAM).c $(SRC1_NAME).h
	cc -c $(TEST_PROGRAM).c $(CFLAGS) -o $@ 

$(SRC1_OBJ): $(SRC1_NAME).c $(SRC1_NAME).h $(HEADER1_NAME) $(HEADER2_NAME)
	cc -c $(SRC1_NAME).c $(CFLAGS) -o $@ 

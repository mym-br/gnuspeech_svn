#  names of object module
MODULE_NAME= letter_to_sound.a

#  names of source files
SRC1_NAME= letter_to_sound
SRC2_NAME= word_to_patphone
SRC3_NAME= isp_trans
SRC4_NAME= syllabify
SRC5_NAME= apply_stress
SRC6_NAME= vowel_before
SRC7_NAME= check_word_list
SRC8_NAME= final_s
SRC9_NAME= ie_to_y
SRC10_NAME= mark_final_e
SRC11_NAME= long_medial_vowels
SRC12_NAME= medial_silent_e
SRC13_NAME= medial_s
SRC14_NAME= member
SRC15_NAME= ends_with
SRC16_NAME= suffix
SRC17_NAME= insert_mark

#  additional header files
HEADER1_NAME= tail.h
HEADER2_NAME= clusters.h
HEADER3_NAME= stresstables.h
HEADER4_NAME= number_pronunciations.h

#  put .o files in this subdirectory
OBJ_DIR= obj

#  flags and libraries (add -DDEBUG and -g to CFLAGS if debugging desired)
CFLAGS= -O -Wall -g -DDEBUG
LIBS=   -lsys_s -lNeXT_s

#  object files are in object subdirectory
SRC1_OBJ= $(OBJ_DIR)/$(SRC1_NAME).o
SRC2_OBJ= $(OBJ_DIR)/$(SRC2_NAME).o
SRC3_OBJ= $(OBJ_DIR)/$(SRC3_NAME).o
SRC4_OBJ= $(OBJ_DIR)/$(SRC4_NAME).o
SRC5_OBJ= $(OBJ_DIR)/$(SRC5_NAME).o
SRC6_OBJ= $(OBJ_DIR)/$(SRC6_NAME).o
SRC7_OBJ= $(OBJ_DIR)/$(SRC7_NAME).o
SRC8_OBJ= $(OBJ_DIR)/$(SRC8_NAME).o
SRC9_OBJ= $(OBJ_DIR)/$(SRC9_NAME).o
SRC10_OBJ= $(OBJ_DIR)/$(SRC10_NAME).o
SRC11_OBJ= $(OBJ_DIR)/$(SRC11_NAME).o
SRC12_OBJ= $(OBJ_DIR)/$(SRC12_NAME).o
SRC13_OBJ= $(OBJ_DIR)/$(SRC13_NAME).o
SRC14_OBJ= $(OBJ_DIR)/$(SRC14_NAME).o
SRC15_OBJ= $(OBJ_DIR)/$(SRC15_NAME).o
SRC16_OBJ= $(OBJ_DIR)/$(SRC16_NAME).o
SRC17_OBJ= $(OBJ_DIR)/$(SRC17_NAME).o


#  main targets
all::  $(OBJ_DIR) $(MODULE_NAME)

clean::
	rm -R $(OBJ_DIR) $(MODULE_NAME)


#  dependencies and rules
$(OBJ_DIR):
	mkdirs $@

$(MODULE_NAME): $(SRC1_OBJ) $(SRC2_OBJ) $(SRC3_OBJ) $(SRC4_OBJ) $(SRC5_OBJ) $(SRC6_OBJ) \
	  $(SRC7_OBJ) $(SRC8_OBJ) $(SRC9_OBJ) $(SRC10_OBJ) $(SRC11_OBJ) $(SRC12_OBJ) $(SRC13_OBJ) \
	  $(SRC14_OBJ) $(SRC15_OBJ) $(SRC16_OBJ) $(SRC17_OBJ)
	ld -r $(SRC1_OBJ) $(SRC2_OBJ) $(SRC3_OBJ) $(SRC4_OBJ) $(SRC5_OBJ) $(SRC6_OBJ) \
	  $(SRC7_OBJ) $(SRC8_OBJ) $(SRC9_OBJ) $(SRC10_OBJ) $(SRC11_OBJ) $(SRC12_OBJ) $(SRC13_OBJ) \
	  $(SRC14_OBJ) $(SRC15_OBJ) $(SRC16_OBJ) $(SRC17_OBJ) -o $@

$(SRC1_OBJ): $(SRC1_NAME).c $(SRC1_NAME).h $(SRC2_NAME).h $(SRC3_NAME).h \
	  $(SRC4_NAME).h $(SRC5_NAME).h $(HEADER1_NAME)
	cc -c $(SRC1_NAME).c $(CFLAGS) -o $@

$(SRC2_OBJ): $(SRC2_NAME).c $(SRC2_NAME).h $(SRC6_NAME).h $(SRC7_NAME).h $(SRC8_NAME).h \
	  $(SRC9_NAME).h $(SRC10_NAME).h $(SRC11_NAME).h $(SRC12_NAME).h  $(SRC13_NAME).h \
	  $(HEADER4_NAME)
	cc -c $(SRC2_NAME).c $(CFLAGS) -o $@

$(SRC3_OBJ): $(SRC3_NAME).c $(SRC3_NAME).h 
	cc -c $(SRC3_NAME).c $(CFLAGS) -o $@

$(SRC4_OBJ): $(SRC4_NAME).c $(SRC4_NAME).h $(HEADER2_NAME)
	cc -c $(SRC4_NAME).c $(CFLAGS) -o $@

$(SRC5_OBJ): $(SRC5_NAME).c $(SRC5_NAME).h $(HEADER3_NAME)
	cc -c $(SRC5_NAME).c $(CFLAGS) -o $@

$(SRC6_OBJ): $(SRC6_NAME).c $(SRC6_NAME).h $(SRC14_NAME).h
	cc -c $(SRC6_NAME).c $(CFLAGS) -o $@

$(SRC7_OBJ): $(SRC7_NAME).c $(SRC7_NAME).h
	cc -c $(SRC7_NAME).c $(CFLAGS) -o $@

$(SRC8_OBJ): $(SRC8_NAME).c $(SRC8_NAME).h $(SRC14_NAME).h
	cc -c $(SRC8_NAME).c $(CFLAGS) -o $@

$(SRC9_OBJ): $(SRC9_NAME).c $(SRC9_NAME).h 
	cc -c $(SRC9_NAME).c $(CFLAGS) -o $@

$(SRC10_OBJ): $(SRC10_NAME).c $(SRC10_NAME).h $(SRC6_NAME).h $(SRC15_NAME).h \
	  $(SRC14_NAME).h $(SRC17_NAME).h $(SRC16_NAME).h 
	cc -c $(SRC10_NAME).c $(CFLAGS) -o $@

$(SRC11_OBJ): $(SRC11_NAME).c $(SRC11_NAME).h $(SRC14_NAME).h
	cc -c $(SRC11_NAME).c $(CFLAGS) -o $@

$(SRC12_OBJ): $(SRC12_NAME).c $(SRC12_NAME).h $(SRC14_NAME).h $(SRC17_NAME).h
	cc -c $(SRC12_NAME).c $(CFLAGS) -o $@

$(SRC13_OBJ): $(SRC13_NAME).c $(SRC13_NAME).h $(SRC14_NAME).h
	cc -c $(SRC13_NAME).c $(CFLAGS) -o $@

$(SRC14_OBJ): $(SRC14_NAME).c $(SRC14_NAME).h
	cc -c $(SRC14_NAME).c $(CFLAGS) -o $@

$(SRC15_OBJ): $(SRC15_NAME).c $(SRC15_NAME).h
	cc -c $(SRC15_NAME).c $(CFLAGS) -o $@

$(SRC16_OBJ): $(SRC16_NAME).c $(SRC16_NAME).h $(SRC15_NAME).h $(SRC6_NAME).h
	cc -c $(SRC16_NAME).c $(CFLAGS) -o $@

$(SRC17_OBJ): $(SRC17_NAME).c $(SRC17_NAME).h
	cc -c $(SRC17_NAME).c $(CFLAGS) -o $@

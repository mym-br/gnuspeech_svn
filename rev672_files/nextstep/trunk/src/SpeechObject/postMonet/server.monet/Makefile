OFILES = obj/delta_calc.o obj/normal_dist.o obj/server.o\
	obj/structs.o obj/main.o obj/Messages.o obj/server_handler.o\
	obj/apply_stress.o obj/final_s.o\
	obj/isp_trans.o obj/mark_final_e.o obj/member.o obj/vowel_before.o\
	obj/check_word_list.o obj/ie_to_y.o obj/letter_to_sound.o obj/medial_s.o\
	obj/suffix.o obj/word_to_patphone.o obj/ends_with.o obj/insert_mark.o\
	obj/long_medial_vowels.o obj/medial_silent_e.o obj/syllabify.o\
	obj/augmented_search.o obj/swiss.o\
	obj/mainDict.o obj/search.o obj/number_parser.o obj/parser_module.o\
	obj/conversion.o obj/preditorDict.o obj/PrDict.o obj/consistent.o

CC = cc

ENCFLAG = -DENC
#DEMOFLAG = -DDEMO
INCLUDE_DIR = -I headerFiles -I /usr/local/include
#CFLAGS = $(INCLUDE_DIR) -g -DV3 -arch m68k 
CFLAGS = $(INCLUDE_DIR) -g -DV3 -arch m68k -arch i386
OFILE_DIR = obj

LIBS = -lsys_s -ldsp -lNeXT_s -lDriver 

#DICTIONARY_INDEX = /Accounts/schock/.speechlibrary/1.0Dictionary_Index.o
#DICTIONARY_INDEX = /Accounts/schock/.speechlibrary/1.05Dictionary_Index.o
#DICTIONARY_INDEX = /Accounts/schock/.speechlibrary/1.1Dictionary_Index.o
DICTIONARY_INDEX = /Accounts/schock/.speechlibrary/2.0Dictionary_Index.o

# main File
out: $(OFILES)
#	cc $(CFLAGS) $(OFILES) /research/source/speechdict/Dictionary_Index1.o -o out $(LIBS)
	cc $(CFLAGS) $(OFILES) $(DICTIONARY_INDEX) version.c monet.a synthesizer_module.a $(LIBS) -o out

# Calculation Engine Stuff (Craig's)
obj/delta_calc.o: delta_calc.c headerFiles/structs.h headerFiles/server_structs.h 
	cc -c $(CFLAGS) -ObjC delta_calc.c -o obj/delta_calc.o

obj/normal_dist.o: normal_dist.c
	cc -c $(CFLAGS) normal_dist.c -o obj/normal_dist.o

obj/structs.o:structs.c headerFiles/structs.h 
	cc -c $(CFLAGS) -ObjC structs.c -o obj/structs.o

obj/Messages.o:Messages.c headerFiles/MessageStructs.h
	cc -c $(CFLAGS) Messages.c -o obj/Messages.o

obj/server.o:server.c headerFiles/MessageStructs.h headerFiles/SpeechMessages.h
	cc -c $(CFLAGS) server.c -o obj/server.o

obj/server_handler.o:server_handler.c headerFiles/SpeechMessages.h headerFiles/structs.h\
	 headerFiles/server_structs.h headerFiles/MessageStructs.h
	cc -c $(CFLAGS) $(DEMOFLAG) server_handler.c -o obj/server_handler.o

obj/main.o:main.c headerFiles/structs.h headerFiles/serverDefaults.h
	cc -c  $(CFLAGS) main.c -o obj/main.o

obj/swiss.o:swiss.c headerFiles/mappingBuffer.h 
	cc -c  $(CFLAGS) swiss.c -o obj/swiss.o

# Letter To Sound
obj/apply_stress.o:letter_to_sound/apply_stress.c
	cc -c $(CFLAGS) letter_to_sound/apply_stress.c -o obj/apply_stress.o

obj/isp_trans.o:letter_to_sound/isp_trans.c
	cc -c $(CFLAGS) letter_to_sound/isp_trans.c -o obj/isp_trans.o

obj/ends_with.o:letter_to_sound/ends_with.c
	cc -c $(CFLAGS) letter_to_sound/ends_with.c -o obj/ends_with.o

obj/member.o: letter_to_sound/member.c
	cc -c $(CFLAGS) letter_to_sound/member.c -o obj/member.o

obj/syllabify.o:letter_to_sound/syllabify.c
	cc -c $(CFLAGS) letter_to_sound/syllabify.c -o obj/syllabify.o

obj/ie_to_y.o:letter_to_sound/ie_to_y.c
	cc -c $(CFLAGS) letter_to_sound/ie_to_y.c -o obj/ie_to_y.o

obj/final_s.o:letter_to_sound/final_s.c
	cc -c $(CFLAGS) letter_to_sound/final_s.c -o obj/final_s.o

obj/insert_mark.o:letter_to_sound/insert_mark.c
	cc -c $(CFLAGS) letter_to_sound/insert_mark.c -o obj/insert_mark.o

obj/medial_s.o:letter_to_sound/medial_s.c
	cc -c $(CFLAGS) letter_to_sound/medial_s.c -o obj/medial_s.o

obj/mark_final_e.o:letter_to_sound/mark_final_e.c
	cc -c $(CFLAGS) letter_to_sound/mark_final_e.c -o obj/mark_final_e.o

obj/long_medial_vowels.o:letter_to_sound/long_medial_vowels.c
	cc -c $(CFLAGS) letter_to_sound/long_medial_vowels.c -o obj/long_medial_vowels.o

obj/medial_silent_e.o:letter_to_sound/medial_silent_e.c
	cc -c $(CFLAGS) letter_to_sound/medial_silent_e.c -o obj/medial_silent_e.o

obj/suffix.o:letter_to_sound/suffix.c
	cc -c $(CFLAGS) letter_to_sound/suffix.c -o obj/suffix.o

obj/check_word_list.o:letter_to_sound/check_word_list.c
	cc -c $(CFLAGS) letter_to_sound/check_word_list.c -o obj/check_word_list.o

obj/vowel_before.o:letter_to_sound/vowel_before.c
	cc -c $(CFLAGS) letter_to_sound/vowel_before.c -o obj/vowel_before.o

obj/letter_to_sound.o:letter_to_sound/letter_to_sound.c
	cc -c $(CFLAGS) letter_to_sound/letter_to_sound.c -o obj/letter_to_sound.o

obj/word_to_patphone.o:letter_to_sound/word_to_patphone.c
	cc -c $(CFLAGS) letter_to_sound/word_to_patphone.c -o obj/word_to_patphone.o

# Main Dictionary Lookup Routines

obj/augmented_search.o:mainDict/augmented_search.c
	cc -c $(CFLAGS) mainDict/augmented_search.c -o obj/augmented_search.o

obj/mainDict.o:mainDict/mainDict.c
	cc -c $(CFLAGS) mainDict/mainDict.c -o obj/mainDict.o

obj/search.o:mainDict/search.c
	cc -c $(CFLAGS) $(ENCFLAG) mainDict/search.c -o obj/search.o

# Number Parser
obj/number_parser.o:number_parser/number_parser.c headerFiles/number_pronunciations.h
	cc -c $(CFLAGS) number_parser/number_parser.c -o obj/number_parser.o

# Main Parser Module
obj/parser_module.o:parser_module/parser_module.c
	cc -c $(CFLAGS) parser_module/parser_module.c -o obj/parser_module.o

obj/PrDict.o:preditorDict/PrDict.m
	cc -c $(CFLAGS) preditorDict/PrDict.m -o obj/PrDict.o

obj/conversion.o: preditorDict/conversion.c
	cc -c $(CFLAGS) preditorDict/conversion.c -o obj/conversion.o

obj/preditorDict.o:preditorDict/preditorDict.m
	cc -c $(CFLAGS) preditorDict/preditorDict.m -o obj/preditorDict.o


obj/consistent.o: Serial/consistent.c
	cc -c $(CFLAGS) Serial/consistent.c -o obj/consistent.o

/*
 *    Filename:	preditorDict.m
 *    Created :	Sun Feb 23 23:25:39 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *
 *    LastEditDate was "Thu May 21 11:10:06 1992"
 *
 * $Log: not supported by cvs2svn $
# Revision 2.2  92/06/28  15:43:15  len
# Fixed 2 bugs:
# 1) alloc'ed the PrDict object before unarchiving
# 2) added a bzero() before fetching pronunciation
#    for each word.
# Also took out unnecessary NXLogError() calls.
# 
# 
# Revision 2.1  1992/06/09  05:07:48  vince
# Made some trivial changes to the names of the routines
# and added preditor_print_dict, to allow printing of the
# contents of a dictionary.
#
# Revision 2.0  1992/04/08  03:47:16  vince
# Initial-Release
#
 *
 */

#define DICTIONARY_OPEN
#import "preditorDict.h"
#import <stdlib.h>
#import <string.h>
#import <objc/error.h>
#import <objc/typedstream.h>
#import <appkit/nextstd.h>
#import <TextToSpeech/TTS_types.h>

#import "conversion.h"
#import "PrDict.h"

int preditor_open_dict(preditorDict *dict,const char *filename)
{
    NXTypedStream *volatile stream = NULL; /* Delared volatile because of the longjmp */
    volatile int retval            = TTS_OK;
                                           /* in the Exception handling routines
					    * Tells the compiler not to store stream
					    * and retval in registers, or they will get blown
					    * away.
					    */

    if ((filename == NULL) || (filename[0] == '\000')){
	dict->dict_object = nil;
	dict->hashTable   = NULL;
	return TTS_NO_FILE;
    }

    NX_DURING

        stream = NXOpenTypedStreamForFile(filename,NX_READONLY);
	if (stream){
	    dict->dict_object = [PrDict alloc];  /* added by len  */
	    dict->dict_object = (void *)NXReadObject(stream);
	    dict->hashTable   = [(id)dict->dict_object _hashTable];
	} else {
	    dict->dict_object = nil;
	    dict->hashTable   = NULL;
	    retval = TTS_NO_FILE;
	}

    NX_HANDLER
	retval = TTS_NO_FILE;
    NX_ENDHANDLER

    if (stream)
	NXCloseTypedStream(stream);

    return retval;
}

void preditor_close_dict(preditorDict *dict)
{
    [(id)dict->dict_object free];
}

char *preditor_get_entry(const preditorDict *dict,const char *word)
{
    wordHashStruct entry;
    wordHashStruct *orig;
    entry.key = (char *)word;

    if (!dict->hashTable)
	return NULL;

    orig = NXHashGet(dict->hashTable,&entry);
    if (orig){
	bzero((char *)dict->currentword,MAX_WORD_LENGTH);  /* added by len */
	PrToTTS(orig->data,(char *)dict->currentword);
	return (char *)dict->currentword;
    }else{
	bzero((char *)dict->currentword,MAX_WORD_LENGTH);
	return NULL;
    }

}

void preditor_print_dict(const preditorDict *dict, FILE *file)
{
    wordHashStruct *entry;
    NXHashState     state = NXInitHashState(dict->hashTable);

    if (!dict->hashTable)
	return;

    while (NXNextHashState(dict->hashTable,&state,(void **)&entry)){
	fprintf(file,"%s %s\n",entry->key,PreditorToTTS(entry->data));
    }

}

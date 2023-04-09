/*
 *    Filename: preditorDict.h
 *    Created : Sun Feb 23 23:25:43 1992 
 *    Author  : Vince DeMarco
 *              <vince@whatnxt.cuc.ab.ca>
 *    LastEditDate was "Tue May 19 18:46:30 1992"
 *
 * $Log: not supported by cvs2svn $
 * Revision 2.1  1992/06/09  05:06:27  vince
 * Made some trivial changes to the names of the routines
 * and added preditor_print_dict, to allow printing of the
 * contents of a dictionary.
 *
 * Revision 2.0  1992/04/08  03:47:16  vince
 * Initial-Release
 *
 *
 */

#include <objc/hashtable.h>
#include <stdio.h>
#define MAX_WORD_LENGTH 1024

typedef struct _preditorDict {  /* Don't depend on anything being in this structure
				 * as it will probably change in the next version
				 */
    void          *dict_object;
    NXHashTable   *hashTable;
    char           currentword[MAX_WORD_LENGTH];
} preditorDict;

/*
 * PREDITOR DICTIONARY ACCESS ROUTINES.
 * Sample Usage.
 *
 * dict = malloc(sizeof(preditorDict));
 * preditor_open_dict(dict,"test.preditor");
 *
 * pronounciation = preditor_get_entry(dict,"word");
 * ...
 * preditor_close_dict(dict);
 * free(dict);
 *
 */

#ifndef DICTIONARY_OPEN

/* preditor_open_dict
 *
 * Open a preditor Dictionary, called filename
 * Returns TTS_OK if the file could be opened otherwise returns
 * TTS_NO_FILE.
 *
 *
 */
extern int   preditor_open_dict(preditorDict *dict,const char *filename);

/* preditor_close_dict
 *
 * Close the preditor dictionary pointed to by dict
 */
extern void  preditor_close_dict(preditorDict *dict);

/* preditor_get_entry
 *
 * Searches dict for word, and returns the pronounciation in the form
 * pronunciation%type
 * notice that there is only 1 % sign.
 */
extern char *preditor_get_entry(const preditorDict *dict,const char *word);

/* preditor_print_dict
 *
 * prints the contents of the preditor dictionary dict to file
 * notice that file is a stdio file not a stream
 */
extern void  preditor_print_dict(const preditorDict *dict, FILE *file);

#endif

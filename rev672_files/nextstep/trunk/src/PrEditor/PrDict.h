/*
 *    Filename:	PrDict.h 
 *    Created :	Tue Jan 14 18:01:58 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *
 * LastEditDate "Thu May 21 18:29:55 1992"
 *
 * $Log: not supported by cvs2svn $
 * Revision 2.1  1992/06/10  14:20:05  vince
 * new method valueAtPos: has been added, so that the nth
 * item in the dictionary can be obtained. Only the key is
 * returned not the data portion of the entry.
 *
 * Revision 2.0  1992/04/08  03:43:23  vince
 * Initial-Release
 *
 *
 */


#import <objc/Object.h>
#import <objc/hashtable.h>
/* #import <zone.h> Don't need this as it is included by objc/Object.h already */

#define CURRENT_VERSION 100 

typedef struct _wordHashStruct {
    char *key;
    char *data;
} wordHashStruct; /* This is a private typedef don't use it */

@interface PrDict:Object
{
    NXZone         *hashTableZone;
    NXZone         *contentsZone;
    NXHashTable    *hashTable;
    char          **word_list;
    BOOL            has_changed;
}

/* Initiialization */
+ initialize;
- init;

/* Freeing */
- free;

- (NXHashTable *) _hashTable; /* Private method shouldn't be  declared */

/* Manipulating */
- insertKey: (const char *)key data: (const char *)data; /* insert new data OVERWRITING old data */
- deleteKey: (const char *)key;
- (BOOL)isMember: (const char *)key;
- (const char *) valueForKey: (const char *)key;
- (unsigned int ) count;

/* Get the positionth word in the Dictionary Returns only the key not the pronuncation*/
- (const char *)valueAtPos:(int) position;

/* Archiving */
- awake;
- write:(NXTypedStream *)stream;
- read:(NXTypedStream *)stream;

@end

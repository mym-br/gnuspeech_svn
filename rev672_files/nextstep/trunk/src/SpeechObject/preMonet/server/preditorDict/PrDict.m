/*
 *    Filename:	PrDict.m 
 *    Created :	Tue Jan 14 18:02:35 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *
 * LastEditDate "Thu May 28 18:36:08 1992"
 *
 * $Log: not supported by cvs2svn $
# Revision 2.1  1992/06/10  14:20:05  vince
# new method valueAtPos: has been added, so that the nth
# item in the dictionary can be obtained. Only the key is
# returned not the data portion of the entry.
#
# Revision 2.0  1992/04/08  03:43:23  vince
# Initial-Release
#
 *
 */

#import "PrDict.h"

#import <stdio.h>

#import <stdlib.h>
#import <strings.h>
#import <mach.h>

/* My own version of quicksort
 * Actually it has been taken out of
 * The C Programming Language by Kernighan and Ritchie.
 *
 * I would have used the qsort routine but:
 *
 * I couldn't figure out how to get it to work
 * and because my version isn't generic it should be a few microseconds
 * faster
 */
 
static void quicksort(char *v[],int left, int right);

@implementation PrDict

+ initialize
{
    [PrDict setVersion:CURRENT_VERSION];
    return self;
}

- init
{
    self = [super init];
    hashTableZone = NXCreateZone(vm_page_size, vm_page_size, NO);
    contentsZone  = NXCreateChildZone(hashTableZone,vm_page_size, vm_page_size, NO);
    NXNameZone(hashTableZone,"PrDict Object hashTableZone");
    NXNameZone(contentsZone,"PrDict Object Contents Viewer Zone");
    hashTable   = NXCreateHashTableFromZone(NXStrStructKeyPrototype,10,"PrDict Object",hashTableZone);
    has_changed = NO;
    word_list   = NULL;
    return self;
}

/* Freeing */
- free
{
    NXDestroyZone(contentsZone);
    NXDestroyZone(hashTableZone);
    return [super free];
}

- (NXHashTable *)_hashTable /* Private method It is declared though*/
{
    return hashTable;
}

/* Manipulating */
- insertKey: (const char *)key data: (const char *)data
{
    wordHashStruct *entry;

    int keylen  = strlen((char *)key);
    int datalen = strlen((char *)data);

    entry       = NXZoneMalloc(hashTableZone,sizeof(wordHashStruct));
    entry->key  = NXZoneMalloc(hashTableZone,sizeof(char)*keylen);
    entry->data = NXZoneMalloc(hashTableZone,sizeof(char)*datalen);
    strcpy(entry->key, (char *)key);
    strcpy(entry->data,(char *)data);
    if (NXHashInsert(hashTable,entry) == NULL)
	has_changed = YES;
    return self;
}

- deleteKey: (const char *)key
{
    wordHashStruct entry;
    wordHashStruct *returnval;    
    entry.key = (char *)key;

    returnval = NXHashRemove(hashTable,&entry);
    has_changed = YES;
    return self;
}

- (BOOL)isMember: (const char *)key
{
    wordHashStruct entry;

    entry.key = (char *)key;
    if (NXHashMember(hashTable,&entry))
	return YES;
    else
	return NO;
}

- (const char *)valueForKey: (const char *)key
{
    wordHashStruct entry;
    wordHashStruct *orig;    
    entry.key = (char *)key;

    orig = NXHashGet(hashTable,&entry);
    if (orig)
	return orig->data;
    else
	return NULL;
}

- (unsigned int ) count
{
    return NXCountHashTable(hashTable);
}

/*
 * Sort the array v of chars
 * call with
 * quicksort(array,0,size-1);
 *
 */

static void quicksort(char *v[],int left, int right)
{
  int i, last,value;
  char *temp;

  if (left >= right)
    return;
  /* swap(v,left,(left + right)/2) */

  temp                = v[left];
  v[left]             = v[(left + right)/2];
  v[(left + right)/2] = temp;

  last = left;
  for (i = left+1;i<= right; i++)
    if (strcmp(v[i],v[left]) < 0){
      /* swap(v,++last,i) */
      value    = ++last;
      temp     = v[value];
      v[value] = v[i];
      v[i]     = temp;
    }
  /* swap(v,left,last) */

  temp    = v[left];
  v[left] = v[last];
  v[last] = temp;

  quicksort(v,left,last-1);
  quicksort(v,last+1,right);

}

/* Get the positionth word in the Dictionary Returns only the key not the pronuncation*/
- (const char *)valueAtPos:(int) position
{
    char           *word;
    wordHashStruct *entry;
    NXHashState     state;
    int             i =0;

    if (has_changed == YES){
	has_changed = NO;
	state = NXInitHashState(hashTable);

	/* Here i copy the contents of the hash table into word_list which is an array of 
	 * pointers to char, this is done because the hash table routines can rearange
	 * the data, ie move it around as insertions and deletions occur.
	 * I know that this is slow, but it is only done when the contents of the hash
	 * table actually change.
	 *
	 * word_list isn't in a ChildZone this is to ensure that all relevant info will
	 * be on the same page in memory, and by using a child zone, i can just destroy
	 * the zone instead of iterating over everything to kill the zone.
	 */
	NXDestroyZone(contentsZone);
	contentsZone = NXCreateChildZone(hashTableZone,vm_page_size, vm_page_size, NO);
	NXNameZone(contentsZone,"PrDict Object Contents Viewer Zone");
	word_list = NXZoneMalloc(contentsZone,sizeof(char *)*[self count]+1);
	if(word_list){
	    while (NXNextHashState(hashTable,&state,(void **)&entry)){
		word = NXZoneMalloc(contentsZone,sizeof(char)*strlen(entry->key));
		strcpy(word,entry->key);
		word_list[i++] = word;
	    }
	    quicksort(word_list,0,i-1);
	}else{
	    return NULL;
	}
    }
    if ((position < [self count]) && word_list[position])
	return word_list[position];
    else
        return NULL;
}

/* Archiving */

- awake
{
    [super awake];
    if (!contentsZone){ /* The awake method can be called multiple times so this needs to
			 * be in the if statement, that way we will not created an excess
			 * number of zones
			 */
	contentsZone = NXCreateChildZone(hashTableZone,vm_page_size, vm_page_size, NO);
	NXNameZone(contentsZone,"PrDict Object Contents Viewer Zone");
    }
    has_changed = YES;
    word_list = NULL;
    return self;
}

- write:(NXTypedStream *)stream
{
    wordHashStruct *entry;
    unsigned        count = NXCountHashTable(hashTable);
    NXHashState     state = NXInitHashState(hashTable);
    int keysize, datasize;

    [super write:stream]; 
    /* WriteOut number of elements in hash table */
    NXWriteTypes(stream,"i",&count);
    while (NXNextHashState(hashTable,&state,(void **)&entry)){
	keysize  = strlen(entry->key);
	datasize = strlen(entry->data);
	NXWriteTypes(stream,"ii",&keysize,&datasize);
	NXWriteArray(stream,"c",keysize,entry->key);
	NXWriteArray(stream,"c",datasize,entry->data);
    }
    return self;
}

- read:(NXTypedStream *)stream
{
    unsigned int    count;
    unsigned int    i=0;
    wordHashStruct *entry;
    int             keysize, datasize;
    int             versionNumber;

    [super read:stream];
    if ((versionNumber = NXTypedStreamClassVersion(stream, "PrDict")) == [PrDict version]) {
	NXReadTypes(stream,"i",&count);
	if (!hashTableZone){ /* This is called because when a object is unarchived it is assummed that
			      * You don't need to call init, because you will be initializing all of
			      * the relevant datastructures from disk
			      */
	    hashTableZone = NXCreateZone(vm_page_size, vm_page_size, NO); 
	    NXNameZone(hashTableZone,"PrDict Object hashTableZone");
	    hashTable = NXCreateHashTableFromZone(NXStrStructKeyPrototype,count*2,"PrDict Object",hashTableZone);
	}
	while(i < count){
	    NXReadTypes(stream,"ii",&keysize,&datasize);
	    entry       = NXZoneMalloc(hashTableZone,sizeof(wordHashStruct));
	    entry->key  = NXZoneMalloc(hashTableZone,sizeof(char)*keysize);
	    entry->data = NXZoneMalloc(hashTableZone,sizeof(char)*datasize);
	    NXReadArray(stream,"c",keysize,entry->key);
	    NXReadArray(stream,"c",datasize,entry->data);
	    NXHashInsert(hashTable,entry);
	    i++;
	}
    } /* Must be older version or something */
    return self;
}

@end

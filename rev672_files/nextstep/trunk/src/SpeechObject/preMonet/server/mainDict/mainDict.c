/***************************************************************************
*
*     mainDict.c 
*
*     Main dictionary lookup and caching.
*
*     NOTE: in my_hash_block, items that are free (have ->data == 0) use
*     their ->next field to point to the next free block in there.
*     *nextfree points to the first free block in there.
*
***************************************************************************/

/*  HEADER FILES  *********************************************************/
#import "mainDict.h"
#import "augmented_search.h"
#import "search.h"
#import <sys/param.h>
#import <stdio.h>
#import <strings.h>
#import <stdlib.h>
#import <appkit/nextstd.h>


/*  LOCAL DEFINES  ********************************************************/
#define LINE_LENGTH    256           /*  MAX LINE LENGTH IN PRELOAD FILE  */
#define HASH_SIZE      MD_HASH_PRIME


/*  DATA STRUCTURES  ******************************************************/
struct cache_entry {
  char *word;
  char *pronunciation;
  struct cache_entry *next;
  struct cache_entry *previous; 
};
typedef struct cache_entry cache_entry_t;
  
struct hash_entry {
  struct cache_entry *data;
  struct hash_entry *next; 
};
typedef struct hash_entry hash_entry_t;


/*  GLOBAL FUNCTIONS (LOCAL TO THIS FILE)  ********************************/
static int init_cache(const char *preload_file_path);
static hash_entry_t *find_vacant(void);
static cache_entry_t *find_in_hashtable(char *word);
static void insert_hash(cache_entry_t *item, hash_entry_t *entry);
static int preload_cache(const char *preload_file_path);
static void hash_free(hash_entry_t *node);
static void delete_hash(char *word);
static void move_word(cache_entry_t *old_position);
static int new_word(char *word, char *pronunciation);
static int my_hash(char *word);  
 

/*  GLOBAL VARIABLES (LOCAL TO THIS FILE)  ********************************/
static cache_entry_t *cache, *head, *end;
static hash_entry_t *hash_table, *my_hash_block, *nextfree, *insert_position;



/***************************************************************************
*
*     mainDict_init
*
*     Initializes main dictionary by mapping the dictionary file into
*     memory, and preloading cache with words and pronunciations in disk
*     file.
*
***************************************************************************/

int init_mainDict(const char *systemPath)
{
  char tempPath[MAXPATHLEN];

  /*  INITIALIZE MAIN DICTIONARY  */
  sprintf(tempPath, "%s/%s", systemPath, MAIN_DICTIONARY_FILE);
  if (init_dict(tempPath) == MD_FAILURE) {
    NXLogError("TTS_Server:  Error mapping main dictionary file");
    return(MD_FAILURE);
  }
    

  /*  INITIALIZE THE CACHE  */
  sprintf(tempPath, "%s/%s", systemPath, MD_CACHE_PRELOAD_FILE);
  if (init_cache(tempPath) == MD_FAILURE) {
    NXLogError("TTS_Server:  Error reading dictionary preload file");
    return(MD_FAILURE);
  }

  /*  RETURN SUCCESS  */
  return(MD_SUCCESS);
}



/***************************************************************************
*
*     mainDict_get_entry
*
*     Lookup routine for higher level functions to call.
*
***************************************************************************/

char *mainDict_get_entry(char *word)
{
  cache_entry_t *location;
  char *w, *pronunciation;


  /*  THIS SETS insert_position  */
  location = find_in_hashtable(word);

  if (location != head) {
    if (!location) {		        /*  IF NOT IN CACHE  */
      if (!(pronunciation = augmented_search(word)))
        return NULL;		        /*  IF NOT IN MAIN DICT. EITHER  */
      if (w = end->word)
        delete_hash(w);			/*  THIS MIGHT UPDATE insert_position  */
      new_word(word, pronunciation);	/*  AFFECT CACHE  */
      insert_hash(head, insert_position);	/*  ATTACH HEAD TO HASHTBL AT POS  */
    }
    else
      move_word(location);
  }
  return(head->pronunciation);
}



/***************************************************************************
*
*     init_cache()
*
*     Initializes the cache and hash table.
*
***************************************************************************/

static int init_cache(const char *preload_file_path)
{
  int i;

  /*  ALLOCATE SPACE FOR CACHE AND HASHTABLE (INTEGRAL # OF PAGES EACH)  */
  cache = valloc(MD_CACHE_SIZE*sizeof(cache_entry_t));
  hash_table = valloc(HASH_SIZE*sizeof(hash_entry_t));
  my_hash_block = valloc(MD_CACHE_SIZE*sizeof(hash_entry_t));

  head = cache;
  nextfree = my_hash_block;
  end = cache + (MD_CACHE_SIZE-1);
  head->previous = NULL;
  head->next = cache + 1;

  for (i = 1; i < (MD_CACHE_SIZE-1); i++) {
    cache[i].next = cache + (i+1);
    cache[i].previous = cache + (i-1);
  }

  for (i = 0; i < (MD_CACHE_SIZE-1); i++)
    (my_hash_block+i)->next = my_hash_block + (i+1);

  end->next = NULL;
  my_hash_block[MD_CACHE_SIZE-1].next = NULL;
  end->previous = cache + (MD_CACHE_SIZE-2);

  /*  FILL CACHE FROM FILE ON DISK  */
  for (i = 0; i < HASH_SIZE; i++) {
    hash_table[i].data = NULL;
    hash_table[i].next = NULL;
  }
  return(preload_cache(preload_file_path));
}



/***************************************************************************
*
*     find_vacant
*
*     Crashes (ref. thru null ptr) if table full.  Should never happen if
*     sizes are correct.
*
***************************************************************************/

static hash_entry_t *find_vacant(void)
{
  hash_entry_t *vacant;
  
  vacant = nextfree;
  nextfree = nextfree->next;
  return(vacant);
}



/***************************************************************************
*
*     find_in_hashtable
*
*     Returns pointer to cache entry containing word, or NULL if not there.
*     Make insert_position point to the last entry examined.
*
***************************************************************************/

static cache_entry_t *find_in_hashtable(char *word)
{
  cache_entry_t *location;
  hash_entry_t *entry, *next_entry;


  /*  POINTER TO THE HASHTABLE ENTRY  */
  entry = hash_table + my_hash(word);
  location = entry->data;

  /*  IF COLLISION, FIND IT BY FOLLOWING CHAIN  */
  while (location && strcmp(location->word, word)) {
    if (next_entry = entry->next)
      location = (entry = next_entry)->data;
    else
      location = NULL;
  }

  /*  IF location IS NULL THEN entry->next IS GUARANTEED TO BE NULL */
  insert_position = entry;
  return(location);
}



/***************************************************************************
*
*     insert_hash
*
*     Put the given cache entry into the hash table. Use coalesced chaining.
*     Note that the field entry->next is guaranteed to be NULL when this is
*     called, so we can attach the next node in the chain to the table here.
*
***************************************************************************/

static void insert_hash(cache_entry_t *item, hash_entry_t *entry)
{
  hash_entry_t *new_position;

  if (entry->data == NULL)	/*  THE NICE CASE. THE SLOT "entry" WAS IN  */
    entry->data = item;		/*  THE ORIGINAL TABLE AND WAS EMPTY  */
  else {
    new_position = find_vacant();     /*  GUARANTEED TO BE VACANCIES SINCE  */
    entry->next = new_position;       /*  HASH_SIZE > MD_CACHE_SIZE  */
    new_position->data = item;
    new_position->next = NULL;	/*  NEEDED SINCE THIS ENTRY WAS USED FOR  */
                                /*  A DIFFERENT PURPOSE IN THE BLOCK OF  */
                                /*  FREE SPACE  */
  }
  return;
}



/***************************************************************************
*
*      preload_cache
*
*      Loads the cache with words and pronunciation contained in
*      preload_file_path.  Returns MD_FAILURE if cache cannot be preloaded,
*      returns MD_SUCCESS otherwise.
*
***************************************************************************/

static int preload_cache(const char *preload_file_path)
{
  cache_entry_t *cache_ptr;
  FILE *preload_file;
  char *temp, *temp2, buffer[LINE_LENGTH];
  cache_entry_t *location;
  int i, length;


  /*  SET POINTER TO CACHE  */
  cache_ptr = cache;

  /*  OPEN PRELOAD FILE  */
  if ((preload_file = fopen(preload_file_path, "r")) == NULL)
    return(MD_FAILURE);

  for (i = 0; i < MD_NUMBER_TO_PRELOAD; i++) {
    fgets(buffer,LINE_LENGTH,preload_file);
    temp = buffer;
    length = 1;

    while (*temp && (*temp != ' ')) {
      temp++;
      length++;
    }

    /*  RETURN IF ERROR IN FILE FORMAT  */
    if (!*temp)
      return(MD_FAILURE);

    *temp = '\0';
    cache_ptr->word = (char *)malloc(length);
    strcpy(cache_ptr->word,buffer);
    temp++;
    temp2 = temp;

    while (*temp2 && (*temp2 != '\n'))
      temp2++;

    *temp2 = '\0';
    cache_ptr->pronunciation = (char *)malloc(1 + strlen(temp));
    strcpy(cache_ptr->pronunciation, temp);

    /*  SET insert_position  */
    location = find_in_hashtable(cache_ptr->word);
    insert_hash(cache_ptr, insert_position);
    cache_ptr++;
  }

  /*  RETURN SUCCESS  */
  return(MD_SUCCESS);
}



/***************************************************************************
*
*      hash_free
*
*      Tack the node onto the front of the free list.
*
***************************************************************************/

static void hash_free(hash_entry_t *node)
{
  node->next = nextfree;
  nextfree = node;
}



/***************************************************************************
*
*      delete_hash
*
*      Will crash (ref. thru null ptr) if the word to delete is
*      not actually in the table.  This should never happen.
*
***************************************************************************/

static void delete_hash(char *word)
{
  hash_entry_t *entry, *temp;
  int hash_value;

  hash_value = my_hash(word);
  entry = hash_table + hash_value;

/*      There are two cases.  I: The word is stored at its native hash location.
 * 	There are two subcases: a) the word has no chain following it.  In this
 *	case we can simply change the data entry to null. b) there is a chain.
 *	In this case we have to copy both fields of the first follower into
 *	the hash table proper, and add the follower to the free list.
 *	II: The word is part of a chain.  In this case, we find its predecessor
 *	in the chain, copy the next field into the predecessor and add the
 *	node to the free list.
 */

  if (!strcmp(word, entry->data->word)) {	/*  IF CASE I  */
    if (temp = entry->next) {		        /*  IF CASE Ib  */
      entry->data = temp->data;
      entry->next = temp->next;
      if (temp == insert_position)
        insert_position = entry;
      hash_free(temp);
    }
    else 				/*  IF CASE Ia  */
      entry->data = NULL;
  }
  else {				/*  IF CASE II  */
    do {
      temp = entry;		        /*  temp WILL BE THE PREDECESSOR  */
      entry = entry->next;
    } while (strcmp(entry->data->word, word));
    temp->next = entry->next;
    if (entry == insert_position)
      insert_position = temp;
    hash_free(entry);
  }
}

  

/***************************************************************************
*
*     move_word
*
*     Moves the given record to the front of the list.  (For the situation
*     where the word was already in the list.)
*
***************************************************************************/

static void move_word(cache_entry_t *old_position)
{
  cache_entry_t *temp;
  
  temp = old_position->previous;
  temp->next = old_position->next;

  if (old_position == end)
    end = temp;
  else
    old_position->next->previous = temp;

  old_position->next = head;
  head->previous = old_position;
  old_position->previous = NULL;   /* = head->previous; */
  head = old_position;
  if (old_position == end)
    end = temp;
}



/***************************************************************************
*
*     new_word
*
*     Copies the word and its phonetic representation into the cache as a
*     new word.  Returns nonzero if error.
*
***************************************************************************/

static int new_word(char *word, char *pronunciation)
{
  /*  MAKE ROOM FOR NEW WORD IN MEMORY  */
  end->word = (char *)realloc(end->word, strlen(word)+1);
  end->pronunciation = (char *)realloc(end->pronunciation, strlen(pronunciation)+1);

  /*  RETURN ERROR IF NO ZERO LENGTH WORD OR PRONUNCIATION  */
  if (!end->word || !end->pronunciation)
    return(1);

  /*  COPY WORD AND PRONUNCIATION INTO MEMORY  */
  strcpy(end->word, word);
  strcpy(end->pronunciation, pronunciation);
  move_word(end);

  /*  RETURN SUCCESS  */
  return(0);
}



/***************************************************************************
*
*     my_hash
*
*     Compute hash function of word.
*
***************************************************************************/

static int my_hash(char *word)
{
  unsigned c, res = 0, offset = 0;

  while (c = *word) {
    res ^= c<<offset ^ c>>(16-offset);
    c = *++word;
    res ^= c<<(8+offset) ^ c>>(8-offset);
    if (c) {
      word++;
      if (++offset == 16)
        offset = 0;
    }
  }
  return((int)(res&0xffff)%MD_HASH_PRIME);
}

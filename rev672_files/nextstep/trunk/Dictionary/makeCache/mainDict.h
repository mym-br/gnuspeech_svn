/*  GLOBAL FUNCTIONS  *****************************************************/
extern int init_mainDict(const char *systemPath);
extern char *mainDict_get_entry(char *word);


/*  GLOBAL DEFINES  *******************************************************/
#define MAIN_DICTIONARY_FILE   "MainDictionary"
#define MD_CACHE_PRELOAD_FILE  "cache.preload"

#define MD_CACHE_SIZE          1000
#define MD_NUMBER_TO_PRELOAD   MD_CACHE_SIZE   /*  MUST BE <= MD_CACHE_SIZE  */
#define MD_HASH_PRIME          1009            /*  MUST BE PRIME, >= MD_CACHE_SIZE  */

#define MD_SUCCESS             0
#define MD_FAILURE             1

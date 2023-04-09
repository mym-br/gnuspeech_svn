/******************************************************************************
*
*     syllabify.c
*
*     
*     
*
******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "syllabify.h"
#import "clusters.h"
#import <stdio.h>
#import <stdlib.h>
#import <strings.h>


/*  LOCAL DEFINES  ***********************************************************/
#define MAX_LEN    1024
#define isvowel(c) ((c)=='a' || (c)=='e' || (c)=='i' || (c)=='o' || (c)=='u' )
#define LEFT       begin_syllable
#define RIGHT      end_syllable


/*  DATA TYPES  **************************************************************/
typedef char phone_type;


/*  GLOBAL FUNCTIONS (LOCAL TO THIS FILE)  ***********************************/
static int syllable_break(char *cluster);
static void create_cv_signature(char *ptr, phone_type *arr);
static char *add_1_phone(char *t);
static char *extract_consonant_cluster(char *ptr, phone_type *type);
static int next_consonant_cluster(phone_type *pt);
static int check_cluster(char *p, char **match_array);




/******************************************************************************
*
*	function:	syllabify
*
*	purpose:	Steps along until probable syllable beginning is found,
*                       taking the longest possible first; then continues
*			skipping vowels until a possible syllable end is found
*                       (again taking the longest possible.)  Changes '_' to
*                       '.' where it occurs between syllable end and start.
*
*       arguments:      word
*                       
*	internal
*	functions:	create_cv_signature, next_consonant_cluster,
*                       add_1_phone, extract_consonant_cluster, syllable_break
*
*	library
*	functions:	none
*
******************************************************************************/

int syllabify(char *word)
{
    int                 i, n, temp, number_of_syllables = 0;
    phone_type          cv_signature[MAX_LEN], *current_type;
    char                *cluster, *ptr;


    /*  INITIALIZE THIS ARRAY TO 'c' (CONSONANT), 'v' (VOWEL), 0 (END)  */
    ptr = word;
    create_cv_signature(ptr, cv_signature);	
    current_type = cv_signature;

    /*  WHILE THERE IS ANOTHER CONSONANT CLUSTER (NOT THE LAST)  */
    while (temp = next_consonant_cluster(current_type)) {	
	number_of_syllables++;

	/*  UPDATE CURRENT TYPE POINTER  */
	current_type += temp;

	/*  MOVE PTR TO POINT TO THAT CLUSTER  */
	for (i = 0; i < temp; i++)
	    ptr = add_1_phone(ptr);

	/*  EXTRACT THE CLUSTER INTO A SEPARATE STRING  */
	cluster = extract_consonant_cluster(ptr, current_type);

	/*  DETERMINE WHERE THE PERIOD GOES (OFFSET FROM PTR, WHICH COULD BE -1)  */
	n = syllable_break(cluster);

	/*  MARK THE SYLLABLE IF POSSIBLE  */
	if (n != -2)
	    *(ptr + n) = '.';
    }

    /*  RETURN NUMBER OF SYLLABLES  */
    return(number_of_syllables ? number_of_syllables : 1);
}



/******************************************************************************
*
*	function:	syllable_break
*
*	purpose:	Returns -2 if could not break the cluster.
*                       
*			
*       arguments:      cluster
*                       
*	internal
*	functions:	check_cluster
*
*	library
*	functions:	strlen, strcpy
*
******************************************************************************/

int syllable_break(char *cluster)
{
    char                *left_cluster, *right_cluster, temp[MAX_LEN];
    int                 offset, length;


    /*  GET LENGTH OF CLUSTER  */
    length = strlen(cluster);

    /*  INITIALLY WE SHALL RETURN THE FIRST 'POSSIBLE' MATCH  */
    for (offset = -1; (offset <= length); offset++) {
	if (offset == -1 || offset == length || cluster[offset] == '_' || cluster[offset] == '.') {
	    strcpy(temp, cluster);
	    if (offset >= 0)
		temp[offset] = 0;
	    left_cluster = (offset < 0 ? temp : offset == length ? temp + length : temp + (offset + 1));
	    /*  POINTS TO BEGINNING OR NULL  */
	    right_cluster = (offset >= 0 ? temp : temp + length);
	    /*  NOW THEY POINT TO EITHER A LEFT/RIGHT HANDED CLUSTER OR A NULL STRING  */
	    if (check_cluster(left_cluster, LEFT) && check_cluster(right_cluster, RIGHT)) {
	        /*  IF THIS IS A POSSIBLE BREAK */
	        /*  TEMPORARY:  WILL STORE LIST OF POSSIBLES AND PICK A 'BEST' ONE  */
	        return(offset);
	    }
	}
    }

    /*  IF HERE, RETURN ERROR  */
    return(-2);
}



/******************************************************************************
*
*	function:	create_cv_signature
*
*	purpose:	
*                       
*			
*       arguments:      ptr, arr
*                       
*	internal
*	functions:	(isvowel), add_1_phone
*
*	library
*	functions:	none
*
******************************************************************************/

void create_cv_signature(char *ptr, phone_type *arr)
{
    phone_type         *arr_next;

    arr_next = arr;
    while (*ptr) {
	*arr_next++ = isvowel(*ptr) ? 'v' : 'c';
	ptr = add_1_phone(ptr);
    }
    *arr_next = 0;
}



/******************************************************************************
*
*	function:	add_1_phone
*
*	purpose:	
*                       
*			
*       arguments:      t
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

char *add_1_phone(char *t)
{
    while (*t && *t != '_' && *t != '.')
	t++;

    while (*t == '_' || *t == '.')
	t++;

    return(t);
}



/******************************************************************************
*
*	function:	extract_consonant_cluster
*
*	purpose:	there is a memory leak which needs fixing!!!!
*                       (fixed temporarily).
*			
*       arguments:      ptr, type
*                       
*	internal
*	functions:	add_1_phone
*
*	library
*	functions:	malloc, strlen, strcpy, fprintf
*
******************************************************************************/

char *extract_consonant_cluster(char *ptr, phone_type *type)
{
    char                *newptr;
    static char         ret[2048];  // to fix memory leak
    int                 offset;

    newptr = ptr;

    while (*type == 'c') {
	type++;
	newptr = add_1_phone(newptr);
    }

//    printf("extract:  strlen(ptr) = %-d\n",strlen(ptr));

//    ret = (char *)malloc(strlen(ptr) + 1);  // to fix memory leak
    strcpy(ret, ptr);
    offset = newptr - ptr - 1;

    if (offset >= 0)
	ret[offset] = 0;
    else
	fprintf(stderr, "offset error\n");  // what's this??

    return(ret);
}



/******************************************************************************
*
*	function:	next_consonant_cluster
*
*	purpose:	Takes a pointer to phone_type and returns an integer
*                       offset from that point to the start of the next
*                       consonant cluster (or 0 if there are no vowels between
*                       the pointer and the end of the word, or if this is the
*                       second-last cluster and the word doesn't end with a
*                       vowel. Basically, 0 means to stop.)
*			
*       arguments:      pt
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

int next_consonant_cluster(phone_type *pt)
{
    phone_type         *pt_var, *pt_temp;

    pt_var = pt;
    while (*pt_var == 'c')
	pt_var++;

    while (*pt_var == 'v')
	pt_var++;

   /*  CHECK TO SEE IF WE ARE NOW ON THE FINAL CLUSTER OF THE WORD WHICH IS AT
       THE END OF THE WORD  */ 
    pt_temp = pt_var;

    while (*pt_temp == 'c')
	pt_temp++;

    return (*pt_var && *pt_temp ? pt_var - pt : 0);
}



/******************************************************************************
*
*	function:	check_cluster
*
*	purpose:	Returns 1 if it is a possible match, 0 otherwise.
*                       
*			
*       arguments:      p, match_array
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	strcmp
*
******************************************************************************/

int check_cluster(char *p, char **match_array)
{
    char                **i;

    /*  EMPTY COUNTS AS A MATCH  */
    if (!*p)
	return(1);

    i = match_array;
    while (*i) {
	if (!strcmp(*i, p))
	    return(1);
	i++;
    }
    return(0);
}

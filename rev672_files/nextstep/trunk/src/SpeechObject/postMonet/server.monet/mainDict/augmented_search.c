/*  HEADER FILES  ********************************************************/
#import "augmented_search.h"
#import "search.h"
#import "suffix_list.h"
#import <strings.h>


/*  LOCAL DEFINES  *******************************************************/
#define MAXLEN      1024


/*  GLOBAL FUNCTIONS (LOCAL TO THIS FILE)  *******************************/
static char *word_has_suffix(char *word, char *suffix);



/**************************************************************************
*
*       function:   augmented search
*
*       purpose:    First looks in main dictionary to see if word is there.
*                   If not, it tries the main dictionary without suffixes,
*                   and if found, tacks on the appropriate ending.
*
*                   NOTE:  some forms will have to be put in the main
*                   dictionary.  For example, "houses" is NOT pronounced as
*                   "house" + "s", or even "house" + "ez".
*
*       internal
*       functions:  word_has_suffix, search
*
*       library
*       functions:  strcpy, strcat
*
**************************************************************************/

char *augmented_search(char *orthography)
{
  char *word, *pt, *word_type_pos;
  suffix_list_t *list_ptr;
  static char buffer[MAXLEN], word_type_buffer[32];


  /*  RETURN IMMEDIATELY IF WORD FOUND IN DICTIONARY  */
  if (word = search(orthography))
    return(word);

  /*  LOOP THROUGH SUFFIX LIST  */
  for (list_ptr = suffix_list; list_ptr->suffix; list_ptr++) {
    if (pt = word_has_suffix(orthography, list_ptr->suffix)) {
      /*  TACK ON REPLACEMENT ENDING  */
      strcpy(buffer, orthography);
      *(buffer + (pt - orthography)) = '\0';
      strcat(buffer, list_ptr->replacement);

      /*  IF WORD FOUND WITH REPLACEMENT ENDING  */
      if (word = search(buffer)) {			
	/*  PUT THE FOUND PRONUNCIATION IN THE BUFFER  */
	strcpy(buffer, word);

	/*  FIND THE WORD-TYPE INFO  */
	for (word_type_pos = buffer; *word_type_pos && (*word_type_pos != '%'); word_type_pos++)
	  ;

	/*  SAVE IT INTO WORD TYPE BUFFER  */
	strcpy(word_type_buffer, word_type_pos);

	/*  APPEND SUFFIX PRONUNCIATION TO WORD  */
	*word_type_pos = '\0';
	strcat(buffer, list_ptr->pronunciation);

	/*  AND PUT BACK THE WORD TYPE  */		
	strcat(buffer, word_type_buffer);

	/*  RETURN WORD WITH SUFFIX AND ORIGINAL WORD TYPE  */
	return(buffer);
      }
    }
  }

  /*  WORD NOT FOUND, EVEN WITH SUFFIX STRIPPED  */
  return(NULL);
}



/**************************************************************************
*
*       function:   word_has_suffix
*
*       purpose:    Returns position of suffix if word has suffix which
*                   matches, else returns NULL.
*
*       internal
*       functions:  none
*
*       library
*       functions:  strlen, strcmp
*
**************************************************************************/

static char *word_has_suffix(char *word, char *suffix)
{
  int word_length, suffix_length;
  char *suffix_position;

  /*  GET LENGTH OF WORD AND SUFFIX  */
  word_length = strlen(word);
  suffix_length = strlen(suffix);

  /*  DON'T ALLOW SUFFIX TO BE LONGER THAN THE WORD, OR THE WHOLE WORD  */
  if (suffix_length >= word_length)		
    return(NULL);

  /*  FIND POSITION OF SUFFIX IN WORD  */
  suffix_position = word + word_length - suffix_length;

  /*  RETURN SUFFIX POSITION IF THE SUFFIX MATCHES, ELSE RETURN NULL  */
  if(!strcmp(suffix_position, suffix))
    return(suffix_position);
  else
    return(NULL);
}

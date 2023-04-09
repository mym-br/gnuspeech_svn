/******************************************************************************
*
*     letter_to_sound.c
*
*     Routines to return pronunciation of word based on letter-to-sound
*     rules.
*
******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "letter_to_sound.h"
#import "word_to_patphone.h"
#import "isp_trans.h"
#import "syllabify.h"
#import "apply_stress.h"
#import "tail.h"
#import <strings.h>
#import <stdio.h>


/*  LOCAL DEFINES  ***********************************************************/
#define WORD_TYPE_UNKNOWN          "j"
#define WORD_TYPE_DELIMITER        '%'
#define MAX_WORD_LENGTH            1024
#define MAX_PRONUNCIATION_LENGTH   8192
#define MAX(a,b)                   (a > b ? a : b)
#define WORDEND(word,string)       (!strcmp(MAX(word+strlen(word)-strlen(string),word),string))


/*  GLOBAL FUNCTIONS (LOCAL TO THIS FILE)  ***********************************/
static char *word_type(char *word);




/******************************************************************************
*
*	function:	letter_to_sound
*
*	purpose:	Returns pronunciation of word based on letter-to-sound
*                       rules.  Returns NULL if any error (rare).
*			
*       arguments:      word
*                       
*	internal
*	functions:	word_to_patphone, isp_trans, syllabify, apply_stress,
*                       word_type
*
*	library
*	functions:	sprintf, strcat
*
******************************************************************************/

char *letter_to_sound(char *word)
{
    char                buffer[MAX_WORD_LENGTH+3];
    static char         pronunciation[MAX_PRONUNCIATION_LENGTH+1];
    int                 number_of_syllables = 0;


    /*  FORMAT WORD  */
    sprintf(buffer, "#%s#", word);

    /*  CONVERT WORD TO PRONUNCIATION  */
    if (!word_to_patphone(buffer)) {
	isp_trans(buffer, pronunciation);
	/*  ATTEMPT TO MARK SYLL/STRESS  */
	number_of_syllables = syllabify(pronunciation);
	if (apply_stress(pronunciation, word))
	    return NULL;
    } else
	strcpy(pronunciation, buffer);

    /*  APPEND WORD_TYPE_DELIMITER  */
    pronunciation[strlen(pronunciation) - 1] = WORD_TYPE_DELIMITER;

    /*  GUESS TYPE OF WORD  */
    if (number_of_syllables != 1)
	strcat(pronunciation, word_type(word));
    else
	strcat(pronunciation, WORD_TYPE_UNKNOWN);

    /*  RETURN RESULTING PRONUNCIATION  */
    return(pronunciation);
}



/******************************************************************************
*
*	function:	word_type
*
*	purpose:	Returns the word type based on the word spelling.
*			
*       arguments:      word
*                       
*	internal
*	functions:	WORDEND
*                       
*	library
*	functions:	(strlen, strcmp)
*
******************************************************************************/

static char *word_type(char *word)
{
    tail_entry          *list_ptr;

    /*  IF WORD END MATCHES LIST, RETURN CORRESPONDING TYPE  */
    for (list_ptr = tail_list; list_ptr->tail; list_ptr++)
	if (WORDEND(word, list_ptr->tail))
	    return(list_ptr->type);

    /*  ELSE RETURN UNKNOWN WORD TYPE  */
    return(WORD_TYPE_UNKNOWN);
}

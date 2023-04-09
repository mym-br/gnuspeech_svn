/******************************************************************************
*
*     final_s.c
*
*     
*     
*
******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "final_s.h"
#import "member.h"



/******************************************************************************
*
*	function:	final_s
*
*	purpose:	Check for a final s, strip it if found and return s or
*                       z, or else return false.  Don't strip if it's the only
*                       character.
*
*       arguments:      in, eow
*                       
*	internal
*	functions:	member
*
*	library
*	functions:	none
*
******************************************************************************/

char final_s(char *in, char **eow)
{
    register char      *end = *eow;
    char                retval = 0;

    /*  STRIP TRAILING S's  */
    if ((*(end - 1) == '\'') && (*(end - 2) == 's')) {
	*--end = '#';
	*eow = end;
    }

    /*  NOW LOOK FOR FINAL S  */
    if (*(end - 1) == 's') {
	*--end = '#';
	*eow = end;

	if (member(*(end - 1), "cfkpt"))
	    retval = 's';
	else
	    retval = 'z';

	/*  STRIP 'S  */
	if (*(end - 1) == '\'') {
	    *--end = '#';
	    *eow = end;
	}
    }
    return(retval);
}

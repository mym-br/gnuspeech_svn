/* 
 *    Filename:	conversion.c 
 *    Created :	Thu Feb 13 23:54:57 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *
 * LastEditDate "Fri May 22 17:49:51 1992"
 *
 * $Log: not supported by cvs2svn $
 * Revision 2.1  1992/06/10  14:13:44  vince
 * Code for phone C has been fixed, in both the font and
 * in TTSConversionTable array.
 * PrToTTS will returns u_u_u_p_s if it can't convert
 * the word (this is better than Seg faulting)
 *
 * TTSToPreditor now checks the length when it is copying the
 * word type from in input array to the output array.
 * The ` character is converted to a '. the ` stress marker
 * is being phased out of the server.
 *
 * Revision 2.0  1992/04/08  03:43:23  vince
 * Initial-Release
 *
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <appkit/NXCType.h>
#include "phone_conversion.h"

#import "word_types.h"

#define MAX_WORD_LENGTH 1024
#define DELIMITER(a) (((a) == 056) || ((a) == 047) || ((a) == 042))

/* Function declarations ****************************************************************/
static inline int   findPreditor(const char inputchar);
static inline int   findTTS(const char *input);

char *PreditorToTTS(const char *input);
void  PrToTTS(const char *input, char *returnvalue);
char *TTSToPreditor(const char *input);
char *pronunciation(const char *word);
char *word_type(const char *word);




static const char  preditorConversionTable[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
static const char *const TTSConversionTable[]= {
        "aa",     /* a */
	"b",      /* b */
	"ch",     /* c */
	"d",      /* d */
	"uh",     /* e */ 
	"f",      /* f */
	"g",      /* g */
	"h",      /* h */
	"i",      /* i */
	"j",      /* j */
	"k",      /* k */
	"l",      /* l */
	"m",      /* m */
	"n",      /* n */
	"o",      /* o */
	"p",      /* p */
	"e_i",    /* q */
	"r",      /* r */
	"s",      /* s */
	"t",      /* t */
	"u",      /* u */
	"v",      /* v */
	"w",      /* w */
	"a",      /* x */
	"o_i",    /* y */
	"z",      /* z */

	"ar",     /* A */
	"b",      /* B */
	"ch",     /* C */
	"dh",     /* D */
	"e",      /* E */
	"f",      /* F */
	"g",      /* G */
	"h",      /* H */
	"ee",     /* I */
	"y",      /* J */
	"k",      /* K */
	"l",      /* L */
	"m",      /* M */
	"ng",     /* N */
	"aw",     /* O */
	"p",      /* P */
	"uh_uu",  /* Q */
	"er",     /* R */
	"sh",     /* S */
	"th",     /* T */
	"uu",     /* U */
	"v",      /* V */
	"w",      /* W */
	"ah_i",   /* X */
	"ah_uu",  /* Y */
	"zh",     /* Z */
    };

static inline int findPreditor(const char inputchar) /* if speed is a problem make this a macro */
{
    int i;

    if (!NXIsAlpha(inputchar))
	return -1;
    i = ((NXIsUpper(inputchar)) ? 26 : 0);

    for (; i < 52; i++){
	if (inputchar == preditorConversionTable[i])
	    return i;
    }
    return -1;
}

static inline int findTTS(const char *input) /* if speed is a problem make this a macro */
{
    int i;
    for (i=0; i < 52; i++){
	if (!strcmp(input,TTSConversionTable[i]))
	    return i;
    }
    return -1;
}

/* given aeq%type% --> ar_uh_e_i%type% */

char *PreditorToTTS(const char *input)
{
    static char returnvalue[MAX_WORD_LENGTH];

    bzero(returnvalue,MAX_WORD_LENGTH*sizeof(char));
    PrToTTS(input,returnvalue);
    return returnvalue;
}

/* given aeq%type% --> ar_uh_e_i%type% */

void PrToTTS(const char *input,char *returnvalue)
{
    int len = strlen(input);
    int i = 0;
    int index;
    int last_delimiter = 0;        /* Was the last character entered a delimiter that
				    * is either a ' or a .
				    */
    if (!input){
	returnvalue[0] = '\000';
	return;
    }
	
    if (DELIMITER(input[i])){ /* '." characters */
	returnvalue[strlen(returnvalue)] = input[i];
	last_delimiter = 1;
    }else{
	if ((index = findPreditor(input[i])) >= 0){
	    strcat(returnvalue,TTSConversionTable[index]);
	    last_delimiter = 0;
	}else{
	    strcpy(returnvalue,"u_u_u_p_s");
	    return;
	}
    }

    for (i=1;(i < len) && (input[i] != '%'); i++){
	if (DELIMITER(input[i])){ /* '." characters */
	    returnvalue[strlen(returnvalue)] = input[i];
	    last_delimiter = 1;
	}else{
	    if (!last_delimiter)
		strcat(returnvalue,"_");
	    if ((index = findPreditor(input[i])) >= 0){
		strcat(returnvalue,TTSConversionTable[findPreditor(input[i])]);
		last_delimiter = 0;
	    }else{
		strcpy(returnvalue,"u_u_u_p_s");
		return;
	    }
	}
    }

    strcat(returnvalue,&input[i]);
}

/* given ar_uh_e_i%type% --> aeq%type% 
 * given ar_uh_e_i%type --> aeq%type 
 *
 */

char *TTSToPreditor(const char *input)
{
    static char  returnvalue[MAX_WORD_LENGTH];
    int          i=0;
    int          j=0;
    int          length = strlen(input);

    bzero(returnvalue,MAX_WORD_LENGTH*sizeof(char)); 

    while(i<length){
        switch(input[i]){
	  case 'h':                         /* h */
	    returnvalue[j++] = PHONE_H;
	    break;
	  case 'u':                        
	    i++;
	    switch(input[i]){
	      case 'u':                    /* uu */
		returnvalue[j++] = PHONE_UU;
		break;
	      case 'h':                    /* uh */
		returnvalue[j++] = PHONE_UH;
		break;
	      default :                    /* u */
		returnvalue[j++] = PHONE_U;
		i--;
		break;
	    }
	    break;
	  case 'a': 
	    i++;
	    switch(input[i]){
	      case 'a':                    /* aa */
		returnvalue[j++] = PHONE_AA;
		break;
	      case 'r':                    /* ar */
		returnvalue[j++] = PHONE_AR;
		break;
	      case 'h':                    /* ah something can be either ah_uu or ah_i */
		i = i+2;
		if (input[i] == 'u'){      /* ah_uu */
		    returnvalue[j++] = PHONE_AH_UU;
		    i++;
		}else{                     /* ah_i */
		    returnvalue[j++] = PHONE_AH_I;
		}
		break;
	      case 'w':                    /* aw */
		returnvalue[j++] = PHONE_AW;
		break;
	      default :                    /* a */
		returnvalue[j++] = PHONE_A;
		i--;
		break;
	    }
	    break;
	  case 'e': 
	    i++;
	    switch(input[i]){
	      case 'r':                   /* er */
		returnvalue[j++] = PHONE_ER;
		break;
	      case 'e':                   /* ee */
		returnvalue[j++] = PHONE_EE;
		break;
	      default:                    /* e */
		returnvalue[j++] = PHONE_E;
		i--;
		break;
	    }
	    break;
	  case 'i':                       /* i */
	    returnvalue[j++] = PHONE_I;
	    break;
	  case 'o':                       /* o */
	    returnvalue[j++] = PHONE_O;
	    break;
	  case 'r':                       /* r */
	    returnvalue[j++] = PHONE_R;
	    break;
	  case 'w':                       /* w */
	    returnvalue[j++] = PHONE_W;
	    break;
	  case 'l':                       /* l */
	    returnvalue[j++] = PHONE_L;
	    break;
	  case 'y':                       /* y */
	    returnvalue[j++] = PHONE_Y;
	    break;
	  case 'm':                       /* m */
	    returnvalue[j++] = PHONE_M;
	    break;
	  case 'b':                       /* b */
	    returnvalue[j++] = PHONE_B;
	    break;
	  case 'p':                       /* p */
	    returnvalue[j++] = PHONE_P;
	    break;
	  case 'n': 
	    i++;
	    switch(input[i]){
	      case 'g':                  /* ng */
		returnvalue[j++] = PHONE_NG;
		break;
	      default:                   /* n */
		returnvalue[j++] = PHONE_N;
		i--;
	        break;
	    }
	    break;
	  case 'd': 
	    i++;
	    switch(input[i]){
	      case 'h':                     /* dh */
		returnvalue[j++] = PHONE_DH;
		break;
	      default :                     /* d */
		returnvalue[j++] = PHONE_D;
		i--;
		break;
	    }
	    break;
	  case 't': 
	    i++;
	    switch(input[i]){
	      case 'h':                     /* th */
		returnvalue[j++] = PHONE_TH;
		break;
	      default :                     /* t */
		returnvalue[j++] = PHONE_T;
		i--;
		break;
	    }
	    break;
	  case 'g': 
	    returnvalue[j++] = PHONE_G;     /* g */
	    break;
	  case 'k': 
	    returnvalue[j++] = PHONE_K;     /* k */
	    break;
	  case 's': 
            i++;
            switch(input[i]){
              case 'h':                    /* sh */
                returnvalue[j++] = PHONE_SH;
                break;
	      default :                    /* s */
                returnvalue[j++] = PHONE_S;
		i--;
                break;
            }
            break;

	  case 'z': 
            i++;
            switch(input[i]){
              case 'h':                     /* zh */
                returnvalue[j++] = PHONE_ZH;
                break;
	      default :                     /* z */
                returnvalue[j++] = PHONE_Z;
		i--;
                break;
            }
            break;
	  
	  case 'f': 
	    returnvalue[j++] = PHONE_F;      /* f */
	    break;
	  case 'v': 
	    returnvalue[j++] = PHONE_V;      /* v */
	    break;
	  case 'c': 
            i++;
	    returnvalue[j++] = PHONE_CH;     /* ch */
	    break;
	  case 'j':
	    returnvalue[j++] = PHONE_J;      /* j */
	    break;
	  case '.': 
	    returnvalue[j++] = '.';          /* . */
	    break;
	  case 0140:                         /* Convert the ` char to a ' */
	  case 047: 
	    returnvalue[j++] = 047;          /* ' */
	    break;
	  case '0':  /*  strip out all tempo numbers, including decimal point  */
	  case '1':
	  case '2':
	  case '3':
	  case '4':
	  case '5':
	  case '6':
	  case '7':
	  case '8':
	  case '9':
	    if (input[++i] != '.')
		i--;
	    break;
	  case '%':                          /* %type% */
	    returnvalue[j++] = input[i++];
	    while((i < length) && (input[i]!='%')){
		char c = input[i++];
		switch (c) {
		  case NOUN:   /*  pass through legal word types  */
		  case VERB:
		  case ADJECTIVE:
		  case ADVERB:
		  case PRONOUN:
		  case ARTICLE:
		  case PREPOSITION:
		  case CONJUNCTION:
		  case INTERJECTION:
		  case UNKNOWN:
		  case UNKNOWN2:
		    returnvalue[j++] = c;
		    break;
		  case 'k':   /*  strip these out  */
		  case 'l':
		  case 'm':
		    break;
		  default:    /*  map everything else to unknown  */
		    returnvalue[j++] = UNKNOWN;
		    break;
		}
	    }
	    if (i < length)
		returnvalue[j++] = input[i++];
	    break;
	  default:
	    break;
	} /* switch */
	i++;
    } /* while */
    returnvalue[j] = '\000';

    return returnvalue;
}

/* Return the pronunciation of word expects word to be in the form
 * pronunciation%abcdef% or
 * pronunciation%abcdef
 *
 * Returns pronunciation
 *
 */
char *pronunciation(const char *word)
{
    static char copy[MAX_WORD_LENGTH];    
    char *first;    
    char *second;

    if (!word)
	return NULL;

    strcpy(copy,word);
    first = rindex(copy,'%');
    
    if (first){
	*first  = '\000';
    }else{
	return copy;
    }

    if (!copy)
	return NULL;

    second = rindex(copy,'%');
    if (second){
	*second = '\000';
    }
    return copy;
}

/* Return the word type of word, expects word to be in the form of
 * pronunciation%abcdef% or
 * pronunciation%abcdef
 * 
 * Returns abcdef
 *
 */
char *word_type(const char *word)
{
    static char copy[MAX_WORD_LENGTH];    
    char *temp;
    char *first;

    if (!word)
	return NULL;

    strcpy(copy,word);
    first = rindex(copy,'%');
    *first = '\000';
    temp = rindex(copy,'%');
    if (!temp){
	first++;
	return first;
    }else{
	temp++;
	return temp;
    }
}

#ifdef TESTING
int main()
{
    char returnval[MAX_WORD_LENGTH];

    printf("------------------------\n");

    printf("input h_e.'l_uh_uu%%?%%\n");
    printf("Returns = %s\n",TTSToPreditor("h_e.'l_uh_uu%?%"));

    printf("input hE.'leU%%?%%\n");
    printf("returns =  %s\n",PreditorToTTS("hE.'leU%?%"));

    printf("------------------------\n");

    printf("input e.'l_uh_uu%%?%%\n");
    printf("Returns = %s\n",TTSToPreditor("e.'l_uh_uu%?%\n"));

    printf("input E.'leU%%?%%\n");
    printf("returns =  %s\n",PreditorToTTS("E.'leU%?%"));

    printf("------------------------\n");
    printf("input e.'l_aa_uu%%?%%\n");
    printf("Returns = %s\n",TTSToPreditor("e.'l_aa_uu%?%\n"));

    printf("------------------------\n");
    return 1;
}
#endif

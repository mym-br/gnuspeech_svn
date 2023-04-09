/*
 *    Filename:	hash.c 
 *    Created :	Sat Apr  4 16:35:04 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *    LastEditDate was "Tue Apr  7 21:38:10 1992"
 *
 * $Log: not supported by cvs2svn $
 * Revision 2.0  1992/04/08  03:43:23  vince
 * Initial-Release
 *
 *
 */


/* C code produced by gperf version 2.1 (K&R C version) */
/* Command-line: gperf -D -t -C -a -G words  */


#include "word_types.h"
#include <strings.h>

struct typestruct { char *name; char code;};

#define MIN_WORD_LENGTH 4
#define MAX_WORD_LENGTH 12
#define MIN_HASH_VALUE 4
#define MAX_HASH_VALUE 17
/*
    9 keywords
   14 is the maximum key range
*/

static inline int typehash (const char *str, int len)
{
  static const unsigned char hash_table[] =
    {
     17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
     17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
     17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
     17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
     17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
     17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
     17, 17, 17, 17, 17,  0, 17,  0, 17, 17,
     17, 17, 17,  5, 17, 17, 17, 17, 10, 17,
      5, 17, 17, 17, 17, 17,  0, 17, 17, 17,
     17, 17, 17, 17, 17, 17, 17, 17,  0, 17,
     17,  0, 17, 17, 17, 17, 17, 17, 17, 17,
      0, 17, 17, 17, 17, 17, 17, 17, 17, 17,
     17, 17, 17, 17, 17, 17, 17, 17,
    };
  return len + hash_table[(int)str[len - 1]] + hash_table[(int)str[0]];
}


static const struct typestruct  wordlist[] =
{
      {"",}, {"",}, {"",}, {"",}, 
      {"Verb", 		VERB},
      {"",}, 
      {"Adverb", 	ADVERB},
      {"Article", 	ARTICLE},
      {"",}, 
      {"Adjective", 	ADJECTIVE},
      {"",}, 
      {"Conjunction", 	CONJUNCTION},
      {"Pronoun", 	PRONOUN},
      {"",}, 
      {"Noun", 		NOUN},
      {"",}, 
      {"Preposition", 	PREPOSITION},
      {"Interjection", 	INTERJECTION},
};

const char typecode(const char *str, int len)
{
  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH){
      int key = typehash (str, len);
      if (key <= MAX_HASH_VALUE && key >= MIN_HASH_VALUE){
	  return wordlist[key].code;
      }
    }
  return 0;
}
#ifdef TESTING	
main()
{
    printf("code = %c for Noun\n", code("Noun",4));
    printf("code = %c for Verb\n", code("Verb",4));
    printf("code = %c for Adj\n",  code("Adjective",9));
    printf("code = %c for Adv\n",  code("Adverb",6));
    printf("code = %c for Pro\n",  code("Pronoun",7));
    printf("code = %c for Arti\n", code("Article",7));
    printf("code = %c for Prep\n", code("Preposition",11));
    printf("code = %c for Conj\n", code("Conjunction",11));
    printf("code = %c for Inter\n",code("Interjection",12));
    printf("code = %c for Inter\n",code("Inte",4));

}
#endif

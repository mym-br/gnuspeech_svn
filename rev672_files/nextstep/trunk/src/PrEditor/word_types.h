/*
 *    Filename:	word_types.h 
 *    Created :	Sat Apr  4 17:26:45 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *    LastEditDate was "Fri May  8 16:24:10 1992"
 *
 * $Log: not supported by cvs2svn $
 * Revision 2.1  1992/06/10  14:08:28  vince
 * Values for UNKNOWN and UNKNOWN2 have been swapped.
 * PrEditor uses UNKNOWN for the dictionaries it creates. It will
 * now use the 'j' code for words that have no type, instead of
 * '?'
 *
 * Revision 2.0  1992/04/08  03:43:23  vince
 * Initial-Release
 *
 *
 */

/* Speech Server word types */

#define NOUN         'a'
#define VERB         'b'
#define ADJECTIVE    'c'
#define ADVERB       'd'
#define PRONOUN      'e'
#define ARTICLE      'f'
#define PREPOSITION  'g'
#define CONJUNCTION  'h'
#define INTERJECTION 'i'
#define UNKNOWN      'j'
#define UNKNOWN2     '?'

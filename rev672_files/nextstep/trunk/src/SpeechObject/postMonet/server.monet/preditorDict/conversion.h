/*
 *    Filename:	conversion.h 
 *    Created :	Fri Mar  6 15:22:55 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *
 * LastEditDate "Tue Apr  7 21:38:05 1992"
 *
 * $Log: not supported by cvs2svn $
 * Revision 2.0  1992/04/08  03:43:23  vince
 * Initial-Release
 *
 *
 */

/* conversion.c */
extern char *PreditorToTTS(const char *input);
extern void PrToTTS(const char *input, char *returnvalue);
extern char *TTSToPreditor(const char *input);
extern char *pronunciation(const char *word);
extern char *word_type(const char *word);

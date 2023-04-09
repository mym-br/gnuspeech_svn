/*
 *    Filename:	EnglishConstruct.h 
 *    Created :	Thu Jul 15 15:08:19 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Thu Jul 15 17:15:50 1993"
 *
 * $Id: EnglishConstruct.h,v 1.2 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: EnglishConstruct.h,v $
 * Revision 1.2  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.1  1993/07/23  07:33:00  dale
 * Initial revision
 *
 */

#import <appkit/Text.h>

@interface Text(EnglishConstruct)

- wordAtPosition:(int)position start:(int *)start length:(int *)length;
- phraseAtPosition:(int)position start:(int *)start length:(int *)length;
- sentenceAtPosition:(int)position start:(int *)start length:(int *)length;
- paragraphAtPosition:(int)position start:(int *)start length:(int *)length;
- titleAtPosition:(int)position start:(int *)start length:(int *)length;
- singleQuoteExpressionAtPosition:(int)position start:(int *)start length:(int *)length;
- doubleQuoteExpressionAtPosition:(int)position start:(int *)start length:(int *)length;
- parentheticalExpressionAtPosition:(int)position start:(int *)start length:(int *)length;

- (char *)wordAtPosition:(int)position;
- (char *)phraseAtPosition:(int)position;
- (char *)sentenceAtPosition:(int)position;
- (char *)paragraphAtPosition:(int)position;
- (char *)titleAtPosition:(int)position;
- (char *)singleQuoteExpressionAtPosition:(int)position;
- (char *)doubleQuoteExpressionAtPosition:(int)position;
- (char *)parentheticalExpressionAtPosition:(int)position;

@end

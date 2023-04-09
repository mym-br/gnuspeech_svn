/*
 *    Filename:	EnglishConstruct.m 
 *    Created :	Thu Jul 15 15:21:14 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Fri Jul 16 15:32:53 1993"
 *
 * $Id: EnglishConstruct.m,v 1.2 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: EnglishConstruct.m,v $
 * Revision 1.2  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.1  1993/07/23  07:33:00  dale
 * Initial revision
 *
 */

/* This class extends the Text class by providing methods for identifying various english constructs
 * residing at particular locations in the stream. The methods work by traversing the stream forwards
 * and backwards from the specified location until the delimiting conditions required are satisfied.
 * Currently, these methods will continue searching until the start and/or end of the stream is 
 * reached if the required conditions are not met. The position arguments in all methods are the same
 * type of values which are used in the Text classes positionFromLine: and lineFromPosition: methods.
 * There are two interfaces available, and both are described below.
 *
 * The first set of interfaces take the position in the stream at which the construct may reside. If 
 * the supplied position falls within the start and end of the appropriate construct, the start and 
 * length are returned in the start and length arguments. If the construct in question does not 
 * straddle the specified position, these methods return nil. Otherwise self is returned.
 *
 * The second set of interfaces again take the position in the stream at which the construct may 
 * reside. If the supplied position falls within the start and end of the appropriate construct, a 
 * character string representing the construct is returned. If the construct in question does not
 * straddle the specified position, these methods return NULL. Note that it is the responsibility of
 * the caller to free the returned character string once it is no longer required.
 */

#import <appkit/NXCType.h>
#import "EnglishConstruct.h"

@implementation Text(EnglishConstruct)

/* This method identifies the word located at position within the text object. If no word could be 
 * found at the position specified, then we return NULL. Incidently, if a word could not be found, 
 * then the position passed is that of a whitespace character, or there are no delimiting whitespace 
 * characters in the stream. Words are defined as any concatenation of printable characters delimited
 * by whitespace. Returns self if a word is found.
 */
- wordAtPosition:(int)position start:(int *)start length:(int *)length
{
    int ch;
    NXStream *stream = [self stream];
    
    NXSeek(stream, position, NX_FROMSTART);
    ch = NXGetc(stream);
    if (!NXIsGraph(ch)) {   // selected whitespace
        return nil;
    }
    *start = position;
    while (*start > 0 && NXIsGraph(ch)) {
	(*start)--;
	NXSeek(stream, -2, NX_FROMCURRENT);
	ch = NXGetc(stream);
    }
    if (!NXIsGraph(ch)) {
        (*start)++;
    }
    NXSeek(stream, position, NX_FROMSTART);
    ch = NXGetc(stream);
    *length = position - *start;
    while (!NXAtEOS(stream) && NXIsGraph(ch)) {
	(*length)++;
	ch = NXGetc(stream);
    }
    return self;
}

/* NOT IMPLEMENTED. */
- phraseAtPosition:(int)position start:(int *)start length:(int *)length
{
    return nil;
}

/* NOT IMPLEMENTED. */
- sentenceAtPosition:(int)position start:(int *)start length:(int *)length
{
    return nil;
}

/* NOT IMPLEMENTED. */
- paragraphAtPosition:(int)position start:(int *)start length:(int *)length
{
    return nil;
}

/* NOT IMPLEMENTED. */
- titleAtPosition:(int)position start:(int *)start length:(int *)length
{
    return nil;
}

/* NOT IMPLEMENTED. */
- singleQuoteExpressionAtPosition:(int)position start:(int *)start length:(int *)length
{
    return nil;
}

/* NOT IMPLEMENTED. */
- doubleQuoteExpressionAtPosition:(int)position start:(int *)start length:(int *)length
{
    return nil;
}

/* NOT IMPLEMENTED. */
- parentheticalExpressionAtPosition:(int)position start:(int *)start length:(int *)length
{
    return nil;
}

/* Returns the word located at position within the text object. position is equivalent to the position
 * values used in the Text classes positionFromLine: and lineFromPosition methods (among others). If
 * no word could be found at the position specified, then we return NULL. Incidently, if a word could
 * not be found, then the position passed is that of a whitespace character. Words are defined as any
 * concatenation of characters delimited by whitespace. NOT IMPLEMENTED.
 */
- (char *)wordAtPosition:(int)position
{
    return NULL;
}

/* NOT IMPLEMENTED. */
- (char *)phraseAtPosition:(int)position
{
    return NULL;
}

/* NOT IMPLEMENTED. */
- (char *)sentenceAtPosition:(int)position
{
    return NULL;
}

/* NOT IMPLEMENTED. */
- (char *)paragraphAtPosition:(int)position
{
    return NULL;
}

/* NOT IMPLEMENTED. */
- (char *)titleAtPosition:(int)position
{
    return NULL;
}

/* NOT IMPLEMENTED. */
- (char *)singleQuoteExpressionAtPosition:(int)position
{
    return NULL;
}

/* NOT IMPLEMENTED. */
- (char *)doubleQuoteExpressionAtPosition:(int)position
{
    return NULL;
}

/* NOT IMPLEMENTED. */
- (char *)parentheticalExpressionAtPosition:(int)position
{
    return NULL;
}

@end

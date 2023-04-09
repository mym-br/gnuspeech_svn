/*
 *    Filename:	Publisher.m 
 *    Created :	Thu May 27 13:14:10 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Fri Sep  9 21:12:39 1994"
 *
 * $Id: Publisher.m,v 1.10 1994/06/10 20:18:28 dale Exp $
 *
 * $Log: Publisher.m,v $
 * Revision 1.10  1994/06/10  20:18:28  dale
 * Modified lines/columns holophrast to use tab or 3 spaces as separator between nodes.
 *
 * Revision 1.9  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.8  1993/07/14  22:11:48  dale
 * *** empty log message ***
 *
 * Revision 1.7  1993/06/18  08:45:44  dale
 * *** empty log message ***
 *
 * Revision 1.6  1993/06/09  18:23:00  dale
 * Added ":" and ")" as part of paragraph punctuation.
 *
 * Revision 1.5  1993/06/07  08:11:40  dale
 * Initial attempt made at getting left holophrasts working throughout the system.
 *
 * Revision 1.4  1993/06/04  20:57:48  dale
 * *** empty log message ***
 *
 * Revision 1.3  1993/06/04  07:18:00  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/06/03  00:37:58  dale
 * *** empty log message ***
 *
 * Revision 1.1  1993/06/02  21:21:45  dale
 * Initial revision
 *
 */

#import "TNTDefinitions.h"
#import "Node.h"
#import "PageNode.h"
#import "BookmarkNode.h"
#import "Document.h"
#import "Publisher.h"

/* Whitespace definitions. */
#define BACKSPACE           010
#define NEWLINE             012
#define SPACE               040
#define TAB                 011

/* Characters used with BACKSPACE. */
#define UNDERSCORE          0137

/* Holophrast symbol definitions. */
#define SINGLE_LEFT_QUOTE   0140
#define SINGLE_RIGHT_QUOTE  047
#define DOUBLE_QUOTE        042
#define LEFT_PAREN          050
#define RIGHT_PAREN         051

/* Size of reallocation buffer increment when wrapping lines. */
#define REALLOC_BUFFER_INC  1024

@implementation Publisher

- init
{
    [super init];
    return self;
}

- free
{
   return [super free];
}

/* Identical to publishEnglishTextDocument:withLineLength except line length is zero. This means no
 * line wrapping is performed. Returns what publishEnglishTextDocument:withLineLength returns.
 */
- publishEnglishTextDocument:aDoc
{
    return [self publishEnglishTextDocument:aDoc withLineLength:0];
}

/* Publishes all nodes in the english text document. These nodes include titles, paragraphs, 
 * sentences, phrases, parenthetical expressions, double quote expressions, single quote expresssions,
 * line/column (tabular data), and pages. We append a single newline character in the event the last
 * character is not a newline. Note, requesting the stream from the Text object returns a READ ONLY
 * stream as documented under the -stream method of the Text class. Also note that textLength is
 * one greater then the ACTUAL number of characters in the Text object. Also, specifying a maxLength
 * of zero indicates that no wrapping should be performed. Returns self.
 */
- publishEnglishTextDocument:aDoc withLineLength:(unsigned int)maxLength
{
    id docText;
    int length;
    char *filterBuffer = NULL, *wrapBuffer = NULL;
    NXStream *stream, *streamToWrap;

    docText = [aDoc text];
    stream = [docText stream];

    // filter control characters from stream
    filterBuffer = [self filterControlCharacters:stream];

    // wrap lines in the buffer if required
    if (maxLength > 0) {
	if (!(streamToWrap = NXOpenMemory(NULL, 0, NX_READWRITE))) {
	    fprintf(stderr, "Publisher: Cannot open memory stream.\n");
	    return self;
	}
	NXWrite(streamToWrap, filterBuffer, strlen(filterBuffer));
	NXSeek(streamToWrap, 0, NX_FROMSTART);   // reposition stream to start
	free(filterBuffer);
	wrapBuffer = [self wrapLines:streamToWrap longerThan:maxLength];
	[docText setText:wrapBuffer];
	free(wrapBuffer);
	NXClose(streamToWrap);   // close and free stream
    } else {
	[docText setText:wrapBuffer];
	free(filterBuffer);
    }

    stream = [docText stream];             // get the new stream
    NXSeek(stream, -1, NX_FROMEND);
    if (NXGetc(stream) != '\n') {          // append single newline character to end of document
	length = [docText textLength];
        [docText setSel:length :length];   // empty selection of last character + 1
        [docText replaceSel:"\n"];
	stream = [docText stream];         // get modified stream
    }

    // generate all node lists for document (except bookmarks)
    [aDoc setTitleNodeList:[self publishTitles:stream]];
    [aDoc setParagraphNodeList:[self publishParagraphs:stream]];
    [aDoc setSentenceNodeList:[self publishSentences:stream]];
    [aDoc setPhraseNodeList:[self publishPhrases:stream]];
    [aDoc setParenNodeList:[self publishParentheses:stream]];
    [aDoc setDoubleQuoteNodeList:[self publishDoubleQuotes:stream]];
    [aDoc setSingleQuoteNodeList:[self publishSingleQuotes:stream]];
    [aDoc setLineColumnNodeList:[self publishLineColumns:stream]];
    [aDoc setPageNodeList:[self publishPages:stream]];

    // update bookmark within all page nodes (must be done after pages are published)
    [self publishBookmarks:aDoc];

    return self;
}

/* Identical to publishCSourceCodeDocument:withLineLength except line length is zero. This means no
 * line wrapping is performed. Returns what publishCSourceCodeDocument:withLineLength returns.
 */
- publishCSourceCodeDocument:aDoc
{
    return [self publishCSourceCodeDocument:aDoc withLineLength:0];
}

/* Not Implemented. */
- publishCSourceCodeDocument:aDoc withLineLength:(unsigned int)maxLength
{
    return self;
}

/* Creates a node with the appropriate start and end values, and adds it to the nodeList List object
 * instance. Note that the level of the node is undefined. Therefore querying node objects for there 
 * level currently returns some arbitrary value. Returns self.
 */
- createNode:(int)start :(int)end forNodeList:nodeList
{
    id node = [[Node allocFromZone:[self zone]] init];

    [[node setStart:start] setEnd:end];
    [nodeList addObject:node];
    return self;
}

/* Identical to -createNode:forNodeList except creates PageNode objects instead of Node objects, and
 * adds them to the nodeList. Returns self.
 */
- createPageNode:(int)start :(int)end forNodeList:nodeList
{
    id node = [[PageNode allocFromZone:[self zone]] init];

    [[node setStart:start] setEnd:end];
    [nodeList addObject:node];
    return self;
}

/* Finds all titles in the text.  A title is defined as follows, begins with a blank line, followed
 * by a maximum of 1 line of text, where the first printable char must be an upper case char, or a 
 * digit, and ending w/ one blank line of text.  Also, the last printable char on the line must not 
 * be a form of punctuation.  The start state is set at 1, since the first line of text MAY not be
 * preceeded by a blank line (eg. if a title is on the first line of the document) in which case we 
 * fake it, by pretending it was preceeded by a blank line.  This has no effect if the first line is 
 * infact a blank line, it will just be eaten up as usual.
 */
- publishTitles:(NXStream *)stream
{
    id nodeList = [[List allocFromZone:[self zone]] init];
    int ch, start = 0, end = 0, state = 1;

    NXSeek(stream, 0, NX_FROMSTART);
    for ( ; ; ) {
        switch (state) {
          case -1:
            if ([self getNewLine:stream])   // need newline char to advance; if EOS, detected below
                state++;
            break;

          case 0:
            if ([self blankLine:stream])   // at least one blank line required; if EOS, detected below
                state++;
            else   // printable char encountered, or EOS; eat to end of line
                [self getNewLine:stream];
            break;

          case 1:
            ch = NXGetc(stream);
            if (NXAtEOS(stream))
                return nodeList;
            if (NXIsUpper(ch) || NXIsDigit(ch)) {   // 1st printable char must be either one
                start = NXTell(stream) - 1;
                state++;
            } else if (NXIsGraph(ch))   // failure, reset and start over
                state = -1;
            break;

          case 2:
            ch = NXGetc(stream);
            if (NXAtEOS(stream))
                return nodeList;
            if (ch == NEWLINE) {
                end = NXTell(stream) - 2;   // don't include newline in selections
                state = 4;
            } else if (NXIsPunct(ch))   // punctuation MIGHT be last on line
                state++;
            break;

          case 3:
            ch = NXGetc(stream);
            if (NXAtEOS(stream))
                return nodeList;
            if (ch == NEWLINE)   // failure, reset and start over; punctuation must not be last
                state = 0;
            else if (NXIsGraph(ch))   // second life; punctuation was not last
               state--;
            break;

          case 4:
            if ([self blankLine:stream]) {   // goal state; we have a title
		[self createNode:start :end forNodeList:nodeList];
                state = 1;   // blank line is also first blank line of next pass
            } else {   // 2 consecutive lines of text; back to start state; maybe EOS
                [self getNewLine:stream];
                state = 0;        
            }
            break;

          default:
            break;
        }
        if (NXAtEOS(stream))   // all done if EOS; here we catch EOS that occurred previously
            return nodeList;
    }
    return nodeList;
}

/* Find all paragraphs in the text.  A paragraph is defined as follows, may or may not begin with a 
 * blank line (special case if first item in text), followed by any number of lines of text, where the
 * first printable char on the first line of text must be an upper case letter.  The final line must
 * end with some form of punctuation.  Finally, the last line must be a blank line.  Note that it is 
 * okay if whitespace follows the punctuation on the last line.  The start state is set at 1.
 */
- publishParagraphs:(NXStream *)stream
{
    id nodeList = [[List allocFromZone:[self zone]] init];
    int ch, start = 0, end = 0, state = 1;

    NXSeek(stream, 0, NX_FROMSTART);
    for ( ; ; ) {
        switch (state) {
          case 0:
            if ([self getNewLine:stream])   // need newline char to advance; if EOS, detected below
                state++;            
            break;

          case 1:
            ch = NXGetc(stream);
            if (NXAtEOS(stream))
                return nodeList;
            if (NXIsUpper(ch)) {   // 1st printable char must be upper case
                start = NXTell(stream) - 1;
                state++;
            } else if (NXIsGraph(ch))   // failure, reset and start over
                state--;
            break;

          case 2:
            ch = NXGetc(stream);
            if (NXAtEOS(stream))
                return nodeList;
            if (ch == NEWLINE) {
                state++;
            } else if ([self isParagraphPunct:ch]) {   // punctuation must end paragraph
                state = 4;
            }
            break;

          case 3:
            if ([self blankLine:stream])   // no blank lines within paragraph allowed, restart
                state = 1;
            else
                state--;
            break;
            
          case 4:
            ch = NXGetc(stream);
            if (NXAtEOS(stream))
                return nodeList;
            if (ch == NEWLINE) {   // almost have a paragraph, only need a blank line now
                end = NXTell(stream) - 2;   // don't include newline in selections
                state++;
            } else if (![self isParagraphPunct:ch] && NXIsGraph(ch)) {
                state = 2;
            }
            break;

          case 5:
            if ([self blankLine:stream]) {   // goal state; we have a paragraph
		[self createNode:start :end forNodeList:nodeList];
                state = 1;   // blank line is also first blank line of next pass
            } else {   // still parsing same paragraph, or EOS
                state = 2;
            }
            break;

          default:
            break;
        }
        if (NXAtEOS(stream))   // all done if EOS; here we catch EOS that occurred previously
            return nodeList;
    }
    return nodeList;
}

/* Find all sentences in the text.  A sentence is defined as follows, may or may not be preceeded by
 * whitespace (special case if first item in text), followed by any number of lines of text, where the
 * first printable char on the first line must be an upper case letter.  The final line must end with
 * some form of punctuation as defined in the isSentencePunct: method.  There must not be blank lines
 * between lines of a sentence.  Also, following the punctuation, terminating the sentence, either a
 * newline char must follow, or 2 other whitespace characters.  This is the reason for states 5 and 6
 * being quite similar.
 */
- publishSentences:(NXStream *)stream
{
    id nodeList = [[List allocFromZone:[self zone]] init];
    int ch, start = 0, end = 0, state = 2;

    NXSeek(stream, 0, NX_FROMSTART);
    for ( ; ; ) {
        switch (state) {
          case 0:
            ch = NXGetc(stream);
            if (NXAtEOS(stream))
                return nodeList;
            if (ch == NEWLINE)   // single newline okay to begin sentence detection
                state = 2;
            else if (NXIsCntrl(ch) || ch == SPACE)   // need 2 whitespace chars (not newline here)
                state++;
            break;

          case 1:
            ch = NXGetc(stream);
            if (NXAtEOS(stream))
                return nodeList;
            if (NXIsCntrl(ch) || ch == SPACE)   // whitespace, incl. newline; begin sentence search
                state++;
            else   // must have 2 consecutive whitespace chars
                state--;
            break;

          case 2:
            ch = NXGetc(stream);
            if (NXAtEOS(stream))
                return nodeList;
            if (NXIsUpper(ch)) {   // char is upper case letter
                start = NXTell(stream) - 1;
                state++;
            } else if (NXIsGraph(ch)) {   // printable char other that upper case letter
                state = 0;
            }
            break;

          case 3:
            ch = NXGetc(stream);
            if (NXAtEOS(stream))
                return nodeList;
            if (ch == NEWLINE)   // make sure next line is NOT a blank line
                state++;
            else if ([self isSentencePunct:ch]) {   // maybe at end of a sentence
                end = NXTell(stream) - 1;           
                state = 5;
            }
            break;

          case 4:
            if ([self blankLine:stream])   // not a sentence; restart by looking for upper case char 
                state = 2;                 // again
            else
                state--;
            break;

          case 5:
            ch = NXGetc(stream);
            if (NXAtEOS(stream))
                return nodeList;        
            if (ch == NEWLINE) {   // goal, sentence recognized
		[self createNode:start :end forNodeList:nodeList];            
                state = 2;
            } else if ([self isSentencePunct:ch]) {   // update end, since > 1 punct. occurred
                end = NXTell(stream) - 1;
            } else if (NXIsCntrl(ch) || ch == SPACE) {
                state++;
            } else {
                state = 3;
            }
            break;

          case 6:
            ch = NXGetc(stream);
            if (NXAtEOS(stream))
                return nodeList;        
            if (NXIsCntrl(ch) || ch == SPACE) {   // newline or second whitespace; goal
		[self createNode:start :end forNodeList:nodeList];
                state = 2;
            } else if ([self isSentencePunct:ch]) {
                end = NXTell(stream) - 1;
                state--;
            } else {
                state = 3;
            }
            break;

          default:
            break;
        }
        if (NXAtEOS(stream))   // all done if EOS; here we catch EOS that occurred previously
            return nodeList;
    }
    return nodeList;
}

/* Find all phrases in the text.  A phrase is defined as follows, begins with anything except a valid
 * phrase punctuation character, must be preceeded by a whitespace character, unless first element in
 * document, may consist of any number of lines, and must be followed by a valid phrase punctuation 
 * character, and then a whitespace character.  Blank lines may not occur within a phrase.
 */
- publishPhrases:(NXStream *)stream
{
    id nodeList = [[List allocFromZone:[self zone]] init];
    int ch, start = 0, end = 0, state = 1;

    NXSeek(stream, 0, NX_FROMSTART);
    for ( ; ; ) {
        ch = NXGetc(stream);
        if (NXAtEOS(stream))
            return nodeList;
        switch (state) {
          case 0:
            if (!NXIsGraph(ch))   // need non printable char to begin search for separation
                state++;
            break;

          case 1:
            if ([self isPhrasePunct:ch]) {   // punctuation in bad place; get whitespace to reset
                state--;
            } else if (NXIsGraph(ch)) {   // pintable char other than punct., begin of phrase
                start = NXTell(stream) - 1;
                state++;
            }
            break;

          case 2:
            if (ch == NEWLINE) {   // maybe blankline on next line, check
                state++;
            } else if ([self isPhrasePunct:ch]) {   // punctuation, end of phrase
                end = NXTell(stream) - 1;
                state = 4;
            }
            break;

          case 3:
            if ([self isPhrasePunct:ch]) {   // punctuation, end of phrase
                end = NXTell(stream) - 1;
                state++;
            } else if (ch == NEWLINE) {   // blank line; restart by getting non punctuation char
                state = 1;
            } else if (NXIsGraph(ch)) {   // not a blank line, okay; keep reading
                state--;
            }
            break;

          case 4:
            if (!NXIsGraph(ch)) {   // nonprintable char including newline etc.
		[self createNode:start :end forNodeList:nodeList];
                state = 1;              
            } else if (![self isPhrasePunct:ch]) {   // printable char; still part of paragraph
                state = 2;
            } else {   // more punctuation
                end = NXTell(stream) - 1;
            }
            break;

          default:
            break;
        }
    }
    return nodeList;
}

/* Find all parenthetical expressions in the text. We currently do not deal with nested expressions.
 * Therefore, if a nested parenthetical expression does occur, we just match the first close 
 * parenthesis with the last open parenthesis encountered.
 */
- publishParentheses:(NXStream *)stream
{
    id nodeList = [[List allocFromZone:[self zone]] init];
    int ch, start = 0, end = 0;
    BOOL haveLeftParen = NO;

    NXSeek(stream, 0, NX_FROMSTART);
    ch = NXGetc(stream);
    while (!NXAtEOS(stream)) {
        switch (ch) {
	  case LEFT_PAREN:
	    if (!haveLeftParen) {   // start new parenthetical node
                start = NXTell(stream) - 1;
                haveLeftParen = YES;
            }
            break;

	  case RIGHT_PAREN:
            if (haveLeftParen) {   // have end of parenthetical node
		end = NXTell(stream) - 1;
		[self createNode:start :end forNodeList:nodeList];
                haveLeftParen = NO;
            }
	    break;

	  default:
	    break;
	}
	ch = NXGetc(stream);
    }
    return nodeList;
}

/* Find all double quoted expressions in the text. We currently do not deal with nested expressions.
 * Therefore, if a nested double quoted expression does occur, we just match sequential pairs of 
 * double quotes encountered.
 */
- publishDoubleQuotes:(NXStream *)stream
{
    id nodeList = [[List allocFromZone:[self zone]] init];
    int ch, start = 0, end = 0;
    BOOL haveDoubleQuote = NO;

    NXSeek(stream, 0, NX_FROMSTART);
    ch = NXGetc(stream);
    while (!NXAtEOS(stream)) {
	switch (ch) {
	  case DOUBLE_QUOTE:
	    if (haveDoubleQuote) {   // now have end of double quote node
		end = NXTell(stream) - 1;
		[self createNode:start :end forNodeList:nodeList];
                haveDoubleQuote = NO;
            } else {   // start new double quote node
                start = NXTell(stream) - 1;
                haveDoubleQuote = YES;
            } 
            break;

	  default:
	    break;
	}
	ch = NXGetc(stream);
    }
    return nodeList;
}

/* Find all single quoted expressions in the text. We currently do not deal with nested expressions.
 * Therefore, if a nested single quoted expression does occur, we just match sequential pairs of 
 * single quotes encountered. We recognize various single quote characters, and various combinations 
 * thereof. Three paired combination of the single quote characters ` and ' are valid single quote 
 * expressions. These combinations include, '...', `...', and `...`. Note that the '...` combination
 * is not valid, and is therefore treated as arbitary text.
 */
- publishSingleQuotes:(NXStream *)stream
{
    id nodeList = [[List allocFromZone:[self zone]] init];
    int ch, start = 0, end = 0;
    BOOL haveLeftQuote = NO, haveRightQuote = NO;

    NXSeek(stream, 0, NX_FROMSTART);
    ch = NXGetc(stream);
    while (!NXAtEOS(stream)) {
        switch (ch) {
	  case SINGLE_LEFT_QUOTE:
	    if (haveLeftQuote) {   // have end of single quote node (2 left quotes)
		end = NXTell(stream) - 1;
		[self createNode:start :end forNodeList:nodeList];
                haveLeftQuote = NO;
	    } else {   // start new single quote node
                start = NXTell(stream) - 1;
                haveLeftQuote = YES;
		haveRightQuote = NO;
	    }
	    break;

	  case SINGLE_RIGHT_QUOTE:
            if (haveLeftQuote) {   // now have end of single quote node (left & right quote)
		end = NXTell(stream) - 1;
		[self createNode:start :end forNodeList:nodeList];
                haveLeftQuote = NO;
            } else if (haveRightQuote) {   // now have end of single quote node (2 right quotes)
		end = NXTell(stream) - 1;
		[self createNode:start :end forNodeList:nodeList];
                haveRightQuote = NO;
	    } else {   // start new single quote node
                start = NXTell(stream) - 1;
                haveRightQuote = YES;
	    }
            break;

	  default:
	    break;
	}
	ch = NXGetc(stream);
    }
    return nodeList;
}

/* Find all columns (tabular text) for all lines. We recognize multiple columns on a single line 
 * whenever tab(s) or a minimum of 3 space characters separates text. If this does not happen, then 
 * the entire line is treated as a single tabular column. Note: TABS are currently filtered out of the
 * text (within TNT) due to problems encountered with tab rulers, so we really never encounter tabs,
 * but we pretend they can exist just the same. The value of 3 spaces or more was chosen since it is 
 * typically the case that two spaces separates the end of a sentence with the beginning of a new
 * sentence. Thus we don't want to treat these sentence parts as two separate nodes. Note, however, 
 * that this division is not always adequate since their may be less that 3 spaces between elements of
 * two columns in a table.
 */
- publishLineColumns:(NXStream *)stream
{
    id nodeList = [[List allocFromZone:[self zone]] init];
    int ch, start = 0, end = 0, state = 0;

    NXSeek(stream, 0, NX_FROMSTART);
    for ( ; ; ) {
        ch = NXGetc(stream);
        if (NXAtEOS(stream))
            return nodeList;
        switch (state) {
          case 0:
            if (NXIsGraph(ch)) {   // node starts with a printable char
                start = NXTell(stream) - 1;
                end = start;
                state++;
            }
            break;

          case 1:
            if (NXIsGraph(ch)) {   // update end of node, but stay in current state
                end = NXTell(stream) - 1;
            } else if (ch == TAB) {   // may be part of separator between current and next node
                state += 3;
	    } else if (ch == SPACE) {   // may be part of separator between current and next node
		state++;      
            } else if (ch == NEWLINE) {   // goal state, we have a node
		[self createNode:start :end forNodeList:nodeList];
                state = 0;
            }
            break;

	  case 2:
	    if (NXIsGraph(ch)) {   // update end of node, and revert to previous state
		end = NXTell(stream) - 1;
		state--;
	    } else if (ch == TAB) {   // may be part of separator between current and next node
		state += 2;
	    } else if (ch == SPACE) {   // may be part of separator between current and next node
		state++;      
	    } else if (ch == NEWLINE) {   // goal state, we have a node
		[self createNode:start :end forNodeList:nodeList];
                state = 0;
	    }
	    break;

	  case 3:
	    if (NXIsGraph(ch)) {   // update end of node, and revert to state - 2
		end = NXTell(stream) - 1;
		state -= 2;
	    } else if (ch == TAB || ch == SPACE) {   // may be part of separator between current and
		state++;                             // next node
	    } else if (ch == NEWLINE) {   // goal state, we have a node
		[self createNode:start :end forNodeList:nodeList];
                state = 0;
	    }
	    break;

          case 4:
            if (NXIsGraph(ch)) {    // goal state; printable char after TAB(s)/SPACES indicates we had
                NXUngetc(stream);   // a node
		[self createNode:start :end forNodeList:nodeList];
                state = 0;
            } else if (ch == NEWLINE) {   // goal state; we have a node
		[self createNode:start :end forNodeList:nodeList];
                state = 0;
            }
            break;

          default:
            break;
        }
    }
    return nodeList;
}

/* Publish information on page breaks.  This is set to TNT_LINES_PER_PAGE. Returns self. */
- publishPages:(NXStream *)stream
{
    id nodeList = [[List allocFromZone:[self zone]] init];
    int i, start, end;

    NXSeek(stream, 0, NX_FROMSTART);
    for ( ; ; ) {
	start = NXTell(stream);
        for (i = 0; i < TNT_LINES_PER_PAGE; i++) {
            if (![self getNewLine:stream]) {   // EOS, all done
		end = NXTell(stream) - 1;
		if (end >= start) {   // don't add a page node (it's empty)
		    [self createPageNode:start :end forNodeList:nodeList];
		}
		return nodeList;
	    }
        }
        end = NXTell(stream) - 1;
	[self createPageNode:start :end forNodeList:nodeList];
    }
    return nodeList;
}

/* Updates the bookmark instance variables in all the (newly created) PageNode objects to correspond
 * to what exists in the bookmarkNodeList. If there are no bookmark nodes, then no updates are made to
 * the pageNode objects within the pageNodeList. If a bookmark node references a page node that no
 * longer exists (after the re-publish, and thru page numbers) then we simply remove that bookmark. 
 * Returns self.
 */
- publishBookmarks:aDoc
{
    unsigned int i, count;
    id bookmarkNode, pageNode;
    id bookmarkNodeList = [aDoc bookmarkNodeList];
    id pageNodeList = [aDoc pageNodeList];

    count = [bookmarkNodeList count];
    if (bookmarkNodeList == nil || count == 0) {   // no bookmarks
	return self;
    }

    // update bookmark within all page nodes
    for (i = 0; i < count; i++) {
	bookmarkNode = [bookmarkNodeList objectAt:i];
	pageNode = [pageNodeList objectAt:[bookmarkNode pageNumber] - 1];
	if (pageNode) {   // page node still exists; update bookmark within page node
	    [pageNode setBookmark:bookmarkNode];
	} else {   // page node no longer exists; remove bookmark, and free
	    [[bookmarkNodeList removeObjectAt:i] free];
	}
    }
    return self;
}

- (BOOL)isParagraphPunct:(char)ch
{
    if ([self isSentencePunct:ch] || ch == ')' || ch == ':')
        return YES;
    else
        return NO;
}

- (BOOL)isSentencePunct:(char)ch
{
    if (ch == '!' || ch == '.' || ch == '?')
        return YES;
    else
        return NO;
}

- (BOOL)isPhrasePunct:(char)ch
{
    if ([self isSentencePunct:ch] || ch == ':' || ch == ';' || ch == ',')
        return YES;
    else
        return NO;
}


/* GENERAL UTILITY METHODS **************************************************************************/


/* Read characters until a newline has been read, and return YES.  If EOS (end of stream) has 
 * occurred, return NO.
 */
- (BOOL)getNewLine:(NXStream *)stream
{
    int ch;

    while ((ch = NXGetc(stream)) != NEWLINE) {
        if (NXAtEOS(stream))
            return NO;
    }
    return YES;
}

/* We begin parsing from the CURRENT position in the stream buffer.  If the current line (or the 
 * remainder, if we are not at the left margin) is a blank line, YES is returned; if not a blank line,
 * NO is returned.  If EOS (end of stream) was encountered, we return NO.  It us up to the caller to 
 * check if EOS was encountered through the function call NXAtEOS().  Note that as soon as a printable
 * character is encountered, we return the last char to the stream, and return NO.
 */
- (BOOL)blankLine:(NXStream *)stream
{
    int ch;
    
    for ( ; ; ) {
        ch = NXGetc(stream);
        if (NXAtEOS(stream))
            return NO;
        if (ch == NEWLINE)
            return YES;
        else if (NXIsGraph(ch)) {   // not a blank line; return last char to stream
            NXUngetc(stream);
            return NO;
        }
    }
}

/* Filters all control characters in the stream. An array is returned with all control characters
 * stripped. Note that we classify "control" characters as characters OTHER THAN printable characters,
 * characters such as space, tab, carriage return, newline, vertical tab, or formfeed. In the event 
 * that a backspace character is encountered, we filter the previous or next character as well iff it
 * is an underscore character. We assume that a printed character was intended to be underlined. Also,
 * if the character is a printable non-ascii character (above 0x7F) we replace it with a space. Note,
 * it is the responsibility of the caller to free the array, once it has been used. This is extremely
 * important since large files may take up undue amounts of memory.
 */
- (char *)filterControlCharacters:(NXStream *)stream
{
    char *buffer;
    long length;
    int i, j, ch;

    NXSeek(stream, -1, NX_FROMEND);
    length = NXTell(stream) + 1;
    buffer = malloc(sizeof(char) * length + 1);   // one character larger for NULL termination
    NXSeek(stream, 0, NX_FROMSTART);
    for (i = j = 0; i < length; i++) {
	ch = NXGetc(stream);
	if ((NXIsPrint(ch) && NXIsAscii(ch)) || NXIsSpace(ch)) {   // not a "control" character
	    buffer[j++] = ch;

	} else {   // is a control character or printable non-ascii

	    if (ch == BACKSPACE) {   // control character is backspace

		// filter underscore char, since probably part of backspace
		if (buffer[j-1] == UNDERSCORE) {   // check last character
		    j--;
		} else if ((ch = NXGetc(stream)) == UNDERSCORE) {   // check next character
		    i++;   // synchronize counter with stream
		} else {   // unread next char since not an underscore character
		    NXUngetc(stream);
		}

	    } else {   // must be a printable non-ascii
		buffer[j++] = SPACE;
	    }
	}
    }
    buffer[j] = '\0';   // NULL terminate
    return buffer;
}

/* Reformats the text stream so lines longer than lineLength are wrapped to the next line. This is
 * particularly useful for reformatting text documents that conform to the formatting scheme that
 * states paragraphs are terminated with carriage returns and sentences run on. Returns a character
 * array containing the new stream. Note, if lineLength is zero then NULL is returend.
 */
- (char *)wrapLines:(NXStream *)stream longerThan:(unsigned int)lineLength
{
    char *buffer;
    long streamLen, bufferLen, bufferIndex = 0, currLineLen = 0, insertEOLPos = 0, lastEOLPos = 0;
    int i, maxlen, ch;

    if (lineLength == 0)
	return NULL;

    NXGetMemoryBuffer(stream, &buffer, &streamLen, &maxlen);   // maxlen and buffer args not used
    bufferLen = streamLen + REALLOC_BUFFER_INC;
    buffer = malloc(sizeof(char) * bufferLen);   // initial buffer increment for required EOL's

    for (i = 0; i < streamLen; i++) {   // go through entire stream character by character
	ch = NXGetc(stream);
	currLineLen++;

	if (bufferIndex >= bufferLen - 1)   // time to realloc local buffer
	    buffer = realloc(buffer, bufferLen += REALLOC_BUFFER_INC);

	// copy the character into the local buffer and increment current buffer index
	buffer[bufferIndex++] = ch;

	// If the current line length is greater than lineLength, wrap it by placing an EOL at the 
	// most recent location of a space character and then begin the wrap detection algorithm from 
	// the next character (subsequent to where the EOL was inserted). Every time we encounter a 
	// space character we set the insertEOLPos variable to its location. If the character 
	// encountered is a newline, then reinitialize the wrap related variables and continue.

	if (currLineLen > lineLength && insertEOLPos != lastEOLPos) {
	    // wrap if current line is greater than lineLength and at least one full word encountered
	    buffer[insertEOLPos] = NEWLINE;
	    i = insertEOLPos;   // will get auto-incremented at bottom of loop
	    currLineLen = 0;
	    NXSeek(stream, insertEOLPos + 1, NX_FROMSTART);   // reposition stream to wrapped loc.
	    bufferIndex = insertEOLPos + 1;   // reposition copy index
	    lastEOLPos = insertEOLPos;   // update last EOL insertion position

	} else if (ch == NEWLINE) {   // reinitialize line wrap variables
	    currLineLen = 0;
	    insertEOLPos = lastEOLPos = i;

	} else if (NXIsSpace(ch)) {   // may want to insert an EOL here so remember location
	    lastEOLPos = insertEOLPos;
	    insertEOLPos = i;
	}
    }

    buffer[bufferIndex] = '\0';   // NULL terminate
    return buffer;
}


/* DEBUG METHODS ************************************************************************************/


- printStream:(NXStream *)stream inNodeList:nodeList
{
    char *buffer;
    int i, count;
    id node;

    count = [nodeList count];
    for (i = 0; i < count; i++) {
	node = [nodeList objectAt:i];
	printf("\nStart: %d, End: %d\n", [node start], [node end]);
	buffer = malloc(sizeof(char) * ([node length] + 1));
	NXSeek(stream, [node start], NX_FROMSTART);
	buffer[NXRead(stream, buffer, [node length])] = '\0';
	printf("%s\n", buffer);
	free(buffer);
    }
    return self;
}

@end

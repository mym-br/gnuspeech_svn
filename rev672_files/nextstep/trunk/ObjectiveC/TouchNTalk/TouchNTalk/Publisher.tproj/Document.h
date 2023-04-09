/*
 *    Filename:	Document.h 
 *    Created :	Thu May 13 11:39:35 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Sat Sep 10 16:13:50 1994"
 *
 * $Id: Document.h,v 1.17 1994/09/11 17:43:12 dale Exp $
 *
 * $Log: Document.h,v $
 * Revision 1.17  1994/09/11  17:43:12  dale
 * Coalesced Publisher and Document together since all Publisher operations were on documents. This is
 * better OO design.
 *
 * Revision 1.16  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.15  1993/07/23  07:32:18  dale
 * *** empty log message ***
 *
 * Revision 1.14  1993/07/14  22:11:48  dale
 * *** empty log message ***
 *
 * Revision 1.13  1993/07/06  00:34:26  dale
 * Incorporated SpeakTactileText object.
 *
 * Revision 1.12  1993/07/04  17:57:23  dale
 * *** empty log message ***
 *
 * Revision 1.11  1993/07/01  20:18:47  dale
 * *** empty log message ***
 *
 * Revision 1.10  1993/06/25  23:38:25  dale
 * Added bookmarkNumber for dealing with default bookmark names.
 *
 * Revision 1.9  1993/06/24  07:40:17  dale
 * *** empty log message ***
 *
 * Revision 1.8  1993/06/22  19:50:38  dale
 * Renamed some instance variables.
 *
 * Revision 1.7  1993/06/05  07:37:08  dale
 * *** empty log message ***
 *
 * Revision 1.6  1993/06/04  20:57:48  dale
 * *** empty log message ***
 *
 * Revision 1.5  1993/06/04  07:18:00  dale
 * *** empty log message ***
 *
 * Revision 1.4  1993/06/03  00:37:58  dale
 * *** empty log message ***
 *
 * Revision 1.3  1993/06/01  08:03:24  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/05/30  08:24:27  dale
 * *** empty log message ***
 *
 * Revision 1.1  1993/05/20  06:03:35  dale
 * Initial revision
 *
 */

#import <appkit/appkit.h>

@interface Document:Object
{
    id text;              // instance of TactileText object (contains all document text)
    id activePage;        // instance of Page object (contains text of active page)
    int bookmarkNumber;   // number of next default bookmark to be added

    // mark holds previous position of system cursor; all values are one-based
    int markLine;
    int markCol;
    int markPage;

    // system cursor holds current working location; all values are one-based
    int systemCursorLine;
    int systemCursorCol;
    int systemCursorPage;

    BOOL edited;       // will be used when editing facility in place

    char pathname[MAXPATHLEN];
    char filename[256];

    id lineWrapStore;   // holds EOL document offsets for wrapped lines

    // node lists
    id titleNodeList;
    id paragraphNodeList;
    id sentenceNodeList;
    id phraseNodeList;
    id parenNodeList;
    id doubleQuoteNodeList;
    id singleQuoteNodeList;
    id lineColumnNodeList;
    id bookmarkNodeList;         // contains ordered bookmark nodes (see BookmarkNode class)
    id pageNodeList;             // contains page nodes; also used with the page locator holophrast
}

/* INITIALIZING AND FREEING */
- init;
- free;

/* ARCHIVING METHODS */
- awake;
- read:(NXTypedStream *)typedStream;
- write:(NXTypedStream *)typedStream;

/* BOOKMARK MANAGEMENT METHODS */
- addBookmarkAtPage:(int)pageNumber withName:(const char *)name;
- removeBookmarkAtPage:(int)pageNumber;
- bookmarkAtPage:(int)pageNumber;
- (const char *)defaultBookmarkName;

/* SET METHODS */
- setPathname:(const char *)pathname;
- setFilename:(const char *)filename;
- setActivePage:(int)pageNumber;
- setRelativeActivePage:(int)pageOffset;

- setSystemCursorPage:(int)page line:(int)line col:(int)col;
- setSystemCursorPage:(int)page;
- setSystemCursorLine:(int)line;
- setSystemCursorCol:(int)col;

- setMarkPage:(int)page line:(int)line col:(int)col;
- setMarkPage:(int)page;
- setMarkLine:(int)line;
- setMarkCol:(int)col;

/* QUERY METHODS */
- (const char *)pathname;
- (const char *)filename;
- (BOOL)isEdited;
- activePage;
- (int)activePageNumber;
- (int)pages;
- (int)bookmarkNumber;
- text;

- (int)systemCursorLine;
- (int)systemCursorCol;
- (int)systemCursorPage;

- (int)markLine;
- (int)markCol;
- (int)markPage;

/* NODE LIST SET METHODS */
- setTitleNodeList:nodeList;
- setParagraphNodeList:nodeList;
- setSentenceNodeList:nodeList;
- setPhraseNodeList:nodeList;
- setParenNodeList:nodeList;
- setDoubleQuoteNodeList:nodeList;
- setSingleQuoteNodeList:nodeList;
- setLineColumnNodeList:nodeList;
- setBookmarkNodeList:nodeList;
- setPageNodeList:nodeList;

/* NODE LIST QUERY METHODS */
- titleNodeList;
- paragraphNodeList;
- sentenceNodeList;
- phraseNodeList;
- parenNodeList;
- doubleQuoteNodeList;
- singleQuoteNodeList;
- lineColumnNodeList;
- bookmarkNodeList;
- pageNodeList;

/* NODE SEARCH METHODS */
- nodesInNodeList:nodeList startingOnLine:(int)line;
- nodesInNodeList:nodeList startingInRange:(int)start :(int)end;
- nodeInNodeList:nodeList endingOnLine:(int)line;
- nodeInNodeList:nodeList endingInRange:(int)start :(int)end;
- bookmarkNodeForPage:(int)pageNumber;

/* FULL DOCUMENT PUBLISHING METHODS */
- publishEnglishText;
- publishEnglishTextWithLineLength:(unsigned int)maxLength;
- publishCSourceCode;
- publishCSourceCodeWithLineLength:(unsigned int)maxLength;

/* LINE WRAPPING AND CHARACTER FILTERING */
- wrapLines:(unsigned int)lineLength;
- unwrapLines;
- filterControlCharacters;

/* NODE CREATION METHODS */
- createNode:(int)start :(int)end forNodeList:nodeList;
- createPageNode:(int)start :(int)end forNodeList:nodeList;

/* PAGE AND BOOKMARK PUBLISHING METHODS */
- publishPages;
- publishBookmarks;

/* ENGLISH TEXT PUBLISHING METHODS */
- publishTitles;
- publishParagraphs;
- publishSentences;
- publishPhrases;
- publishParentheses;
- publishDoubleQuotes;
- publishSingleQuotes;
- publishLineColumns;

/* ENGLISH TEXT UTILITY METHODS */
- (BOOL)isParagraphPunct:(char)ch;
- (BOOL)isSentencePunct:(char)ch;
- (BOOL)isPhrasePunct:(char)ch;

/* GENERAL UTILITY METHODS */
- (BOOL)getNewLine:(NXStream *)stream;
- (BOOL)blankLine:(NXStream *)stream;

/* ANSI C SOURCE CODE PUBLISHING METHODS (example)
- publishComments;
- publishIncludes;
- publishDefines;
- publishFunctionDeclarations;
- publishBraces;
- publishVariableDeclarations;
- publishForStatements;
- publishWhileStatements;
- publishDoWhileStatements;
- publishIfStatements;
- publishSwitchStatements;
*/

/* DEBUG METHODS */
- printStream:(NXStream *)stream inNodeList:nodeList;

@end

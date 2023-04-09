/*
 *    Filename:	Publisher.h 
 *    Created :	Thu May 27 13:13:43 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Sun Jun  6 21:01:15 1993"
 *
 * $Id: Publisher.h,v 1.5 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: Publisher.h,v $
 * Revision 1.5  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.4  1993/06/07  08:11:40  dale
 * Initial attempt made at getting left holophrasts working throughout the system.
 *
 * Revision 1.3  1993/06/04  20:57:48  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/06/03  00:37:58  dale
 * *** empty log message ***
 *
 * Revision 1.1  1993/05/30  08:24:27  dale
 * Initial revision
 *
 */

#import <appkit/appkit.h>

@interface Publisher:Object
{
}

/* GENERAL METHODS */
- init;
- free;

/* FULL DOCUMENT PUBLISHING METHODS */
- publishEnglishTextDocument:aDoc;
- publishCSourceCodeDocument:aDoc;

/* GENERAL PUBLISHING METHODS */
- publishPages:(NXStream *)stream;
- publishBookmarks:aDoc;

/* ENGLISH TEXT PUBLISHING METHODS */
- publishTitles:(NXStream *)stream;
- publishParagraphs:(NXStream *)stream;
- publishSentences:(NXStream *)stream;
- publishPhrases:(NXStream *)stream;
- publishParentheses:(NXStream *)stream;
- publishDoubleQuotes:(NXStream *)stream;
- publishSingleQuotes:(NXStream *)stream;
- publishLineColumns:(NXStream *)stream;

/* ENGLISH TEXT NODE CREATION METHODS */
- createNode:(int)start :(int)end forNodeList:nodeList;
- createPageNode:(int)start :(int)end forNodeList:nodeList;


/* ENGLISH TEXT UTILITY METHODS */
- (BOOL)isParagraphPunct:(char)ch;
- (BOOL)isSentencePunct:(char)ch;
- (BOOL)isPhrasePunct:(char)ch;

/* GENERAL UTILITY METHODS */
- (BOOL)getNewLine:(NXStream *)stream;
- (BOOL)blankLine:(NXStream *)stream;
- (char *)filterControlCharacters:(NXStream *)stream;

/* ANSI C SOURCE CODE PUBLISHING METHODS (example)
- publishComments:(NXStream *)stream;
- publishIncludes:(NXStream *)stream;
- publishDefines:(NXStream *)stream;
- publishFunctionDeclarations:(NXStream *)stream;
- publishBraces:(NXStream *)stream;
- publishVariableDeclarations:(NXStream *)stream;
- publishForStatements:(NXStream *)stream;
- publishWhileStatements:(NXStream *)stream;
- publishDoWhileStatements:(NXStream *)stream;
- publishIfStatements:(NXStream *)stream;
- publishSwitchStatements:(NXStream *)stream;
*/

/* DEBUG METHODS */
- printStream:(NXStream *)stream inNodeList:nodeList;

@end

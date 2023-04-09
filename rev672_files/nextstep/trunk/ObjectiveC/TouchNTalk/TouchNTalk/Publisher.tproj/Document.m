/*
 *    Filename:	Document.m 
 *    Created :	Thu May 13 11:39:41 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Sun Sep 11 00:48:54 1994"
 *
 * $Id: Document.m,v 1.21 1994/09/11 17:43:12 dale Exp $
 *
 * $Log: Document.m,v $
 * Revision 1.21  1994/09/11  17:43:12  dale
 * Coalesced Publisher and Document together since all Publisher operations were on documents. This is
 * better OO design.
 *
 * Revision 1.20  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.19  1994/05/28  21:24:37  dale
 * Added code for handling relative page turns.
 *
 * Revision 1.18  1993/07/28  21:23:52  dale
 * Fixed index access out of array bounds for bookmark insertions.
 *
 * Revision 1.17  1993/07/23  07:32:18  dale
 * *** empty log message ***
 *
 * Revision 1.16  1993/07/14  22:11:48  dale
 * *** empty log message ***
 *
 * Revision 1.15  1993/07/06  00:34:26  dale
 * Incorporated SpeakTactileText object.
 *
 * Revision 1.14  1993/07/04  17:57:23  dale
 * *** empty log message ***
 *
 * Revision 1.13  1993/07/01  20:18:47  dale
 * *** empty log message ***
 *
 * Revision 1.12  1993/06/25  23:38:25  dale
 * Added bookmarkNumber for dealing with default bookmark names.
 *
 * Revision 1.11  1993/06/24  07:40:17  dale
 * *** empty log message ***
 *
 * Revision 1.10  1993/06/22  19:50:38  dale
 * Renamed some instance variables.
 *
 * Revision 1.9  1993/06/18  08:45:44  dale
 * *** empty log message ***
 *
 * Revision 1.8  1993/06/07  08:11:40  dale
 * Initial attempt made at getting left holophrasts working throughout the system.
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

#import "TNTDefinitions.h"
#import "Node.h"
#import "PageNode.h"
#import "BookmarkNode.h"
#import "Page.h"
#import "Document.h"

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

/* Default bookmark names. */
#define DEFAULT_BOOKMARK_NAME "Bookmark"


/* STATIC CLASS VARIABLES */


static NXSize maxSize = {1.0E38, 1.0E38};   // maximum size of the text object

/* Here we set the frameRect which will be used for the minimum page size to be 4.0 less in width and
 * height since this stops the text object from shifting up and down a couple of pixels when selection
 * occurs. This is mostly for aesthetics.
 */
static NXRect frameRect = {0.0, 0.0, TNT_TACTILE_DISPLAY_WIDTH - 4.0, 
                                     TNT_TACTILE_DISPLAY_HEIGHT - 4.0};

@implementation Document


/* INITIALIZING AND FREEING *************************************************************************/


/* Initializes a Document instance with the frameRect of the view in which the individual document 
 * pages will reside. This is required in order that the size of all pages are correct. Returns self.
 */
- init
{
    [super init];
    [Text setDefaultFont:[Font newFont:TNT_DEFAULT_FONT size:TNT_DEFAULT_FONT_SIZE]];
    text = [[TactileText allocFromZone:[self zone]] initFrame:&frameRect];

    // initialize (empty) active page object
    activePage = [[Page allocFromZone:[self zone]] initFrame:&frameRect];
    [activePage setMasterDocument:self];
    [activePage setBackgroundGray:NX_WHITE];
    [activePage setOpaque:YES];
    [activePage setNoWrap];
    [activePage setHorizResizable:YES];
    [activePage setVertResizable:YES];
    [activePage setEditable:NO];
    [activePage setMinSize:&(frameRect.size)];
    [activePage setMaxSize:&maxSize];

    // pathname and filename initialization
    pathname[0] = filename[0] = (char)0;

    // system cursor initialization
    systemCursorLine = 1;
    systemCursorCol  = 1;
    systemCursorPage = 1;

    // mark initialization
    markLine = 1;
    markCol  = 1;
    markPage = 1;

    edited = NO;

    // init node lists
    titleNodeList = paragraphNodeList = sentenceNodeList = phraseNodeList = nil;
    parenNodeList = doubleQuoteNodeList = singleQuoteNodeList = lineColumnNodeList = nil;
    pageNodeList = nil;

    // create empty bookmark node list
    bookmarkNodeList = [[List allocFromZone:[self zone]] init];
    bookmarkNumber = 1;

    // init line wrapping store
    lineWrapStore = nil;

    return self;
}

- free
{
    [text free];
    [activePage free];
    [lineWrapStore free];

    // free node lists and node objects they contain
    [[titleNodeList freeObjects] free];
    [[paragraphNodeList freeObjects] free];
    [[sentenceNodeList freeObjects] free];
    [[phraseNodeList freeObjects] free];
    [[parenNodeList freeObjects] free];
    [[doubleQuoteNodeList freeObjects] free];
    [[singleQuoteNodeList freeObjects] free];
    [[lineColumnNodeList freeObjects] free];
    [[bookmarkNodeList freeObjects] free];
    [[pageNodeList freeObjects] free];
    return [super free];
}


/* ARCHIVING METHODS */


/* Perform class specific initialization after object has been unarchived. Returns self. */
- awake
{
    [super awake];

    // initialize active page object
    activePage = [[Page allocFromZone:[self zone]] initFrame:&frameRect];
    [activePage setMasterDocument:self];
    [activePage setFont:[Font newFont:TNT_DEFAULT_FONT size:TNT_DEFAULT_FONT_SIZE]];
    [activePage setBackgroundGray:NX_WHITE];
    [activePage setOpaque:YES];
    [activePage setNoWrap];
    [activePage setHorizResizable:YES];
    [activePage setVertResizable:YES];
    [activePage setEditable:NO];
    [activePage setMinSize:&(frameRect.size)];

    // set active page to first page of document
    [self setActivePage:1];

    edited = NO;
    
    return self;
}

- read:(NXTypedStream *)typedStream
{
    [super read:typedStream];

    /* class-specific unarchiving code */

    text                = NXReadObject(typedStream);
    lineWrapStore       = NXReadObject(typedStream);
    titleNodeList       = NXReadObject(typedStream);
    paragraphNodeList   = NXReadObject(typedStream);
    sentenceNodeList    = NXReadObject(typedStream);
    phraseNodeList      = NXReadObject(typedStream);
    parenNodeList       = NXReadObject(typedStream);
    doubleQuoteNodeList = NXReadObject(typedStream);
    singleQuoteNodeList = NXReadObject(typedStream);
    lineColumnNodeList  = NXReadObject(typedStream);
    bookmarkNodeList    = NXReadObject(typedStream);
    pageNodeList        = NXReadObject(typedStream);

    // The system cursor and mark are archived so that in future, when an editing facility is in
    // place, users can save their current working locations within the document, and locate them
    // again with ease.

    NXReadTypes(typedStream, "iiiiiii", &systemCursorLine, &systemCursorCol, &systemCursorPage,
		                        &markLine, &markCol, &markPage, &bookmarkNumber);
    return self;
}

- write:(NXTypedStream *)typedStream
{
    [super write:typedStream];

    /* class-specific archiving code */

    NXWriteObject(typedStream, text);
    NXWriteObject(typedStream, lineWrapStore);
    NXWriteObject(typedStream, titleNodeList);
    NXWriteObject(typedStream, paragraphNodeList);
    NXWriteObject(typedStream, sentenceNodeList);
    NXWriteObject(typedStream, phraseNodeList);
    NXWriteObject(typedStream, parenNodeList);
    NXWriteObject(typedStream, doubleQuoteNodeList);
    NXWriteObject(typedStream, singleQuoteNodeList);
    NXWriteObject(typedStream, lineColumnNodeList);
    NXWriteObject(typedStream, bookmarkNodeList);
    NXWriteObject(typedStream, pageNodeList);

    // The system cursor and mark are archived so that in future, when an editing facility is in
    // place, users can save their current working locations within the document, and locate them
    // again with ease.

    NXWriteTypes(typedStream, "iiiiiii", &systemCursorLine, &systemCursorCol, &systemCursorPage,
		                         &markLine, &markCol, &markPage, &bookmarkNumber);
    return self;
}


/* BOOKMARK MANAGEMENT METHODS */


/* Adds a bookmark node with the specified pageNumber and name. If a bookmark with the specified page
 * number already exists, we destroy the old bookmark. Bookmarks with identical names are allowed, 
 * provided they do not share the same page number. Note that bookmarks are not kept in any particular
 * order. The bookmarkNodeList is really only used to re-establish the bookmark locations after 
 * re-publishes. If a NULL points is passed as the bookmark name, we use the default name 
 * DEFAULT_BOOKMARK_NAME with a number following it. Returns self.
 */
- addBookmarkAtPage:(int)pageNumber withName:(const char *)name
{
    id bookmarkNode = [[BookmarkNode allocFromZone:[self zone]] init];
    id oldBookmark, pageNode;
    char bookmarkName[TNT_MAX_BOOKMARK_LEN];

    // Set to default bookmark name if name is a NULL pointer or name matches next default bookmark, 
    // and update bookmarkNumber if we did use the default bookmark name with the bookmarkNumber 
    // appended to it.

    sprintf(bookmarkName, "%s %d", DEFAULT_BOOKMARK_NAME, bookmarkNumber);
    if (!name || !strcmp(name, bookmarkName)) {   // use default bookmark name
	bookmarkNumber++;
    } else {
	strncpy(bookmarkName, name, TNT_MAX_BOOKMARK_LEN);
	bookmarkName[TNT_MAX_BOOKMARK_LEN - 1] = (char)0;
    }

    [[(BookmarkNode *)bookmarkNode setName:bookmarkName] setPageNumber:pageNumber];
    [bookmarkNodeList addObject:bookmarkNode];

    pageNode = [pageNodeList objectAt:pageNumber - 1];
    oldBookmark = [pageNode bookmark];

    // set the bookmark in the appropriate pageNode
    [pageNode setBookmark:bookmarkNode];

    // check if bookmark for pageNumber already existed
    if (oldBookmark && ([oldBookmark pageNumber] == pageNumber)) {   // bookmark already existed
	[[bookmarkNodeList removeObject:oldBookmark] free];
    }
    return self;
}

/* Removes the bookmark at pageNumber. We set the bookmark variable for the pageNode at pageNumber to
 * nil, and then remove the bookmark node from the bookmark node list and free it. Returns self.
 */
- removeBookmarkAtPage:(int)pageNumber
{
    id bookmarkNode, pageNode;

    pageNode = [pageNodeList objectAt:pageNumber - 1];
    bookmarkNode = [pageNode bookmark];
    [pageNode setBookmark:nil];
    [[bookmarkNodeList removeObject:bookmarkNode] free];
    return self;
}

/* Returns the bookmark node at pageNumber. If no bookmark exists, returns nil. */
- bookmarkAtPage:(int)pageNumber
{
    return [[pageNodeList objectAt:pageNumber - 1] bookmark];
}

/* Returns the default bookmark name that will be used on the next default bookmark addition 
 * request. 
 */
- (const char *)defaultBookmarkName
{
    static char bookmarkName[TNT_MAX_BOOKMARK_LEN];

    sprintf(bookmarkName, "%s %d", DEFAULT_BOOKMARK_NAME, bookmarkNumber);
    return bookmarkName;
}


/* SET METHODS */


/* Sets the pathname instance variable. Returns self. */
- setPathname:(const char *)aPathname
{
    if (aPathname) {
	strcpy(pathname, aPathname);
    } else {
	pathname[0] = (char)0;
    }
    return self;
}

/* Sets the filename instance variable. Returns self. */
- setFilename:(const char *)aFilename
{
    if (aFilename) {
	strcpy(filename, aFilename);
    } else {
	filename[0] = (char)0;
    }
    return self;
}

/* Set the active page to be the page numbered pageNum. If no such page exists, returns nil, otherwise
 * otherwise displays the new page, and returns self. Note that pageNumber is taken to be one-based. 
 * We finally send the -resetPosition, and -calcLinesColumns to the page when all else is completed.
 */
- setActivePage:(int)pageNumber
{
    NXRect frame;
    char *buffer;
    int length;
    id pageNode;

    if (!(pageNode = [pageNodeList objectAt:pageNumber - 1])) {   // page does not exist, return nil
	return nil;
    }

    // set page node and page number
    [activePage setPageNode:pageNode];
    [activePage setPageNumber:pageNumber];

    // set to requested page; note, we replace the last newline with a NULL character
    length = [pageNode length];
    buffer = malloc(sizeof(char) * length);
    [text getSubstring:buffer start:[pageNode start] length:length];
    buffer[length - 1] = '\0';
    [[activePage setText:buffer] sizeToFit];
    free(buffer);

    // set max page size now that NULL has replaced newline
    [activePage getFrame:&frame];
    [activePage setMaxSize:&(frame.size)];

    // append newline so last visible line is entirely selectable (aesthetics)
    length = [activePage textLength];
    [activePage setSel:length :length];   // empty selection of last character + 1
    [activePage replaceSel:"\n"];

    // resets the page's position within a scroll view; calculates the number of lines and columns
    [[activePage resetPosition] calcLinesColumns];
    return self;
}

/* Set the relative active page based on an offset from the current active page. If the pageOffset
 * results in a page that does not exist, we go to the first/last page of the document (depending on
 * the direction of page turns), and return nil. Otherwise if their are enough pages in the document,
 * we turn to the appropriate page and return self.
 */
- setRelativeActivePage:(int)pageOffset
{
    int pageNumber = [activePage pageNumber];
    int numPages = [self pages];

    if (pageNumber + pageOffset < 1) {
	[self setActivePage:1];
	return nil;
    } else if (pageNumber + pageOffset > numPages) {
	[self setActivePage:numPages];
	return nil;
    } else {
	[self setActivePage:pageNumber + pageOffset];
    }
    return self;
}

/* Returns the number of pages in the document. If there are no page nodes, then we just return 1,
 * since the user is working on a new document, and every new document has at least 1 page even though
 * it may have not yet been published.
 */
- (int)pages
{
    int count = [pageNodeList count];

    return (count > 0 ? count : 1);
}

- setMarkPage:(int)page line:(int)line col:(int)col
{
    markPage = page;
    markLine = line;
    markCol = col;
    return self;
}

- setMarkPage:(int)page
{
    markPage = page;
    return self;
}

- setMarkLine:(int)line
{
    markLine = line;
    return self;
}

- setMarkCol:(int)col
{
    markCol = col;
    return self;
}

- setSystemCursorPage:(int)page line:(int)line col:(int)col
{
    systemCursorPage = page;
    systemCursorLine = line;
    systemCursorCol = col;
    return self;
}

- setSystemCursorPage:(int)page;
{
    systemCursorPage = page;
    return self;
}

- setSystemCursorLine:(int)line
{
    systemCursorLine = line;
    return self;
}

- setSystemCursorCol:(int)col
{
    systemCursorCol = col;
    return self;
}


/* QUERY METHODS */


/* Returns the pathname instance variable. If the pathname is a NULL string, we return NULL. */
- (const char *)pathname
{
    if (pathname[0] == (char)0) {
	return NULL;
    }
    return pathname;
}

/* Returns the filename instance variable. If the filename is a NULL string, we return NULL. */
- (const char *)filename
{
    if (filename[0] == (char)0) {
	return NULL;
    }
    return filename;
}

- (BOOL)isEdited
{
    return NO;
}

- activePage
{
    return activePage;
}

- (int)activePageNumber
{
    return [activePage pageNumber];
}

- (int)bookmarkNumber
{
    return bookmarkNumber;
}

- text
{
    return text;
}

- (int)markLine
{
    return markLine;
}

- (int)markCol
{
    return markCol;
}

- (int)markPage
{
    return markPage;
}

- (int)systemCursorLine
{
    return systemCursorLine;
}

- (int)systemCursorCol
{
    return systemCursorCol;
}

- (int)systemCursorPage
{
    return systemCursorPage;
}


/* NODE LIST SET METHODS */


/* These node list set methods all free the existing node lists and the node objects they contained 
 * before setting the node lists to their new values. All return self.
 */

- setTitleNodeList:nodeList
{
    [[titleNodeList freeObjects] free];
    titleNodeList = nodeList;
    return self;
}

- setParagraphNodeList:nodeList
{
    [[paragraphNodeList freeObjects] free];
    paragraphNodeList = nodeList;
    return self;
}

- setSentenceNodeList:nodeList
{
    [[sentenceNodeList freeObjects] free];
    sentenceNodeList = nodeList;
    return self;
}

- setPhraseNodeList:nodeList
{
    [[phraseNodeList freeObjects] free];
    phraseNodeList = nodeList;
    return self;
}

- setParenNodeList:nodeList
{
    [[parenNodeList freeObjects] free];
    parenNodeList = nodeList;
    return self;
}

- setDoubleQuoteNodeList:nodeList
{
    [[doubleQuoteNodeList freeObjects] free];
    doubleQuoteNodeList = nodeList;
    return self;
}

- setSingleQuoteNodeList:nodeList
{
    [[singleQuoteNodeList freeObjects] free];
    singleQuoteNodeList = nodeList;
    return self;
}

- setLineColumnNodeList:nodeList
{
    [[lineColumnNodeList freeObjects] free];
    lineColumnNodeList = nodeList;
    return self;
}

- setBookmarkNodeList:nodeList
{
    [[bookmarkNodeList freeObjects] free];
    bookmarkNodeList = nodeList;
    return self;
}

- setPageNodeList:nodeList
{
    [[pageNodeList freeObjects] free];
    pageNodeList = nodeList;
    return self;
}


/* NODE LIST QUERY METHODS */


- titleNodeList
{
    return titleNodeList;
}

- paragraphNodeList
{
    return paragraphNodeList;
}

- sentenceNodeList
{
    return sentenceNodeList;
}

- phraseNodeList
{
    return phraseNodeList;
}

- parenNodeList
{
    return parenNodeList;
}

- doubleQuoteNodeList
{
    return doubleQuoteNodeList;
}

- singleQuoteNodeList
{
    return singleQuoteNodeList;
}

- lineColumnNodeList
{
    return lineColumnNodeList;
}

- bookmarkNodeList
{
    return bookmarkNodeList;
}

- pageNodeList
{
    return pageNodeList;
}


/* NODE SEARCH METHODS */

/* Line is the actual line within the active page object (one-based). This method utilizes 
 * -nodesInNodeList:startingInRange: to obtain the required list of nodes, and therefore has the same
 * return values. See -nodesInNodeList:startingInRange: for more details. We obtain the start and end
 * values for the line supplied, which are to be passed to -nodesInNodeList:startingInRange:.
 */
- nodesInNodeList:nodeList startingOnLine:(int)line
{
    int start, end, pageStart;

    // convert line number to start and end range values
    start = [activePage positionFromLine:line];
    end = start + ([activePage positionFromLine:line + 1] - start) - 1;
    pageStart = [[activePage pageNode] start];
    return [self nodesInNodeList:nodeList startingInRange:pageStart+start :pageStart+end];
}

/* Line is the actual line within the active page object (one-based). This method utilizes 
 * -nodesInNodeList:endingInRange: to obtain the required list of nodes, and therefore has the same
 * return values. See -nodesInNodeList:endingInRange: for more details. We obtain the start and end
 * values for the line supplied, which are to be passed to -nodesInNodeList:endingInRange:.
 */
- nodeInNodeList:nodeList endingOnLine:(int)line
{
    int start, end, pageStart;

    // convert line number to start and end range values
    start = [activePage positionFromLine:line];
    end = start + ([activePage positionFromLine:line + 1] - start) - 1;
    pageStart = [[activePage pageNode] start];
    return [self nodeInNodeList:nodeList endingInRange:pageStart+start :pageStart+end];
}


/* Search the nodeList object for all nodes STARTING in the range indicated by the arguments start and
 * end. Start and end are numerical quantities that indicate the offsets from the beginning of the
 * active page (zero-based). The nodes that are found to START in this range are returned within a 
 * list object. If zero nodes were found within the range, we return nil. Note, it is the 
 * responsibility of the caller to free the list object returned, although the caller must NOT free 
 * the node objects that are contained within the returned list object.
 */
- nodesInNodeList:nodeList startingInRange:(int)start :(int)end
{
    int i, low, mid, high;   // binary search variables
    int nodeCount;           // keeps track of how many nodes are in start-end range
    id node;                 // holds current node
    id startNodeList;        // List of nodes starting in start-end range

    low = 0;
    high = [nodeList count] - 1;

    if (high < 0) {   // the nodeList is empty
	return nil;
    }

    // perform binary search for *a* node that starts in start-end range
    while (low < high) {
	mid = (low + high +1) / 2;
	node = [nodeList objectAt:mid];
	if ([node start] > end) {   // throw out upper half of sublist
	    high = mid - 1;
	} else {   // throw out lower half of sublist
	    low = mid;
	}
    }
    node = [nodeList objectAt:low];   // low == high at this point, take one

    // If we have *a* node starting in the start-end range, find the first and last node within this 
    // range by searching backwards, then forwards for the extents. We then insert these nodes into a
    // list object (startNodeList) and return it.

    if ([node start] >= start && [node start] <= end) {   // we have *a* node
	nodeCount = 0;
	while (node && [node start] >= start) {
	    low--;
	    nodeCount++;
	    node = [nodeList objectAt:low];
	}
	low++;   // add one to get the start of valid nodes

	nodeCount--;   // will get a free inc, so dec first
	node = [nodeList objectAt:high];   // reset to original node (node obtained in binary search)
	while (node && [node start] <= end) {
	    high++;
	    nodeCount++;
	    node = [nodeList objectAt:high];
	}

	// now add all the nodes to startNodeList in order
	startNodeList = [[List allocFromZone:[self zone]] init];
	for (i = 0; i < nodeCount; i++) {
	    [startNodeList addObject:[nodeList objectAt:low + i]];
	}
	return startNodeList;
    }

    // we don't have a node starting in the start-end range
    return nil;
}

/* Search the nodeList object for a node ENDING in the range indicated by the arguments start and end.
 * Start and end are numerical quantities that indicate the offsets from the beginning of the active
 * page (zero-based). The node that is found to END in this range is returned. If a node is not found
 * within the range, we return nil. Note, the caller must NOT free the node object returned.
 */
- nodeInNodeList:nodeList endingInRange:(int)start :(int)end
{
    int low, mid, high;   // binary search variables
    id node;              // holds current node

    low = 0;
    high = [nodeList count] - 1;

    if (high < 0) {   // the nodeList is empty
	return nil;
    }

    // perform binary search for *a* node that starts in start-end range
    while (low < high) {
	mid = (low + high +1) / 2;
	node = [nodeList objectAt:mid];
	if ([node end] > end) {   // throw out upper half of sublist
	    high = mid - 1;
	} else {   // throw out lower half of sublist
	    low = mid;
	}
    }
    node = [nodeList objectAt:low];   // low == high at this point, take one
    if ([node end] >= start && [node end] <= end) {   // node is in start-end range
	return node;
    }

    // we don't have a node ending in the start-end range
    return nil;
}

/* Search the bookmark node list object for the first bookmark which belongs to the page numbered
 * pageNumber, and return it. If no bookmark node is found, returns nil. Because there will typically
 * only exist a handful of bookmarks for any given document, we incorporate a linear search rather 
 * than a binary search. A linear search is more efficient in this case. Binary searches should only 
 * be used when there are a reasonably large number of elements.
 */
- bookmarkNodeForPage:(int)pageNumber
{
    unsigned int i, count;
    id node;

    count = [bookmarkNodeList count];
    for (i = 0; i < count; i++) {
	node = [bookmarkNodeList objectAt:i];
	if ([node pageNumber] == pageNumber) {
	    return node;
	}
    }
    return nil;
}


/* FULL DOCUMENT PUBLISHING METHODS *****************************************************************/


- publishEnglishText;
{
    return [self publishEnglishTextWithLineLength:0];
}

/* Publishes all nodes in the english text document. These nodes include titles, paragraphs, 
 * sentences, phrases, parenthetical expressions, double quote expressions, single quote expresssions,
 * line/column (tabular data), and pages. We append a single newline character in the event the last
 * character is not a newline. Note, requesting the stream from the Text object returns a READ ONLY
 * stream as documented under the -stream method of the Text class. Also note that textLength is
 * one greater then the ACTUAL number of characters in the Text object. Also, specifying a maxLength
 * of zero indicates that no wrapping should be performed. Returns self.
 */
- publishEnglishTextWithLineLength:(unsigned int)maxLength
{
    int textLength = [text textLength];
    NXStream *stream;

    if (textLength == 0)
	return self;

    // filter control characters from stream and wrap lines to maxLength
    [[self filterControlCharacters] wrapLines:maxLength];

    stream = [text stream];   // get the text stream
    NXSeek(stream, -1, NX_FROMEND);
    if (NXGetc(stream) != '\n') {   // append single newline character to end of document
        [text setSel:textLength :textLength];   // empty selection of last character + 1
        [text replaceSel:"\n"];
    }

    // generate node lists for document (except bookmarks)
    [self publishTitles];
    [self publishParagraphs];
    [self publishSentences];
    [self publishPhrases];
    [self publishParentheses];
    [self publishDoubleQuotes];
    [self publishSingleQuotes];
    [self publishLineColumns];
    [self publishPages];

    // update bookmark within all page nodes (must be done after pages are published)
    [self publishBookmarks];

    return self;
}

/* Identical to publishCSourceCodeWithLineLength except line length is zero. This means no line 
 * wrapping is performed. Returns what publishCSourceCodeWithLineLength returns.
 */
- publishCSourceCode
{
    return [self publishCSourceCodeWithLineLength:0];
}

/* Not Implemented. */
- publishCSourceCodeWithLineLength:(unsigned int)maxLength
{
    return self;
}


/* LINE WRAPPING AND CHARACTER FILTERING ************************************************************/


/* Reformats the text stream so lines longer than lineLength are wrapped to the next line. This is
 * particularly useful for reformatting text documents that conform to the formatting scheme that
 * states paragraphs are terminated with carriage returns and sentences run on. Note, if lineLength is
 * zero then we immediately return. Note: we cannot use NXGetMemoryBuffer() with streams returned by
 * the text object, since such streams are not memory streams. Returns self.
 */
- wrapLines:(unsigned int)lineLength
{
    char *buffer;
    long streamLen = [text textLength];
    long bufferIndex = 0, currLineLen = 0, insertEOLPos = 0, lastEOLPos = 0;
    int i, ch;
    NXStream *stream = [text stream];

    if (lineLength == 0 || streamLen == 0)
	return self;

    if (lineWrapStore)
	[lineWrapStore free];

    lineWrapStore = [[Storage allocFromZone:[self zone]] initCount:0 
							 elementSize:sizeof(unsigned long)
							 description:"L"];

    buffer = malloc(sizeof(char) * streamLen + 1);
    for (i = 0; i < streamLen; i++) {   // go through entire stream character by character
	ch = NXGetc(stream);
	currLineLen++;

	// copy the character into the local buffer and increment current buffer index
	buffer[bufferIndex++] = ch;

	// If the current line length is greater than lineLength, wrap it by placing an EOL at the 
	// most recent location of a space character and then begin the wrap detection algorithm from 
	// the next character (subsequent to where the EOL was inserted). Every time we encounter a 
	// space character we set the insertEOLPos variable to its location. If the character 
	// encountered is a newline, then reinitialize the wrap related variables and continue. Also,
	// whenever we wrap a line by replacing the space with an EOL we add the location of the EOL
	// to the lineWrapStore so we can unwrap the stream later on.

	if (currLineLen > lineLength && insertEOLPos != lastEOLPos) {

	    // wrap if current line > lineLength and at least one full word encountered

	    buffer[insertEOLPos] = NEWLINE;
	    [lineWrapStore addElement:&insertEOLPos];   // store location of inserted EOL
	    i = insertEOLPos;   // will get auto-incremented at bottom of loop
	    currLineLen = 0;
	    NXSeek(stream, insertEOLPos + 1, NX_FROMSTART);   // reposition stream to wrapped location
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
    [text setText:buffer];
    free(buffer);
    return self;
}

/* Unwraps the text so that any insertions of EOL's are replaced with spaces. This effectively returns
 * the text to its original form. The lineWrapStore contains the offsets from the start of the stream
 * to where the EOL's were inserted. We make a copy of the stream buffer and replace the locations in
 * the buffer corresponding to EOL insertion points. Returns self.
 */
- unwrapLines
{
    long textLength = [text textLength];
    char *buffer;
    unsigned int i, count;

    if (!lineWrapStore || textLength == 0)
	return self;

    buffer = malloc(sizeof(char) * textLength + 1);
    count = [lineWrapStore count];

    [text seekToCharacterAt:0 relativeTo:NX_StreamStart];
    [text readCharacters:buffer count:textLength + 1];
    buffer[textLength] = '\0';   // NULL terminate (safety)

    for (i = 0; i < count; i++)
	buffer[*(long *)[lineWrapStore elementAt:i]] = SPACE;   // lineWrapStore holds offsets

    [text setText:buffer];
    free(buffer);
    return self;
}

/* Filters all control characters in the stream. An array is returned with all control characters
 * stripped. Note that we classify "control" characters as characters OTHER THAN printable characters,
 * characters such as space, tab, carriage return, newline, vertical tab, or formfeed. In the event 
 * that a backspace character is encountered, we filter the previous or next character as well iff it
 * is an underscore character. We assume that a printed character was intended to be underlined. Also,
 * if the character is a printable non-ascii character (above 0x7F) we replace it with a space.
 */
- filterControlCharacters
{
    char *buffer;
    long length;
    int i, j, ch;
    NXStream *stream = [text stream];

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
    [text setText:buffer];
    free(buffer);
    return self;
}


/* NODE CREATION METHODS ****************************************************************************/


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


/* ENGLISH TEXT PUBLISHING METHODS ******************************************************************/


/* Finds all titles in the text.  A title is defined as follows, begins with a blank line, followed
 * by a maximum of 1 line of text, where the first printable char must be an upper case char, or a 
 * digit, and ending w/ one blank line of text.  Also, the last printable char on the line must not 
 * be a form of punctuation.  The start state is set at 1, since the first line of text MAY not be
 * preceeded by a blank line (eg. if a title is on the first line of the document) in which case we 
 * fake it, by pretending it was preceeded by a blank line.  This has no effect if the first line is 
 * infact a blank line, it will just be eaten up as usual.
 */
- publishTitles
{
    int ch, start = 0, end = 0, state = 1;
    NXStream *stream = [text stream];

    if (titleNodeList)
	[[titleNodeList freeObjects] free];
    titleNodeList = [[List allocFromZone:[self zone]] init];

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
                return self;
            if (NXIsUpper(ch) || NXIsDigit(ch)) {   // 1st printable char must be either one
                start = NXTell(stream) - 1;
                state++;
            } else if (NXIsGraph(ch))   // failure, reset and start over
                state = -1;
            break;

          case 2:
            ch = NXGetc(stream);
            if (NXAtEOS(stream))
                return self;
            if (ch == NEWLINE) {
                end = NXTell(stream) - 2;   // don't include newline in selections
                state = 4;
            } else if (NXIsPunct(ch))   // punctuation MIGHT be last on line
                state++;
            break;

          case 3:
            ch = NXGetc(stream);
            if (NXAtEOS(stream))
                return self;
            if (ch == NEWLINE)   // failure, reset and start over; punctuation must not be last
                state = 0;
            else if (NXIsGraph(ch))   // second life; punctuation was not last
               state--;
            break;

          case 4:
            if ([self blankLine:stream]) {   // goal state; we have a title
		[self createNode:start :end forNodeList:titleNodeList];
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
            return self;
    }
    return self;
}

/* Find all paragraphs in the text.  A paragraph is defined as follows, may or may not begin with a 
 * blank line (special case if first item in text), followed by any number of lines of text, where the
 * first printable char on the first line of text must be an upper case letter.  The final line must
 * end with some form of punctuation.  Finally, the last line must be a blank line.  Note that it is 
 * okay if whitespace follows the punctuation on the last line.  The start state is set at 1.
 */
- publishParagraphs
{
    int ch, start = 0, end = 0, state = 1;
    NXStream *stream = [text stream];

    if (paragraphNodeList)
	[[paragraphNodeList freeObjects] free];
    paragraphNodeList = [[List allocFromZone:[self zone]] init];

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
                return self;
            if (NXIsUpper(ch)) {   // 1st printable char must be upper case
                start = NXTell(stream) - 1;
                state++;
            } else if (NXIsGraph(ch))   // failure, reset and start over
                state--;
            break;

          case 2:
            ch = NXGetc(stream);
            if (NXAtEOS(stream))
                return self;
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
                return self;
            if (ch == NEWLINE) {   // almost have a paragraph, only need a blank line now
                end = NXTell(stream) - 2;   // don't include newline in selections
                state++;
            } else if (![self isParagraphPunct:ch] && NXIsGraph(ch)) {
                state = 2;
            }
            break;

          case 5:
            if ([self blankLine:stream]) {   // goal state; we have a paragraph
		[self createNode:start :end forNodeList:paragraphNodeList];
                state = 1;   // blank line is also first blank line of next pass
            } else {   // still parsing same paragraph, or EOS
                state = 2;
            }
            break;

          default:
            break;
        }
        if (NXAtEOS(stream))   // all done if EOS; here we catch EOS that occurred previously
            return self;
    }
    return self;
}

/* Find all sentences in the text.  A sentence is defined as follows, may or may not be preceeded by
 * whitespace (special case if first item in text), followed by any number of lines of text, where the
 * first printable char on the first line must be an upper case letter.  The final line must end with
 * some form of punctuation as defined in the isSentencePunct: method.  There must not be blank lines
 * between lines of a sentence.  Also, following the punctuation, terminating the sentence, either a
 * newline char must follow, or 2 other whitespace characters.  This is the reason for states 5 and 6
 * being quite similar.
 */
- publishSentences
{
    int ch, start = 0, end = 0, state = 2;
    NXStream *stream = [text stream];

    if (sentenceNodeList)
	[[sentenceNodeList freeObjects] free];
    sentenceNodeList = [[List allocFromZone:[self zone]] init];

    NXSeek(stream, 0, NX_FROMSTART);
    for ( ; ; ) {
        switch (state) {
          case 0:
            ch = NXGetc(stream);
            if (NXAtEOS(stream))
                return self;
            if (ch == NEWLINE)   // single newline okay to begin sentence detection
                state = 2;
            else if (NXIsCntrl(ch) || ch == SPACE)   // need 2 whitespace chars (not newline here)
                state++;
            break;

          case 1:
            ch = NXGetc(stream);
            if (NXAtEOS(stream))
                return self;
            if (NXIsCntrl(ch) || ch == SPACE)   // whitespace, incl. newline; begin sentence search
                state++;
            else   // must have 2 consecutive whitespace chars
                state--;
            break;

          case 2:
            ch = NXGetc(stream);
            if (NXAtEOS(stream))
                return self;
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
                return self;
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
                return self;        
            if (ch == NEWLINE) {   // goal, sentence recognized
		[self createNode:start :end forNodeList:sentenceNodeList];            
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
                return self;        
            if (NXIsCntrl(ch) || ch == SPACE) {   // newline or second whitespace; goal
		[self createNode:start :end forNodeList:sentenceNodeList];
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
            return self;
    }
    return self;
}

/* Find all phrases in the text.  A phrase is defined as follows, begins with anything except a valid
 * phrase punctuation character, must be preceeded by a whitespace character, unless first element in
 * document, may consist of any number of lines, and must be followed by a valid phrase punctuation 
 * character, and then a whitespace character.  Blank lines may not occur within a phrase.
 */
- publishPhrases
{
    int ch, start = 0, end = 0, state = 1;
    NXStream *stream = [text stream];

    if (phraseNodeList)
	[[phraseNodeList freeObjects] free];
    phraseNodeList = [[List allocFromZone:[self zone]] init];

    NXSeek(stream, 0, NX_FROMSTART);
    for ( ; ; ) {
        ch = NXGetc(stream);
        if (NXAtEOS(stream))
            return self;
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
		[self createNode:start :end forNodeList:phraseNodeList];
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
    return self;
}

/* Find all parenthetical expressions in the text. We currently do not deal with nested expressions.
 * Therefore, if a nested parenthetical expression does occur, we just match the first close 
 * parenthesis with the last open parenthesis encountered.
 */
- publishParentheses
{
    int ch, start = 0, end = 0;
    BOOL haveLeftParen = NO;
    NXStream *stream = [text stream];

    if (parenNodeList)
	[[parenNodeList freeObjects] free];
    parenNodeList = [[List allocFromZone:[self zone]] init];

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
		[self createNode:start :end forNodeList:parenNodeList];
                haveLeftParen = NO;
            }
	    break;

	  default:
	    break;
	}
	ch = NXGetc(stream);
    }
    return self;
}

/* Find all double quoted expressions in the text. We currently do not deal with nested expressions.
 * Therefore, if a nested double quoted expression does occur, we just match sequential pairs of 
 * double quotes encountered.
 */
- publishDoubleQuotes
{
    int ch, start = 0, end = 0;
    BOOL haveDoubleQuote = NO;
    NXStream *stream = [text stream];

    if (doubleQuoteNodeList)
	[[doubleQuoteNodeList freeObjects] free];
    doubleQuoteNodeList = [[List allocFromZone:[self zone]] init];

    NXSeek(stream, 0, NX_FROMSTART);
    ch = NXGetc(stream);
    while (!NXAtEOS(stream)) {
	switch (ch) {
	  case DOUBLE_QUOTE:
	    if (haveDoubleQuote) {   // now have end of double quote node
		end = NXTell(stream) - 1;
		[self createNode:start :end forNodeList:doubleQuoteNodeList];
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
    return self;
}

/* Find all single quoted expressions in the text. We currently do not deal with nested expressions.
 * Therefore, if a nested single quoted expression does occur, we just match sequential pairs of 
 * single quotes encountered. We recognize various single quote characters, and various combinations 
 * thereof. Three paired combination of the single quote characters ` and ' are valid single quote 
 * expressions. These combinations include, '...', `...', and `...`. Note that the '...` combination
 * is not valid, and is therefore treated as arbitary text.
 */
- publishSingleQuotes
{
    int ch, start = 0, end = 0;
    BOOL haveLeftQuote = NO, haveRightQuote = NO;
    NXStream *stream = [text stream];

    if (singleQuoteNodeList)
	[[singleQuoteNodeList freeObjects] free];
    singleQuoteNodeList = [[List allocFromZone:[self zone]] init];

    NXSeek(stream, 0, NX_FROMSTART);
    ch = NXGetc(stream);
    while (!NXAtEOS(stream)) {
        switch (ch) {
	  case SINGLE_LEFT_QUOTE:
	    if (haveLeftQuote) {   // have end of single quote node (2 left quotes)
		end = NXTell(stream) - 1;
		[self createNode:start :end forNodeList:singleQuoteNodeList];
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
		[self createNode:start :end forNodeList:singleQuoteNodeList];
                haveLeftQuote = NO;
            } else if (haveRightQuote) {   // now have end of single quote node (2 right quotes)
		end = NXTell(stream) - 1;
		[self createNode:start :end forNodeList:singleQuoteNodeList];
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
    return self;
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
- publishLineColumns
{
    int ch, start = 0, end = 0, state = 0;
    NXStream *stream = [text stream];

    if (lineColumnNodeList)
	[[lineColumnNodeList freeObjects] free];
    lineColumnNodeList = [[List allocFromZone:[self zone]] init];

    NXSeek(stream, 0, NX_FROMSTART);
    for ( ; ; ) {
        ch = NXGetc(stream);
        if (NXAtEOS(stream))
            return self;
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
		[self createNode:start :end forNodeList:lineColumnNodeList];
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
		[self createNode:start :end forNodeList:lineColumnNodeList];
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
		[self createNode:start :end forNodeList:lineColumnNodeList];
                state = 0;
	    }
	    break;

          case 4:
            if (NXIsGraph(ch)) {    // goal state; printable char after TAB(s)/SPACES indicates we had
                NXUngetc(stream);   // a node
		[self createNode:start :end forNodeList:lineColumnNodeList];
                state = 0;
            } else if (ch == NEWLINE) {   // goal state; we have a node
		[self createNode:start :end forNodeList:lineColumnNodeList];
                state = 0;
            }
            break;

          default:
            break;
        }
    }
    return self;
}


/* PAGE AND BOOKMARK PUBLISHING METHODS *************************************************************/


/* Publish information on page breaks.  This is set to TNT_LINES_PER_PAGE. Returns self. */
- publishPages
{
    int i, start, end;
    NXStream *stream = [text stream];

    if (pageNodeList)
	[[pageNodeList freeObjects] free];
    pageNodeList = [[List allocFromZone:[self zone]] init];

    NXSeek(stream, 0, NX_FROMSTART);
    for ( ; ; ) {
	start = NXTell(stream);
        for (i = 0; i < TNT_LINES_PER_PAGE; i++) {
            if (![self getNewLine:stream]) {   // EOS, all done
		end = NXTell(stream) - 1;
		if (end >= start) {   // don't add a page node (it's empty)
		    [self createPageNode:start :end forNodeList:pageNodeList];
		}
		return self;
	    }
        }
        end = NXTell(stream) - 1;
	[self createPageNode:start :end forNodeList:pageNodeList];
    }
    return self;
}

/* Updates the bookmark instance variables in all the (newly created) PageNode objects to correspond
 * to what exists in the bookmarkNodeList. If there are no bookmark nodes, then no updates are made to
 * the pageNode objects within the pageNodeList. If a bookmark node references a page node that no
 * longer exists (after the re-publish, and thru page numbers) then we simply remove that bookmark. 
 * Returns self.
 */
- publishBookmarks
{
    unsigned int i, count;
    id bookmarkNode, pageNode;

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


/* ENGLISH TEXT UTILITY METHODS *********************************************************************/


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

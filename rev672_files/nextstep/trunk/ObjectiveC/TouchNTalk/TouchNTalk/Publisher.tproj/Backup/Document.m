/*
 *    Filename:	Document.m 
 *    Created :	Thu May 13 11:39:41 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Sat Sep 10 13:36:48 1994"
 *
 * $Id: Document.m,v 1.20 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: Document.m,v $
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

    // create empty line wrapping store (for newline locations)
    lineWrapStore = [[Storage allocFromZone:[self zone]] initCount:0 
							 elementSize:sizeof(unsigned long)
							 description:"L"];
    return self;
}

- free
{
    [text free];
    [activePage free];
    [[lineWrapStore free];

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


/* LINE WRAPPING SET/QUERY METHODS ******************************************************************/


- setLineWrapStore:store
{
    lineWrapStore = store;
    return self;
}

- lineWrapStore
{
    return lineWrapStore;
}


/* LINE WRAPPING METHODS ****************************************************************************/


- wrapLines:(unsigned int)lineLength
{
    if (lineLength == 0)
	return self;

    return self;
}

- unwrapLines
{
    return self;
}

@end

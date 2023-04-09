/*
 *    Filename:	TactileDisplay.m 
 *    Created :	Wed May 19 14:39:20 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Tue Oct 18 17:28:06 1994"
 *
 * $Id: TactileDisplay.m,v 1.33 1994/10/19 00:02:05 dale Exp $
 *
 * $Log: TactileDisplay.m,v $
 * Revision 1.33  1994/10/19  00:02:05  dale
 * *** empty log message ***
 *
 * Revision 1.32  1994/07/26  20:11:02  dale
 * *** empty log message ***
 *
 * Revision 1.31  1994/07/25  02:30:52  dale
 * *** empty log message ***
 *
 * Revision 1.30  1994/06/30  09:06:03  dale
 * *** empty log message ***
 *
 * Revision 1.29  1994/06/29  22:53:11  dale
 * Added complete cursor location support.
 *
 * Revision 1.28  1994/06/29  22:39:07  dale
 * Fixed inconsistent vertical/horizontal behavioural problem. 
 *
 * Revision 1.27  1994/06/15  19:32:35  dale
 * Added length saftey margin for groove lengths.
 *
 * Revision 1.26  1994/06/10  20:18:28  dale
 * *** empty log message ***
 *
 * Revision 1.25  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.24  1994/06/03  08:03:28  dale
 * *** empty log message ***
 *
 * Revision 1.23  1994/05/28  21:24:37  dale
 * *** empty log message ***
 *
 * Revision 1.22  1993/08/31  04:51:27  dale
 * *** empty log message ***
 *
 * Revision 1.21  1993/08/24  02:08:33  dale
 * *** empty log message ***
 *
 * Revision 1.20  1993/07/23  07:33:00  dale
 * *** empty log message ***
 *
 * Revision 1.19  1993/07/14  22:11:48  dale
 * *** empty log message ***
 *
 * Revision 1.18  1993/07/06  00:34:26  dale
 * *** empty log message ***
 *
 * Revision 1.17  1993/07/04  17:57:23  dale
 * *** empty log message ***
 *
 * Revision 1.16  1993/07/01  20:18:47  dale
 * Added bookmark panel for entering bookmarks.
 *
 * Revision 1.15  1993/06/25  23:38:25  dale
 * Completed Page locator, and bookmark holophrast functionality.
 *
 * Revision 1.14  1993/06/24  07:40:50  dale
 * Moved some position setting, and charWidth calculation methods to the Page class.
 *
 * Revision 1.13  1993/06/22  19:50:38  dale
 * Completed scrolling behaviour, and added cursor location, with mouse click to select page with
 * system cursor, centering the page as much as possible so that the system cursor lies in the center
 * of the view.
 *
 * Revision 1.12  1993/06/18  08:45:44  dale
 * Added scrolling behaviour, and fixed left holophrast behaviour.
 *
 * Revision 1.11  1993/06/16  07:45:38  dale
 * Removed interface buttons.
 *
 * Revision 1.10  1993/06/14  15:09:57  dale
 * *** empty log message ***
 *
 * Revision 1.9  1993/06/11  08:38:39  dale
 * Incorporated GroovePalette for soft function activation.
 *
 * Revision 1.8  1993/06/09  18:23:00  dale
 * Added end node detection with appropriate sound.
 *
 * Revision 1.7  1993/06/07  08:11:40  dale
 * Initial attempt made at getting left holophrasts working throughout the system.
 *
 * Revision 1.6  1993/06/05  07:37:08  dale
 * *** empty log message ***
 *
 * Revision 1.5  1993/06/03  00:37:58  dale
 * *** empty log message ***
 *
 * Revision 1.4  1993/06/01  08:03:24  dale
 * *** empty log message ***
 *
 * Revision 1.3  1993/05/30  08:24:27  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/05/27  00:16:28  dale
 * Added skeleton methods to deal with button presses associated with sliders.
 *
 * Revision 1.1  1993/05/20  06:03:35  dale
 * Initial revision
 *
 */

#import <mach/cthreads.h>
#import <sound/sound.h>
#import <grooveslider/GrooveSlider.h>
#import "Publisher.tproj.h"
#import "TouchNTalk.h"
#import "TNTControl.h"
#import "SIL.h"
#import "SILSpeaker.h"
#import "DSPTone.h"
#import "TactileDisplay.h"

/* Left holophrast node sounds. */
#define START_NODE_SOUND        "Bonk"    // sound for start node detected
#define END_NODE_SOUND          "Funk"    // sound for end node detected
#define END_SERIES_SOUND        "Basso"   // sound for end of node series on same line
#define OVER_SCROLL_SOUND       "Basso"   // sound for vertical/horizontal overscrolling

@implementation TactileDisplay


/* INITIALIZING AND FREEING *************************************************************************/


- initFrame:(NXRect *)frameRect
{
    [super initFrame:frameRect];
    [self setBackgroundGray:NX_LTGRAY];
    [self setBorderType:NX_BEZEL]; 

    document = nil;
    activePage = nil;
    tactileSpeaker = [TactileSpeaker new];

    tone = [[DSPTone alloc] init];
    [tone setNumberHarmonics:TNT_HARMONICS];
    [(DSPTone *)tone setVolume:TNT_BASE_VOLUME];

    // init holophrast state information
    nodeList = nil;
    topPage = bottomPage = NO;
    nodeIndex = 0;

    // init general interface state information (used in left holophrasts, and cursor location)
    lastLine = MAXINT;   // init to invalid values
    lastCol = MAXINT;    
    lastNodeHighlighted = nil;

    // init sounds
    startNodeSound = [Sound findSoundFor:START_NODE_SOUND];
    endNodeSound   = [Sound findSoundFor:END_NODE_SOUND];
    endSeriesSound = [Sound findSoundFor:END_SERIES_SOUND];
    overScrollSound = [Sound findSoundFor:OVER_SCROLL_SOUND]; 
    return self;
}

/* Set the tactileSpeaker in the SIL by sending a shared instance of the TactileSpeaker class, so
 * the SIL can control all speech. Returns self.
 */
- awakeFromNib
{
    [bookmarkPanel setFloatingPanel:YES];
    [sil setTactileSpeaker:tactileSpeaker];
    return self;
}

- initTargetAction
{
    // left holophrast sliders
    [leftHolo1Slider setMouseDownTarget:self action:@selector(leftHolo1Active:)];
    [leftHolo2Slider setMouseDownTarget:self action:@selector(leftHolo2Active:)];
    [leftHolo3Slider setMouseDownTarget:self action:@selector(leftHolo3Active:)];
    [leftHolo4Slider setMouseDownTarget:self action:@selector(leftHolo4Active:)];

    [leftHolo1Slider setSingleClickTarget:self action:@selector(leftHoloSelect:)];
    [leftHolo2Slider setSingleClickTarget:self action:@selector(leftHoloSelect:)];
    [leftHolo3Slider setSingleClickTarget:self action:@selector(leftHoloSelect:)];
    [leftHolo4Slider setSingleClickTarget:self action:@selector(leftHoloSelect:)];

    [leftHolo1Slider setDoubleClickTarget:self action:@selector(leftHolo1Preview:)];
    [leftHolo2Slider setDoubleClickTarget:self action:@selector(leftHolo2Preview:)];
    [leftHolo3Slider setDoubleClickTarget:self action:@selector(leftHolo3Preview:)];
    [leftHolo4Slider setDoubleClickTarget:self action:@selector(leftHolo4Preview:)];

    [leftHolo1Slider setMouseUpTarget:self action:@selector(leftHoloUp:)];
    [leftHolo2Slider setMouseUpTarget:self action:@selector(leftHoloUp:)];
    [leftHolo3Slider setMouseUpTarget:self action:@selector(leftHoloUp:)];
    [leftHolo4Slider setMouseUpTarget:self action:@selector(leftHoloUp:)];

    // vertical and horizontal page scroll sliders
    [vertPageScrollSlider setMouseDownTarget:self action:@selector(vertPageScrollDown:)];
    [vertPageScrollSlider setMouseUpTarget:self action:@selector(vertPageScrollUp:)];
    [horizPageScrollSlider setMouseDownTarget:self action:@selector(horizPageScrollDown:)];
    [horizPageScrollSlider setMouseUpTarget:self action:@selector(horizPageScrollUp:)];    

    // cursor locator slider
    [cursorLocatorSlider setMouseDownTarget:self action:@selector(cursorLocatorActive:)];
    [cursorLocatorSlider setSingleClickTarget:self action:@selector(cursorLocatorSelect:)];
    [cursorLocatorSlider setDoubleClickTarget:self action:@selector(cursorLocatorDoubleSelect:)];
    [cursorLocatorSlider setMouseUpTarget:self action:@selector(cursorLocatorUp:)];

    // page locator slider
    [pageLocatorSlider setMouseDownTarget:self action:@selector(pageLocatorActive:)];
    [pageLocatorSlider setSingleClickTarget:self action:@selector(pageLocatorSelect:)];
    [pageLocatorSlider setMouseUpTarget:self action:@selector(pageLocatorUp:)];

    // bookmark slider
    [bookmarkHoloSlider setMouseDownTarget:self action:@selector(bookmarkHoloActive:)];
    [bookmarkHoloSlider setSingleClickTarget:self action:@selector(bookmarkHoloSelect:)];
    [bookmarkHoloSlider setDoubleClickTarget:self action:@selector(bookmarkHoloDoubleSelect:)];
    [bookmarkHoloSlider setMouseUpTarget:self action:@selector(bookmarkHoloUp:)];

    return self;
}

/* Note that if document is nil, we send -free to a nil object which is allright. Returns self. */
- free
{
    [document free];
    [nodeList free];
    [tactileSpeaker free];
    return [super free];
}

/* Sets the current document for the tactile display to aDoc. We then set the docView for the
 * tactileDisplay to the active page within the document. Finally, we set the resolution for the 
 * pageLocatorSlider and the bookmarkSlider to the required resolution, that is, to the number of
 * pages in the document plus 1 (due to inherent slider behaviour at extremes). Returns self.
 */
- setDocument:aDoc
{
    // set document and set tactile display docView to activePage within the document
    document = aDoc;
    [document setActivePage:1];
    [[self setDocView:activePage = [aDoc activePage]] free];

    // set the pageLocatorSlider and bookmarkHoloSlider to the required resolution
    [pageLocatorSlider setMinValue:1];
    [bookmarkHoloSlider setMinValue:1];
    [pageLocatorSlider setMaxValue:[document pages] + 1];
    [bookmarkHoloSlider setMaxValue:[document pages] + 1];
    return self;
}


/* QUERY METHODS ************************************************************************************/


- document
{
    return document;
}

/* Returns the active page. This is identical to sending the message [tactileDisplay docView]. */
- activePage
{
    return activePage;
}

- bookmarkPanel
{
    return bookmarkPanel;
}

- tone
{
    return tone;
}


/* ACTION METHODS ***********************************************************************************/


/* Page Backward. If unable to page backward, emits beep and returns nil, otherwise returns self. When
 * consecutive pages with greater than TNT_TACTILE_DISPLAY_COLUMNS columns occur, the view is not 
 * updated properly if horizontally scrolled, so we must always send the -display message to the view
 * to circumvent this problem. The -display message is also required to update the system cursor and 
 * mark if necessary.
 */
- pageBackward:sender
{
    [window disableFlushWindow];
    if (![document setActivePage:[document activePageNumber] - 1]) {   // can't page backward
	NXBeep();
	[window reenableFlushWindow];
	return nil;
    } else {   // can page backward
	[window reenableFlushWindow];
	[activePage display];
	sprintf(buffer, "Page %d of %d.", [document activePageNumber], [document pages]);
	[sil setText:buffer];
    }
    return self;
}

/* Page forward. If unable to page forward, emits beep and returns nil, otherwise returns self. When
 * consecutive pages with greater than TNT_TACTILE_DISPLAY_COLUMNS columns occur, the view is not 
 * updated properly if horizontally scrolled, so we must always send the -display message to the view
 * to circumvent this problem. The -display message is also required to update the system cursor and 
 * mark if necessary.
 */
- pageForward:sender
{
    [window disableFlushWindow];
    if (![document setActivePage:[document activePageNumber] + 1]) {   // can't page forward
	NXBeep();
	[window reenableFlushWindow];
	return nil;
    } else {   // can page forward
	[window reenableFlushWindow];
	[activePage display];
	sprintf(buffer, "Page %d of %d.", [document activePageNumber], [document pages]);
	[sil setText:buffer];
    }
    return self;
}

/* Add, change, or remove a bookmark for the current page. Returns self. */
- addChangeRemoveBookmark:sender
{
    int pageNumber = [document activePageNumber];
    id bookmark = [document bookmarkAtPage:pageNumber];

    if (bookmark) {   // no change, rename, or remove current bookmark

	if (*[nameField stringValue] != (char)0) {   // no change, or rename bookmark
                                                        // (since non-empty)
	    if (!strcmp([nameField stringValue], [bookmark name])) {   // no change
		sprintf(buffer, "Bookmark name unchanged.");
	    } else {   // rename current bookmark
		[document addBookmarkAtPage:pageNumber withName:[nameField stringValue]];
		sprintf(buffer, "Renamed bookmark for page %d to \"%s\".", pageNumber, 
			[nameField stringValue]);
	    }

	} else {   // remove current bookmark since empty field
	    [document removeBookmarkAtPage:pageNumber];
	    sprintf(buffer, "Removed bookmark for page %d.", pageNumber);
	}

	// move panel out of screen list
	[bookmarkPanel orderOut:nil];

    } else {   // add a bookmark

	// no change, or rename bookmark (since non-empty)
	if (*[nameField stringValue] != (char)0) {   
	    [document addBookmarkAtPage:pageNumber withName:[nameField stringValue]];
	    sprintf(buffer, "Added bookmark named \"%s\" for page %d.", [nameField stringValue],
		    pageNumber);

	    // move panel out of screen list
	    [bookmarkPanel orderOut:nil];

	} else {   // cannot accept empty bookmark name
	    sprintf(buffer, "Please enter a bookmark name.");
	    [nameField selectText:nil];
	}
    }
    [sil setText:buffer];
    return self;
}

- cancelBookmark:sender
{
    // move panel out of screen list
    [bookmarkPanel orderOut:nil];
    return self;
}

/* Called when the vertical page scroll becomes active. Sets the various scroll state variables as
 * required. Returns self.
 */
- vertPageScrollDown:sender
{
    startTopLine = [activePage topVisibleLine];
    lastScrollVal = currScrollVal = [sender intValue];
    return self;
}

/* Scrolls the page vertically by the amount calculated and described below. This method assumes that
 * every active page begins with the topmost line visible. Returns self. 
 */
- vertPageScrollActive:sender
{
    if ((currScrollVal = [sender intValue]) == TNT_TACTILE_DISPLAY_LINES) {  // adjust if slider @ top
	currScrollVal--;
    }
    if (currScrollVal == lastScrollVal) {   // slider is not being scrolled
	return self;
    }

    // update scroll state information
    overScroll = FALSE;

    // In order to get the desired vertical scroll effect, we inverse the subtraction of lastScrollVal
    // from currScrollVal since the text object is a flipped view. Note, that we must temporarily 
    // disable flushing output to the window so the view does not get mucked up (duplicated lines). 
    // Note, the call to -moveBy:: returns nil when the user has overscrolled and a beep is emitted.

    [window disableFlushWindow];
    if (![activePage moveBy:0 :(lastScrollVal - currScrollVal) * [activePage lineHeight]]) {
	[(Sound *)overScrollSound play];
	overScroll = TRUE;
    }
    [window reenableFlushWindow];
    [activePage display];

    // update last scroll
    lastScrollVal = currScrollVal;
    return self;
}

/* Actually speaks how many lines were scrolled. If we were unable to scroll the full amount, we 
 * indicate so by preceeding the spoken and displayed message by "Only". If the value to scroll is 0 
 * we simply tell the user that the page was not scrolled. Returns self.
 */
- vertPageScrollUp:sender
{
    int currTopLine = [activePage topVisibleLine];

    if (currTopLine < startTopLine) {   // window scrolled up
	if (overScroll) {   // unable to scroll all lines
	    sprintf(buffer, "Only up %d lines.", startTopLine - currTopLine);
	} else {   // able to scroll all lines
	    sprintf(buffer, "Up %d lines.", startTopLine - currTopLine);
	}
    } else if (currTopLine > startTopLine) {   // window scrolled down
	if (overScroll) {   // unable to scroll all lines
	    sprintf(buffer, "Only down %d lines.", currTopLine - startTopLine);
	} else {   // able to scroll all lines
	    sprintf(buffer, "Down %d lines.", currTopLine - startTopLine);
	}
    } else {   // no scroll
	sprintf(buffer, "No scroll.");
    }
    [sil setText:buffer];
    return self;
}

/* Called when the horizontal page scroll becomes active. Sets the various scroll state variables as
 * required. Returns self.
 */
- horizPageScrollDown:sender
{
    startLeftCol = [activePage leftVisibleCol];
    lastScrollVal = currScrollVal = [sender intValue];
    return self;
}

/* Scrolls the page horizontally by the amount calculated and described below. This methods assumes 
 * that every active page begins with the leftmost column visible. Returns self.
 */
- horizPageScrollActive:sender
{
    if ((currScrollVal = [sender intValue]) == TNT_TACTILE_DISPLAY_COLUMNS) {    // adjust if slider @
	currScrollVal--;                                                         // right
    }
    if (currScrollVal == lastScrollVal) {   // slider is not being scrolled
	return self;
    }

    // update scroll state information
    overScroll = FALSE;

    // In order to get the desired horizontal scroll effect, we inverse the subtraction of 
    // curreScrollVal from lastScrollVal since the text object is a flipped view. Note, that we must 
    // temporarily disable flushing output to the window so the view does not get mucked up 
    // (duplicated lines). Note, the call to -moveBy:: returns nil when the user has overscrolled and
    // a beep is emitted.

    [window disableFlushWindow];
    if (![activePage moveBy:(currScrollVal - lastScrollVal) * [activePage charWidth] :0]) {
	[(Sound *)overScrollSound play];
	overScroll = TRUE;
    }
    [window reenableFlushWindow];
    [activePage display];

    // update last scroll
    lastScrollVal = currScrollVal;
    return self;
}

/* Actually speaks how many columns were scrolled, If we are unable to scroll the full amount, we 
 * indicate so by preceeding the spoken and displayed message by "Only". If the value to scroll is 0
 * we simply tell the user that the page was not scrolled. Returns self.
 */
- horizPageScrollUp:sender
{
    int currLeftCol = [activePage leftVisibleCol];

    if (currLeftCol < startLeftCol) {   // window scrolled left
	if (overScroll) {   // unable to scroll all columns
	    sprintf(buffer, "Only left %d columns.", startLeftCol - currLeftCol);
	} else {   // able to scroll all columns
	    sprintf(buffer, "Left %d columns.", startLeftCol - currLeftCol);
	}
    } else if (currLeftCol > startLeftCol) {   // window scrolled right
	if (overScroll) {   // unable to scroll all columns
	    sprintf(buffer, "Only right %d columns.", currLeftCol - startLeftCol);
	} else {   // able to scroll all columns
	    sprintf(buffer, "Right %d columns.", currLeftCol - startLeftCol);
	}
    } else {   // no scroll
	sprintf(buffer, "No scroll.");
    }
    [sil setText:buffer];
    return self;
}

- pageLocatorActive:sender
{
    float pitch, newVolume, baseVolume = [[NXApp delegate] baseVolume];
    int col, pageDistance;

    // play locator tone
    [self playLocatorTone];

    // Since sliders have one last partition in the extreme we want to treat this last value as the 
    // previous value in the slider. This applies to ALL sliders used.

    col = [sender intValue];
    if (col > [document pages]) {   // upper limit == # pages
	col--;
    }
    if (col == lastCol) {   // current column same as last column; ignore
	return self;
    }
    lastCol = col;   // keep track of last column

    // get page distance to current page from current column in pageLocatorSlider (sender)
    pageDistance = ABS([document activePageNumber] - col);

    // Set volume according to pitch of tone (variable volume). When the tone has high pitch we
    // decrease the volume since it "seems" to get louder. We adjust the new volume if it has gone
    // past the lower and upper volume bounds less the TNT_VOLUME_VARIATION.
    newVolume = baseVolume - TNT_VOLUME_VARIATION * (pageDistance / (TNT_PITCH_MAX - TNT_PITCH_MIN));
    if (newVolume < baseVolume - TNT_VOLUME_VARIATION) {
	newVolume = baseVolume - TNT_VOLUME_VARIATION;
    } else if (newVolume > baseVolume) {
	newVolume = baseVolume;
    }
    [(DSPTone *)tone setVolume:newVolume];

    // get and play tone based on distance
    pitch = TNT_PITCH_MIN + pageDistance - 1.0;
    if (pitch < TNT_PITCH_MIN) {   // out of range
	[(DSPTone *)tone setVolume:0];
    } else if (pitch > TNT_PITCH_MAX) {   // out of range
	[tone setPitch:TNT_PITCH_MAX];	
    } else {   // slider within range of page with system cursor
	[tone setPitch:pitch];
    }
    return self;
}

/* Sets the display with the page which corresponds to the column where the click occurred. If the 
 * page to load is equal to the current page we add a bookmark instead since the current page is
 * already visible. If a new page is loaded, we speak the page number, otherwise we tell the user that
 * the active page was unchanged. If we are adding a bookmark and a bookmark already exists, we 
 * replace. Whenever we add a bookmark we speak that we have done so. Disabling flushing the window 
 * allows us to circumvent momentarily messing up the view. The -display message is required to update
 * the system cursor and mark if they are on the current page. Returns self.
 */
- pageLocatorSelect:sender
{
    id bookmark;

    if (lastCol != [document activePageNumber]) {   // load page if not the current page
	[window disableFlushWindow];
	[document setActivePage:lastCol];
	[window reenableFlushWindow];
	[activePage display];   // update cursors if necessary

	// release DSP prematurely to speak the bookmark addition instructions
	[self pageLocatorUp:sender];

	// init lastCol and message -pageLocatorActive: so tone is updated
	lastCol = MAXINT;
	[self pageLocatorActive:sender];

	// display current page number without speaking
	sprintf(buffer, "Page %d of %d.", [document activePageNumber], [document pages]);
	[sil setTextNoSpeech:buffer];

    } else {   // col corresponds to current page, so add a bookmark to the current page

	// release DSP prematurely to speak the bookmark addition/removal instructions
	[self pageLocatorUp:sender];

	// get bookmark
	bookmark = [document bookmarkAtPage:[document activePageNumber]];

	// speak bookmark addition/removal instructions
	if (bookmark) {   // bookmark already exists
	    [instructionsTitle setStringValue:"Type a new name for the bookmark, or press delete then enter to remove."];
	    sprintf(buffer, "%s Current name is %s.", [instructionsTitle stringValue], 
		    [bookmark name]);
	    [sil setText:buffer];
	    [nameField setStringValue:[bookmark name]];   // set default with existing bookmark name
	} else {   // no bookmark present
	    [instructionsTitle setStringValue:"Type a name for the new bookmark, or press enter for default."];
	    sprintf(buffer, "%s Default name is %s.", [instructionsTitle stringValue], 
		    [document defaultBookmarkName]);
	    [sil setText:buffer];
	    [nameField setStringValue:[document defaultBookmarkName]];
	}

	// display bookmark panel and select text
	[bookmarkPanel makeKeyAndOrderFront:nil];
	[nameField selectText:nil];
    }
    return self;
}

- pageLocatorUp:sender
{
    // stop all music
    [tone stopTone];
    lastCol = MAXINT;
    return self;
}

/* Behaves similarly to the left holophrast sliders, except that the nodes are now bookmarks. When the
 * column of the slider corresponding to a particular page has a bookmark, we emit a beep to indicate
 * this. Returns self.
 */
- bookmarkHoloActive:sender
{
    int col;

    // Since sliders have one last partition in the extreme we want to treat this last value as the 
    // previous value in the slider. This applies to ALL sliders used.

    col = [sender intValue];
    if (col > [document pages]) {   // upper limit == # pages
	col--;
    }
    if (col == lastCol) {   // current column same as last column; ignore
	return self;
    }
    lastCol = col;   // keep track of last column

    if ([document bookmarkAtPage:col]) {   // bookmark exists at page corresponding to current column
	[(Sound *)startNodeSound play];
    }
    return self;
}

/* Speaks the bookmark name if the slider is currently ontop of a bookmark. If the slider is not ontop
 * of a bookmark, this has no effect. Returns self.
 */
- bookmarkHoloSelect:sender
{
    id bookmark = [document bookmarkAtPage:lastCol];

    if (bookmark) {   // bookmark exists at page corresponding to last column
	sprintf(buffer, "%s.", [bookmark name]);
	[sil setText:buffer];
    }
    return self;
}

/* Sets the active page to the page which corresponds to the bookmark the slider is currently ontop.
 * If the slider is not ontop of a bookmark, this has no effect. Disabling flushing the window allows
 * to circumvent momentarily messing up the view. The -display message is required to update the 
 * system cursor and mark if they are on the current page. Returns self.
 */
- bookmarkHoloDoubleSelect:sender
{
    id bookmark = [document bookmarkAtPage:lastCol];

    if (bookmark) {   // bookmark exists at page corresponding to last column
	if (lastCol != [document activePageNumber]) {   // don't load new page if it's already active
	    [window disableFlushWindow];
	    [document setActivePage:lastCol];
	    [window reenableFlushWindow];
	    [activePage display];
	}
	sprintf(buffer, "Page %d of %d.", lastCol, [document pages]);
	[sil setText:buffer];
    }
    return self;
}

/* Init lastCol to invalid value for subsequent bookmarkHoloSlider activations. Returns self. */
- bookmarkHoloUp:sender
{
    lastCol = MAXINT;
    return self;
}

/* NOTE: Assumes all pages up to the page which contains the system cursor have TNT_LINES_PER_PAGE 
 * lines.
 */
- cursorLocatorActive:sender
{
    float pitch, newVolume, baseVolume = [[NXApp delegate] baseVolume];
    int line, lineDistance;

    // play locator tone
    [self playLocatorTone];

    line = TNT_TACTILE_DISPLAY_LINES - [sender intValue];
    if (line == 0) {   // for cursor locator slider, 0 == 1
	line++;
    }
    if (line == lastLine) {   // current line same as last line; ignore
	return self;
    }
    lastLine = line;   // keep track of last line

    // get line distance to system cursor from current line in cursorLocatorSlider (sender)
    lineDistance = ABS((([document activePageNumber] - 1) * TNT_LINES_PER_PAGE + line + 
			[activePage topVisibleLine] - 1) - 
		       (([document systemCursorPage] - 1) * TNT_LINES_PER_PAGE + 
			[document systemCursorLine]));

    // Set volume according to pitch of tone (variable volume). When the tone has high pitch we
    // decrease the volume since it "seems" to get louder. We adjust the new volume if it has gone
    // based the lower and upper volume bounds indicated by TNT_VOLUME_VARIATION.
    newVolume = baseVolume - TNT_VOLUME_VARIATION * (lineDistance / (TNT_PITCH_MAX - TNT_PITCH_MIN));
    if (newVolume < baseVolume - TNT_VOLUME_VARIATION) {
	newVolume = baseVolume - TNT_VOLUME_VARIATION;
    } else if (newVolume > baseVolume) {
	newVolume = baseVolume;
    }
    [(DSPTone *)tone setVolume:newVolume];

    // get and play tone based on distance
    pitch = TNT_PITCH_MIN + lineDistance - 1.0;
    if (pitch < TNT_PITCH_MIN) {   // out of range
	[(DSPTone *)tone setVolume:0];
    } else if (pitch > TNT_PITCH_MAX) {   // out of range
	[tone setPitch:TNT_PITCH_MAX];	
    } else {   // slider within range of line of system cursor
	[tone setPitch:pitch];
    }
    return self;
}

/* Turn to the page with the system cursor, and make the line and column visible. Returns self. */
- cursorLocatorSelect:sender
{
    int vertScroll, horizScroll, linesInPage, columnsInPage;

    linesInPage = [activePage linesInPage];
    columnsInPage = [activePage columnsInPage];

    [window disableFlushWindow];

    // system cursor not on current page; get correct page first
    if ([document activePageNumber] != [document systemCursorPage]) {
	[document setActivePage:[document systemCursorPage]];
    }

    // Get amount to scroll the page vertically so that system cursor is as close as possible to the 
    // middle of the page. We may have an overly small or large vertical scroll amount, but we let
    // the moveBy:: call handle how much to "scroll" if we are unable to vertically scroll the full 
    // calculated amount. Similarly for the horizontal scroll, so that the system cursor is as close 
    // to the center of the page as possible.

    vertScroll = [document systemCursorLine] - [activePage topVisibleLine] - 
	TNT_TACTILE_DISPLAY_LINES/2;
    horizScroll = [document systemCursorCol] - [activePage leftVisibleCol] -
	TNT_TACTILE_DISPLAY_COLUMNS/2;

    [activePage moveBy:horizScroll * [activePage charWidth] :vertScroll * [activePage lineHeight]];
    [window reenableFlushWindow];
    [activePage display];

    // init lastLine to invalid value, and message -cursorLocatorActive: so tone is updated
    lastLine = MAXINT;
    [self cursorLocatorActive:sender];
    return self;
}

/* Set the current TouchNTalk mode to TNT_LOCATE. This means that subsequent movement in the tactile
 * document display area will emit location tones for location of the system cursor. Movement detected
 * in any other area of the display will cancel system cursor location. Note, only when the stylus is
 * on the line containing the system cursor AND the double click is detected, does TouchNTalk enter 
 * into TNT_LOCATE mode when double. Otherwise, the double click is ignored. Returns self.
 */
- cursorLocatorDoubleSelect:sender
{
    int line = TNT_TACTILE_DISPLAY_LINES - [sender intValue];

    if (line == 0) {   // for cursor locator slider, 0 == 1
	line++;
    }
    if ([document activePageNumber] == [document systemCursorPage] &&
	[document systemCursorLine] == (line + [activePage topVisibleLine] - 1)) {
	// system cursor on current page AND adjacent current line
	[tntControl setOperationMode:TNT_LOCATE];
    }
    return self;
}

- cursorLocatorUp:sender
{
    // stop playing tone
    [tone stopTone];
    lastLine = MAXINT;
    return self;
}

/* The following -leftHolo?Active: methods handle highlighting nodes on the current line for the
 * active holophrast. We get the line number for the active holophrast, and obtain a list of nodes on
 * the current line. We then set the nodeList instance variable to this List, and highlight the first
 * node in the nodeList. We use the lastLine static variable to keep track of the last line to avoid 
 * re-highlighting the current line due to continuous mouse-dragged events. Also note that the 
 * instance variable nodeIndex is set to 1 within the -highlightNodeAt:inList method. This variable 
 * keeps track of the index for the nexr node to be displayed in the nodeList. All return self.
 */

- leftHolo1Active:sender
{
    int line;
    id holoNodeList;   // holophrast node list to search

    line = TNT_TACTILE_DISPLAY_LINES - [leftHolo1Slider intValue];
    if (line == 0) {   // for holophrast sliders, 0 == 1
	line++;
    }
    if (line == lastLine) {   // current line same as last line, ignore
	return self;
    }
    lastLine = line;   // keep track of last line

    if ([tntControl activeHoloSet] == TNT_HOLO_SET1) {   // titles
	holoNodeList = [document titleNodeList];
    } else {   // parentheses
	holoNodeList = [document parenNodeList];
    }
    return [self highlightNodeAt:line inList:holoNodeList];
}

- leftHolo2Active:sender
{
    int line;
    id holoNodeList;   // holophrast node list to search

    line = TNT_TACTILE_DISPLAY_LINES - [leftHolo2Slider intValue];
    if (line == 0) {   // for holophrast sliders, 0 == 1
	line++;
    }
    if (line == lastLine) {   // current line same as last line, ignore
	return self;
    }
    lastLine = line;   // keep track of last line

    if ([tntControl activeHoloSet] == TNT_HOLO_SET1) {   // paragraphs
	holoNodeList = [document paragraphNodeList];
    } else {   // double quotes
	holoNodeList = [document doubleQuoteNodeList];
    }
    return [self highlightNodeAt:line inList:holoNodeList];
}

- leftHolo3Active:sender
{
    int line;
    id holoNodeList;   // holophrast node list to search

    line = TNT_TACTILE_DISPLAY_LINES - [leftHolo3Slider intValue];
    if (line == 0) {   // for holophrast sliders, 0 == 1
	line++;
    }
    if (line == lastLine) {   // current line same as last line, ignore
	return self;
    }
    lastLine = line;   // keep track of last line

    if ([tntControl activeHoloSet] == TNT_HOLO_SET1) {   // sentences
	holoNodeList = [document sentenceNodeList];
    } else {   // single quotes
	holoNodeList = [document singleQuoteNodeList];
    }
    return [self highlightNodeAt:line inList:holoNodeList];
}

- leftHolo4Active:sender
{
    int line;
    id holoNodeList;   // holophrast node list to search

    line = TNT_TACTILE_DISPLAY_LINES - [leftHolo4Slider intValue];
    if (line == 0) {   // for holophrast sliders, 0 == 1
	line++;
    }
    if (line == lastLine) {   // current line same as last line, ignore
	return self;
    }
    lastLine = line;   // keep track of last line

    if ([tntControl activeHoloSet] == TNT_HOLO_SET1) {   // phrases
	holoNodeList = [document phraseNodeList];
    } else {   // line/columns (tabular data)
	holoNodeList = [document lineColumnNodeList];
    }
    return [self highlightNodeAt:line inList:holoNodeList];
}

/* Handles highlighting and speaking the next node on the current line for the currently active 
 * holophrast. This method is called for all left holophrasts when a single right mouse click occurs. 
 * Note that if a selection occurs in the middle of a larger node no sound is emitted since the cursor
 * must be adjacent the start of the node. We use the nodeIndex value of -1 to indicate that we are
 * back at the first node after cycling through all of the nodes on the line, as opposed to first
 * encountering the first node on the line. In this case we have to highlight it since it is not yet
 * highlighted. Lastly, if a node crosses a page boundary, we send a message to the SIL to indicate 
 * whether it crosses the top of bottom page. Note: before a node is spoken we erase all sound so that
 * the user does not have to wait for the last utterance to be completed. Returns self.
 */
- leftHoloSelect:sender
{
    if (topPage) {   // speak qualifier phrase to indicate node begins on previous page
	[sil setText:"Top of page."];
    }

    if (nodeIndex == -1) {   // first node after cycling through series
	[(Sound *)startNodeSound play];
	[[activePage speaker] eraseAllSound];
	[self highlightNodeAt:nodeIndex = 0];
	[activePage speakSelection];
	nodeIndex++;
    } else if (nodeIndex == 0) {   // first node already highlighted, just speak it
	[[activePage speaker] eraseAllSound];
	[activePage speakSelection];
	nodeIndex++;
    } else if (nodeIndex < [nodeList count]) {   // highlight next node on current line
	[(Sound *)startNodeSound play];
	[[activePage speaker] eraseAllSound];
	[self highlightNodeAt:nodeIndex++];
	[activePage speakSelection];
    } else if (nodeIndex == [nodeList count]) {   // we have passed the last node on the current line
	[(Sound *)endSeriesSound play];
	nodeIndex = -1;
    } else {                                    // the highlighted node may span the line adjacent the
	[[activePage speaker] eraseAllSound];   // slider knob, but not begin at that line
	[activePage speakSelection];
    }

    if (bottomPage) {   // speak qualifier phrase to indicate node begins on previous page
	[sil setTextNoErase:"Bottom of page."];
    }
    return self;
}

/* Handles freeing the nodeList object when the mouse is raised, and setting the nodeIndex to 0. We
 * can do this since the nodeList will no longer be used. The lastLine instance variable is 
 * initialized to some invalid variable so any line that becomes active is considered a new line. 
 * Returns self.
 */
- leftHoloUp:sender
{
    [nodeList free];
    nodeList = nil;
    nodeIndex = 0;
    lastLine = MAXINT;

    // additions for speaking nodes that span a the slider line
    lastNodeHighlighted = nil;
    [activePage selectCharactersFrom:0 to:0];

    return self;
}

/* The following -leftHolo?Preview: methods speak and display the type of holophrast selected. All 
 * return self.
 */

- leftHolo1Preview:sender
{
    if ([tntControl activeHoloSet] == TNT_HOLO_SET1) {
	[sil setText:"Title holophrast."];
    } else if ([tntControl activeHoloSet] == TNT_HOLO_SET2) {
	[sil setText:"Parenthetical holophrast."];
    }
    return self;
}

- leftHolo2Preview:sender
{
    if ([tntControl activeHoloSet] == TNT_HOLO_SET1) {
	[sil setText:"Paragraph holophrast."];
    } else if ([tntControl activeHoloSet] == TNT_HOLO_SET2) {
	[sil setText:"Double quote holophrast."];
    }
    return self;
}

- leftHolo3Preview:sender
{
    if ([tntControl activeHoloSet] == TNT_HOLO_SET1) {
	[sil setText:"Sentence holophrast."];
    } else if ([tntControl activeHoloSet] == TNT_HOLO_SET2) {
	[sil setText:"Single quote holophrast."];
    }
    return self;
}

- leftHolo4Preview:sender
{
    if ([tntControl activeHoloSet] == TNT_HOLO_SET1) {
	[sil setText:"Phrase holophrast."];
    } else if ([tntControl activeHoloSet] == TNT_HOLO_SET2) {
	[sil setText:"Line/column holophrast."];
    }
    return self;
}


/* NODE HIGHLIGHT METHODS ***************************************************************************/


/* Highlights the node at nodeIndex in the nodeList (instance variable), within the activePage object.
 * Returns self.
 */
- highlightNodeAt:(int)index
{
    id node;

    if (node = [nodeList objectAt:index]) {
	[self highlightNode:node];
    }
    return self;
}

/* Highlights the node within the activePage object. We have to consider 3 cases. The first case is 
 * when the node began at the end of the previous page, and simply end on the current page. The second
 * case is when the node begins on the current page, and ends on the next page. The last case is when 
 * the entire node is contained within the current page. If either of the first cases occur, we set 
 * the bottomPage or topPage to indicate that only part of the node appears. For example, topPage = 
 * YES indicates that part of the node appears at the top of the page. The remainder must therefore be
 * on the previous page. Conversely for bottomPage. These variables are examined when the node is 
 * requested to be spoken in -leftHoloSelect. Returns self. 
 */
- highlightNode:node
{
    int pageStart, pageEnd, nodeStart, nodeEnd;
    id pageNode = [activePage pageNode];

    topPage = bottomPage = NO;
    pageStart = [pageNode start];
    pageEnd = [pageNode end];
    nodeStart = [node start];
    nodeEnd = [node end];
    if (nodeStart < pageStart) {   // end node partially visible at top of page
	[activePage selectCharactersFrom:0 to:nodeEnd - pageStart + 1];
	topPage = YES;
    }
    if (nodeEnd > pageEnd) {   // start node partially visible at bottom of page
	[activePage selectCharactersFrom:nodeStart - pageStart to:pageEnd - pageStart];
	bottomPage = YES;
    }
    if (!topPage && !bottomPage) {   // node fully contained within page
	[activePage selectCharactersFrom:nodeStart - pageStart to:nodeEnd - pageStart + 1];
    }
    lastNodeHighlighted = node;   // remember it so we can determine whether to speak the node if it
    return self;                  // spans the current line in the holophrast grooves 
}

/* Highlights a node on the current line. If no start node(s) exist on the current line, then we
 * attempt to highlight an end node. Note that if start nodes do exist on the current line, then only
 * the first one is ever highlighted. For highlighting of arbitrary start nodes on a line, use the
 * method -highlightNodeAt:. This method is always called before -highlightNodeAt: in order to set up
 * the nodeList appropriately. This nodeList is loaded with all the start nodes for the current line.
 * The value of nodeIndex is set to the index of the node that is highlighted on the current line.
 * In the event no nodes are found, we clear the topPage and bottomPage variables so that the 
 * qualifier phrase (which indicates whether the node spans a page break) from a previous invocation 
 * will not be spoken. Returns self.
 */
- highlightNodeAt:(int)line inList:holoNodeList
{
    id nodeEnd;

    // start node(s) exist on current line
    if (nodeList = [document nodesInNodeList:holoNodeList 
			     startingOnLine:line + [activePage topVisibleLine] - 1]) {
	[(Sound *)startNodeSound play];
	[self highlightNodeAt:nodeIndex = 0];
    } else {   // no start node(s) on current line; look for an end node
	// end node exists on current line
	if (nodeEnd = [document nodeInNodeList:holoNodeList 
		      endingOnLine:line + [activePage topVisibleLine] - 1]) {
	    [(Sound *)endNodeSound play];
	    [self highlightNode:nodeEnd];
	} else {   // no node(s) begin or end on current line, but we may still be adjacent one

	    // the last highlighted node does not span the current line; adjust line for vert. scroll
	    if (![self node:lastNodeHighlighted spansLine:line + [activePage topVisibleLine] - 1]) {
		topPage = bottomPage = NO;   // we must not speak "Top (Bottom) of page." message
		[activePage selectCharactersFrom:0 to:0];   // unhighlight a selection (if any)
		lastNodeHighlighted = nil;   // indicate that no node is currently highlighted
	    }
	}
	nodeIndex = MAXINT;   // some value greater than 1 ([nodeList count])
    }
    return self;
}

/* Returns whether or not the node spans the specified line in the active page. */
- (BOOL)node:aNode spansLine:(int)line;
{
    int pageStart, pageEnd, nodeStart, nodeEnd, nodeLineStart, nodeLineEnd;
    id pageNode;

    if (!aNode) {   // node == nil does not span line
	return NO;
    }
    pageNode = [activePage pageNode];
    pageStart = [pageNode start];
    pageEnd = [pageNode end];
    nodeStart = [aNode start];
    nodeEnd = [aNode end];

    if (nodeStart < pageStart) {   // end node partially visible at top of page
	nodeLineEnd = [activePage lineFromPosition:nodeEnd - pageStart];
	if (line <= nodeLineEnd) {
	    return YES;
	} else {
	    return NO;
	}
    }
    if (nodeEnd > pageEnd) {   // start partially visible at bottom of page
	nodeLineStart = [activePage lineFromPosition:nodeStart - pageStart];
	if (line >= nodeLineStart) {
	    return YES;
	} else {
	    return NO;
	}
    }
    nodeLineStart = [activePage lineFromPosition:nodeStart - pageStart];
    nodeLineEnd = [activePage lineFromPosition:nodeEnd - pageStart];
    if (line >= nodeLineStart && line <= nodeLineEnd) {   // node fully contained within page
	return YES;
    }
    return NO;
}


/* UTILITY METHODS **********************************************************************************/


/* If the tone is not yet playing, try and play it. If the tone cannot be played, then some other
 * application (probably the TTSKit) currently has control of the DSP. We keep trying to play the tone
 * as long as the slider is down or being dragged. If we are able to play the tone, or the tone is 
 * already playing, we return self. Note that we only turn on the tone, but the frequency still needs
 * to be set since by default, the tone plays at a frequency of 0.0 Hz, which is inaudible.
 */
- playLocatorTone
{
    if (![tone isPlaying]) {   // tone is not yet playing, attempt to play it
	[tactileSpeaker eraseAllSound];
	[[sil speaker] eraseAllSound];
	while (![tone playTone])
	    ;
    }
    return self;
}

/* Resets the current document for the tactile display. We set the resolution for the 
 * pageLocatorSlider and the bookmarkSlider to the required resolution, that is, to the number of 
 * pages in the document plus 1 (due to inherent slider behaviour at extremes). Finally, we reset the
 * system cursor and mark to page, line, and column 1. Returns self.
 */
- resetDocument
{
    // set document and set tactile display docView to activePage within the document
    [document setActivePage:1];

    // set the pageLocatorSlider and bookmarkHoloSlider to the required resolution
    [pageLocatorSlider setMaxValue:[document pages] + 1];
    [bookmarkHoloSlider setMaxValue:[document pages] + 1];

    // reset system cursor
    [document setSystemCursorLine:1];
    [document setSystemCursorCol:1];
    [document setSystemCursorPage:1];

    // reset mark
    [document setMarkLine:1];
    [document setMarkCol:1];
    [document setMarkPage:1];
    return self;
}


/* CURSOR MANIPULATION METHODS **********************************************************************/


/* Repositions the mark and system cursors by moving the mark to the system cursor, and moving the
 * system cursor to the user cursor. Also sends a message to the SIL indicating the new location of
 * the system cursor. Returns self.
 */
- repositionCursors;
{
    int pageNumber, userCursorLine, userCursorCol;

    // move mark to system cursor
    [document setMarkPage:[document systemCursorPage] line:[document systemCursorLine] 
	      col:[document systemCursorCol]];

    // move system cursor to user cursor
    pageNumber = [activePage pageNumber];
    userCursorLine = [activePage userCursorLine];
    userCursorCol = [activePage userCursorCol];
    [document setSystemCursorPage:pageNumber line:userCursorLine col:userCursorCol];

    // update the system cursor and mark
    [activePage updateSystemCursor];
    [activePage updateMark];

    // speak change of system cursor location
    sprintf(buffer, "System cursor moved to page %d, line %d, column %d.", pageNumber, 
	    userCursorLine, userCursorCol);
    [sil setText:buffer];
    return self;
}

/* Swaps the system cursor and the mark. We then send a message to the SIL indicating the exchange
 * occurred. Returns self.
 */
- swapCursors
{
    int markPage, markLine, markCol;

    // remember mark position
    markPage = [document markPage];
    markLine = [document markLine];
    markCol = [document markCol];

    // move mark to system cursor
    [document setMarkPage:[document systemCursorPage] line:[document systemCursorLine] 
	      col:[document systemCursorCol]];

    // move system cursor to previous mark position
    [document setSystemCursorPage:markPage line:markLine col:markCol];

    // update the system cursor and mark
    [activePage updateSystemCursor];
    [activePage updateMark];

    // speak change of system cursor location
    sprintf(buffer, "Exchanged system cursor and mark.");
    [sil setText:buffer];
    return self;
}

- (BOOL)userCursorAtSystemCursor
{
    if ([activePage pageNumber] == [document systemCursorPage] &&
	[activePage userCursorLine] == [document systemCursorLine] &&
	[activePage userCursorCol] == [document systemCursorCol]) {
	return YES;
    } else {
	return NO;
    }
}

@end

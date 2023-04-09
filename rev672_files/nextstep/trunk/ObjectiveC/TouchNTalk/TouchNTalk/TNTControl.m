/*
 *    Filename:	TNTControl.m 
 *    Created :	Tue May 18 14:00:53 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Tue Jul 26 11:05:29 1994"
 *
 * $Id: TNTControl.m,v 1.37 1994/07/26 20:11:02 dale Exp $
 *
 * $Log: TNTControl.m,v $
 * Revision 1.37  1994/07/26  20:11:02  dale
 * *** empty log message ***
 *
 * Revision 1.36  1994/07/25  02:30:52  dale
 * *** empty log message ***
 *
 * Revision 1.35  1994/06/30  17:45:50  dale
 * Refixed column distance problem when dragging in TNT_LOCATE mode.
 *
 * Revision 1.34  1994/06/30  09:06:03  dale
 * Fixed bug when dragging on active page of open document.
 *
 * Revision 1.33  1994/06/29  22:39:07  dale
 * *** empty log message ***
 *
 * Revision 1.32  1994/06/15  19:32:35  dale
 * *** empty log message ***
 *
 * Revision 1.31  1994/06/10  20:18:28  dale
 * *** empty log message ***
 *
 * Revision 1.30  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.29  1994/06/03  08:03:28  dale
 * Fixed speech mode and holo set so they work on a per document basis. Other minor fixes.
 *
 * Revision 1.28  1994/06/01  19:13:28  dale
 * Moved soft function related methods into TouchNTalk class.
 *
 * Revision 1.27  1994/05/30  19:18:08  dale
 * *** empty log message ***
 *
 * Revision 1.26  1993/10/10  20:58:14  dale
 * *** empty log message ***
 *
 * Revision 1.25  1993/09/01  19:35:12  dale
 * *** empty log message ***
 *
 * Revision 1.24  1993/08/31  04:51:27  dale
 * *** empty log message ***
 *
 * Revision 1.23  1993/08/27  08:08:08  dale
 * *** empty log message ***
 *
 * Revision 1.22  1993/08/27  03:51:06  dale
 * Added functionality to handle configuration of the tablet.
 *
 * Revision 1.21  1993/08/24  10:17:58  dale
 * *** empty log message ***
 *
 * Revision 1.20  1993/08/24  02:08:33  dale
 * *** empty log message ***
 *
 * Revision 1.19  1993/07/23  07:33:00  dale
 * Adding interactive file I/O.
 *
 * Revision 1.18  1993/07/14  22:11:48  dale
 * *** empty log message ***
 *
 * Revision 1.17  1993/07/06  00:34:26  dale
 * *** empty log message ***
 *
 * Revision 1.16  1993/07/04  17:57:23  dale
 * *** empty log message ***
 *
 * Revision 1.15  1993/07/01  20:18:47  dale
 * *** empty log message ***
 *
 * Revision 1.14  1993/06/25  23:38:25  dale
 * *** empty log message ***
 *
 * Revision 1.13  1993/06/18  08:45:44  dale
 * *** empty log message ***
 *
 * Revision 1.12  1993/06/16  07:45:38  dale
 * Fixed close selection problem with custom groove sliders (message sent to freed object).
 *
 * Revision 1.11  1993/06/11  08:38:39  dale
 * Incorporated GroovePalette for soft function activation.
 *
 * Revision 1.10  1993/06/07  08:11:40  dale
 * Initial attempt made at getting left holophrasts working throughout the system.
 *
 * Revision 1.9  1993/06/05  07:37:08  dale
 * *** empty log message ***
 *
 * Revision 1.8  1993/06/04  20:57:48  dale
 * *** empty log message ***
 *
 * Revision 1.7  1993/06/04  07:18:00  dale
 * *** empty log message ***
 *
 * Revision 1.6  1993/06/03  00:37:58  dale
 * *** empty log message ***
 *
 * Revision 1.5  1993/06/01  08:03:24  dale
 * *** empty log message ***
 *
 * Revision 1.4  1993/05/30  08:24:27  dale
 * *** empty log message ***
 *
 * Revision 1.3  1993/05/27  00:16:28  dale
 * Adjusted setFilesOwnerOutlet... methods to reflect new interface. Added -softFunctionActive/Select
 * methods to handle soft function slider activity. Added utility method to filter control characters
 * from text buffers passed as arguments.
 *
 * Revision 1.2  1993/05/20  19:24:41  dale
 * Fixed problems with messages sent to FREED objects, and temporary appearance of UNTITLED%d in the
 * window title bar.
 *
 * Revision 1.1  1993/05/20  06:03:35  dale
 * Initial revision
 *
 */

#import <tabletkit/tabletkit.h>
#import <grooveslider/GrooveSlider.h>
#import "Publisher.tproj.h"
#import "TabletSurface.h"
#import "TabletRegion.h"
#import "TabletGroove.h"
#import "EnglishConstruct.h"
#import "TouchNTalk.h"
#import "TactileDisplay.h"
#import "SIL.h"
#import "SILText.h"
#import "SILSpeaker.h"
#import "FileListing.h"
#import "TNTControl.h"
#import "DSPTone.h"

/* Newline sound. */
#define NEWLINE_SOUND  "Basso"

@implementation TNTControl


/* INITIALIZING AND FREEING *************************************************************************/


- init
{
    [super init];

    // Get shared instances of open and save panel. We will use the -directory and -setDirectory
    // methods to synchronize default directories for document open/save requests with the NeXTSTEP 
    // and TouchNTalk interfaces.

    openPanel = [OpenPanel new];
    savePanel = [SavePanel new];

    // init document settings
    speechMode = ST_SPEAK;
    activeHoloSet = TNT_HOLO_SET1;

    previousOperationMode = operationMode = TNT_NORMAL;
    lastActivePageLine = lastActivePageCol = MAXINT;
    lastWord[0] = (char)0;
    newlineSound = [Sound findSoundFor:NEWLINE_SOUND];
    return self;
}

/* This is called when all controls have finished loading and have initialized themselves. We
 * set up the required singleClick, doubleClick, and mouseUp targets and actions for the 
 * grooveSliders used in the window. The active page target/actions are initialized whenever the 
 * window becomes main. Returns self.
 */
- initTargetAction
{
    // init all groove sliders except soft function slider
    [tactileDisplay initTargetAction];

    // set SIL text target/actions (subclass of ActionText)
    [self setSILTextTargetActions];

    return self;
}

- free
{
    return [super free];
}


/* WINDOW DELEGATE METHODS **************************************************************************/


/* Before speaking that the window did become active we check if it was already active, so that we do
 * not speak this message when TouchNTalk is activated after another application was previously 
 * active. In this case, the active window REALLY did not change (within TouchNTalk of course). Note 
 * that documents that are resident on disk have pathnames and filenames. New documents that are not 
 * resident on disk only have filenames. Control documents (used for file selection) have neither a 
 * pathname, or a filename. This is how the different document types can be distinguished. Returns 
 * self.
 */
- windowDidBecomeMain:sender
{
    const char *windowName;
    id topHolo = [[filesOwner tabletSurface] topHolo];

    // speak window name only if we are different from the previous TNTControl AND the tablet is not
    // currently being configured

    if ([filesOwner previousTNTControl] != self && ![filesOwner configuringTablet]) {

	// update system interaction line (SIL)
	if (windowName = [[tactileDisplay document] pathname]) {
	    sprintf(buffer, "Active window is %s.", windowName);
	} else if (windowName = [[tactileDisplay document] filename]) {
	    sprintf(buffer, "Active window is %s.", windowName);
	} else {   // use window title
	    sprintf(buffer, "Active window is %s.", [window title]);
	}
	[sil setTextNoEraseSIL:buffer];

	// update the speech mode soft function display title
	if (speechMode == ST_SPEAK) {
	    [[filesOwner speechModeTitle] setStringValue:"Speak\nMode"];
	} else if (speechMode == ST_SPELL) {
	    [[filesOwner speechModeTitle] setStringValue:"Spell\nMode"];
	}

	// update the holoset soft function display title
	if (activeHoloSet == TNT_HOLO_SET1) {
	    [[filesOwner holoSetTitle] setStringValue:"Holo\nSet 1"];
	} else if (activeHoloSet == TNT_HOLO_SET2) {
	    [[filesOwner holoSetTitle] setStringValue:"Holo\nSet 2"];
	}

	// set files's owner outlets to appropriate window controls
	[self setFilesOwnerOutlets];

	// set previousTNTControl outlet
	[filesOwner setPreviousTNTControl:self];
    } 

    // set active page target/actions for new main window
    [self setActivePageTargetActions];

    // set number of partitions in page locator and bookmark holo grooves for tablet
    [[topHolo grooveAt:TNT_PAGE_LOCATOR-1] setPartitions:[[tactileDisplay document] pages]];
    [[topHolo grooveAt:TNT_BOOKMARK_HOLO-1] setPartitions:[[tactileDisplay document] pages]];
    return self;
}

/* NOT USED. */
- windowDidBecomeKey:sender
{
    return self;
}

/* Note that documents that are resident on disk have pathnames and filenames. New documents that are
 * not resident on disk only have filenames. Control documents (used for file selection for example) 
 * have neither a pathname, or a filename. This is how the different document types can be 
 * distinguished. Thus, if the document does not have a filename or pathname, then we know it is a 
 * control document, and we don't want to speak a message saying the document was closed since
 * another message is spoken when this happens, namely, that the operation that created the document 
 * was cancelled. This applies to file selection, opening files, and help. Also note that if the 
 * tablet is currently being configured, then we do not allow the window to close and we return nil, 
 * otherwise we return self.
 */
- windowWillClose:sender
{
    const char *windowName;

    if ([filesOwner configuringTablet]) {   // don't close window if configuring the tablet.
	NXBeep();
	return nil;
    }

    if (operationMode == TNT_WINDOWS) {   // document selection window closing (free docWindowList)
	[[filesOwner docWindowList] free];
	[filesOwner setDocWindowList:nil];
    } else if (operationMode == TNT_OPEN || operationMode == TNT_SAVE) {   // open document window
	[[[filesOwner fileListingTable] freeObjects] free];                // closing (free table)
	[filesOwner setFileListingTable:nil];
    }

    // set file's owner handles to the window controls to nil
    [self clearFilesOwnerOutlets];

    // Since window will close set up to reflect the non-existent window. This is required if we
    // wish to perform the required initialization when the window becomes main for the open and
    // document selection windows. This is also a safety precaution.
    [filesOwner setPreviousTNTControl:nil];
    [filesOwner setTNTControl:nil];

    // update system interaction line (SIL)
    if (windowName = [[tactileDisplay document] pathname]) {
	sprintf(buffer, "Closed window %s.", windowName);
	[sil setTextNoDisplayNoErase:buffer];
    } else if (windowName = [[tactileDisplay document] filename]) {
	sprintf(buffer, "Closed window %s.", windowName);
	[sil setTextNoDisplayNoErase:buffer];
    }
    [sender setDelegate:nil];
    [self free];                // erase instance
    return self;                // window WILL free itself on close
}

/* We close the window if it is operating in any of the modes indicated below. There cannot exist
 * multiple occurrences of windows operating in these modes, and therefore we close the respective 
 * window if another window is activated. In this sense, these modes are considered to be "modal" as
 * in the NeXTSTEP open and save panels. In the case of TNT_WINDOWS, the docWindowList is freed. In 
 * the case of TNT_OPEN or TNT_SAVE the fileListingTable is freed as well as all fileListing objects 
 * it contains. Note that we must clear the active page target/actions since the window is about to 
 * resign main status. If the mouse is currently in the active page area then NOT doing this could 
 * cause messages to be sent to objects in other windows or freed objects if the window was closed. 
 * Key words: control document.
 */
- windowDidResignMain:sender
{
    // clear active page target/actions
    [self clearActivePageTargetActions];

    if (operationMode == TNT_WINDOWS) {
	[[filesOwner docWindowList] free];
	[filesOwner setDocWindowList:nil];
	[window performClose:sender];
    } else if (operationMode == TNT_OPEN || operationMode == TNT_SAVE) {
	[[[filesOwner fileListingTable] freeObjects] free];
	[filesOwner setFileListingTable:nil];
	[window performClose:sender];
    }
    return self;
}

/* NOT USED. */
- windowDidResignKey:sender
{
    return self;
}


/* FIRST RESPONDER METHODS **************************************************************************/


/* Not Implemented. */
- save:sender
{
    return self;
}

/* Not Implemented. */
- saveAs:sender
{
    return self;
}

/* Prints the active document by bringing up the standard print panel. Returns self. */
- print:sender
{
    [[[tactileDisplay document] activePage] printPSCode:nil];
    return self;
}


/* QUERY METHODS ************************************************************************************/


- window
{
    return window;
}

- (int)activeHoloSet
{
    return activeHoloSet;
}

- (int)speechMode
{
    return speechMode;
}

- (int)operationMode
{
    return operationMode;
}

- tactileDisplay
{
    return tactileDisplay;
}

- sil
{
    return sil;
}

- (int)windowEventMask
{
    return windowEventMask;
}

/* This method is used to retrieve the previous operation mode when the current operation mode
 * operates WITHIN the current window, such as TNT_CONFIGURE, or TNT_LOCATOR. When these modes 
 * complete, we must return to the mode that was previously active. The mode is set through the
 * -setPreviousOperationMode: method.
 */
- (int)previousOperationMode
{
    return previousOperationMode;
}

- windowContentView
{
    return windowContentView;
}

- (char *)lastWord
{
    return lastWord;
}


/* SET METHODS **************************************************************************************/


- setOperationMode:(int)opMode
{

    // previousOperationMode should never be equal to TNT_LOCATE since this is a temporary mode within
    // an existing document. All other modes are actual document modes.
    if (opMode != TNT_LOCATE) {   
	previousOperationMode = operationMode;
    }
    operationMode = opMode;
    return self;
}

/* Holds the event mask for the display window when the tablet is being configured. This is required
 * since we disable all events for all display windows so that they cannot be activated. We store the
 * existing event masks for restoration when tablet configuration is complete. Returns self.
 */
- setWindowEventMask:(int)eventMask
{
    windowEventMask = eventMask;
    return self;
}

- setPreviousOperationMode:(int)opMode
{
    previousOperationMode = opMode;
    return self;
}

- setWindowContentView:contentView
{
    windowContentView = contentView;
    return self;
}

- setSpeechMode:(int)spMode
{
    speechMode = spMode;
    [[tactileDisplay activePage] setSpeechMode:spMode];
    return self;
}

- setActiveHoloSet:(int)holoSet
{
    activeHoloSet = holoSet;
    return self;
}

/* ACTIVE PAGE ACTION METHODS ***********************************************************************/


/* Need to initialize lastActivePageLine and lastActivePageCol and then manually call drag action. */
- activePageMouseDown:sender
{
    lastActivePageLine = lastActivePageCol = MAXINT;
    return [self activePageDrag:sender];
}

/* This method is called so frequently that we make the local variables static. It would probably be
 * quite useful to optimize this method somewhat. Returns self.
 */
- activePageDrag:sender
{
    static id activePage, document, tone;
    static int position, start, length;    // pos. of user cursor, start pos. and length of word found
    static int ucLine, ucColumn;           // line and column of user cursor
    static int linePosition;               // start position of user cursor line
    static char word[MAXPATHLEN];          // current word for speaking

    static int columnDistance;             // column distance between system and user cursor
    float pitch, newVolume, baseVolume = [[NXApp delegate] baseVolume];

    // init local variables
    activePage = [tactileDisplay activePage];
    ucLine = [activePage userCursorLine];
    ucColumn = [activePage userCursorCol];
    document = [tactileDisplay document];
    tone = [tactileDisplay tone];

    // current line and columns same as last line and column -- ignore drag
    if (ucLine == lastActivePageLine && ucColumn == lastActivePageCol) {
	return self;
    }
    lastActivePageLine = ucLine;
    lastActivePageCol = ucColumn;

    // check the operation mode (locate cursor?)
    if (operationMode == TNT_LOCATE) {
	if (ucLine != [document systemCursorLine]) {   // system cursor is not on current line
	    operationMode = previousOperationMode;   // cancel cursor location mode
	    [tone stopTone];
	    return self;
	}

	// play locator tone if it's not already playing (should be though)
	[tactileDisplay playLocatorTone];

	// get column distance to system cursor from current column in document
	columnDistance = ABS([document systemCursorCol] - [activePage userCursorCol]);

	// Set volume according to pitch of tone (variable volume). When the tone has high pitch we
	// decrease the volume since it "seems" to get louder. We adjust the new volume if it has gone
	// based the lower and upper volume bounds indicated by TNT_VOLUME_VARIATION.
	newVolume = baseVolume - TNT_VOLUME_VARIATION * 
	    (columnDistance / (TNT_PITCH_MAX - TNT_PITCH_MIN));
	if (newVolume < baseVolume - TNT_VOLUME_VARIATION) {
	    newVolume = baseVolume - TNT_VOLUME_VARIATION;
	} else if (newVolume > baseVolume) {
	    newVolume = baseVolume;
	}
	[(DSPTone *)[tactileDisplay tone] setVolume:newVolume];

	// get and play tone based on distance
	pitch = TNT_PITCH_MIN + columnDistance - 1.0;
	if (pitch < TNT_PITCH_MIN) {   // cursor outside range
	    [(DSPTone *)tone setVolume:0];
	} else if (pitch > TNT_PITCH_MAX) {   // cursor outside range
	    [tone setPitch:TNT_PITCH_MAX];	
	} else {   // user cursor within range of system cursor
	    [tone setPitch:pitch];
	}
    }

    // init additional local variables (not locating system cursor)
    linePosition = [activePage positionFromLine:ucLine];
    position = linePosition + [activePage userCursorCol] - 1;

    // Check if position of user cursor is beyond the end of the line (newline). If not, then we
    // can safely search for a word on the current line under the user cursor. If we do not find
    // one, then we are on whitespace or no delimiting whitespace was found.

    if (position > [activePage positionFromLine:ucLine+1] - 1) {   // beyond end of line
	lastWord[0] = (char)0;
    } else if (position == [activePage positionFromLine:ucLine+1] - 1) {   // at end of line
	[(Sound *)newlineSound play];
	lastWord[0] = (char)0;
    } else if ([activePage wordAtPosition:position start:&start length:&length]) {   // word found
	if (length >= MAXPATHLEN) {   // word does not fit in local buffer
	    length = MAXPATHLEN-1;
	    NXLogError("Maximum word length of %d surpassed -- truncating.", MAXPATHLEN-1);
	}
	[activePage getSubstring:word start:start length:length];
	word[length] = (char)0;
	if (strcmp(word, lastWord)) {   // only speak if different from last word
	    [(Page *)activePage speakText:word];
	    strcpy(lastWord, word);
	}
    } else if ([activePage wordAtPosition:position-1 start:&start length:&length] ||
	       [activePage wordAtPosition:position+1 start:&start length:&length]) {   // delimiting
	NXBeep();                                                                      // spaces only
	lastWord[0] = (char)0;	
    } else {   // no word under user cursor (embedded space)
	lastWord[0] = (char)0;
    }
    return self;
}

/* This method speaks the word in the tactile display the user cursor is currently on top of. If
 * the user cursor is currently on white space, beeps instead. Note, if the system is currently in
 * TNT_LOCATE mode, then we swap the system cursor and mark instead. Returns self. 
 */
- activePageSelect:sender
{
    id activePage = [tactileDisplay activePage];

    // swap system and mark cursors, and beep
    if (operationMode == TNT_LOCATE && [tactileDisplay userCursorAtSystemCursor]) {
	[[tactileDisplay tone] stopTone];   // stop the tone so SIL message can be heard
	[tactileDisplay swapCursors];
	operationMode = previousOperationMode;
	return self;
    }

    // speak the word under user cursor; if there is none beep
    if (lastWord[0]) {   // only speak if lastWord exists
	[(Page *)activePage speakText:lastWord];
    } else {   // lastWord does not exist
	NXBeep();
    }
    return self;
}

/* This method has different effects depending on the current mode. If the current mode is TNT_NORMAL,
 * then a double click in the active page will cause the system cursor to be moved to the user cursor
 * If the current mode is TNT_WINDOWS, then the window identified by the title at which the double 
 * click occurred is selected. If the current mode is TNT_OPEN or TNT_SAVE, then the directory or file
 * name where the double clicked occurred is ascended/descended into or opened appropriately. Meanings
 * of double clicks in TNT_HELP mode has not yet been established. Returns self.
 */
- activePageDoubleSelect:sender
{
    id fileListing;
    int ucLine;

    switch (operationMode) {
      case TNT_NORMAL:
      case TNT_SHELL:
	[tactileDisplay repositionCursors];
	break;

      case TNT_OPEN:
	ucLine = [sender userCursorLine];
	if (ucLine == 1) {   // possibly enter a directory in the directory path
	    // handle selection of individual words (directories) in path
	    [self enterDirectoryInDisplayPathSel];
	} else if (fileListing = 
		   [[filesOwner fileListingTable] valueForKey:(const void *)ucLine]) {  // key found
	    // either open a new directory or a file
	    [filesOwner processFileListingSel:fileListing];
	}
	break;

      case TNT_WINDOWS:
	ucLine = [sender userCursorLine];
	if (ucLine > 2 && ucLine <= [[filesOwner docWindowList] count] + 2) {
	    // valid document window selection
	    [[[filesOwner docWindowList] objectAt:ucLine - 3] makeKeyAndOrderFront:nil];
	    return self;
	}
	break;

      case TNT_SAVE:
	break;

      case TNT_HELP:
	break;

      case TNT_LOCATE:
	break;
	
      default:
	break;
    }
    return self;
}

- activePageMouseUp:sender
{
    // stop all music
    [[tactileDisplay tone] stopTone];
    lastWord[0] = (char)0;
    lastActivePageLine = lastActivePageCol = MAXINT;
    if (operationMode == TNT_LOCATE) {
	operationMode = previousOperationMode;
    }
    return self;
}


/* SIL ACTION METHODS *******************************************************************************/


/* Not used. */
- silMouseDown:sender
{
    return self;
}

/* This method is similar to -activePageDrag: except that all occurrences of activePage have been
 * replaced with silText, and we do not consider any cursor location. Returns self.
 */
- silDrag:sender
{
    id silText;
    int position, start, length;       // position of user cursor, start pos. and length of word found
    int ucLine, linePosition;          // line of user cursor, and start position of line
    static char word[MAXPATHLEN];      // current word for speaking

    // init local vars
    silText = [sil silText];
    ucLine = 1;
    linePosition = 0;
    position = [silText userCursorCol] - 1;

    // Check if position of user cursor is beyond the end of the line. If not, then we can safely 
    // search for a word on the current line under the user cursor. If we do not find one, then we 
    // are on whitespace or no delimiting whitespace was found.

    if (position > [silText textLength]) {   // beyond end of line
	lastWord[0] = (char)0;

    } else if (position == [silText textLength]) {
	[(Sound *)newlineSound play];
	lastWord[0] = (char)0;
    } else if ([silText wordAtPosition:position start:&start length:&length]) {   // word found
	if (length >= MAXPATHLEN) {   // word does not fit in local buffer
	    length = MAXPATHLEN-1;
	    NXLogError("Maximum word length of %d surpassed -- truncating.", MAXPATHLEN-1);
	}
	[silText getSubstring:word start:start length:length];
	word[length] = (char)0;
	if (strcmp(word, lastWord)) {   // only speak if different from last word
	    [(SILText *)silText speakText:word];
	    strcpy(lastWord, word);
	}
    } else if ([silText wordAtPosition:position-1 start:&start length:&length] ||
	       [silText wordAtPosition:position+1 start:&start length:&length]) {   // delimiting
	NXBeep();                                                                   // spaces only
	lastWord[0] = (char)0;	
    } else {   // no word under user cursor (embedded space)
	lastWord[0] = (char)0;
    }
    return self;
}

/* This method speaks the word in the SIL the user cursor is currently on top of. If the user cursor 
 * is currently on white space, beeps instead. Returns self. 
 */
- silSelect:sender
{
    id silText = [sil silText];

    if (lastWord[0]) {   // only speak if lastWord exists
	[(SILText *)silText speakText:lastWord];
    } else {   // lastWord does not exist
	NXBeep();
    }
    return self;
}

/* Double selecting on the SIL causes the entire CURRENT contents of the SIL to be spoken. This is 
 * useful since there is currently no facility for scrolling the SIL in the event system information 
 * scrolls off the end of the SIL. Returns self.
 */
- silDoubleSelect:sender
{
    id silText = [sil silText];

    [silText getSubstring:buffer start:0 length:MAXPATHLEN];
    [(SILText *)silText speakText:buffer];
    return self;
}

- silMouseUp:sender
{
    lastWord[0] = (char)0;
    return self;
}


/* FILES' OWNER OUTLET MANAGEMENT METHODS ***********************************************************/


/* We require that the files's owner has update handles to all controls and the TNTControl in order
 * that the server methods within TouchNTalk (subclass of TNTServer) invoke the controls in the
 * correct window. Returns self.
 */
- setFilesOwnerOutlets
{
    // set button outlets
    [filesOwner setPrevPageButton:prevPageButton];
    [filesOwner setNextPageButton:nextPageButton];

    // set slider outlets
    [filesOwner setPageLocatorSlider:pageLocatorSlider];
    [filesOwner setBookmarkHoloSlider:bookmarkHoloSlider];
    [filesOwner setHorizPageScrollSlider:horizPageScrollSlider];
    [filesOwner setVertPageScrollSlider:vertPageScrollSlider];
    [filesOwner setCursorLocatorSlider:cursorLocatorSlider];
    [filesOwner setLeftHolo1Slider:leftHolo1Slider];
    [filesOwner setLeftHolo2Slider:leftHolo2Slider];
    [filesOwner setLeftHolo3Slider:leftHolo3Slider];
    [filesOwner setLeftHolo4Slider:leftHolo4Slider];

    // set custom view outlets
    [filesOwner setTactileDisplay:tactileDisplay];
    [filesOwner setSil:sil];

    // set tntControl
    [filesOwner setTNTControl:self];
    return self;
}

/* Make the files's owner's handles to all controls equal to nil. This would be called when a window
 * is about to close, and we don't want the file's owner messaging a freed object. Returns self.
 */
- clearFilesOwnerOutlets
{
    // set button outlets
    [filesOwner setPrevPageButton:nil];
    [filesOwner setNextPageButton:nil];

    // set slider outlets
    [filesOwner setPageLocatorSlider:nil];
    [filesOwner setBookmarkHoloSlider:nil];
    [filesOwner setHorizPageScrollSlider:nil];
    [filesOwner setVertPageScrollSlider:nil];
    [filesOwner setCursorLocatorSlider:nil];
    [filesOwner setLeftHolo1Slider:nil];
    [filesOwner setLeftHolo2Slider:nil];
    [filesOwner setLeftHolo3Slider:nil];
    [filesOwner setLeftHolo4Slider:nil];

    // set custom view outlets
    [filesOwner setTactileDisplay:nil];
    [filesOwner setSil:nil];

    // set tntControl
    [filesOwner setTNTControl:nil];
    return self;
}


/* ACTIVE PAGE TARGET/ACTION METHODS ****************************************************************/


/* Sets all active page target/actions to their appropriate values. Returns self. */
- setActivePageTargetActions
{
    id activePage = [tactileDisplay activePage];

    [activePage setMouseDownTarget:self action:@selector(activePageMouseDown:)];
    [activePage setMouseDragTarget:self action:@selector(activePageDrag:)];
    [activePage setMouseUpTarget:self action:@selector(activePageMouseUp:)];
    [activePage setSingleClickTarget:self action:@selector(activePageSelect:)];
    [activePage setDoubleClickTarget:self action:@selector(activePageDoubleSelect:)];
    return self;
}

/* Only invoke when ALL active page target/actions should be cleared. Returns self. */
- clearActivePageTargetActions
{
    id activePage = [tactileDisplay activePage];

    [activePage setMouseDownTarget:nil action:(SEL)0];
    [activePage setMouseDragTarget:nil action:(SEL)0];
    [activePage setMouseUpTarget:nil action:(SEL)0];
    [activePage setSingleClickTarget:nil action:(SEL)0];
    [activePage setDoubleClickTarget:nil action:(SEL)0];
    return self;
}


/* SIL TEXT TARGET/ACTION METHODS *******************************************************************/


/* Sets all SIL text target/actions to their appropriate values. Returns self. */
- setSILTextTargetActions
{
    id silText = [sil silText];

    [silText setMouseDownTarget:self action:@selector(silDrag:)];
    [silText setMouseDragTarget:self action:@selector(silDrag:)];
    [silText setMouseUpTarget:self action:@selector(silMouseUp:)];
    [silText setSingleClickTarget:self action:@selector(silSelect:)];
    [silText setDoubleClickTarget:self action:@selector(silDoubleSelect:)];
    return self;
}

/* Only invoke when ALL SIL text target/actions should be cleared. Returns self. */
- clearSILTextTargetActions
{
    id silText = [sil silText];

    [silText setMouseDownTarget:nil action:(SEL)0];
    [silText setMouseDragTarget:nil action:(SEL)0];
    [silText setMouseUpTarget:nil action:(SEL)0];
    [silText setSingleClickTarget:nil action:(SEL)0];
    [silText setDoubleClickTarget:nil action:(SEL)0];
    return self;
}


/* VISUALLY IMPAIRED FILE BROWSING METHODS **********************************************************/


/* Enters the directory in the path (word corresponding to the directory) that was selected. We 
 * use location of the user cursor and the last word spoken to determine the directory name. We then 
 * open that directory with the help of the open panel in order to find the prefix of the first part 
 * of the path as exists in the open panel. Recall that the current open panel directory path is made
 * to be synchronous with that appearing in the open document display window. Returns self.
 */
- enterDirectoryInDisplayPathSel
{
    id activePage = [tactileDisplay activePage];
    char dirPath[MAXPATHLEN+32];
    int i, lineLength, ucCol = [activePage userCursorCol];

    // current directory path begins at column 26
    if (ucCol < 25 || lastWord[0] == (char)0) {   // not on a word in the path
	return self;
    }

    // get text of entire first line of active page
    lineLength = [activePage positionFromLine:2];
    [activePage getSubstring:dirPath start:0 length:lineLength-1];
    dirPath[lineLength-1] = (char)0;   // replace last char == newline with NULL character

    // find end of word user cursor is on, and NULL terminate
    for (i = ucCol; dirPath[i] != ' '; i++)
	;
    dirPath[i] = (char)0;

    // remove prefixed title, replace spaces with '/', and synchronize with openPanel directory
    strcpy(dirPath, &dirPath[23]);
    [filesOwner replaceChar:' ' withChar:'/' inString:dirPath];
    [openPanel setDirectory:dirPath];

    if (![filesOwner displayDirectoryListing:dirPath forNewWindow:NO]) {   // unable to display 
	NXBeep();                                                          // directory listing
	[sil setText:"Unable to open selected directory."];
    } else {
	sprintf(buffer, "Current directory is %s.", lastWord);
	[sil setText:buffer];
    }
    return self;
}

@end

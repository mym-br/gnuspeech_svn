/*
 *    Filename:	TNTControl.h 
 *    Created :	Tue May 18 13:59:43 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Fri Jul  1 10:23:12 1994"
 *
 * $Id: TNTControl.h,v 1.24 1994/07/25 02:30:52 dale Exp $
 *
 * $Log: TNTControl.h,v $
 * Revision 1.24  1994/07/25  02:30:52  dale
 * *** empty log message ***
 *
 * Revision 1.23  1994/06/30  09:06:03  dale
 * Fixed bug when dragging on active page of open document.
 *
 * Revision 1.22  1994/06/29  22:39:07  dale
 * *** empty log message ***
 *
 * Revision 1.21  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.20  1994/06/03  08:03:28  dale
 * Fixed speech mode and holo set so they work on a per document basis. Other minor fixes.
 *
 * Revision 1.19  1994/06/01  19:13:28  dale
 * Moved soft function related methods into TouchNTalk class.
 *
 * Revision 1.18  1994/05/30  19:18:08  dale
 * *** empty log message ***
 *
 * Revision 1.17  1993/08/27  03:51:06  dale
 * Added functionality to handle configuration of the tablet.
 *
 * Revision 1.16  1993/08/24  02:08:33  dale
 * *** empty log message ***
 *
 * Revision 1.15  1993/07/23  07:33:00  dale
 * Adding interactive file I/O.
 *
 * Revision 1.14  1993/07/14  22:11:48  dale
 * *** empty log message ***
 *
 * Revision 1.13  1993/07/06  00:34:26  dale
 * *** empty log message ***
 *
 * Revision 1.12  1993/07/04  17:57:23  dale
 * *** empty log message ***
 *
 * Revision 1.11  1993/06/18  08:45:44  dale
 * *** empty log message ***
 *
 * Revision 1.10  1993/06/16  07:45:38  dale
 * Fixed close selection problem with custom groove sliders (message sent to freed object).
 *
 * Revision 1.9  1993/06/11  08:38:39  dale
 * Incorporated GroovePalette for soft function activation.
 *
 * Revision 1.8  1993/06/05  07:37:08  dale
 * *** empty log message ***
 *
 * Revision 1.7  1993/06/04  20:57:48  dale
 * *** empty log message ***
 *
 * Revision 1.6  1993/06/04  07:18:00  dale
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
 * Added title and slider button instance variables. Also added utility filter method.
 *
 * Revision 1.1  1993/05/20  06:03:35  dale
 * Initial revision
 *
 */

#import <appkit/appkit.h>

@interface TNTControl:Object
{
    id filesOwner;                 // IB outlet to File's Owner
    id window;                     // IB Outlet
    id openPanel;                  // shared open panel instance
    id savePanel;                  // shared save panel instance
    char buffer[MAXPATHLEN+128];   // utility buffer (used for SIL, invoking shell commands, etc.)

    // interface state information
    id windowContentView;          // the windows content view
    int operationMode;             // current TNT operation mode
    int windowEventMask;           // holds window event mask when tablet is being configured
    int previousOperationMode;     // holds the previous operation mode (in configure & locator modes)
    int lastActivePageLine;        // holds the last encountered line in the active page
    int lastActivePageCol;         // holds the last encountered column in the active page
    char lastWord[MAXPATHLEN];     // last word dragged on in tactile display or SIL
    int speechMode;                // current speech mode (speak/spell)
    int activeHoloSet;             // current active holoset

    // end of line sound
    id newlineSound;             

    // IB outlet interface controls
    id prevPageButton;
    id nextPageButton;

    id leftHolo1Slider;
    id leftHolo2Slider;
    id leftHolo3Slider;
    id leftHolo4Slider;

    id pageLocatorSlider;
    id bookmarkHoloSlider;
    id horizPageScrollSlider;
    id vertPageScrollSlider;
    id cursorLocatorSlider; 

    id tactileDisplay;      
    id sil;                 
}

/* INITIALIZING AND FREEING */
- init;
- initTargetAction;
- free;

/* WINDOW DELEGATE METHODS */
- windowDidBecomeMain:sender;
- windowWillClose:sender;
- windowDidResignMain:sender;
- windowDidBecomeKey:sender;
- windowDidResignKey:sender;

/* FIRST RESPONDER METHODS */
- save:sender;
- saveAs:sender;
- print:sender;

/* QUERY METHODS */
- window;
- tactileDisplay;
- sil;
- (int)activeHoloSet;
- (int)speechMode;
- (int)operationMode;
- (int)windowEventMask;
- (int)previousOperationMode;
- windowContentView;
- (char *)lastWord;

/* SET METHODS */
- setOperationMode:(int)opMode;
- setWindowEventMask:(int)eventMask;
- setPreviousOperationMode:(int)opMode;
- setWindowContentView:contentView;
- setSpeechMode:(int)spMode;
- setActiveHoloSet:(int)holoSet;

/* ACTIVE PAGE ACTION METHODS */
- activePageMouseDown:sender;
- activePageDrag:sender;
- activePageSelect:sender;
- activePageDoubleSelect:sender;
- activePageMouseUp:sender;

/* SIL ACTION METHODS */
- silMouseDown:sender;
- silDrag:sender;
- silSelect:sender;
- silDoubleSelect:sender;
- silMouseUp:sender;

/* FILES' OWNER OUTLET MANAGEMENT METHODS */
- setFilesOwnerOutlets;
- clearFilesOwnerOutlets;

/* ACTIVE PAGE TARGET/ACTION METHODS */
- setActivePageTargetActions;
- clearActivePageTargetActions;

/* VISUALLY IMPAIRED FILE BROWSING METHODS */
- enterDirectoryInDisplayPathSel;

/* SIL TEXT TARGET/ACTION METHODS */
- setSILTextTargetActions;
- clearSILTextTargetActions;

@end

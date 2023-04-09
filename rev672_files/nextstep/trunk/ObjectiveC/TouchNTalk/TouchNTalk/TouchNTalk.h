/*
 *    Filename:	TouchNTalk.h 
 *    Created :	Wed May 12 22:45:01 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Tue Oct 18 16:48:02 1994"
 *
 * $Id: TouchNTalk.h,v 1.28 1994/10/19 00:02:05 dale Exp $
 *
 * $Log: TouchNTalk.h,v $
 * Revision 1.28  1994/10/19  00:02:05  dale
 * Added IB outlet for tty device selection. Also added code to write the device used as a default.
 *
 * Revision 1.27  1994/09/11  17:46:11  dale
 * Removed references to Publisher and replaced with messages to Document since all functionality now
 * in Document. This is better OO design since everything applies to a document.
 *
 * Revision 1.26  1994/07/25  02:30:52  dale
 * *** empty log message ***
 *
 * Revision 1.25  1994/06/15  19:32:35  dale
 * When configuring tablet windows no longer disabled, only soft function is disabled.
 *
 * Revision 1.24  1994/06/10  20:18:28  dale
 * *** empty log message ***
 *
 * Revision 1.23  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.22  1994/06/03  08:03:28  dale
 * Fixed dynamic publish problem that occurred with new interface. Also fixed problem in soft function
 * groove that caused all the functions to stop working when all windows were closed. Added code to
 * properly handle appearance of document selection window ONLY when non-control documents are
 * present. Various other minor fixes.
 *
 * Revision 1.21  1994/06/01  19:13:28  dale
 * Moved soft function related methods from TNTControl class to here since
 * soft function should not be part of a document. This also reflects the
 * new interface with a separate soft function panel.
 *
 * Revision 1.20  1994/05/30  19:18:28  dale
 * *** empty log message ***
 *
 * Revision 1.19  1994/05/28  21:24:37  dale
 * *** empty log message ***
 *
 * Revision 1.18  1993/10/10  20:58:14  dale
 * *** empty log message ***
 *
 * Revision 1.17  1993/09/04  17:49:22  dale
 * *** empty log message ***
 *
 * Revision 1.16  1993/08/31  04:51:27  dale
 * *** empty log message ***
 *
 * Revision 1.15  1993/08/27  08:08:08  dale
 * Added code to handle multiple documents opened when tablet needs to be configured in -appDidInit:.
 *
 * Revision 1.14  1993/08/27  03:51:06  dale
 * Added methods to handle disabling windows and menu items.
 *
 * Revision 1.13  1993/08/24  02:08:33  dale
 * *** empty log message ***
 *
 * Revision 1.12  1993/07/23  07:33:00  dale
 * *** empty log message ***
 *
 * Revision 1.11  1993/07/14  22:11:48  dale
 * *** empty log message ***
 *
 * Revision 1.10  1993/07/06  00:34:26  dale
 * *** empty log message ***
 *
 * Revision 1.9  1993/07/04  17:57:23  dale
 * *** empty log message ***
 *
 * Revision 1.8  1993/07/01  20:18:47  dale
 * *** empty log message ***
 *
 * Revision 1.7  1993/06/18  08:45:44  dale
 * *** empty log message ***
 *
 * Revision 1.6  1993/06/16  07:45:38  dale
 * Removed interface buttons.
 *
 * Revision 1.5  1993/06/04  20:57:48  dale
 * *** empty log message ***
 *
 * Revision 1.4  1993/06/03  00:37:58  dale
 * *** empty log message ***
 *
 * Revision 1.3  1993/05/30  08:24:27  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/05/27  00:16:28  dale
 * Added set methods to deal with new interface.
 *
 * Revision 1.1  1993/05/20  19:44:30  dale
 * Initial revision
 *
 */

#import <appkit/appkit.h>
#import "TNTServer.h"

@interface TouchNTalk:TNTServer
{
    id documentSubmenuCell;        // IB Outlet (?)
    id openCell;                   // IB Outlet
    id newCell;                    // IB Outlet
    id saveCell;                   // IB Outlet (later editing facility)
    id saveAsCell;                 // IB Outlet (later editing facility)
    id saveAllCell;                // IB Outlet (later editing facility)
    id revertToSavedCell;          // IB Outlet (later editing facility)
    id closeCell;                  // IB Outlet (?)

    id fileListingTable;           // hashtable of FileListing instances for opening/saving files
    id docWindowList;              // list of document windows that can be selected

    id tabletDriver;               // instance of TabletDriver class
    id tabletSurface;              // instance of TabletSurface class in nib file
    id eventGenerator;             // instance of TNTEventGenerator class
    id gestureExpert;              // instance of GestureExpert class

    id openPanel;
    id savePanel;                  // later editing facility

    id tntControl;                 // IB outlet for current display control (loaded from nib file)
    id previousTNTControl;         // previously active TNTControl instance
    id silSpeaker;                 // shared instance of SILSpeaker class
    id activeSoftTitle;            // soft title currently active but unselected (colored black)
    int untitled;                  // keep track of number of untitled TNT windows
    BOOL configuringTablet;        // holds whether the tablet is currently being configured
    int lastLineWrapColumns;       // holds previous value of line wrap columns text field

    id volumeField;                // custom tone generation IB outlets
    id volumeSlider;
    id balanceField;
    id balanceSlider;
    id harmonicsField;
    id harmonicsSlider;
    id rampTimeField;
    id rampTimeSlider;

    id priorityText;               // application priority IB outlets
    id prioritySlider;

    id lineWrapSwitch;
    id lineWrapColumnsText;        // maximum columns in line

    id deviceRadioButtons;         // tty device preference radio buttons
}

/* CLASS INITIALIZATION */
+ initialize;

/* INITIALIZING AND FREEING */
- init;
- createTabletDriver:(const char *)deviceName;
- free;

/* APPLICATION DELEGATE METHODS */
- appDidInit:sender;
- (BOOL)appAcceptsAnotherFile:sender;
- (int)app:sender openFile:(const char *)filename type:(const char *)aType;
- appWillTerminate:sender;
- applicationDefined:(NXEvent *)theEvent;

/* FILE OPERATION METHODS */
- open:sender;
- new:sender;
- saveAll:sender;
- openFile:(const char *)aPathname;
- newFile:(const char *)aPathname;

/* CONTROL WINDOW DISPLAY METHODS */
- displayDocumentSelectionWindow;
- displayOpenDocumentWindow;
- displayDirectoryListing:(const char *)directoryPath forNewWindow:(BOOL)flag;

/* MENU UPDATE METHODS */
- (BOOL)menuActive:menuCell;
- (BOOL)saveMenuActive:menuCell;

/* TARGET/ACTION METHODS */
- speakInfoPanel:sender;
- configureCancel:sender;
- helpRequest:sender;

/* SET METHODS */
- setTNTControl:theControl;
- setPreviousTNTControl:theControl;
- setConfiguringTablet:(BOOL)flag;
- setFileListingTable:listTable;
- setDocWindowList:winList;

/* QUERY METHODS */
- tntControl;
- previousTNTControl;
- tabletSurface;
- tabletDriver;
- (BOOL)configuringTablet;
- fileListingTable;
- docWindowList;
- (float)baseVolume;

/* SOFT FUNCTION ACTION METHODS */
- softFunctionDown:sender;
- softFunctionActive:sender;
- softFunctionSelect:sender;
- softFunctionUp:sender;

/* SOFT FUNCTIONS */
- softHelp;
- softOpen;
- softSave;
- softClose;
- softPage;
- softShell;
- softWindows;
- softHoloSet;
- softSpeechMode;
- softConfigure;

/* SOFT FUNCTION TARGET/ACTION METHODS */
- setSoftFunctionTargetActions;
- clearSoftFunctionTargetActions;

/* DISABLING/ENABLING DISPLAY WINDOWS */
- disableDisplayWindows;
- reenableDisplayWindows;

/* VISUALLY IMPAIRED FILE PROCESSING METHODS */
- processFileListingSel:fileListing;

/* UTILITY METHODS */
- filterControlCharacters:(char *)aBuffer;
- (BOOL)isTNTDocument:(const char *)aPathname;
- replaceChar:(char)c1 withChar:(char)c2 inString:(char *)string;

/* TONE GENERATION METHODS */
- volumeChanged:sender;
- balanceChanged:sender;
- harmonicsChanged:sender;
- rampTimeChanged:sender;

/* TABLET SETTINGS */
- sendTabletCommands:sender;
- setTTYBaudRate:sender;
- setTaskPriority:sender;
- setEventCoalescing:sender;
- setLineWrapping:sender;
- setLineWrapColumns:sender;
- changeDevice:sender;

@end

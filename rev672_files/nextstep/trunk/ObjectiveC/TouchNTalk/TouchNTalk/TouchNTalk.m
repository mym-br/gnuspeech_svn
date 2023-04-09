/*
 *    Filename:	TouchNTalk.m 
 *    Created :	Wed May 12 22:45:07 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Sat Jan 21 14:41:07 1995"
 *
 * $Id: TouchNTalk.m,v 1.36 1995/01/21 22:48:01 dale Exp $
 *
 * $Log: TouchNTalk.m,v $
 * Revision 1.36  1995/01/21  22:48:01  dale
 * Moved TabletDriver instantiation to the appDidInit: method.
 *
 * Revision 1.35  1994/10/19  00:02:05  dale
 * Added IB outlet for tty device selection. Also added code to write the device used as a default.
 *
 * Revision 1.34  1994/09/11  17:46:11  dale
 * Removed references to Publisher and replaced with messages to Document since all functionality now
 * in Document. This is better OO design since everything applies to a document.
 *
 * Revision 1.33  1994/07/26  20:11:02  dale
 * *** empty log message ***
 *
 * Revision 1.32  1994/07/25  05:33:34  dale
 * Implemented help soft function and created help document.
 *
 * Revision 1.31  1994/07/25  02:30:52  dale
 * *** empty log message ***
 *
 * Revision 1.30  1994/06/15  19:32:35  dale
 * When configuring tablet windows no longer disabled, only soft function is disabled.
 *
 * Revision 1.29  1994/06/10  20:18:28  dale
 * *** empty log message ***
 *
 * Revision 1.28  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.27  1994/06/03  08:03:28  dale
 * Fixed dynamic publish problem that occurred with new interface. Also fixed problem in soft function
 * groove that caused all the functions to stop working when all windows were closed. Added code to
 * properly handle appearance of document selection window ONLY when non-control documents are
 * present. Various other minor fixes.
 *
 * Revision 1.26  1994/06/01  19:13:28  dale
 * Moved soft function related methods from TNTControl class to here since
 * soft function should not be part of a document. This also reflects the
 * new interface with a separate soft function panel.
 *
 * Revision 1.25  1994/05/30  19:18:28  dale
 * *** empty log message ***
 *
 * Revision 1.24  1994/05/28  21:24:37  dale
 * *** empty log message ***
 *
 * Revision 1.23  1993/10/10  20:58:14  dale
 * *** empty log message ***
 *
 * Revision 1.22  1993/09/04  17:49:22  dale
 * *** empty log message ***
 *
 * Revision 1.21  1993/09/01  19:35:12  dale
 * *** empty log message ***
 *
 * Revision 1.20  1993/08/31  04:51:27  dale
 * *** empty log message ***
 *
 * Revision 1.19  1993/08/27  08:08:08  dale
 * Added code to handle multiple documents opened when tablet needs to be configured in -appDidInit:.
 *
 * Revision 1.18  1993/08/27  03:51:06  dale
 * Added methods to handle disabling windows and menu items.
 *
 * Revision 1.17  1993/08/24  10:17:58  dale
 * *** empty log message ***
 *
 * Revision 1.16  1993/08/24  02:08:33  dale
 * *** empty log message ***
 *
 * Revision 1.15  1993/07/23  07:33:00  dale
 * *** empty log message ***
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
 * Revision 1.11  1993/07/01  20:18:47  dale
 * *** empty log message ***
 *
 * Revision 1.10  1993/06/18  08:45:44  dale
 * *** empty log message ***
 *
 * Revision 1.9  1993/06/16  07:45:38  dale
 * Removed interface buttons.
 *
 * Revision 1.8  1993/06/11  08:38:39  dale
 * Incorporated GroovePalette for soft function activation.
 *
 * Revision 1.7  1993/06/04  20:57:48  dale
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
 * Added set methods to deal with new interface.
 *
 * Revision 1.2  1993/05/20  19:24:41  dale
 * Fixed problems with messages sent to FREED objects, and temporary appearance of UNTITLED%d in the
 * window title bar. Also inhibited -open: from sending the -new message to generate the new document,
 * but instead take care of this within -open:.
 *
 * Revision 1.1  1993/05/20  06:03:35  dale
 * Initial revision
 *
 */

#import <tabletkit/tabletkit.h>
#import <objc/HashTable.h>
#import <mach/mach.h>
#import <mach/mach_error.h>
#import <grooveslider/GrooveSlider.h>
#import "Publisher.tproj.h"
#import "TNTControl.h"
#import "TactileDisplay.h"
#import "TabletSurface.h"
#import "GestureExpert.h"
#import "TNTEventGenerator.h"
#import "SILSpeaker.h"
#import "SIL.h"
#import "FileListing.h"
#import "DSPTone.h"
#import "TouchNTalk.h"

/* IB tags associated with soft function titles. */
#define TNT_SOFT_HELP         9
#define TNT_SOFT_OPEN         8
#define TNT_SOFT_SAVE         7
#define TNT_SOFT_CLOSE        6
#define TNT_SOFT_PAGE         5
#define TNT_SOFT_SHELL        4
#define TNT_SOFT_WINDOWS      3
#define TNT_SOFT_HOLO_SET     2
#define TNT_SOFT_SPEECH_MODE  1
#define TNT_SOFT_CONFIGURE    0

/* Radio button device tags. */
#define TNT_TTYA              0
#define TNT_TTYB              1

/* STATIC CLASS VARIABLES */
static BOOL appFileLaunch = NO;   // TNT document was launched from Workspace?
static NXDefaultsVector TNTDefaults = {{TNT_DEVICE_NAME, "/dev/ttyb"},
					   {NULL}};


@implementation TouchNTalk


/* CLASS INITIALIZATION *****************************************************************************/


+ initialize
{
    if (!NXRegisterDefaults(TNT_DEFAULTS_OWNER, TNTDefaults))
	NXLogError("TouchNTalk: Defaults database could not be opened.");
    return self;
}


/* INITIALIZING AND FREEING  ************************************************************************/


- init
{
    kern_return_t error;
    struct task_basic_info info;
    unsigned int info_count = TASK_BASIC_INFO_COUNT;

    [super initRegisterRoot:self];

    // raise base priority of task
    error = task_info(task_self(), TASK_BASIC_INFO, (task_info_t)&info, &info_count);
    if (error != KERN_SUCCESS) {
	mach_error("Error calling task_info()", error);
    } else {   // set this task's base priority to be higher than normal
	error = task_priority(task_self(), info.base_priority + 6, TRUE);
	if (error != KERN_SUCCESS)
	    mach_error("Call to task_priority() failed", error);
    }

    // get shared instances of open and save panel
    openPanel = [OpenPanel new];
    savePanel = [SavePanel new];

    [savePanel setDirectory:NXHomeDirectory()];
    [openPanel setDirectory:NXHomeDirectory()];

    //
    // silSpeaker initialization (and tactileSpeaker) will eventually be done via preferences
    //

    // get shared instance of SILSpeaker object; set voice quality parameters
    silSpeaker = [SILSpeaker new];
    [silSpeaker setPitchOffset:[silSpeaker pitchOffset] - 8.0];
    [silSpeaker setIntonation:TTS_INTONATION_NONE];

    untitled = 0;   // document count
    previousTNTControl = nil;
    activeSoftTitle = nil;
    fileListingTable = nil;
    docWindowList = nil;
    lastLineWrapColumns = 0;

    // init TouchNTalk event generator
    eventGenerator = [[TNTEventGenerator allocFromZone:[self zone]] init];

    // open nib containing TabletSurface instance and connect to tabletSurface outlet
    if ([NXApp loadNibSection:"configureTablet.nib" owner:self] == nil) {
	NXBeep();
	NXLogError("TouchNTalk: Unable to load configureTablet.nib.");
    }

    return self;
}

- createTabletDriver:(const char *)deviceName
{    
    // start tablet driver; if we fail continue anyway with tablet unconnected
    if (!(tabletDriver = [[TabletDriver alloc] initTabletDevice:deviceName 
					       tabletReader:TNT_TABLET_READER])) {
	NXBeep();
	NXLogError("TouchNTalk: Unable to connect tablet.");
    }

    // Set the tablet so that is is reporting at approximately 32 rps. This was calculated based on
    // 22 rps @ 9600 baud (S setting), 114 rps @ 9600 baud (Q setting), and 164 rps @ 19200 (Q 
    // setting). We complete the command to the tablet after the 100 ms. delay in order to give the 
    // tablet time to send the <ACK>. Also, the "@I " command places the tablet into event report 
    // mode, generating an event continuously. Change the space to larger ascii value in order to 
    // incorporate location hysteresis. The difference between this ascii character and the space 
    // character is the amount of location hysteresis. For example, having the space present in "@I "
    // indicates no location hysteresis, and "!" in place of the space would indicate a location 
    // hysteresis of 1, as """ would indicate a location hysteresis of 2 etc.

    // reset tablet and ttyb port in/out baud rates to defaults
    [tabletDriver sendCommandsToTablet:"\000"];   // 10 ms. delay after reset

    // set tablet to 32 rps @ 19200 baud (S setting)
    [tabletDriver sendCommandsToTablet:TNT_NORMAL_REPORT1];
    [[[tabletDriver sendCommandsToTablet:"Sz "] setInBaud:B19200] setOutBaud:B19200];
    usleep(100000);   // delay of 100 ms. for reception of <ACK>
    [tabletDriver sendCommandsToTablet:" "];

    // set resolution of tablet to display resolution
    [tabletDriver sendCommandsToTablet:TNT_1xDISPLAY_RES];
    return self;
}

- free
{
    [silSpeaker free];
    [tabletDriver free];
    [tabletSurface free];
    return [super free];
}


/* APPLICATION DELEGATE METHODS *********************************************************************/


/* Perform some additional initialization after the app has been loaded and initialized. Some of the
 * code which should appear here when editing facilities are in place appear on pg. 348 of NeXTSTEP
 * programming. Currently we just speak a startup message, and load up a new document. Note, the
 * gestureExpert object must be initialized after the application has finished initializing since it 
 * requires a handle to the application's delegate. See below for IMPORTANT information regarding
 * creation and initialization of the TabletDriver instance. Returns self.
 */
- appDidInit:sender
{
    id docMenu = [documentSubmenuCell target];
    const char *deviceName;

    // It is EXTREMELY IMPORTANT that the TabletDriver instance is created and
    // intialized AFTER the application has completely initialized itself
    // and can therefore receive messages from the outside world. The reason
    // for this is that the TabletDriver instance will sometimes send
    // -applicationDefined: messages directly to the application's delegate, as
    // part of the TabletKit event coalescing logic.

    if (!(deviceName = NXGetDefaultValue(TNT_DEFAULTS_OWNER, TNT_DEVICE_NAME)))
	NXLogError("TouchNTalk: Defaults database could not be opened.");

    // force tty default to be written out to defaults database immediately
    if (!NXWriteDefault(TNT_DEFAULTS_OWNER, TNT_DEVICE_NAME, deviceName))
	NXLogError("TouchNTalk: Could not write to defaults database.");

    // create a working instance of the tablet driver class
    [self createTabletDriver:deviceName];

    if (!appFileLaunch) {   // application not launched from file
	[self new:self];
    }

    // initialize gesture expert once application is initialized
    gestureExpert = [[GestureExpert allocFromZone:[self zone]] init];

    // set update action for document menu cells
    [openCell setUpdateAction:@selector(menuActive:) forMenu:docMenu];
    [newCell setUpdateAction:@selector(menuActive:) forMenu:docMenu];
    [saveCell setUpdateAction:@selector(saveMenuActive:) forMenu:docMenu];
    [saveAsCell setUpdateAction:@selector(saveMenuActive:) forMenu:docMenu];
    [saveAllCell setUpdateAction:@selector(saveMenuActive:) forMenu:docMenu];
    [revertToSavedCell setUpdateAction:@selector(saveMenuActive:) forMenu:docMenu];
    [closeCell setUpdateAction:@selector(menuActive:) forMenu:docMenu];
    [NXApp setAutoupdate:YES];

    // line wrapping text field disabled by default
    [lineWrapColumnsText setEnabled:NO];

    // Initialize the soft function slider target/actions. Note, this MUST be done after the
    // application has completely loaded and initialized itself. This is because manual target/action
    // connections are made to and from the soft function slider, and the IB connections (none) to 
    // interface objects are made after the -init method is invoked. In our case, since we have no
    // IB connections all connections are set to nil after being loaded from the nib file.
    [self setSoftFunctionTargetActions];

    if (![tabletSurface registerDefaults]) {    // need to configure tablet
	[tabletDriver sendCommandsToTablet:TNT_CONFIGURE_REPORT];
	[self clearSoftFunctionTargetActions];   // disconnect soft function target/actions
	[[tabletSurface enableCancel:NO] showConfigurePanel];
	configuringTablet = YES;
    } else {    // simulate window becoming main in order to speak window name
	[tntControl windowDidBecomeMain:nil];
    }

    // DEBUG
    // [tabletSurface showContents];
    return self;
}

/* Indicates via the return value that it is okay for our application to open another file. */
- (BOOL)appAcceptsAnotherFile:sender
{
    appFileLaunch = YES;
    return YES;
}

/* Attempts to open the file filename with the extension aType. If the file is not successfully opened
 * we create a new untitled document. Returns YES if the file is successfully opened, and NO
 * otherwise. This is indirectly invoked from the Workspace or from another app. If multiple files are
 * selected from the Workspace and the tablet has not yet been configured, then we restore tntControl
 * to the first document window, since tntControl automatically is assigned when the displayWindow.nib
 * is loaded. 
 */
- (int)app:sender openFile:(const char *)filename type:(const char *)aType
{
    int returnValue = NO;

    if ([NXApp loadNibSection:"displayWindow.nib" owner:self] != nil) {
	if ([self openFile:filename]) {
	    returnValue = YES;
	} else {
	    [[tntControl window] performClose:self];
	    [self new:self];
	    NXBeep();
	    [[tntControl sil] setText:"Unable to open file."];
	    returnValue = NO;
	}
    }
    return returnValue;
}

/* Makes sure all windows are sent a performClose: message before terminating. When editing facilities
 * have been added, add some of the functionality that appears on pgs. 343-344 in NeXTSTEP 
 * Programming. We also set the tablet and tty baud rates back to the 9600 baud defaults. This is 
 * required if the tablet remains on while TouchNTalk is launched more than once, in order that the
 * baud rates of the tablet and tty device match at launch time. Returns self.
 */
- appWillTerminate:sender
{
    id win, windowList = [NXApp windowList];
    int i, count;

    // delay required between setting in/out baud and sending remainder of autobaud code
    [[[tabletDriver sendCommandsToTablet:"z "] setInBaud:B9600] setOutBaud:B9600];

    count = [windowList count];
    for (i = 0; i < count; i++) {
	win = [windowList objectAt:i];
	if ([[win delegate] isKindOf:[TNTControl class]]) {
	    [win performClose:self];
	}
    }
    [silSpeaker eraseAllSound];
    [(SILSpeaker *)silSpeaker speakText:"TouchNTalk has been terminated."];

    // complete remainder of autobaud code
    [tabletDriver sendCommandsToTablet:" "];
    return self;
}

/* Handle application defined events. Returns self. */
- applicationDefined:(NXEvent *)theEvent
{
    if (theEvent->TNT_APPSUBTYPE == TK_EVENT) {   // tablet kit event
	if (configuringTablet) {   // configuring tablet
	    if ([tabletSurface configure:theEvent]) {   // done configuration
		configuringTablet = NO;
		previousTNTControl = nil;   // set up to speak the name of the key window

		// clear selected configure title and knob
		[softFunctionSlider hideKnob];
		[[softTitleMatrix cellAt:(TNT_SOFT_FUNCTIONS-1) - TNT_SOFT_CONFIGURE 
				  :0] setTextGray:NX_DKGRAY];
		activeSoftTitle = nil;

		// reconnect soft function target/actions
		[self setSoftFunctionTargetActions];   
		[[tntControl window] makeKeyAndOrderFront:nil];
		[tntControl windowDidBecomeMain:nil];   // speak document name
		[tabletDriver sendCommandsToTablet:TNT_NORMAL_REPORT1];
	    }
	} else {   // normal event processing

	    // dispatch tablet kit event to TNTEventGenerator
	    [eventGenerator generateEvent:theEvent];
	}
    } else if (theEvent->TNT_APPSUBTYPE == TNT_EVENT) {   // TouchNTalk event

	// dispatch TNT_EVENT to gesture expert
	[gestureExpert pandemonium:theEvent];
    }
    return self;
}


/* FILE OPERATION METHODS ***************************************************************************/


/* Attempts to open a file with the proper extension thru the openPanel. Include all ascii files by
 * making the first item in the fileTypes array NULL. Returns self.
 */
- open:sender
{
    const char *pathname;
    const char *const fileTypes[3] = {NULL, TNT_FILE_EXTENSION, NULL};

    if ([openPanel runModalForTypes:fileTypes]) {
	if (pathname = [openPanel filename]) {
	    if ([NXApp loadNibSection:"displayWindow.nib" owner:self] == nil) {
		return nil;
	    }
	    if ([self openFile:pathname] == nil) {   // unable to open file
		[[tntControl window] performClose:self];
		NXBeep();
		[(SILSpeaker *)silSpeaker speakText:"Unable to open file."];
		return nil;
	    }
	}
    }
    return self;
}

/* Creates a new document. Note that we don't set the text in the SIL to indicate the active buffer
 * since this is automatically done in TNTControl when the window becomes key. For this reason, the
 * filename must be set within the instance of TNTControl BEFORE making the window key, as shown 
 * below. Returns self.
 */
- new:sender
{
    id window;
    char buf[16];   // holds "UNTITLEDxx" title

    if ([NXApp loadNibSection:"displayWindow.nib" owner:self] == nil) {
	return nil;
    }
    window = [tntControl window];
    sprintf(buf, [window title], ++untitled);
    [self newFile:buf];
    [[window setTitle:buf] makeKeyAndOrderFront:nil];
    return self;
}

/* Not Implemented. */
- saveAll:sender
{
    return self;
}


/* Attempts to open the file and display it. If we are unable to read the document, returns nil, 
 * otherwise returns self. Note that aPathname is assumed to be NULL terminated.
 */
- openFile:(const char *)aPathname
{
    NXTypedStream *typedStream;
    NXStream *stream;
    FILE *expandPipe;
    id document;
    char pBuffer[MAXPATHLEN+128];

    if ([self isTNTDocument:aPathname]) {   // file is a TNT document (we think)
	if(!(typedStream = NXOpenTypedStreamForFile(aPathname, NX_READONLY))) {
	    return nil;
	}

	// read in new document and set window title, as well as document pathname
	document = NXReadObject(typedStream);
	[[document setPathname:aPathname] setFilename:rindex(aPathname, '/') + 1];

	// republish to conform to user specified line wrapping (if necessary)
	if ([lineWrapSwitch state])
	    [document publishEnglishTextWithLineLength:[lineWrapColumnsText intValue]];

	[[tntControl tactileDisplay] setDocument:document];
	[[[tntControl window] setTitleAsFilename:aPathname] makeKeyAndOrderFront:nil];
	NXCloseTypedStream(typedStream);
	[tntControl initTargetAction];
	return self;
    }

    // file is probably ascii; convert all tabs to spaces via "expand" system call
    sprintf(pBuffer, "/usr/ucb/expand %s", aPathname);
    if ((expandPipe = popen(pBuffer, "r")) == NULL) {
	return nil;
    }
    if (!(stream = NXOpenFile(fileno(expandPipe), NX_READONLY))) {   // error during open
	return nil;
    }

    // now perform on-the-fly (dynamic) publish
    document = [[Document alloc] init];
    [[document text] readText:stream];

    if ([lineWrapSwitch state])   // wrap lines
	[document publishEnglishTextWithLineLength:[lineWrapColumnsText intValue]];
    else   // don't wrap lines
	[document publishEnglishText];
    [[document setPathname:aPathname] setFilename:rindex(aPathname, '/') + 1];
    [[tntControl tactileDisplay] setDocument:document];
    [[[tntControl window] setTitleAsFilename:aPathname] makeKeyAndOrderFront:nil];
    NXClose(stream);
    pclose(expandPipe);
    [tntControl initTargetAction];
    return self;
}

- newFile:(const char *)aFilename
{
    id document;

    document = [[Document allocFromZone:[self zone]] init];
    [[document setPathname:NULL] setFilename:aFilename];
    [[tntControl tactileDisplay] setDocument:document];
    [tntControl initTargetAction];
    return self;
}


/* CONTROL WINDOW DISPLAY METHODS *******************************************************************/


/* Displays the open document window via a call to -displayDirectoryListing:forNewWindow:. If errors 
 * occur, we close the window and return nil. Otherwise returns self.
 */
- displayOpenDocumentWindow
{
    // set operation mode
    [tntControl setOperationMode:TNT_OPEN];

    if (![self displayDirectoryListing:[openPanel directory] forNewWindow:YES]) {
	[[tntControl window] performClose:self];
	return nil;
    }
    [[[tntControl window] setTitle:"Open Document"] makeKeyAndOrderFront:nil];
    [tntControl initTargetAction];
    return self;
}

/* We obtain a directory listing via the "ls -lgAL" command. See the UNIX man page for a description 
 * of the additional flags used. We use the popen command to create a FILE which we can read the 
 * output of the command. We don't actually read the FILE, but instead open a NXStream on the FILE via
 * the NXOpenFile function. We pass the stream to instances of the FileListing class which initializes
 * itself with the appropriate values read from the stream. The FileListing class is a class that 
 * contains various pieces of information on a file listing. The file is a UNIX file and can be a 
 * traditional file, directory, symbolic link, etc. We create as many instances of FileListing objects
 * as there are individual file listings. We write the directory file listings to the stream which
 * will be displayed and published, followed by the file file listings. When all is complete, we 
 * publish and load/display the document. The flag argument is explained below, but essentially 
 * indicates whether we are displaying a directory listing for a new open/save document window or for
 * an existing one. The difference is explained below. Returns nil if errors occurred, otherwise 
 * returns self.
 */
- displayDirectoryListing:(const char *)directoryPath forNewWindow:(BOOL)flag
{
    NXStream *listingStream, *stream;
    FILE *lsPipe;
    int i, count, key;
    id fileListing, fileListingList, document, activePage;

    sprintf(buffer, "/bin/ls -lgAL %s", directoryPath);
    if ((lsPipe = popen(buffer, "r")) == NULL) {
	return nil;
    }

    if (!(listingStream = NXOpenFile(fileno(lsPipe), NX_READONLY))) {   // error during open
	return nil;
    }

    // ignore first line of listing
    NXScanf(listingStream, "total %d", &i);   // ignore argument read

    // create temporary list
    fileListingList = [[List allocFromZone:[self zone]] init];

    // create hash table and add fileListing objects with appropriate tags
    fileListingTable = [[HashTable allocFromZone:[self zone]] initKeyDesc:"i"];

    // prepare stream which will be published and displayed
    stream = NXOpenMemory(NULL, 0, NX_READWRITE);
    strcpy(&buffer[1], [openPanel directory]);
    [self replaceChar:'/' withChar:' ' inString:buffer]; 
    buffer[0] = '/';
    NXPrintf(stream, "Current directory path: %s\n\nDirectories\n\n", buffer);

    // We want the first directory to be associated with line 5 of the document. The first line will
    // contain the full pathname of the current directory, followed by a blank line, followed by a
    // "Directories" title, followed by a block of child directories, followed by a blank line, 
    // followed by a "Files" title, followed by a block of files in the current directory. We add the
    // fileListing directories (to the hashtable in the form of FileListing instances) when we get 
    // them, since they come first. We must temporarily store the fileListing files (again in the form
    // of FileListing instances) since we may not be done with those that are directories. While all 
    // this is happening, we also write the fileListing directories to the stream which is to be 
    // published and displayed. The fileListing files will be written immediately after.

    key = 5;
    while (fileListing = [[FileListing allocFromZone:[self zone]] initFromStream:listingStream]) {
	if ([fileListing isDirectory] || [fileListing isSymbolicLink]) {        // is dir. or symbolic
	    [fileListingTable insertKey:(const void *)key value:fileListing];   // link to dir.
	    NXPrintf(stream, "%-30s %3s %2d %9d\t %-10s %10s\n", [fileListing filename], 
		     [fileListing month], [fileListing day], [fileListing sizeInBytes], 
		     [fileListing owner], [fileListing permissions]);
	    key++;
	} else if ([fileListing isFile]) {   // file listing is a file
	    [fileListingList addObject:fileListing];
	} else {   // file listing is neither a directory or a file
	    [fileListing free];
	}
    }

    if (key == 5) {   // no child directories have been encountered
	NXPrintf(stream, "No child directories.\n");
	key++;
    }
    NXClose(listingStream);
    pclose(lsPipe);
    NXPrintf(stream, "\nFiles\n\n");   // skip the lines that will separate the
    key += 3;                          // directory block from the file block

    if ((count = [fileListingList count]) == 0) {   // no accessible files in directory
	NXPrintf(stream, "No files.\n");
    }
    
    // All fileListing directories are now in the hash table and in the stream to be published and
    // displayed. Now add all fileListing files to the hash table and the stream.

    for (i = 0; i < count; i++) {
	fileListing = [fileListingList objectAt:i];
	[fileListingTable insertKey:(const void *)key value:fileListing];
	NXPrintf(stream, "%-30s %3s %2d %9d\t %-10s %10s\n", [fileListing filename], 
		 [fileListing month], [fileListing day], [fileListing sizeInBytes], 
		 [fileListing owner], [fileListing permissions]);
	key++;
    }

    // free temporary storage for fileListing objects
    [fileListingList free];

    // flush buffer associated with stream, and reset stream
    NXFlush(stream);
    NXSeek(stream, 0, NX_FROMSTART);

    // If flag is YES, then we are loading the directory listing information into a new open/save
    // document window. This means that we must create a new document, and set the document in the
    // tactileDisplay once it has been published. Otherwise, we are loading the directory listing into
    // an existing window, and we only want to replace the text in the document and display.

    if (flag) {   // new open/save document window
	document = [[Document allocFromZone:[self zone]] init];
    } else {   // existing open/save document window
	document = [tactileDisplay document];
    }

    // publish document with directory listings
    [[document text] readText:stream];
    [document publishEnglishText];   // never wrap lines for open document window
    [[document setPathname:NULL] setFilename:NULL];

    if (flag) {   // new open/save document window
	[[tntControl tactileDisplay] setDocument:document];
    } else {   // existing open/save document window

	// Unlock focus on the active page before resetting the document. We know the view is locked
	// since we can only arrive here as a result of a mouse action which requires the view to be
	// locked. Therefore we really need not check if the view is locked or not. Notice that we 
	// reset instance drawing so that the user cursor will continue to be drawn correctly.

	activePage = [tactileDisplay activePage];
	if ([activePage isFocusView]) {
	    [activePage unlockFocus];
	} else {
	    printf("TouchNTalk: Active page is NOT focused view (in directory listing).");
	}
	[tactileDisplay resetDocument];
	[activePage lockFocus];
	PSsetinstance(YES);   // reset instance drawing
	[activePage showUserCursor];   // redisplay user cursor
    }
    NXCloseMemory(stream, NX_TRUNCATEBUFFER);
    return self;
}

/* Opens a window with a listing of all window's that contain normal documents. By "normal" we mean 
 * documents that are not used for selecting other documents, like the document selection window, or 
 * the open document window. Note that documents that are resident on disk have pathnames and 
 * filenames. New documents that are not resident on disk only have filenames. Control documents, that
 * is, non-normal documents, have neither a pathname, nor a filename. This is how the different 
 * document types can be distinguished. Note that this method is only called when the window soft 
 * function is selected. This means that TNT now operates in TNT_WINDOWS mode. Returns self.
 */
- displayDocumentSelectionWindow
{
    id win, windowList, document;
    int i, count, fileCount = 0;
    NXStream *stream;
    const char *pathname, *filename;

    // set operation mode
    [tntControl setOperationMode:TNT_WINDOWS];

    windowList = [NXApp windowList];
    count = [windowList count];
    stream = NXOpenMemory(NULL, 0, NX_READWRITE);

    // print document window header
    NXPrintf(stream, "Document Windows\n\n");

    // create list and add document windows at indices corresponding to line number - 3
    docWindowList = [[List allocFromZone:[self zone]] init];

    for (i = 0; i < count; i++) {   // get filenames and pathnames for all windows
	win = [windowList objectAt:i];
	if ([[win delegate] isKindOf:[TNTControl class]]) {   // have a TNT document
	    document = [[[win delegate] tactileDisplay] document];
	    if (filename = [document filename]) {   // not a control document
		NXPrintf(stream, "%-30s %d\t ", filename, ++fileCount);
		if (pathname = [document pathname]) {
		    NXWrite(stream, pathname, strlen(pathname) - strlen(filename) - 1);
		}
		NXPutc(stream, '\n');
		[docWindowList addObject:win];
	    }
	}
    }

    // flush buffer associated with stream, and reset stream
    NXFlush(stream);
    NXSeek(stream, 0, NX_FROMSTART);

    // create and publish new document with file window listings
    document = [[Document allocFromZone:[self zone]] init];
    [[document text] readText:stream];
    [document publishEnglishText];   // never wrap lines for document selection window
    [[document setPathname:NULL] setFilename:NULL];
    [[tntControl tactileDisplay] setDocument:document];
    [[[tntControl window] setTitle:"Document Selection"] makeKeyAndOrderFront:nil];
    NXCloseMemory(stream, NX_TRUNCATEBUFFER);
    [tntControl initTargetAction];
    return self;
}


/* MENU UPDATE METHODS ******************************************************************************/


/* This should be used for updating the open, new, and close document menu cells. All menu cells are 
 * disabled when the tablet is being configured. Returns YES if the cell should be redisplayed since
 * it has changed, or NO if no changes were made.
 */
- (BOOL)menuActive:menuCell
{
    if (configuringTablet) {   // disable menu cell (if not already)
	if ([menuCell isEnabled]) {
	    [menuCell setEnabled:NO];
	    return YES;   // redisplay
	}
    } else if (![menuCell isEnabled]) {   // enable menu cell
	[menuCell setEnabled:YES];
	return YES;   // redisplay
    }
    return NO;   // no change
}


/* This should be used for updating the save... menu cells, since they should only be enabled when
 * there actually are documents (windows). Currently, since editing facilities are not in place, we
 * just return NO. The code that should appear here is that which appears on pg. 348 of NeXTSTEP 
 * Programming.
 */
- (BOOL)saveMenuActive:menuCell
{
    if (configuringTablet) {   // disable menu cell (if not already)
	if ([menuCell isEnabled]) {
	    [menuCell setEnabled:NO];
	    return YES;   // redisplay
	}
    } else if (![menuCell isEnabled]) {   // handle save enable/disable here
	[menuCell setEnabled:NO];
	return YES;   // redisplay
    }
    return NO;   // no change
}


/* TARGET/ACTION METHODS ****************************************************************************/


- speakInfoPanel:sender
{
    [(SILSpeaker *)silSpeaker speakText:"TouchNTalk"];
    return self;
}

- configureCancel:sender
{
    id speaker = [tabletSurface speaker];

    [(TextToSpeech *)speaker eraseAllSound];
    [(TextToSpeech *)speaker speakText:"Tablet configuration cancelled."];
    [[[tabletSurface revertToPreviousRegions] configurePanel] orderOut:nil];
    configuringTablet = NO;
    previousTNTControl = nil;   // set up to speak the name of the key window

    // clear selected configure title and knob
    [softFunctionSlider hideKnob];
    [[softTitleMatrix cellAt:(TNT_SOFT_FUNCTIONS-1) - TNT_SOFT_CONFIGURE :0] setTextGray:NX_DKGRAY];
    activeSoftTitle = nil;

    // restore target/actions
    [self setSoftFunctionTargetActions];
    [[tntControl window] makeKeyAndOrderFront:nil];
    [tntControl windowDidBecomeMain:nil];   // speak document name
    return self;
}

- helpRequest:sender
{
    return [self softHelp];
}


/* SET METHODS **************************************************************************************/


/* These methods which are called from an instance of the TNTControl in order to update the tntControl
 * outlets to point to the TNTControl for the currently active window. Thus messages sent to the 
 * TouchNTalk Server will result in the correct controls being messaged. All return self.
 */

- setTNTControl:theControl
{
    tntControl = theControl;
    return self;
}

- setPreviousTNTControl:theControl
{
    previousTNTControl = theControl;
    return self;
}

- setConfiguringTablet:(BOOL)flag
{
    configuringTablet = flag;
    return self;
}

- setFileListingTable:listTable
{
    fileListingTable = listTable;
    return self;
}

- setDocWindowList:winList
{
    docWindowList = winList;
    return self;
}


/* QUERY METHODS ************************************************************************************/


- tntControl
{
    return tntControl;
}

- previousTNTControl
{
    return previousTNTControl;
}

- tabletSurface
{
    return tabletSurface;
}

- tabletDriver
{
    return tabletDriver;
}

- (BOOL)configuringTablet;
{
    return configuringTablet;
}

- fileListingTable
{
    return fileListingTable;
}

- docWindowList
{
    return docWindowList;
}

- (float)baseVolume
{
    return [volumeSlider floatValue];
}


/* SOFT FUNCTION ACTION METHODS *********************************************************************/


/* The user has just clicked in the soft function groove. We want to set the initial activeSoftTitle
 * and color it black for subsequent activity. Returns self.
 */
- softFunctionDown:sender
{
    int sliderVal, intValue = [sender intValue];
    id titleCell;

    NXBeep();   // beep to indicate a new soft function
    sliderVal = (intValue > (TNT_SOFT_FUNCTIONS-1) ? (TNT_SOFT_FUNCTIONS-1) : intValue);

    // get appropriate titleCell, speak text, and set text to black
    titleCell = [softTitleMatrix cellAt:(TNT_SOFT_FUNCTIONS-1) - sliderVal :0];
    [titleCell setTextGray:NX_BLACK];
    sprintf(buffer, "%s.", [titleCell stringValue]);
    [self filterControlCharacters:buffer];
    [sil setText:buffer];
    activeSoftTitle = titleCell;
    return self;
}

/* Sets the text color of the title which the slider knob is adjacent to black. The previous black 
 * colored title is set to NX_DKGRAY. We then set the activeSoftTitle to reflect the currently active
 * (or black colored) title. Note that initially, activeSoftTitle is set to a title (colored black) 
 * within IB. Also note, when the soft function button is pressed, the currently active title (colored
 * black) is the soft function that is selected. Returns self.
 */
- softFunctionActive:sender
{
    int sliderVal;
    id titleCell;

    sliderVal = ([sender intValue] > (TNT_SOFT_FUNCTIONS-1) ? (TNT_SOFT_FUNCTIONS-1) 
		                                            : [sender intValue]);
    if ([activeSoftTitle tag] != sliderVal) {

	NXBeep();   // beep to indicate a new soft function
	[activeSoftTitle setTextGray:NX_DKGRAY];   // set previously active title back to gray

	// get appropriate titleCell, speak text, and set text to black
	titleCell = [softTitleMatrix cellAt:(TNT_SOFT_FUNCTIONS-1) - sliderVal :0];
	[titleCell setTextGray:NX_BLACK];
	sprintf(buffer, "%s.", [titleCell stringValue]);
	[self filterControlCharacters:buffer];
	[sil setText:buffer];
	activeSoftTitle = titleCell;
    }
    return self;
}

- softFunctionSelect:sender
{
    switch ([activeSoftTitle tag]) {
      case TNT_SOFT_HELP:
	[self softHelp];
	break;
      case TNT_SOFT_OPEN:
	[self softOpen];
	break;
      case TNT_SOFT_SAVE:
	[self softSave];
	break;
      case TNT_SOFT_CLOSE:
	[self softClose];	
	break;
      case TNT_SOFT_PAGE:
	[self softPage];
	break;
      case TNT_SOFT_SHELL:
	[self softShell];
	break;
      case TNT_SOFT_WINDOWS:
	[self softWindows];
	break;
      case TNT_SOFT_HOLO_SET:
	[self softHoloSet];
	break;
      case TNT_SOFT_SPEECH_MODE:
	[self softSpeechMode];
	break;
      case TNT_SOFT_CONFIGURE:
	[self softConfigure];
	break;
      default:
	break;
    }
    return self;
}

/* Make currently active title cell gray and activeSoftTitle = nil. This is the method that gets
 * called when the softFunctionSlider is no longer active, that is, when the left mouse goes up.
 * Returns self.
 */
- softFunctionUp:sender
{
    int sliderVal;

    sliderVal = [activeSoftTitle tag];
    [[softTitleMatrix cellAt:(TNT_SOFT_FUNCTIONS-1) - sliderVal :0] setTextGray:NX_DKGRAY];
    activeSoftTitle = nil;
    return self;
}


/* SOFT FUNCTIONS ***********************************************************************************/


/* There really is no need for a TNT_HELP operation mode. We may as well keep things consistent.
 * Therefore the user can click on the help button several times and each time a new identical help
 * document will come up. Returns self.
 */
- softHelp
{
    if ([NXApp loadNibSection:"displayWindow.nib" owner:self] == nil) {
	[sil setText:"Unable to open display window."];
	return self;
    }

    // help document is either in /LocalApps or ~/Apps
    sprintf(buffer, "/LocalApps/%s/%s", TNT_APP_WRAPPER, TNT_HELP_DOCUMENT);
    if (access(buffer, F_OK) || access(buffer, R_OK)) {   // no file/read permissions
	sprintf(buffer, "%s/Apps/%s/%s", NXHomeDirectory(), TNT_APP_WRAPPER, TNT_HELP_DOCUMENT);
	if (access(buffer, F_OK) || access(buffer, R_OK)) {   // no file/read permissions
	    NXBeep();
	    [sil setText:"Unable to locate help file."];
	    [[tntControl window] performClose:self];
	    return self;
	}
    }
    
    // now tntControl outlet is associated with the new displayWindow
    if ([self openFile:buffer] == nil) {   // unable to open file
	NXBeep();
	[sil setText:"Unable to open help file."];
	[[tntControl window] performClose:self];
    }
    return self;
}

/* Only open an open file window if one is not already active. If the open soft function is selected
 * selected when the open window is active, the open process is cancelled, and the window is closed.
 * Also, if there are no document windows then automatically open the window since tntControl is
 * then nil. Returns self.
 */
- softOpen
{
    // we already ARE an open file window!
    if (tntControl && [tntControl operationMode] == TNT_OPEN) {
	[sil setTextNoDisplay:"Open document cancelled."];
	[[tntControl window] performClose:self];
	return self;
    }
    if ([NXApp loadNibSection:"displayWindow.nib" owner:self] == nil) {
	if (tntControl)
	    [sil setText:"Unable to load open document window."];
	else
	    [(SILSpeaker *)silSpeaker speakText:"Unable to load open document window."];
	return self;
    }

    // now tntControl outlet is associated with the new displayWindow
    if (![self displayOpenDocumentWindow]) {   // unable to get directory listing
	[sil setTextNoDisplay:"Unable to get directory listing."];
    }
    return self;
}

- softSave
{
    if (tntControl)
	[sil setText:"Save not implemented."];
    else
	[(SILSpeaker *)silSpeaker speakText:"Save not implemented."];
    return self;
}

- softClose
{
    if (tntControl)
	[[tntControl window] performClose:self];
    else
	[(SILSpeaker *)silSpeaker speakText:"No active document."];
    return self;
}

- softPage
{
    id document = [tactileDisplay document];

    if (tntControl) {
	sprintf(buffer, "Page %d of %d.", [document activePageNumber], [document pages]);
	[sil setText:buffer];
    } else {
	[(SILSpeaker *)silSpeaker speakText:"No active document."];	
    }
    return self;
}

- softShell
{

    if (tntControl)
	[sil setText:"Shell not implemented."];
    else
	[(SILSpeaker *)silSpeaker speakText:"Shell not implemented."];
    return self;
}

/* Only open a document selection window if one is not already active. If the windows soft function is
 * selected when the document selection is active, the document selection process is cancelled, and 
 * the window is closed. If there are no open non-control documents, indicate so by sending a message
 * to an instance of the SILSpeaker class. Always returns self.
 */
- softWindows
{
    id win, windowList = [NXApp windowList];
    int i, documentCount = 0, count = [windowList count];

    // Find the number of open non-control documents. The absence of a filename for a document (NULL)
    // indicates it is a control document. If there are no non-control documents open, then we 
    // indicate so in the next block of code, and return self.

    for (i = 0; i < count; i++) {
	win = [windowList objectAt:i];
	if ([[win delegate] isKindOf:[TNTControl class]])   // have a TNT document
	    if ([[[[win delegate] tactileDisplay] document] filename])   // not a control document
		documentCount++;
    }

    // no TNTControl document OR there are no open documents -- indicate so and return
    if (!tntControl || documentCount == 0) {
	[(SILSpeaker *)silSpeaker speakText:"No document windows open."];
	return self;
    }

    if ([tntControl operationMode] == TNT_WINDOWS) {   // we already ARE a document selection window!
	[sil setTextNoDisplay:"Document selection cancelled."];
	[[tntControl window] performClose:self];
	return self;
    }
    if ([NXApp loadNibSection:"displayWindow.nib" owner:self] == nil) {
	[sil setText:"Unable to load document selection window."];
	return self;
    }

    // now tntControl outlet is associated with the new displayWindow
    [self displayDocumentSelectionWindow];
    return self;
}

/* Toggle the current speech mode. Note that we query the speech mode definitions in the TNTControl
 * class to determine what the current mode is, since every document may have a different mode. 
 * Returns self.
 */
- softSpeechMode
{
    int speechMode = [tntControl speechMode];

    if (!tntControl) {
	[(SILSpeaker *)silSpeaker speakText:"Default speech mode is speak."];
	[speechModeTitle setStringValue:"Speak\nMode"];
	return self;
    }
    if (speechMode == ST_SPEAK) {
	[speechModeTitle setStringValue:"Spell\nMode"];
	[sil setText:"New speech mode is spell."];
	[tntControl setSpeechMode:ST_SPELL];
    } else if (speechMode == ST_SPELL) {
	[speechModeTitle setStringValue:"Speak\nMode"];
	[sil setText:"New speech mode is speak."];
	[tntControl setSpeechMode:ST_SPEAK];
    }
    return self;
}

/* Toggle the current active holo set. Return self */
- softHoloSet
{
    int activeHoloSet = [tntControl activeHoloSet];

    if (!tntControl) {
	[(SILSpeaker *)silSpeaker speakText:"Default holo set is 1."];
	[holoSetTitle setStringValue:"Holo\nSet 1"];
	return self;
    }
    if (activeHoloSet == TNT_HOLO_SET1) {
	[holoSetTitle setStringValue:"Holo\nSet 2"];
	[sil setText:"Holo set 2 is now active."];
	[tntControl setActiveHoloSet:TNT_HOLO_SET2];
    } else if (activeHoloSet == TNT_HOLO_SET2) {
	[holoSetTitle setStringValue:"Holo\nSet 1"];
	[sil setText:"Holo set 1 is now active."];
	[tntControl setActiveHoloSet:TNT_HOLO_SET1];
    }
    return self;
}

/* Invokes the tablet configuration panel, and places the system in tablet configuration mode. When 
 * the left mouse goes up, we disable all display windows to inhibit operations within these windows
 * while tablet configuration is proceeding. See -softFunctionUp: for more details. Returns self.
 */
- softConfigure
{
    [[tabletSurface enableCancel:YES] showConfigurePanel];
    configuringTablet = YES;
    [tabletDriver sendCommandsToTablet:TNT_CONFIGURE_REPORT];
    [self clearSoftFunctionTargetActions];   // disconnect soft function target/actions
    return self;
}


/* SOFT FUNCTION TARGET/ACTION METHODS **************************************************************/


/* Sets all soft function target/actions to their appropriate values. Returns self. */
- setSoftFunctionTargetActions
{
    [softFunctionSlider setMouseDownTarget:self action:@selector(softFunctionDown:)];
    [softFunctionSlider setSingleClickTarget:self action:@selector(softFunctionSelect:)];
    [softFunctionSlider setMouseUpTarget:self action:@selector(softFunctionUp:)];
    [softFunctionSlider setTarget:self action:@selector(softFunctionActive:)];
    return self;
}

/* Only invoke when ALL soft function target/actions should be cleared. Returns self. */
- clearSoftFunctionTargetActions
{
    [softFunctionSlider setMouseDownTarget:nil action:(SEL)0];
    [softFunctionSlider setSingleClickTarget:nil action:(SEL)0];
    [softFunctionSlider setMouseUpTarget:nil action:(SEL)0];
    [softFunctionSlider setTarget:nil action:(SEL)0];
    return self;
}


/* DISABLING/ENABLING DISPLAY WINDOWS ***************************************************************/


/* Disables all display windows, so the controls have no effect. This is done to inhibit window 
 * operations while the tablet is being configured. Returns self. NOTE: THIS METHOD IS NO LONGER
 * INVOKED.
 */
- disableDisplayWindows
{
    id win, winDelegate, contentView, activePage, windowList = [NXApp windowList];
    int i, count;

    // disable windows while the tablet is being configured
    count = [windowList count];
    for (i = 0; i < count; i++) {
	win = [windowList objectAt:i];
	winDelegate = [win delegate];
	if ([winDelegate isKindOf:[TNTControl class]]) {
	    [winDelegate setWindowContentView:contentView = [win contentView]];
	    [activePage = [[winDelegate tactileDisplay] activePage] stopSystemCursorBlink];
	    [activePage stopMarkBlink];
	    [contentView removeFromSuperview];
	    [win orderOut:nil];
	}
    }
    return self;
}

/* Reenables all display window, so the controls are once again usable. The display windows were
 * previously disabled to inhibit window operations while the tablet was being configured. This method
 * is called once tablet configuration is complete. Returns self. NOTE: THIS METHOD IS NO LONGER 
 * INVOKED.
 */
- reenableDisplayWindows
{
    id win, winDelegate, activePage, windowList = [NXApp windowList];
    int i, count;

    count = [windowList count];
    for (i = 0; i < count; i++) {
	win = [windowList objectAt:i];
	winDelegate = [win delegate];
	if ([winDelegate isKindOf:[TNTControl class]]) {
	    [win setContentView:[winDelegate windowContentView]];
	    [activePage = [[winDelegate tactileDisplay] activePage] startSystemCursorBlink];
	    [activePage startMarkBlink];
	    [win orderFront:nil];
	}
    }
    [tntControl windowDidBecomeMain:nil];   // speak document window name (simulate)
    return self;
}


/* VISUALLY IMPAIRED FILE PROCESSING METHODS ********************************************************/


/* Process the file listing selected. fileListing is an instance of the FileListing class. We will 
 * either open a new directory or file. Returns self.
 */
- processFileListingSel:fileListing
{
    // fileListing is a directory or symbolic link to a directory
    if ([fileListing isDirectory] || [fileListing isSymbolicLink]) {   // open new directory
	strcpy(buffer, [openPanel directory]);
	strcat(buffer, "/");
	strcat(buffer, [fileListing filename]);
	[openPanel setDirectory:buffer];         // set new directory in openPanel
	if (![self displayDirectoryListing:[openPanel directory] forNewWindow:NO]) {   // unable to 
	    NXBeep();                                                                  // display dir.
	    [sil setText:"Unable to open selected directory."];	                       // listing
	} else {
	    sprintf(buffer, "Current directory is %s.", [tntControl lastWord]);
	    [sil setText:buffer];
	}
    } else if ([fileListing isFile]) {   // open selected file
	if ([NXApp loadNibSection:"displayWindow.nib" owner:self] == nil) {
	    [sil setText:"Unable to open display window."];
	    return self;
	}
	// append filename to directory path in open panel for full pathname
	strcpy(buffer, [openPanel directory]);
	strcat(buffer, "/");
	strcat(buffer, [fileListing filename]);

	// now tntControl outlet is associated with the new displayWindow
	if ([self openFile:buffer] == nil) {   // unable to open file
	    NXBeep();
	    [sil setText:"Unable to open selected file."];
	    [[tntControl window] performClose:self];
	}
    }
    return self;
}


/* UTILITY METHODS **********************************************************************************/


/* Filter all control characters and replace them with spaces. Note that the buffer that is passed in
 * is changed, and must be NULL terminated. Returns self.
 */
- filterControlCharacters:(char *)aBuffer
{
    int i;

    for (i = 0; aBuffer[i] != '\0'; i++) {
	if (NXIsCntrl(aBuffer[i])) {   // character is control
	    aBuffer[i] = ' ';	    
	}
    }
    return self;
}

/* Determines if the pathname is that of a TNT document. If the filename has the TNT extension then it
 * is classified as a TNT file, and YES is returned. Otherwise we return NO. Note that this only a 
 * guess as to whether the file is REALLY a TNT file or not. It could be the case that the file is
 * disguised as a TNT file. If this is the case, then it will be caught when an attempt is made to
 * load the file.
 */
- (BOOL)isTNTDocument:(const char *)aPathname
{
    char *filename, *extension, docExtension[16];

    filename = rindex(aPathname, '/');   // filename includes '/'
    extension = rindex(filename, '.');   // extension includes '.'
    sprintf(docExtension, ".%s", TNT_FILE_EXTENSION);
    if (extension && !strcmp(extension, docExtension)) {
	return YES;
    }
    return NO;
}

/* Replaces all occurrences of c1 in string with c2. Assumes string is NULL terminated. If string is 
 * a NULL pointer or c1 is a NULL character, the input string is untouched. Returns self.
 */
- replaceChar:(char)c1 withChar:(char)c2 inString:(char *)string
{
    int i, len;

    if (string) {
	len = strlen(string);
	for (i = 0; i < len; i++) {
	    if (string[i] == c1) {
		string[i] = c2;
	    }
	}
    }
    return self;
}


/* TONE GENERATION METHODS **************************************************************************/


- volumeChanged:sender
{
    [volumeField setFloatValue:[sender floatValue]];
    [volumeSlider setFloatValue:[sender floatValue]];
    [(DSPTone *)[tactileDisplay tone] setVolume:[sender floatValue]];
    return self;
}

- balanceChanged:sender
{
    [balanceField setFloatValue:[sender floatValue]];
    [balanceSlider setFloatValue:[sender floatValue]];
    [[tactileDisplay tone] setStereoBalance:[sender floatValue]];
    return self;
}

- harmonicsChanged:sender
{
    if ([sender isKindOf:[Slider class]])
	[harmonicsField setIntValue:[sender intValue]];
    else
	[harmonicsSlider setIntValue:[sender intValue]];
    [[tactileDisplay tone] setNumberHarmonics:[sender intValue]];
    return self;
}

- rampTimeChanged:sender
{
    [rampTimeField setFloatValue:[sender floatValue]];
    [rampTimeSlider setFloatValue:[sender floatValue]];
    [[tactileDisplay tone] setRampTime:[sender floatValue]];
    return self;
}


/* TABLET SETTINGS **********************************************************************************/


- sendTabletCommands:sender
{
    [tabletDriver sendCommandsToTablet:[sender stringValue]];
    return self;
}

- setTTYBaudRate:sender
{
    id selCell = [sender selectedCell];

    [tabletDriver setInBaud:[selCell tag]];
    [tabletDriver setOutBaud:[selCell tag]];
    return self;
}

- setTaskPriority:sender
{
    kern_return_t error;
    struct task_basic_info info;
    unsigned int info_count = TASK_BASIC_INFO_COUNT;

    [priorityText setIntValue:[sender intValue]];
    [prioritySlider setIntValue:[sender intValue]];

    // raise base task priority
    error = task_info(task_self(), TASK_BASIC_INFO, (task_info_t)&info, &info_count);
    if (error != KERN_SUCCESS) {
	mach_error("Error calling task_info()", error);
    } else {   // set this task's base priority to be higher than normal
	error = task_priority(task_self(), info.base_priority = [sender intValue], TRUE);
	if (error != KERN_SUCCESS)
	    mach_error("Call to task_priority() failed", error);
    }
    return self;
}

- setEventCoalescing:sender
{
    [tabletDriver setDeviceTracking:[sender state]];
    return self;
}

- setLineWrapping:sender
{
    id document = [tactileDisplay document];
    int lineWrapColumns = [lineWrapColumnsText intValue];

    if ([sender state]) {   // line wrap is on

	[lineWrapColumnsText setEnabled:YES];
	if (lineWrapColumns <= 0) {   // invalid line length
	    [lineWrapColumnsText setIntValue:lastLineWrapColumns];
	    return self;
	}

	// must unwrap lines first to preserve original layout
	[document unwrapLines];

	[document publishEnglishTextWithLineLength:lineWrapColumns];
	lastLineWrapColumns = lineWrapColumns;

    } else {   // line wrap is off

	[lineWrapColumnsText setEnabled:NO];
	[document unwrapLines];

	// now we need to republish so node lists are updated
	[document publishEnglishText];

	lastLineWrapColumns = 0;
    }

    [document setRelativeActivePage:0];   // update display
    return self;
}

- setLineWrapColumns:sender
{
    return [self setLineWrapping:lineWrapSwitch];
}

- changeDevice:sender
{
    const char *deviceName = NULL;

    [tabletDriver free];
    switch ([[deviceRadioButtons selectedCell] tag]) {
      case TNT_TTYA:
	deviceName = "/dev/ttya";
	break;
      case TNT_TTYB:
	deviceName = "/dev/ttyb";
	break;
      default:
	break;
    }
    
    [self createTabletDriver:deviceName];
    if (!NXWriteDefault(TNT_DEFAULTS_OWNER, TNT_DEVICE_NAME, deviceName))
	NXLogError("TouchNTalk: Could not write to defaults database.");
    return self;
}

@end

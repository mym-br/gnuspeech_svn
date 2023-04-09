/*
 *    Filename:	PenDraw.m 
 *    Created :	Thu Oct 21 23:31:49 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Sat Jan 21 16:27:38 1995"
 *    Copyright (c) 1995, Dale Brisinda. All rights reserved.
 */

#import <tabletkit/tabletkit.h>
#import "CanvasControl.h"
#import "PenDraw.h"

/* Radio button device tags. */
#define PD_TTYA              0
#define PD_TTYB              1

/* Radio button tablet cursor image tags. */
#define PD_PENCIL            0
#define PD_CROSS             1
#define PD_NOCURSOR          2

/* Defaults owner and names. */
#define PD_DEFAULTS_OWNER    [NXApp appName]
#define PD_DEVICE_NAME       "DeviceName"

/* Cursor image names. */
#define PD_PENCIL_IMAGE      "Pencil.tiff"
#define PD_CROSS_IMAGE       "Crosshair.tiff"

/* Library tablet reader used with PenDraw. */
#define PD_TABLET_READER     "SummaMMBinaryReader.bundle"

/* Tablet report modes. */
#define PD_HYSTERESIS_REPORT "@I#"   // event mode w/ location hysteresis of 3
#define PD_NORMAL_REPORT     "@I "   // event mode w/ no location hysteresis

/* Summagraphics 1201 command string for 1120x832 resolution. */
#define PD_1xDISPLAY_RES     "r\x64\x04\x4b\x03"

/* Class variables. */
static NXDefaultsVector PDDefaults = {{PD_DEVICE_NAME, "/dev/ttyb"},
					  {NULL}};

@implementation PenDraw


/* CLASS INITIALIZATION ******************************************************/


+ initialize
{
    if (!NXRegisterDefaults(PD_DEFAULTS_OWNER, PDDefaults))
	NXLogError("Defaults database could not be opened (initialize).");
    return self;
}


/* INITIALIZING AND FREEING **************************************************/


- init
{
    [super init];

    // get shared instances of open and save panel
    openPanel = [OpenPanel new];
    savePanel = [SavePanel new];

    [savePanel setDirectory:NXHomeDirectory()];
    [openPanel setDirectory:NXHomeDirectory()];

    // ensure that a required file type has been set for the save panel
    [savePanel setRequiredFileType:"tiff"];
    
    tabletDriver = nil;
    canvasControl = nil;
    offset = 0.0;
    canvasNum = 0;
    appFileLaunch = NO;

    return self;
}

- createTabletDriver:(const char *)deviceName
{
    if (!(tabletDriver = 
	  [[TabletDriver alloc] initTabletDevice:deviceName 
				tabletReader:PD_TABLET_READER])) {
	NXBeep();
	NXLogError("Could not connect to tablet (createTabletDriver:).");
	NXRunAlertPanel("Error", "Could not connect to the tablet.",
			NULL, NULL, NULL);
	return nil;
    }

    // Set the tablet so that it is reporting at approximately 114 rps. We 
    // complete the command to the tablet after a brief delay in order to give
    // the tablet time to send the <ACK>. We could do a lot of things here, 
    // like change the resolution of the tablet to correspond (map) to a 
    // pariticular display size, for example. We could even boost the rps to a
    // maximum of 164 by setting the in and out baud to B19200.

    [tabletDriver sendCommandsToTablet:PD_NORMAL_REPORT];
    [[[tabletDriver sendCommandsToTablet:"Qz "] setInBaud:B9600] setOutBaud:B9600];
    usleep(100000);   // delay for 1/10 of a second
    [tabletDriver sendCommandsToTablet:" "];

    // set tablet resolution
    [tabletDriver sendCommandsToTablet:PD_1xDISPLAY_RES];
    return self;
}

- free
{
    if (!NXWriteDefault(PD_DEFAULTS_OWNER, PD_DEVICE_NAME, 
			[tabletDriver tabletDevice]))
	NXLogError("Could not write to defaults database (free).");

    [tabletDriver free];
    return [super free];
}


/* APPLICATION DELEGATE METHODS **********************************************/


/* Peform additional intialization once the application has completely loaded
 * and initialized itself. See below for IMPORTANT information regarding
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

    if (!(deviceName = NXGetDefaultValue(PD_DEFAULTS_OWNER, PD_DEVICE_NAME)))
	NXLogError("Defaults database could not be opened (init).");
    [self createTabletDriver:deviceName];

    // create new empty document if app not launched from file in Workspace
    if (!appFileLaunch)
	[self newRequest:self];

    [saveMenuCell setUpdateAction:@selector(menuActive:) forMenu:docMenu];
    [saveAsMenuCell setUpdateAction:@selector(menuActive:) forMenu:docMenu];
    [saveAllMenuCell setUpdateAction:@selector(menuActive:) forMenu:docMenu];
    [revertToSavedMenuCell setUpdateAction:@selector(menuActive:) 
			   forMenu:docMenu];
    [closeMenuCell setUpdateAction:@selector(menuActive:) forMenu:docMenu];
    [NXApp setAutoupdate:YES];

    return self;
}

/* This is the method that is invoked when an application defined event is
 * detected. We check to see if the event type is infact a TabletKit event.
 * This is not necessary here, since we have not defined our own application
 * defined events -- we know the event is a TabletKit event. But if we did 
 * define our own events, we would check this field to distinguish between our
 * own app-defined events, and the app-defined TabletKit event. See the 
 * TabletKit documentation for more details.
 */
- applicationDefined:(NXEvent *)theEvent
{
    if (theEvent->TK_APPSUBTYPE == TK_EVENT) {
	[canvasControl trackEvent:theEvent];
    }
    return self;
}

- (BOOL)appAcceptsAnotherFile:sender
{
    return YES;
}

- (int)app:sender openFile:(const char *)filename type:(const char *)aType
{
    // app launched from file selected in Workspace
    appFileLaunch = YES;

    if ([self newRequest:self]) {

	// canvasControl outlet should now be set
	[[canvasControl window] setTitle:"Loading..."];
	if ([canvasControl openImageFile:filename])
	    return YES;
    }
    return NO;
}

- appWillTerminate:sender
{
    if ([self countEditedWindows] > 0) {

	int value = NXRunAlertPanel("Quit", "There are edited windows.",
				    "Review Unsaved", 
				    "Quit Anyway", 
				    "Cancel");

	if (value == NX_ALERTDEFAULT) {   // review unsaved

	    int i;
	    id winList;

	    winList = [NXApp windowList];
	    for (i = 0; i < [winList count]; i++) {
		id win = [winList objectAt:i];
		if ([[win delegate] isKindOf:[CanvasControl class]]) 
		    [win performClose:nil];
	    }
	    return self;
	}
    
	if (value == NX_ALERTOTHER)   // cancel
	    return nil;
    }
    return self;   // quit
}


/* PREFERENCES ***************************************************************/


- changeDevice:sender
{
    const char *deviceName = NULL;

    [tabletDriver free];
    switch ([[sender selectedCell] tag]) {   // sender is a matrix
      case PD_TTYA:
	deviceName = "/dev/ttya";
	break;
      case PD_TTYB:
	deviceName = "/dev/ttyb";
	break;
      default:
	break;
    }

    [self createTabletDriver:deviceName];
    if (!NXWriteDefault(PD_DEFAULTS_OWNER, PD_DEVICE_NAME, deviceName))
	NXLogError("Could not write to defaults database (changeDevice:).");
    return self;
}

- changeCursor:sender
{
    const char *cursorImage = NULL;

    switch ([[sender selectedCell] tag]) {   // sender is a matrix
      case PD_PENCIL:
	cursorImage = PD_PENCIL_IMAGE;
	break;
      case PD_CROSS:
	cursorImage = PD_CROSS_IMAGE;
	break;
      case PD_NOCURSOR:
	cursorImage = NULL;
	break;
      default:
	break;
    }
    [canvasControl setCursor:cursorImage];
    return self;
}


/* TARGET/ACTION METHODS *****************************************************/


- changeLineWidth:sender
{
    float lineWidth = [sender floatValue];

    if ([sender isKindOf:[Slider class]])
	[lineWidthTextField setFloatValue:lineWidth];
    else
	[lineWidthSlider setFloatValue:lineWidth];
    [canvasControl setLineWidth:lineWidth];
    return self;
}

- changeLineColor:sender
{
    [canvasControl setLineColor:[sender color]];
    return self;
}

- clearCanvas:sender
{
    [canvasControl clearCanvas];
    return self;
}

- selectTIFFImageFormat:sender
{
    [savePanel setRequiredFileType:"tiff"];
    return self;
}

- selectEPSImageFormat:sender
{
    [savePanel setRequiredFileType:"eps"];
    return self;
}


/* QUERY METHODS *************************************************************/


- (float)lineWidth
{
    return [lineWidthTextField floatValue];
}

- (NXColor)lineColor
{
    return [lineColorWell color];
}

- accessoryContentView
{
    return [accessoryPanel contentView];
}


/* SET METHODS ***************************************************************/


- setCanvasControl:canvasCtl
{
    canvasControl = canvasCtl;
    return self;
}


/* DOCUMENT OPERATION METHODS ************************************************/


- newRequest:sender
{
    id window;
    
    if ([NXApp loadNibSection:"canvasWindow.nib" owner:self] == nil)
	return nil;

    // canvasControl outlet should now be set
    if (window = [canvasControl window]) {
	NXRect frame;
	char buffer[16];

	[window getFrame:&frame];
	NX_X(&frame) += offset;
	NX_Y(&frame) -= offset;
	if ((offset += 24.0) > 144.0)   // max. of 7 stacked windows
	    offset = 0.0;

	sprintf(buffer, [window title], ++canvasNum);
	[window setTitle:buffer];
	[window placeWindowAndDisplay:&frame];
	[window makeKeyAndOrderFront:nil];

	// init drawing attributes
	[canvasControl setLineWidth:[lineWidthSlider floatValue]];
	[canvasControl setLineColor:[lineColorWell color]];
	return canvasControl;
    }
    return nil;
}

- openRequest:sender
{
    const char *const fileTypes[] = {"tiff", "eps", NULL};

    if ([openPanel runModalForTypes:fileTypes]) {
	if ([self newRequest:self]) {

	    // canvasControl outlet should now be set
	    [[canvasControl window] setTitle:"Loading..."];
	    [canvasControl openImageFile:[openPanel filename]];
	}
    }
    return self;
}

- saveAllRequest:sender
{
    id winList;
    int i;

    winList = [NXApp windowList];
    for (i = 0; i < [winList count]; i++) {

	id win = [winList objectAt:i];
	id delegate = [win delegate];

	if ([delegate isKindOf:[CanvasControl class]]) {
	    [win makeKeyAndOrderFront:nil];
	    [delegate save:win];
	}
    }
    return self;
}

- revertToSavedRequest:sender
{
    const char *fname = [canvasControl filename];    
    id win = [canvasControl window];

    if ([win isDocEdited] && fname) {

	int value;
	if (rindex(fname, '/'))
	    fname = rindex(fname, '/') + 1;
	
	value = NXRunAlertPanel("Revert", "If you revert, you will lose all changes you made to %s after it was last saved.",
				"Revert Anyway", 
				"Cancel", 
				NULL, fname);

	if (value == NX_ALERTDEFAULT) {   // revert anyway
	    [win setTitle:"Reverting to saved..."];
	    [canvasControl openImageFile:[canvasControl filename]];
	    [win setDocEdited:NO];
	}
    }
    return self;
}

- (int)countEditedWindows
{
    id winList;
    int i, count = 0;

    winList = [NXApp windowList];
    for (i = 0; i < [winList count]; i++)
	if ([[winList objectAt:i] isDocEdited])
	    count++;
    return count;
}

- (BOOL)menuActive:menuCell
{
    BOOL shouldBeEnabled = 
	[[[NXApp mainWindow] delegate] isKindOf:[CanvasControl class]];

    if ([menuCell isEnabled] != shouldBeEnabled) {

	// Menu cell is either enabled and shouldn't be, or is not enabled and
	// should be. In either case, set the correct state.

	[menuCell setEnabled:shouldBeEnabled];
	return YES;   // redisplay
    }
    return NO;   // no change
}

@end

/*
 *    Filename:	TabletSurface.m 
 *    Created :	Fri Aug 20 01:38:15 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Tue Jul 26 11:27:05 1994"
 *
 * $Id: TabletSurface.m,v 1.14 1994/07/26 20:11:02 dale Exp $
 *
 * $Log: TabletSurface.m,v $
 * Revision 1.14  1994/07/26  20:11:02  dale
 * *** empty log message ***
 *
 * Revision 1.13  1994/07/25  02:30:52  dale
 * *** empty log message ***
 *
 * Revision 1.12  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.11  1994/05/28  21:24:37  dale
 * *** empty log message ***
 *
 * Revision 1.10  1993/10/10  20:58:14  dale
 * *** empty log message ***
 *
 * Revision 1.9  1993/09/04  17:49:22  dale
 * Added previous page and next page configuration.
 *
 * Revision 1.8  1993/09/01  19:35:12  dale
 * *** empty log message ***
 *
 * Revision 1.7  1993/08/31  04:51:27  dale
 * Added skeletal methods for returning the partition of a groove in region and groove. This method
 * depends on the machining of the tablet, and groove lengths.
 *
 * Revision 1.6  1993/08/27  08:08:08  dale
 * Added methods to free regions and restore/create grooves based on defaults if configuration is
 * cancelled. Lines added in the -getClickLocation: method.
 *
 * Revision 1.5  1993/08/27  03:51:06  dale
 * *** empty log message ***
 *
 * Revision 1.4  1993/08/25  05:42:14  dale
 * *** empty log message ***
 *
 * Revision 1.3  1993/08/24  10:17:58  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/08/24  05:47:43  dale
 * *** empty log message ***
 *
 * Revision 1.1  1993/08/24  02:08:33  dale
 * Initial revision
 *
 *
 * The TouchNTalk region definitions appearing in TNTDefinitions.h are used here as states for
 * advancing the configuration process to the next region of the tablet. They are also used as the
 * defaults vector indices for storing the configuration information for that region.
 */

#import <tabletkit/tabletkit.h>
#import <TextToSpeech/TextToSpeech.h>
#import "Publisher.tproj.h"
#import "TabletRegion.h"
#import "TabletGroove.h"
#import "TabletSurface.h"

/* Defaults owner. */
#define TNT_DEFAULTS_OWNER        [NXApp appName]

/* Defaults names. */
#define TNT_DEFAULTS_CONFIGURE    "Configure"
#define TNT_DEFAULTS_SOFTAREA     "SoftArea"
#define TNT_DEFAULTS_LEFTHOLO     "LeftHolo"
#define TNT_DEFAULTS_TOPHOLO      "TopHolo"
#define TNT_DEFAULTS_RIGHTAREA    "RightArea"
#define TNT_DEFAULTS_TACTILEAREA  "TactileArea"
#define TNT_DEFAULTS_SILAREA      "SILArea"
#define TNT_DEFAULTS_PREVAREA     "PrevArea"
#define TNT_DEFAULTS_NEXTAREA     "NextArea"

/* Configure vector default index. */
#define TNT_CONFIGVECT_INDEX      0

/* Region location states. */
#define INIT                      0
#define LOCATION1                 1
#define LOCATION2                 2
#define LOCATION3                 3
#define LOCATION4                 4

/* Class variables. */
NXDefaultsVector TNTVector = {{TNT_DEFAULTS_CONFIGURE, "YES"},
				  {TNT_DEFAULTS_SOFTAREA, NULL},
				  {TNT_DEFAULTS_LEFTHOLO, NULL},
				  {TNT_DEFAULTS_TOPHOLO, NULL},
				  {TNT_DEFAULTS_RIGHTAREA, NULL},
				  {TNT_DEFAULTS_TACTILEAREA, NULL},
				  {TNT_DEFAULTS_SILAREA, NULL},
				  {TNT_DEFAULTS_PREVAREA, NULL},
				  {TNT_DEFAULTS_NEXTAREA, NULL},
				  {NULL}};

@implementation TabletSurface


/* INITIALIZING AND FREEING *************************************************************************/


/* This method is the designated initializer. Returns self. */
- init
{
    [super init];
    [self initRegionIVars];
    configureCancelled = NO;

    if (!(speaker = [[TextToSpeech allocFromZone:[self zone]] init])) {   // no connection possible
	NXBeep();
	NXRunAlertPanel("TextToSpeech Server", "Too many clients, or server cannot be started.", 
			"OK", NULL, NULL);
	[NXApp terminate:self];
    }
    return self;
}

/* This method should not be invoked externally. */
- initRegionIVars
{
    softArea = leftHolo = topHolo = rightArea = tactileArea = silArea = prevArea = nextArea = nil;
    return self;
}

- free
{
    [speaker free];
    [self freeRegions];
    return [super free];
}

/* This method should not be invoked externally. */
- freeRegions
{
    if (softArea) {
	[softArea free];
    }
    if (leftHolo) {
	[leftHolo free];
    }
    if (topHolo) {
	[topHolo free];
    }
    if (rightArea) {
	[rightArea free];
    }
    if (tactileArea) {
	[tactileArea free];
    }
    if (silArea) {
	[silArea free];
    }
    if (prevArea) {
	[prevArea free];
    }
    if (nextArea) {
	[nextArea free];
    }
    return self;
}

/* Reverts to the previous regions if the configuration process is cancelled. This method must be 
 * called externally to actually force the reversion. This should be called within a "cancel" 
 * target/action method. The method performs the reversion by reading the defaults database once 
 * again. Returns nil if we could not revert to the previous defaults, since the defaults were unable
 * to be registered. Otherwise returns self.
 */
- revertToPreviousRegions
{
    return [[[self freeRegions] initRegionIVars] registerDefaults];
}


/* TABLET CONFIGURATION  ****************************************************************************/


- showConfigurePanel
{
    // init values and speak initial message
    [(TextToSpeech *)speaker eraseAllSound];
    [(TextToSpeech *)speaker speakText:"Initiating tablet configuration."];
    [xCurrentField setFloatValue:0];
    [yCurrentField setFloatValue:0];
    [xClickField setFloatValue:0];
    [yClickField setFloatValue:0];
    [[configurePanel makeKeyAndOrderFront:nil] setFloatingPanel:YES];

    [[self freeRegions] initRegionIVars];
    configureCancelled = NO;

    // display/speak first instruction
    regionState = TNT_SOFTAREA;
    locationState = INIT;
    [self configureSoftArea];
    return self;
}

/* Configure all regions of the tablet. The user is prompted by text and speech to place the stylus in
 * various regions of the tablet in order to configure those regions for usage. We utilize the tablet
 * event passed, by updating the display to reflect the current stylus location. The click location of
 * the stylus is also indicated when the first stylus button STYLUSBUTTON1 is clicked. When the button
 * is released, the resulting location is the location entered for configuration applicable for the 
 * current region. Returns YES when tablet configuration is complete, otherwise returns NO, indicating
 * that more events are required in order to complete the configuration process. Note that we use
 * TNT_DEADZONE as a region state indicating we are finished configuring the tablet.
 */
- (BOOL)configure:(NXEvent *)anEvent
{
    // set current event for subsequent processing
    currentEvent = anEvent;

    switch (regionState) {
      case TNT_SOFTAREA:
	[self configureSoftArea];
	break;
      case TNT_LEFTHOLO:
	[self configureLeftHolo];
	break;
      case TNT_TOPHOLO:
	[self configureTopHolo];
	break;
      case TNT_RIGHTAREA:
	[self configureRightArea];
	break;
      case TNT_TACTILEAREA:
	[self configureTactileArea];
	break;
      case TNT_SILAREA:
	[self configureSILArea];
	break;
      case TNT_PREVAREA:
	[self configurePrevArea];
	break;
      case TNT_NEXTAREA:
	[self configureNextArea];
	break;
      case TNT_DEADZONE:
	[(TextToSpeech *)speaker eraseAllSound];
	[(TextToSpeech *)speaker speakText:"Tablet configuration complete."];    
	TNTVector[TNT_CONFIGVECT_INDEX].value = "NO";   // subsequent configure default
	if (NXWriteDefaults(TNT_DEFAULTS_OWNER, TNTVector) != TNT_DEFAULTS) {
	    NXLogError("TouchNTalk: Errors writing defaults.");
	}
	[configurePanel orderOut:nil];
	return YES; break;
      default:
	break;
    }	

    // configuration not complete
    return NO;
}


/* INTERNAL REGION CONFIGURATION ********************************************************************/


/* The following region configuration methods incoprorate a finite state machine approach to
 * configuration. This is required since the tablet events are generated externally, and passed to
 * the TabletSurface configuration method which records the value of the current event. As actions are
 * realized, the finite state machine is pushed into new states until all required states for tablet
 * configuration have been visited. When a region has been configured, the points for that region have
 * been entered by the user and placed in a bounding box. This bounding box is adjusted so that it is
 * perfectly square. A safety value is then added to the width of the box if it bounds a set of 
 * vertical grooves, or to the height of the box if it bounds a set of horizontal grooves. The origin
 * must also then be adjusted to compensate for this safety. All methods return self.
 */

/* Always the first region to be configured. Because of this, the code structure is slightly 
 * different. The first call to this method will perform some iitialization then immediately return 
 * (if location == INIT). See -showConfigurePanel which calls this method initially. Returns self.
 */
- configureSoftArea
{
    static NXPoint upper, lower;
    static char buffer[64];

    if (locationState == INIT) {
	locationState = LOCATION1;
	[locationTitle setStringValue:"upper end"];
	[regionTitle setStringValue:"SOFT AREA."];
	[(TextToSpeech *)speaker speakText:"Tap stylus at upper end of soft area."];
    } else if (locationState == LOCATION1) {
	if ([self getClickLocation:&upper]) {   // we have upper click
	    locationState = LOCATION2;
	    [locationTitle setStringValue:"lower end"];
	    [(TextToSpeech *)speaker eraseAllSound];
	    [(TextToSpeech *)speaker speakText:"Tap stylus at lower end of soft area."];
	}
    } else if (locationState == LOCATION2) {
	if ([self getClickLocation:&lower]) {   // we have lower click
	    locationState = INIT;         // for next region
	    regionState = TNT_LEFTHOLO;

	    // create Region instance and store defaults vector
	    softArea = [[TabletRegion allocFromZone:[self zone]] initUpperLeft:&upper
								 lowerLeft:&lower 
								 upperRight:&upper
								 lowerRight:&lower
								 tag:TNT_SOFTAREA];
	    sprintf(buffer, "%.0f %.0f %.0f %.0f", upper.x, upper.y, lower.x, lower.y); 
	    TNTVector[TNT_SOFTAREA].value = buffer;
	}
    }
    return self;
}

- configureLeftHolo;
{
    static NXPoint upperLeft, lowerLeft, upperRight, lowerRight;
    static char buffer[64];

    if (locationState == INIT) {
	locationState = LOCATION1;
	[locationTitle setStringValue:"upper left"];
	[regionTitle setStringValue:"LEFT HOLO."];
	[(TextToSpeech *)speaker eraseAllSound];
	[(TextToSpeech *)speaker speakText:"Tap stylus at upper left of left holo."];
    }
    if (locationState == LOCATION1) {
	if ([self getClickLocation:&upperLeft]) {   // we have upper left click
	    locationState = LOCATION2;
	    [locationTitle setStringValue:"lower left"];
	    [(TextToSpeech *)speaker eraseAllSound];
	    [(TextToSpeech *)speaker speakText:"Tap stylus at lower left of left holo."];
	}
    } else if (locationState == LOCATION2) {
	if ([self getClickLocation:&lowerLeft]) {   // we have lower left click
	    locationState = LOCATION3;
	    [locationTitle setStringValue:"upper right"];
	    [(TextToSpeech *)speaker eraseAllSound];
	    [(TextToSpeech *)speaker speakText:"Tap stylus at upper right of left holo."];
	}
    } else if (locationState == LOCATION3) {
	if ([self getClickLocation:&upperRight]) {   // we have upper right click
	    locationState = LOCATION4;
	    [locationTitle setStringValue:"lower right"];
	    [(TextToSpeech *)speaker eraseAllSound];
	    [(TextToSpeech *)speaker speakText:"Tap stylus at lower right of left holo."];
	}
    } else if (locationState == LOCATION4) {
	if ([self getClickLocation:&lowerRight]) {   // we have lower right click
	    locationState = INIT;        // for next region
	    regionState = TNT_TOPHOLO;

	    // create Region instance and store defaults vector
	    leftHolo = [[TabletRegion allocFromZone:[self zone]] initUpperLeft:&upperLeft 
								 lowerLeft:&lowerLeft 
								 upperRight:&upperRight 
								 lowerRight:&lowerRight
								 tag:TNT_LEFTHOLO];
	    sprintf(buffer, "%.0f %.0f %.0f %.0f %.0f %.0f %.0f %.0f", upperLeft.x, upperLeft.y,
		    lowerLeft.x, lowerLeft.y, upperRight.x, upperRight.y, lowerRight.x, lowerRight.y);
	    TNTVector[TNT_LEFTHOLO].value = buffer;
	}
    }
    return self;
}

- configureTopHolo
{
    static NXPoint upperLeft, lowerLeft, upperRight, lowerRight;
    static char buffer[64];

    if (locationState == INIT) {
	locationState = LOCATION1;
	[locationTitle setStringValue:"upper left"];
	[regionTitle setStringValue:"TOP HOLO."];
	[(TextToSpeech *)speaker eraseAllSound];
	[(TextToSpeech *)speaker speakText:"Tap stylus at upper left of top holo."];
    }
    if (locationState == LOCATION1) {
	if ([self getClickLocation:&upperLeft]) {   // we have upper left click
	    locationState = LOCATION2;
	    [locationTitle setStringValue:"lower left"];
	    [(TextToSpeech *)speaker eraseAllSound];
	    [(TextToSpeech *)speaker speakText:"Tap stylus at lower left of top holo."];
	}
    } else if (locationState == LOCATION2) {
	if ([self getClickLocation:&lowerLeft]) {   // we have lower left click
	    locationState = LOCATION3;
	    [locationTitle setStringValue:"upper right"];
	    [(TextToSpeech *)speaker eraseAllSound];
	    [(TextToSpeech *)speaker speakText:"Tap stylus at upper right of top holo."];
	}
    } else if (locationState == LOCATION3) {
	if ([self getClickLocation:&upperRight]) {   // we have upper right click
	    locationState = LOCATION4;
	    [locationTitle setStringValue:"lower right"];
	    [(TextToSpeech *)speaker eraseAllSound];
	    [(TextToSpeech *)speaker speakText:"Tap stylus at lower right of top holo."];
	}
    } else if (locationState == LOCATION4) {
	if ([self getClickLocation:&lowerRight]) {   // we have lower right click
	    locationState = INIT;        // for next region
	    regionState = TNT_RIGHTAREA;

	    // create Region instance and store defaults vector
	    topHolo = [[TabletRegion allocFromZone:[self zone]] initUpperLeft:&upperLeft 
								lowerLeft:&lowerLeft 
								upperRight:&upperRight 
								lowerRight:&lowerRight
								tag:TNT_TOPHOLO];
	    sprintf(buffer, "%.0f %.0f %.0f %.0f %.0f %.0f %.0f %.0f", upperLeft.x, upperLeft.y,
		    lowerLeft.x, lowerLeft.y, upperRight.x, upperRight.y, lowerRight.x, lowerRight.y);
	    TNTVector[TNT_TOPHOLO].value = buffer;
	}
    }
    return self;
}

- configureRightArea
{
    static NXPoint upperLeft, lowerLeft, upperRight, lowerRight;
    static char buffer[64];

    if (locationState == INIT) {
	locationState = LOCATION1;
	[locationTitle setStringValue:"upper left"];
	[regionTitle setStringValue:"RIGHT AREA."];
	[(TextToSpeech *)speaker eraseAllSound];
	[(TextToSpeech *)speaker speakText:"Tap stylus at upper left of right area."];
    }
    if (locationState == LOCATION1) {
	if ([self getClickLocation:&upperLeft]) {   // we have upper left click
	    locationState = LOCATION2;
	    [locationTitle setStringValue:"lower left"];
	    [(TextToSpeech *)speaker eraseAllSound];
	    [(TextToSpeech *)speaker speakText:"Tap stylus at lower left of right area."];
	}
    } else if (locationState == LOCATION2) {
	if ([self getClickLocation:&lowerLeft]) {   // we have lower left click
	    locationState = LOCATION3;
	    [locationTitle setStringValue:"upper right"];
	    [(TextToSpeech *)speaker eraseAllSound];
	    [(TextToSpeech *)speaker speakText:"Tap stylus at upper right of right area."];
	}
    } else if (locationState == LOCATION3) {
	if ([self getClickLocation:&upperRight]) {   // we have upper right click
	    locationState = LOCATION4;
	    [locationTitle setStringValue:"lower right"];
	    [(TextToSpeech *)speaker eraseAllSound];
	    [(TextToSpeech *)speaker speakText:"Tap stylus at lower right of right area."];
	}
    } else if (locationState == LOCATION4) {
	if ([self getClickLocation:&lowerRight]) {   // we have lower right click
	    locationState = INIT;        // for next region
	    regionState = TNT_TACTILEAREA;

	    // create Region instance and store defaults vector
	    rightArea = [[TabletRegion allocFromZone:[self zone]] initUpperLeft:&upperLeft
								  lowerLeft:&lowerLeft
								  upperRight:&upperRight
								  lowerRight:&lowerRight
								  tag:TNT_RIGHTAREA];
	    sprintf(buffer, "%.0f %.0f %.0f %.0f %.0f %.0f %.0f %.0f", upperLeft.x, upperLeft.y,
		    lowerLeft.x, lowerLeft.y, upperRight.x, upperRight.y, lowerRight.x, lowerRight.y);
	    TNTVector[TNT_RIGHTAREA].value = buffer;
	}
    }
    return self;
}

- configureTactileArea
{
    static NXPoint upperLeft, lowerLeft, upperRight, lowerRight;
    static char buffer[64];

    if (locationState == INIT) {
	locationState = LOCATION1;
	[locationTitle setStringValue:"upper left"];
	[regionTitle setStringValue:"TACTILE AREA."];
	[(TextToSpeech *)speaker eraseAllSound];
	[(TextToSpeech *)speaker speakText:"Tap stylus at upper left of tactile area."];
    }
    if (locationState == LOCATION1) {
	if ([self getClickLocation:&upperLeft]) {   // we have upper left click
	    locationState = LOCATION2;
	    [locationTitle setStringValue:"lower left"];
	    [(TextToSpeech *)speaker eraseAllSound];
	    [(TextToSpeech *)speaker speakText:"Tap stylus at lower left of tactile area."];
	}
    } else if (locationState == LOCATION2) {
	if ([self getClickLocation:&lowerLeft]) {   // we have lower left click
	    locationState = LOCATION3;
	    [locationTitle setStringValue:"upper right"];
	    [(TextToSpeech *)speaker eraseAllSound];
	    [(TextToSpeech *)speaker speakText:"Tap stylus at upper right of tactile area."];
	}
    } else if (locationState == LOCATION3) {
	if ([self getClickLocation:&upperRight]) {   // we have upper right click
	    locationState = LOCATION4;
	    [locationTitle setStringValue:"lower right"];
	    [(TextToSpeech *)speaker eraseAllSound];
	    [(TextToSpeech *)speaker speakText:"Tap stylus at lower right of tactile area."];
	}
    } else if (locationState == LOCATION4) {
	if ([self getClickLocation:&lowerRight]) {   // we have lower right click
	    locationState = INIT;        // for next region
	    regionState = TNT_SILAREA;

	    // create Region instance and store defaults vector
	    tactileArea = [[TabletRegion allocFromZone:[self zone]] initUpperLeft:&upperLeft
								    lowerLeft:&lowerLeft
								    upperRight:&upperRight
								    lowerRight:&lowerRight
								    tag:TNT_TACTILEAREA];
	    sprintf(buffer, "%.0f %.0f %.0f %.0f %.0f %.0f %.0f %.0f", upperLeft.x, upperLeft.y,
		    lowerLeft.x, lowerLeft.y, upperRight.x, upperRight.y, lowerRight.x, lowerRight.y);
	    TNTVector[TNT_TACTILEAREA].value = buffer;
	}
    }
    return self;
}

- configureSILArea
{
    static NXPoint left, right;
    static char buffer[64];

    if (locationState == INIT) {
	locationState = LOCATION1;
	[locationTitle setStringValue:"left end"];
	[regionTitle setStringValue:"SIL AREA."];
	[(TextToSpeech *)speaker eraseAllSound];
	[(TextToSpeech *)speaker speakText:"Tap stylus at left end of sil area."];
    }
    if (locationState == LOCATION1) {
	if ([self getClickLocation:&left]) {   // we have left click
	    locationState = LOCATION2;
	    [locationTitle setStringValue:"right end"];
	    [(TextToSpeech *)speaker eraseAllSound];
	    [(TextToSpeech *)speaker speakText:"Tap stylus at right end of sil area."];
	}
    } else if (locationState == LOCATION2) {
	if ([self getClickLocation:&right]) {   // we have right click
	    locationState = INIT;         // for next region
	    regionState = TNT_PREVAREA;

	    // create Region instance and store defaults vector
	    silArea = [[TabletRegion allocFromZone:[self zone]] initUpperLeft:&left
								lowerLeft:&left
								upperRight:&right
								lowerRight:&right
								tag:TNT_SILAREA];
	    sprintf(buffer, "%.0f %.0f %.0f %.0f", left.x, left.y, right.x, right.y);
	    TNTVector[TNT_SILAREA].value = buffer;
	}
    }
    return self;
}

- configurePrevArea
{
    static NXPoint upperLeft, lowerLeft, upperRight, lowerRight;
    static char buffer[64];
    
    if (locationState == INIT) {
	locationState = LOCATION1;
	[locationTitle setStringValue:"upper left"];
	[regionTitle setStringValue:"P. PAGE AREA."];
	[(TextToSpeech *)speaker eraseAllSound];
	[(TextToSpeech *)speaker speakText:"Tap stylus at upper left of previous page area."];
    }
    if (locationState == LOCATION1) {
	if ([self getClickLocation:&upperLeft]) {   // we have upper left click
	    locationState = LOCATION2;
	    [locationTitle setStringValue:"lower right"];
	    [(TextToSpeech *)speaker eraseAllSound];
	    [(TextToSpeech *)speaker speakText:"Tap stylus at lower right of previous page area."];
	}
    } else if (locationState == LOCATION2) {
	if ([self getClickLocation:&lowerRight]) {   // we have lower right click
	    locationState = INIT;   // for next region
	    regionState = TNT_NEXTAREA;

	    lowerLeft.x = upperLeft.x; 
	    lowerLeft.y = lowerRight.y;
	    upperRight.x = lowerRight.x; 
	    upperRight.y = upperLeft.y;

	    // create Region instance and store defaults vector
	    prevArea = [[TabletRegion allocFromZone:[self zone]] initUpperLeft:&upperLeft
								 lowerLeft:&lowerLeft
								 upperRight:&upperRight
								 lowerRight:&lowerRight
								 tag:TNT_PREVAREA];
	    sprintf(buffer, "%.0f %.0f %.0f %.0f %.0f %.0f %.0f %.0f", upperLeft.x, upperLeft.y, 
		    lowerLeft.x, lowerLeft.y, upperRight.x, upperRight.y, lowerRight.x, lowerRight.y);
	    TNTVector[TNT_PREVAREA].value = buffer;
	}
    }
    return self;
}

- configureNextArea
{
    static NXPoint upperLeft, lowerLeft, upperRight, lowerRight;
    static char buffer[64];
    
    if (locationState == INIT) {
	locationState = LOCATION1;
	[locationTitle setStringValue:"upper left"];
	[regionTitle setStringValue:"N. PAGE AREA."];
	[(TextToSpeech *)speaker eraseAllSound];
	[(TextToSpeech *)speaker speakText:"Tap stylus at upper left of next page area."];
    }
    if (locationState == LOCATION1) {
	if ([self getClickLocation:&upperLeft]) {   // we have upper left click
	    locationState = LOCATION2;
	    [locationTitle setStringValue:"lower right"];
	    [(TextToSpeech *)speaker eraseAllSound];
	    [(TextToSpeech *)speaker speakText:"Tap stylus at lower right of next page area."];
	}
    } else if (locationState == LOCATION2) {
	if ([self getClickLocation:&lowerRight]) {   // we have lower right click
	    locationState = INIT;   // for next region
	    regionState = TNT_DEADZONE;

	    lowerLeft.x = upperLeft.x; 
	    lowerLeft.y = lowerRight.y;
	    upperRight.x = lowerRight.x; 
	    upperRight.y = upperLeft.y;

	    // create Region instance and store defaults vector
	    nextArea = [[TabletRegion allocFromZone:[self zone]] initUpperLeft:&upperLeft
								 lowerLeft:&lowerLeft
								 upperRight:&upperRight
								 lowerRight:&lowerRight
								 tag:TNT_NEXTAREA];
	    sprintf(buffer, "%.0f %.0f %.0f %.0f %.0f %.0f %.0f %.0f", upperLeft.x, upperLeft.y, 
		    lowerLeft.x, lowerLeft.y, upperRight.x, upperRight.y, lowerRight.x, lowerRight.y);
	    TNTVector[TNT_NEXTAREA].value = buffer;
	}
    }
    return self;
}


/* CONFIGURATION CLICK LOCATION *********************************************************************/


/* Attempts to obtain the location of the click, if the tablet kit event has the required button down.
 * If a complete click is encountered, the location is placed in thePoint, and YES is returned. 
 * Otherwise the value of thePoint is not modified, and NO is returned. In addition, various elements
 * of the display panel are updated to reflect the event location, and whether the stylus is clicked.
 * If the second stylus button is clicked, then this signifies a cancellation of the tablet 
 * configuration process ONLY if the cancel button is enabled. If the cancel button is disabled, then
 * cancellation cannot occur.
 */
- (BOOL)getClickLocation:(NXPoint *)thePoint
{
    if (currentEvent->TK_SUBTYPE == TK_STYLUSDOWN ||
	currentEvent->TK_SUBTYPE == TK_STYLUSDRAGGED) {   // a button is down

	if (currentEvent->TK_BUTTON == TK_BUTTON2) {   // cancel (barrel) button depressed
	    if ([cancelButton isEnabled]) {
		// load defaults with current defaults database definitions
		[[[self freeRegions] initRegionIVars] getDefaultValues];
		[cancelButton performClick:nil];   
	    }
	    return NO;

	} else if (currentEvent->TK_BUTTON == TK_BUTTON1) {   // primary button clicked
	    
	    // disable colors
	    [xCurrentTitle setTextGray:NX_DKGRAY];
	    [yCurrentTitle setTextGray:NX_DKGRAY];
	    [xCurrentField setTextGray:NX_DKGRAY];
	    [yCurrentField setTextGray:NX_DKGRAY];
	    
	    // enable colors
	    [xClickTitle setTextGray:NX_BLACK];
	    [yClickTitle setTextGray:NX_BLACK];
	    [xClickField setTextGray:NX_BLACK];
	    [yClickField setTextGray:NX_BLACK];
	}
	[xClickField setFloatValue:currentEvent->location.x];
	[yClickField setFloatValue:currentEvent->location.y];

    } else if (currentEvent->TK_SUBTYPE == TK_STYLUSUP) {   // stylus button is up

	// set disable colors for click coordinates, and enable colors for current coordinates
	NXBeep();   

	// disable colors
	[xClickTitle setTextGray:NX_DKGRAY];
	[yClickTitle setTextGray:NX_DKGRAY];
	[xClickField setTextGray:NX_DKGRAY];
	[yClickField setTextGray:NX_DKGRAY];
	
	// enable colors
	[xCurrentTitle setTextGray:NX_BLACK];
	[yCurrentTitle setTextGray:NX_BLACK];
	[xCurrentField setTextGray:NX_BLACK];
	[yCurrentField setTextGray:NX_BLACK];
	
	// load return parameters and return YES
	thePoint->x = currentEvent->location.x;
	thePoint->y = currentEvent->location.y;
	return YES;

    } else {   // anything else just updates current field

	[xCurrentField setFloatValue:currentEvent->location.x];
	[yCurrentField setFloatValue:currentEvent->location.y];
    }
    return NO;
}


/* DEFAULTS RELATED METHODS *************************************************************************/


/* Attempts to register the defaults. This has the effect of loading the application defaults from the
 * defaults database, and placing the paramter values in a quick access cache. If we cannot open the
 * database or the Configure default parameter equals YES, then we return nil, indicating that the 
 * tablet needs to be configured since we were unable to register the defaults. Otherwise if we were
 * able to successfully register the defaults, we return self.
 */
- registerDefaults
{
    const char *value;   // hold value of parameters

    if (!NXRegisterDefaults(TNT_DEFAULTS_OWNER, TNTVector)) {   // cannot open database
	NXLogError("TouchNTalk: Defaults database could not be opened.");
	return nil;
    } else {
	value = NXGetDefaultValue(TNT_DEFAULTS_OWNER, TNT_DEFAULTS_CONFIGURE);
	if (!value || strcmp(value, "NO")) {   // configure value != NO
	    return nil;
	}
    }

    // Get defaults and assume they are valid since TNT_DEFAULTS_CONFIGURE value is NO, which 
    // indicates that the tablet should not be configured since it already has been configured.

    [self getDefaultValues];
    return self;
}

/* Get the default values for all regions. For each value obtained, create the actual region by 
 * allocating and initializing new instances of the TabletRegion class with the region rectangle 
 * coordinates obtained from the defaults cache. Returns self.
 */
- getDefaultValues
{
    NXPoint upperLeft, lowerLeft, upperRight, lowerRight;
    NXPoint upper, lower, left, right;

    // soft area
    sscanf(NXGetDefaultValue(TNT_DEFAULTS_OWNER, TNT_DEFAULTS_SOFTAREA), "%f%f%f%f", 
	   &upper.x, &upper.y, &lower.x, &lower.y);
    softArea = [[TabletRegion allocFromZone:[self zone]] initUpperLeft:&upper
							 lowerLeft:&lower 
							 upperRight:&upper
							 lowerRight:&lower
							 tag:TNT_SOFTAREA];
    // left holo
    sscanf(NXGetDefaultValue(TNT_DEFAULTS_OWNER, TNT_DEFAULTS_LEFTHOLO), "%f%f%f%f%f%f%f%f",
	   &upperLeft.x, &upperLeft.y, &lowerLeft.x, &lowerLeft.y, 
	   &upperRight.x, &upperRight.y, &lowerRight.x, &lowerRight.y);
    leftHolo = [[TabletRegion allocFromZone:[self zone]] initUpperLeft:&upperLeft 
							 lowerLeft:&lowerLeft 
							 upperRight:&upperRight 
							 lowerRight:&lowerRight
							 tag:TNT_LEFTHOLO];
    // top holo
    sscanf(NXGetDefaultValue(TNT_DEFAULTS_OWNER, TNT_DEFAULTS_TOPHOLO), "%f%f%f%f%f%f%f%f",
	   &upperLeft.x, &upperLeft.y, &lowerLeft.x, &lowerLeft.y, 
	   &upperRight.x, &upperRight.y, &lowerRight.x, &lowerRight.y);
    topHolo = [[TabletRegion allocFromZone:[self zone]] initUpperLeft:&upperLeft 
							lowerLeft:&lowerLeft 
							upperRight:&upperRight 
							lowerRight:&lowerRight
							tag:TNT_TOPHOLO];
    // right area
    sscanf(NXGetDefaultValue(TNT_DEFAULTS_OWNER, TNT_DEFAULTS_RIGHTAREA), "%f%f%f%f%f%f%f%f",
	   &upperLeft.x, &upperLeft.y, &lowerLeft.x, &lowerLeft.y, 
	   &upperRight.x, &upperRight.y, &lowerRight.x, &lowerRight.y);
    rightArea = [[TabletRegion allocFromZone:[self zone]] initUpperLeft:&upperLeft
							  lowerLeft:&lowerLeft
							  upperRight:&upperRight
							  lowerRight:&lowerRight
							  tag:TNT_RIGHTAREA];
    // tactile area
    sscanf(NXGetDefaultValue(TNT_DEFAULTS_OWNER, TNT_DEFAULTS_TACTILEAREA), "%f%f%f%f%f%f%f%f",
	   &upperLeft.x, &upperLeft.y, &lowerLeft.x, &lowerLeft.y, 
	   &upperRight.x, &upperRight.y, &lowerRight.x, &lowerRight.y);
    tactileArea  = [[TabletRegion allocFromZone:[self zone]] initUpperLeft:&upperLeft
							     lowerLeft:&lowerLeft
							     upperRight:&upperRight
							     lowerRight:&lowerRight
							     tag:TNT_TACTILEAREA];
    // sil area
    sscanf(NXGetDefaultValue(TNT_DEFAULTS_OWNER, TNT_DEFAULTS_SILAREA), "%f%f%f%f",
	   &left.x, &left.y, &right.x, &right.y);
    silArea = [[TabletRegion allocFromZone:[self zone]] initUpperLeft:&left
							lowerLeft:&left
							upperRight:&right
							lowerRight:&right
							tag:TNT_SILAREA];
    // prev area
    sscanf(NXGetDefaultValue(TNT_DEFAULTS_OWNER, TNT_DEFAULTS_PREVAREA), "%f%f%f%f%f%f%f%f",
	   &upperLeft.x, &upperLeft.y, &lowerLeft.x, &lowerLeft.y, 
	   &upperRight.x, &upperRight.y, &lowerRight.x, &lowerRight.y);
    prevArea = [[TabletRegion allocFromZone:[self zone]] initUpperLeft:&upperLeft
							 lowerLeft:&lowerLeft
							 upperRight:&upperRight
							 lowerRight:&lowerRight
							 tag:TNT_PREVAREA];
    // next area
    sscanf(NXGetDefaultValue(TNT_DEFAULTS_OWNER, TNT_DEFAULTS_NEXTAREA), "%f%f%f%f%f%f%f%f",
	   &upperLeft.x, &upperLeft.y, &lowerLeft.x, &lowerLeft.y, 
	   &upperRight.x, &upperRight.y, &lowerRight.x, &lowerRight.y);
    nextArea = [[TabletRegion allocFromZone:[self zone]] initUpperLeft:&upperLeft
							 lowerLeft:&lowerLeft
							 upperRight:&upperRight
							 lowerRight:&lowerRight
							 tag:TNT_NEXTAREA];
    return self;
}


/* GENERAL QUERY METHODS ****************************************************************************/


- softArea
{
    return softArea;
}

- leftHolo
{
    return leftHolo;
}

- topHolo
{
    return topHolo;
}

- rightArea
{
    return rightArea;
}

- tactileArea
{
    return tactileArea;
}

- silArea
{
    return silArea;
}

- prevArea
{
    return prevArea;
}

- nextArea
{
    return nextArea;
}

- configurePanel
{
    return configurePanel;
}

- speaker
{
    return speaker;
}


/* REGION AND GROOVE QUERY **************************************************************************/


/* Returns the region in which aPoint lies. We search the regions in the order in which they are 
 * likely to be most often used. If the point is in none of the regions of the tablet, then we return
 * nil to indicate the point is in an undefined region (deadzone).
 */
- regionForPoint:(const NXPoint *)aPoint
{
    if ([tactileArea inRegion:aPoint]) {
	return tactileArea;
    } else if ([leftHolo inRegion:aPoint]) {
	return leftHolo;
    } else if ([softArea inRegion:aPoint]) {
	return softArea;
    } else if ([rightArea inRegion:aPoint]) {
	return rightArea;
    } else if ([topHolo inRegion:aPoint]) {
	return topHolo;
    } else if ([nextArea inRegion:aPoint]) {
	return nextArea;
    } else if ([prevArea inRegion:aPoint]) {
	return prevArea;
    } else if ([silArea inRegion:aPoint]) {
	return silArea;
    } else {
	return nil;
    }
}

/* Only call this method if you will not require the region of the point since this method utilizes
 * calls to both -regionForPoint: and -grooveForPoint:inRegion: in order to return the groove. Returns
 * the groove of the point or nil if the point is not in a groove.
 */
- grooveForPoint:(const NXPoint *)aPoint
{
    return [self grooveForPoint:aPoint inRegion:[self regionForPoint:aPoint]];
}

/* Returns the groove for aPoint in region aRegion. Assumes the point is in fact within the region 
 * aRegion. For regions we know have more than one groove, we obtain the groove by calculation rather
 * than sequential/binary searching. This makes the algorithm O(1). Suppose we are dealing with a
 * horizontal region.
 *
 * Since all grooves within a region are copies of the first groove in the region, we can determine
 * which groove is active by the difference in the location of the point and the origin of the region
 * bounding box. We can then divide this value by the sum of the width of grooves within the region
 * and the gap between grooves (constant for each region). We finally take the floor function of the
 * result to arrive at a value which when subtracted from the number of grooves in the region less one
 * results in the groove index in the regions grooveList, which corresponds to the active groove. For
 * vertical grooves, we can omit the last step, and simply use the floor function of the previous 
 * result to arrive at the index in the regions grooveList which corresponds to the active groove.
 */
- grooveForPoint:(const NXPoint *)aPoint inRegion:aRegion
{
    int grooveIndex = 0;

    switch ([aRegion tag]) {

      case TNT_TACTILEAREA:
	grooveIndex = TNT_TACTILEAREA_GROOVES - (int)floor((aPoint->y - [aRegion originY]) / 
							   ([[aRegion grooveAt:0] height] + 
							    [aRegion grooveGap])) - 1;
	if ([tactileArea isPoint:aPoint inGrooveAt:grooveIndex]) {
	    return [tactileArea grooveAt:grooveIndex];
	}
	break;

      case TNT_LEFTHOLO:
	grooveIndex = (int)floor((aPoint->x - [aRegion originX]) / 
				 ([[aRegion grooveAt:0] width] + [aRegion grooveGap]));
	if ([leftHolo isPoint:aPoint inGrooveAt:grooveIndex]) {
	    return [leftHolo grooveAt:grooveIndex];
	}
	break;
	
      case TNT_SOFTAREA:
	if ([softArea isPoint:aPoint inGrooveAt:0]) {
	    return [softArea grooveAt:grooveIndex];
	}
	break;
	
      case TNT_RIGHTAREA:
	grooveIndex = (int)floor((aPoint->x - [aRegion originX]) / 
				 ([[aRegion grooveAt:0] width] + [aRegion grooveGap]));
	if ([rightArea isPoint:aPoint inGrooveAt:grooveIndex]) {
	    return [rightArea grooveAt:grooveIndex];
	}
	break;
	
      case TNT_TOPHOLO:
	grooveIndex = TNT_TOPHOLO_GROOVES - (int)floor((aPoint->y - [aRegion originY]) / 
						       ([[aRegion grooveAt:0] height] + 
							[aRegion grooveGap])) - 1;
	if ([topHolo isPoint:aPoint inGrooveAt:grooveIndex]) {
	    return [topHolo grooveAt:grooveIndex];
	}
	break;
	
      case TNT_NEXTAREA:
	if ([nextArea isPoint:aPoint inGrooveAt:0]) {
	    return [nextArea grooveAt:grooveIndex];
	}
	break;
	
      case TNT_PREVAREA:
	if ([prevArea isPoint:aPoint inGrooveAt:0]) {
	    return [prevArea grooveAt:grooveIndex];
	}
	break;
	
      case TNT_SILAREA:
	if ([silArea isPoint:aPoint inGrooveAt:0]) {
	    return [silArea grooveAt:0];
	}
	break;
	
      default:
	break;
    }
    return nil;
}


/* CONFIGURE CANCEL METHODS *************************************************************************/


- enableCancel:(BOOL)flag
{
    [cancelButton setEnabled:flag];
    return self;
}

- (BOOL)configureCancelled
{
    return configureCancelled;
}


/* STYLUS PARTITION LOCATION ************************************************************************/


/* These methods returns the groove partition of the groove that aPoint straddles, within the region 
 * and groove specified. This partition value varies for each groove. For example, if the soft 
 * function groove has 10 soft functions then this method will return the partition at which the 
 * stylus is currently located. The groove should be pictured as being divided into 10 partitions with
 * the one at which the stylus is located being returned. For vertical grooves, the topmost location 
 * of the groove is partition 1, while in horizontal grooves, the leftmost location is partition 1. 
 * For the left holo and right area grooves, the end paritions (top and bottom) are slightly smaller 
 * in length than the others due to the grooves matching the length of the tactile area. In order for 
 * these end point partitions to be the same as the rest of the partitions in the groove, the grooves 
 * are temporarily extended 1/2 the groove gap in the tactile area, beyond the top and bottom ends. 
 * The location of aPoint in the y coordinate is also temporarily increased by 1/2 this groove gap. 
 * Now we can obtain a correct percentage for the portion of the vertical groove the point covers, 
 * take its inverse, and arrive at the partition at which the stylus is located. Note, if the tag for
 * aRegion is not valid, we return 0. Valid groove partitions range from 1 to the number of partitions
 * in aGroove.
 */

- (int)groovePartitionAtPoint:(const NXPoint *)aPoint inRegion:aRegion inGroove:aGroove
{
    int grooveGap;

    switch ([aRegion tag]) {
      case TNT_TOPHOLO:
      case TNT_TACTILEAREA:
      case TNT_SILAREA:
	return (int)ceil(((aPoint->x - [aRegion originX]) / [aRegion width]) * [aGroove partitions]);
	break;

      case TNT_LEFTHOLO:
      case TNT_RIGHTAREA:
	grooveGap = [tactileArea grooveGap];
	return (int)ceil((1 - (aPoint->y - [aRegion originY] + 0.5 * grooveGap) / 
			  ([aRegion height] + grooveGap)) *  [aGroove partitions]);
	break;

      case TNT_SOFTAREA:
	return (int)ceil((1 - (aPoint->y - [aRegion originY]) / [aRegion height]) * 
			 [aGroove partitions]);
	break;

      case TNT_PREVAREA:
      case TNT_NEXTAREA:
	return [aGroove partitions]; break;   // always returns 1
      default:
	return 0; break;   // return error value
    }
}

- (int)groovePartitionAtPoint:(const NXPoint *)aPoint inRegion:aRegion inGrooveWithTag:(int)aTag
{
    return [self groovePartitionAtPoint:aPoint inRegion:aRegion inGroove:[aRegion grooveAt:aTag-1]];
}


/* DEBUGGING ****************************************************************************************/


- showContents
{
    printf("\nSOFTAREA\n--------\n\n");
    [softArea showContents];
    printf("\nLEFTHOLO\n--------\n\n");
    [leftHolo showContents];
    printf("\nTOPHOLO\n-------\n\n");
    [topHolo showContents];
    printf("\nRIGHTAREA\n---------\n\n");
    [rightArea showContents];
    printf("\nTACTILEAREA\n-----------\n\n");
    [tactileArea showContents];
    printf("\nSILAREA\n-------\n\n");
    [silArea showContents];
    printf("\nPREVAREA\n--------\n\n");
    [prevArea showContents];
    printf("\nNEXTAREA\n--------\n\n");
    [nextArea showContents];
    return self;
}

@end

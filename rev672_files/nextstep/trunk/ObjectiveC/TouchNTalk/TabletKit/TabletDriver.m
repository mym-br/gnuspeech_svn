/*
 *    Filename : TabletDriver.m 
 *    Created  : Tue Aug  3 01:45:47 1993 
 *    Author   : Dale Brisinda
 *		 <dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Sat Jan 21 13:04:07 1995"
 *    Copyright (c) 1993, Dale Brisinda. All rights reserved.
 *
 * $Id: TabletDriver.m,v 1.8 1996/09/14 04:10:00 dale Exp $
 *
 * $Log: TabletDriver.m,v $
 * Revision 1.8  1996/09/14 04:10:00  dale
 * Moved files in top-level TabletKit folder from Terry's system to pegasus.
 *
 * Revision 1.6  1995/01/21  23:47:17  dale
 * Added an additional "flushAllQueues" message for safety.
 *
 * Revision 1.5  1994/10/04  09:43:13  dale
 * Commented out multi-button clicks unsupported message.
 *
 * Revision 1.4  1994/06/10  08:25:28  dale
 * Added button number for stylus/cursor button-up events foe convenience of client.
 *
 */

#import <appkit/Application.h>
#import <appkit/nextstd.h>
#import <objc/NXBundle.h>
#import <dpsclient/event.h>
#import <libc.h>
#import "TabletDriver.h"
#import "TabletReader.h"

/* Tablet reader locations. */
#define USER_LIB_READERS  "Library/TabletReaders"
#define LOCAL_LIB_READERS "/LocalLibrary/TabletReaders"
#define NEXT_LIB_READERS  "/NextLibrary/TabletReaders"

/* Default settings. */
#define DEFAULT_TABLET_DEVICE "/dev/ttyb"
#define DEFAULT_TABLET_READER "SummaUIOFBinaryReader.bundle"

/* Maximum seconds for timestamp. Multiplying this value by 1000, then adding 1000 should be less than
 * the maximum signed integer for the machine. For the m68k this is INT_MAX defined in the header file
 * ansi/m68k/limits.h.
 */
#define MAXSEC 2147482   

@implementation TabletDriver

/* Allocate local variables only once. If the event queue is full, the event should replace the the 
 * next slot in the event queue since it is a ring buffer. This means the next event to be processed 
 * should be replaced. The DPSPostEvent documentation seems to say otherwise. Maybe for kit defined 
 * events, old events are replaced, but not for events generated via DPSPostEvent since they were not
 * sent from the window server, but generated internally. No return value. Note, static variables are
 * by default automatically initialized to zero, unlike automatic variables.
 */
static void processDataAtTabletFD(int fd, TabletDriver *self)
{
    NXEvent anEvent;
    NXPoint location;
    short identifier, pressure, angle, button, proximity, temp;
    struct timeval tp;
    struct timezone tzp;
    double clickTimeThresh;

    // load with default values
    location.x = location.y = 0.0;
    identifier = pressure = button = angle = proximity = 0;

    // keep asking for tablet data until no more exists at the descriptor
    while ([[self tabletReader] convertDataAtTabletFD:fd 
				location:&location
				identifier:&identifier
				proximity:&proximity
				pressure:&pressure
				angle:&angle
				button:&button]) {   // successfully read tablet data

	// get event timestamp in millisecond resolution; roll-over every 24.86 days
	gettimeofday(&tp, &tzp);
	anEvent.time = self->lastEvent.time = (tp.tv_sec % MAXSEC) * 1000 + tp.tv_usec / 1000;

	anEvent.type = NX_APPDEFINED;
	anEvent.location = location;
	anEvent.TK_APPSUBTYPE = TK_EVENT;  // flags component holds app-defined event type
	anEvent.window = identifier;       // no window, so track tablet instead
	anEvent.ctxt = [NXApp context];
	anEvent.TK_BUTTON = button;
	anEvent.TK_CLICKS = 0;
	anEvent.TK_PRESSURE = pressure;
	anEvent.TK_ANGLE = angle;

	if (proximity != self->lastProximity) {   // stylus/cursor lowered or raised
	    if (proximity == 1)
		anEvent.TK_SUBTYPE = TK_STYLUSLOWERED;
	    else
		anEvent.TK_SUBTYPE = TK_STYLUSRAISED;

	    if (DPSPostEvent(&anEvent, NO) == -1)   // event queue full
		NXLogError("TabletDriver: Unable to post app-defined event, event queue full.");

	} else if (button != self->lastEvent.TK_BUTTON) {

	    if (self->lastEvent.TK_BUTTON == TK_NOBUTTON) {   // dealing with stylus/cursor button DOWN event
		if (self->clickCount == 0) {   // single click
		    anEvent.TK_SUBTYPE = TK_STYLUSDOWN;
		    anEvent.TK_CLICKS = self->clickCount = 1;
		    self->lastDownEvent = anEvent;

		} else {   // could be a multi-click

		    clickTimeThresh = NXClickTime(self->eventHandle) * 1000;   // convert to milliseconds

		    if (ABS(anEvent.time - self->lastDownEvent.time) <= (long)clickTimeThresh &&
			ABS(anEvent.location.x - self->lastDownEvent.location.x) <= self->clickSpaceThresh.width &&
			ABS(anEvent.location.y - self->lastDownEvent.location.y) <= self->clickSpaceThresh.height) {

			anEvent.TK_SUBTYPE = TK_STYLUSDOWN;
			anEvent.TK_CLICKS = ++(self->clickCount);
			self->lastDownEvent = anEvent;

		    } else {   // time/location change too large; make it a single click

			anEvent.TK_SUBTYPE = TK_STYLUSDOWN;
			anEvent.TK_CLICKS = self->clickCount = 1;
			self->lastDownEvent = anEvent;
		    }
		}

		if (DPSPostEvent(&anEvent, NO) == -1)   // event queue full
		    NXLogError("TabletDriver: Unable to post app-defined event, event queue full.");

	    } else {   // stylus/cursor UP or multi-button click

		if (anEvent.TK_BUTTON == TK_NOBUTTON) {   // dealing with stylus/cursor button UP event
		    if (self->clickCount == 0) {
			NXLogError("TabletDriver: Invalid click count!");
		    } else {

			clickTimeThresh = NXClickTime(self->eventHandle) * 1000;   // convert to milliseconds

			if (ABS(anEvent.time - self->lastDownEvent.time) <= (long)clickTimeThresh &&
			    ABS(anEvent.location.x - self->lastDownEvent.location.x) <= self->clickSpaceThresh.width &&
			    ABS(anEvent.location.y - self->lastDownEvent.location.y) <= self->clickSpaceThresh.height) {

			    anEvent.TK_SUBTYPE = TK_STYLUSUP;
			    anEvent.TK_CLICKS = self->clickCount;
			    temp = self->lastDownEvent.TK_BUTTON;
			    self->lastDownEvent = anEvent;
			    anEvent.TK_BUTTON = temp;   // indicate which button was released for client's convenience

			} else {   // time/location change too large; make it a zero click (ignore it)

			    anEvent.TK_SUBTYPE = TK_STYLUSUP;
			    anEvent.TK_CLICKS = self->clickCount = 0;
			    self->lastDownEvent = anEvent;
			}

			if (DPSPostEvent(&anEvent, NO) == -1)   // event queue full
			    NXLogError("TabletDriver: Unable to post app-defined event, event queue full.");

			// restore actual button status now that event (for client) has been posted
			anEvent.TK_BUTTON = TK_NOBUTTON;
		    }

		} else {   // multiple buttons were de/pressed

		    //////////////////////////////////////////////////////
		    // 
		    // Comment this so fewer messages sent to the console.
		    // 
		    // NXLogError("TabletDriver: Multi-button clicks not supported.");
		}
	    }
	    
	} else {   // there is a location movement (drag or move); pressure and angle change qualify

	    if (anEvent.TK_BUTTON == TK_NOBUTTON)   // MOVED event since no button is down
		anEvent.TK_SUBTYPE = TK_STYLUSMOVED;
	    else   // DRAGGED event since a button is down
		anEvent.TK_SUBTYPE = TK_STYLUSDRAGGED;

	    if (self->deviceTracking)   // coalesce tablet kit "input device-moved/dragged" events
		[self trackInputDevice:&anEvent];

	    if (DPSPostEvent(&anEvent, NO) == -1)   // event queue full
		NXLogError("TabletDriver: Unable to post app-defined event, event queue full.");
	}	

	self->lastProximity = proximity;
	self->lastEvent = anEvent;
    }
}


/* INITIALIZING AND FREEING *************************************************************************/


/* This method is the designated initializer for the class. We initialize the tablet manager by 
 * opening the device specified in deviceName. This device is the full device path and is usually one 
 * of /dev/ttya or /dev/ttyb. The tablet manager is also loaded with the tablet reader bundle 
 * specified by bundleName. The name must contain the name of the bundle directory. The search path 
 * for the bundle proceeds in the following order:
 *
 *     1) The user's home directory, ~/Library/TabletReaders,
 *     2) The site-specific library, /LocalLibrary/TabletReaders,
 *     3) The NeXT-supplied library, /NextLibrary/TabletReaders.
 *
 * The device is initialized by default to 9600 baud input/output, with no parity, in RAW mode. If
 * different settings are required, obtain the tabletFD, and make the appropriate ioctl function calls
 * as outlined in tty(4). Returns nil if any errors occurred, otherwise returns self.
 */
- initTabletDevice:(const char *)deviceName tabletReader:(const char *)bundleName
{
    char path[MAXPATHLEN+1];
    
    // init instance variables
    tabletDeviceOpen = NO;
    deviceTracking = YES;   // default to event-coalescing turned on
    lastProximity = 0;
    clickCount = 0;
    if (!(eventHandle = NXOpenEventStatus()))
	NXLogError("TabletDriver: Unable to open event status driver.");
    
    // default click space threshold assumes tablet resolution = screen resolution
    NXGetClickSpace(eventHandle, &clickSpaceThresh);

    // Because the TabletDriver will be used in other applications, the return value for the
    // -initForDirectory: call will always be the mainbundle for the application if the bundle 
    // specified a path that could not be found. We must therefore check for file accessibility
    // before making the call, rather than relying on the return value for -initForDirectory:.

    sprintf(path, "%s/%s/%s", NXHomeDirectory(), USER_LIB_READERS, bundleName);
    if (access(path, F_OK) || access(path, R_OK)) {   // no file/read permissions
	sprintf(path, "%s/%s", LOCAL_LIB_READERS, bundleName);
	if (access(path, F_OK) || access(path, R_OK)) {   // no file/read permissions
	    sprintf(path, "%s/%s", NEXT_LIB_READERS, bundleName);
	    if (access(path, F_OK) || access(path, R_OK)) {   // no file/read permissions
		NXLogError("TabletDriver: Cannot find tablet reader bundle.");
		return nil;   // error initializing bundle
	    }
	}
    }

    // get an instance of the bundle
    readerBundle = [[NXBundle alloc] initForDirectory:path];

    // The first class that was linked in must be the tablet reader class for the bundle. To assure 
    // this is the case, make sure that the tablet reader class appears BEFORE any other classes in
    // in the classes directory of Project Builder. Control-drag to rearrange the class ordering, and
    // hence the order in which classes are compiled and linked.

    if (!(tabletReader = [[[readerBundle principalClass] alloc] init])) {   // can't load class
	NXLogError("TabletDriver: Cannot load principal class.");
	return nil;
    }

    // check that class conforms to TabletReader Protocol
    if (![tabletReader conformsTo:@protocol(TabletReader)]) {   // class does not conform to protocol
	NXLogError("TabletDriver: Class does not conform to protocol.");
	[self free];
	return nil;
    }

    // store the tablet device name
    strcpy(tabletDevice, deviceName);

    // open tablet device
    if ((tabletFD = open(deviceName, O_RDWR, 0)) < 0) {
	NXLogError("TabletDriver: Unable to open device.");
	[self free];
	return nil;
    }

    // record tablet device is open
    tabletDeviceOpen = YES;

    // flush input/output queues of device
    [self flushAllQueues];

    // Set the line discipline to the tablet line discipline. Then set device of file descriptor in 
    // raw mode so input sent immediately instead of buffered. Also set input and output speed to 9600
    // baud. Since TIOCSETP is used instead of TIOCSETN, we DO wait for a quiescent output state, and
    // flush any unread characters. Lastly, we set the device in "exlusuve-use" mode, so no further 
    // opens on the device can occur, until the device is closed.

    [[[[self setLineDiscipline:TABLDISC] setFlags:RAW] setInBaud:B9600] setOutBaud:B9600];
    ioctl(tabletFD, TIOCEXCL, 0);   // set exclusive-use mode

    // set to non-blocking read
    fcntl(tabletFD, F_SETFL, FNDELAY);

    // flush input/output queues of device (just before DPSAdd to be safe)
    [self flushAllQueues];

    // define function to be called when data detected at tabletFD
    DPSAddFD(tabletFD, (DPSFDProc)processDataAtTabletFD, self, NX_MODALRESPTHRESHOLD);

    return self;
}

/* Initializes the device using deviceName, and the default tablet reader. Returns the value returned
 * by the designated initializer.
 */
- initTabletDevice:(const char *)deviceName
{
    return [self initTabletDevice:deviceName tabletReader:DEFAULT_TABLET_READER];
}

/* Initializes the device using the default device name, and bundleName. Returns the value returned by
 * the designated initializer.
 */
- initTabletReader:(const char *)bundleName
{
    return [self initTabletDevice:DEFAULT_TABLET_DEVICE tabletReader:bundleName];
}

/* Initializes the device using the default device name, and the default tablet reader. Returns the
 * value returned by the designated initializer.
 */
- init
{
    return [self initTabletDevice:DEFAULT_TABLET_DEVICE tabletReader:DEFAULT_TABLET_READER];
}

- free
{
    if (tabletDeviceOpen) {
	DPSRemoveFD(tabletFD);
    }
    [tabletReader free];
    [readerBundle free];
    if (tabletDeviceOpen && close(tabletFD) == -1) {
	NXLogError("TabletDriver: Unable to close device.");
    }
    NXCloseEventStatus(eventHandle);
    return [super free];
}


/* BUNDLE AND DEVICE QUERIES ************************************************************************/


- readerBundle
{
    return readerBundle;
}

- tabletReader
{
    return tabletReader;
}

- (int)tabletFD
{
    return tabletFD;
}

- (const char *)tabletDevice
{
    return tabletDevice;
}


/* TABLET DEVICE CONFIGURATION **********************************************************************/


- setFlags:(int)flagsCode
{
    struct sgttyb arg;

    ioctl(tabletFD, TIOCGETP, &arg);
    arg.sg_flags = flags = flagsCode;
    ioctl(tabletFD, TIOCSETP, &arg);
    return self;
}

- setInBaud:(int)speed
{
    struct sgttyb arg;

    ioctl(tabletFD, TIOCGETP, &arg);
    arg.sg_ispeed = inBaud = speed;
    ioctl(tabletFD, TIOCSETP, &arg);
    return self;
}

- setOutBaud:(int)speed
{
    struct sgttyb arg;

    ioctl(tabletFD, TIOCGETP, &arg);
    arg.sg_ospeed = outBaud = speed;
    ioctl(tabletFD, TIOCSETP, &arg);
    return self;
}

- setLineDiscipline:(int)lineDisciplineCode
{
    lineDiscipline = lineDisciplineCode;
    ioctl(tabletFD, TIOCSETD, &lineDisciplineCode);
    return self;
}

- (int)flags
{
    return flags;
}

- (int)inBaud
{
    return inBaud;
}

- (int)outBaud
{
    return outBaud;
}

- (int)lineDiscipline
{
    return lineDiscipline;
}


/* DEVICE TRACKING **********************************************************************************/


/* This method turns event-coalescing on or off. If flag is FALSE, coalescing is turned off; 
 * otherwise, it's turned on (the default). Event coalescing is an optimization that's useful when 
 * tracking the tablet input device. When the input device is moved (depending on the tablet mode), 
 * numerous events flow into the event queue. To reduce the number of events awaiting removal by the 
 * application, adjacent input device-moved events are replaced by the most recent event of the semi-
 * contiguous group (other application-defined events do not qualify as group delimiters but are
 * skipped). The same is done for input device-moved events that have a button depressed, with the 
 * addition that an input device-up event replaces the input device-moved events (with a button 
 * depressed), that come before it in the queue. Returns self.
 */
- setDeviceTracking:(BOOL)flag
{
    deviceTracking = flag;
    return self;
}

- (BOOL)deviceTracking
{
    return deviceTracking;
}

/* This method tracks the input device as outlined in the -setDeviceTracking: method documentation. A
 * single argument is passed, representing the tablet event that is about to be posted into the 
 * application event queue. This event contains all the necessary information to determine if we 
 * should remove all stylus moved events or stylus dragged events from the event queue in order to
 * emulate event coalescing. Note, the event passed is NOT posted within this method, but rather, 
 * within the caller. Returns self.
 */
- trackInputDevice:(NXEvent *)postEvent
{
    NXEvent anEvent, *peekEvent;

    // Manually process app-defined events until a TabletKit MOVED or DRAGGED event is found. Manual
    // processesing is performed by explicitly sending the applicationDefined: message to the
    // application's delegate. This is necessary because we must examine the next element in the 
    // event queue which is only possible if we "get" the current element. Once an element is 
    // obtained, we cannot put it back in the event queue at its previous location, so we manually
    // process it in order to avoid loosing the event. 

    // Note: there will be at MOST 1 moved/dragged event in the queue at any given instance in time. 
    // Therefore, we need only find the appropriate event and remove it. The contents of postEvent->
    // TK_SUBTYPE is always one of TK_STYLUSMOVED or TK_STYLUSDRAGGED. Also note, if multiple tablets
    // are connected, then we should also check the tablet identification code to make sure we are
    // processing events from the right tablet.

    while ((peekEvent = [NXApp peekNextEvent:NX_APPDEFINEDMASK into:&anEvent]) && 
	   (peekEvent->TK_APPSUBTYPE != TK_EVENT || 
	    peekEvent->TK_TABLETID != postEvent->TK_TABLETID || 
	    peekEvent->TK_SUBTYPE != postEvent->TK_SUBTYPE)) {

	[[NXApp delegate] applicationDefined:[NXApp getNextEvent:NX_APPDEFINEDMASK]];
    }
    
    if (peekEvent)   // remove MOVED or DRAGGED event
	[NXApp getNextEvent:NX_APPDEFINEDMASK];
    return self;
}


/* CLICK SPACE THRESHOLD ****************************************************************************/


- setClickSpaceThresh:(NXSize *)area
{
    clickSpaceThresh = *area;
    return self;
}

- getClickSpaceThresh:(NXSize *)area
{
    *area = clickSpaceThresh;
    return self;
}


/* SENDING THE TABLET COMMANDS **********************************************************************/


/* Sends the commands in commandString to the tablet. If an error occurred, nil is returned, otherwise
 * returns self. Note that commandString must be NULL terminated.
 */
- sendCommandsToTablet:(const char *)commandString
{
    if (write(tabletFD, commandString, strlen(commandString)) == -1) {
	return nil;
    }
    return self;
}


/* FLUSHING DEVICE QUEUES ***************************************************************************/


/* Flush input queues of device. Returns self. */
- flushInQueues
{
    int arg = FREAD;
    ioctl(tabletFD, TIOCFLUSH, &arg);
    return self;
}

/* Flush output queues of device. Returns self. */
- flushOutQueues
{
    int arg = FWRITE;
    ioctl(tabletFD, TIOCFLUSH, &arg);
    return self;
}

/* Flush input/output queues of device. Returns self. */
- flushAllQueues
{
    int arg = 0;
    ioctl(tabletFD, TIOCFLUSH, &arg);
    return self;
}

@end

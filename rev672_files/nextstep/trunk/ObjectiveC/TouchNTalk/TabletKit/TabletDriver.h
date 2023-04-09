/*
 *    Filename:	TabletDriver.h 
 *    Created :	Tue Aug  3 00:53:17 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Thu Jan 12 21:05:24 1995"
 *    Copyright (c) 1995, Dale Brisinda. All rights reserved.
 */

#import <objc/Object.h>
#import <dpsclient/event.h>
#import <sys/param.h>
#import <drivers/event_status_driver.h>

/* TabletKit event types. */
#define TK_STYLUSLOWERED   0x1
#define TK_STYLUSRAISED    0x2
#define TK_STYLUSDOWN      0x4
#define TK_STYLUSUP        0x8
#define TK_STYLUSMOVED     0x10
#define TK_STYLUSDRAGGED   0x20
#define TK_CURSORLOWERED   TK_STYLUSLOWERED
#define TK_CURSORRAISED    TK_STYLUSRAISED
#define TK_CURSORDOWN      TK_STYLUSDOWN
#define TK_CURSORUP        TK_STYLUSUP
#define TK_CURSORMOVED     TK_STYLUSMOVED
#define TK_CURSORDRAGGED   TK_STYLUSDRAGGED

/* TabletKit app-defined event type. */
#define TK_EVENT           7117

/* NXEvent component definitions. */
#define TK_APPSUBTYPE      flags
#define TK_TABLETID        window
#define TK_SUBTYPE         data.compound.subtype
#define TK_BUTTON          data.compound.misc.S[0]
#define TK_CLICKS          data.compound.misc.S[1]
#define TK_PRESSURE        data.compound.misc.S[2]
#define TK_ANGLE           data.compound.misc.S[3]

/* Button definitions. */
#define TK_NOBUTTON        0
#define TK_BUTTON1         1   // also the primary stylus button
#define TK_BUTTON2         2   // also the secondary stylus button (if present)
#define TK_BUTTON3         3   // also the tertiary stylus button (if present)
#define TK_BUTTON4         4
#define TK_BUTTON5         5
#define TK_BUTTON6         6
#define TK_BUTTON7         7
#define TK_BUTTON8         8
#define TK_BUTTON9         9
#define TK_BUTTON10        10
#define TK_BUTTON11        11
#define TK_BUTTON12        12
#define TK_BUTTON13        13
#define TK_BUTTON14        14
#define TK_BUTTON15        15
#define TK_BUTTON16        16

@interface TabletDriver:Object
{
    id readerBundle;
    id tabletReader;
    int tabletFD;
    int flags;
    int inBaud;
    int outBaud;
    int lineDiscipline;
    char tabletDevice[MAXPATHLEN+1];
    char buffer[MAXPATHLEN+1];
    BOOL tabletDeviceOpen;

@public

    BOOL deviceTracking;
    NXSize clickSpaceThresh;
    NXEventHandle eventHandle;
    NXEvent lastEvent;
    NXEvent lastDownEvent;
    short lastProximity;
    int clickCount;
}

/* INITIALIZING AND FREEING */
- initTabletDevice:(const char *)deviceName tabletReader:(const char *)bundleName;
- initTabletDevice:(const char *)deviceName;
- initTabletReader:(const char *)bundleName;
- init;
- free;

/* BUNDLE AND DEVICE QUERIES */
- readerBundle;
- tabletReader;
- (int)tabletFD;
- (const char *)tabletDevice;

/* TABLET DEVICE CONFIGURATION */
- setFlags:(int)flagsCode;
- setInBaud:(int)speed;
- setOutBaud:(int)speed;
- setLineDiscipline:(int)lineDisciplineCode;
- (int)flags;
- (int)inBaud;
- (int)outBaud;
- (int)lineDiscipline;

/* DEVICE TRACKING */
- setDeviceTracking:(BOOL)flag;
- (BOOL)deviceTracking;
- trackInputDevice:(NXEvent *)postEvent;

/* CLICK SPACE THRESHOLD */
- setClickSpaceThresh:(NXSize *)area;
- getClickSpaceThresh:(NXSize *)area;

/* SENDING THE TABLET COMMANDS */
- sendCommandsToTablet:(const char *)commandString;

/* FLUSHING DEVICE QUEUES */
- flushInQueues;
- flushOutQueues;
- flushAllQueues;

@end

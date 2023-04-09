/*
 *    Filename:	PenDraw.h 
 *    Created :	Thu Oct 21 23:31:55 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Sat Jan 21 16:17:12 1995"
 *    Copyright (c) 1995, Dale Brisinda. All rights reserved.
 */

#import <appkit/appkit.h>

/* IB save panel accessory image type tags. */
#define PD_TIFF_TAG  0
#define PD_EPS_TAG   1

@interface PenDraw:Object
{
    id tabletDriver;           // instance of TabletDriver class
    id canvasControl;          // outlet to instance of CanvasControl in nib

    id openPanel;              // shared instance of the open panel
    id savePanel;              // shared instance of the save panel

    id lineWidthSlider;        // IB outlets
    id lineWidthTextField;
    id lineColorWell;

    id accessoryPanel;         // the save panel accessory panel

    float offset;              // offset for each new canvas window
    int canvasNum;             // current new canvas number (for untitled)
    BOOL appFileLaunch;        // did app launch from file?

    // outlets for updating menu cells
    id documentSubmenuCell;
    id saveMenuCell;
    id saveAsMenuCell;
    id saveAllMenuCell;
    id revertToSavedMenuCell;
    id closeMenuCell;
}

/* CLASS INITIALIZATION */
+ initialize;

/* INITIALIZING AND FREEING */
- init;
- createTabletDriver:(const char *)deviceName;
- free;

/* APPLICATION DELEGATE METHODS */
- appDidInit:sender;
- applicationDefined:(NXEvent *)theEvent;
- (BOOL)appAcceptsAnotherFile:sender;
- (int)app:sender openFile:(const char *)filename type:(const char *)aType;
- appWillTerminate:sender;

/* PREFERENCES */
- changeDevice:sender;
- changeCursor:sender;

/* TARGET/ACTION METHODS */
- changeLineWidth:sender;
- changeLineColor:sender;
- clearCanvas:sender;
- selectTIFFImageFormat:sender;
- selectEPSImageFormat:sender;

/* QUERY METHODS */
- (float)lineWidth;
- (NXColor)lineColor;
- accessoryContentView;

/* SET METHODS */
- setCanvasControl:canvasCtl;

/* DOCUMENT OPERATION METHODS */
- newRequest:sender;
- openRequest:sender;
- saveAllRequest:sender;
- revertToSavedRequest:sender;
- (int)countEditedWindows;
- (BOOL)menuActive:menuCell;

@end

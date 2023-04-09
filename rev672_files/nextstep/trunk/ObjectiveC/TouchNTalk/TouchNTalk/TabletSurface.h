/*
 *    Filename:	TabletSurface.h 
 *    Created :	Thu Aug 19 00:42:53 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Tue Jul 12 10:12:52 1994"
 *
 * $Id: TabletSurface.h,v 1.13 1994/07/25 02:30:52 dale Exp $
 *
 * $Log: TabletSurface.h,v $
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
 */

#import <appkit/appkit.h>
#import <defaults/defaults.h>

/* Number of defaults in defaults database. */
#define TNT_DEFAULTS  9

@interface TabletSurface:Object
{
    // TextToSpeech instance
    id speaker;

    // IB outlets
    id configurePanel;
    id xCurrentField;   
    id yCurrentField;
    id xCurrentTitle;
    id yCurrentTitle;

    id xClickField;
    id yClickField;
    id xClickTitle;
    id yClickTitle;

    id locationTitle;
    id regionTitle;
    id cancelButton;

    // tablet regions
    id softArea;
    id leftHolo;
    id topHolo;
    id rightArea;
    id tactileArea;
    id silArea;
    id prevArea;
    id nextArea;

    // state variables
    int regionState;           // state of tablet region configuration
    int locationState;         // state of region location configuration
    BOOL configureCancelled;   // reflect whether configuration has been cancelled
    NXEvent *currentEvent;     // holds current event
}

/* INITIALIZING AND FREEING */
- init;
- free;
- initRegionIVars;
- freeRegions;
- revertToPreviousRegions;

/* TABLET CONFIGURATION */
- showConfigurePanel;
- (BOOL)configure:(NXEvent *)anEvent;

/* INTERNAL REGION CONFIGURATION */
- configureSoftArea;
- configureLeftHolo;
- configureTopHolo;
- configureRightArea;
- configureTactileArea;
- configureSILArea;
- configurePrevArea;
- configureNextArea;

/* CONFIGURATION CLICK LOCATION */
- (BOOL)getClickLocation:(NXPoint *)aPoint;

/* DEFAULTS RELATED METHODS */
- registerDefaults;
- getDefaultValues;

/* GENERAL QUERY METHODS  */
- softArea;
- leftHolo;
- topHolo;
- rightArea;
- tactileArea;
- silArea;
- prevArea;
- nextArea;
- configurePanel;
- speaker;

/* REGION AND GROOVE QUERY */
- regionForPoint:(const NXPoint *)aPoint;
- grooveForPoint:(const NXPoint *)aPoint;
- grooveForPoint:(const NXPoint *)aPoint inRegion:aRegion;

/* CONFIGURE CANCEL METHODS */
- enableCancel:(BOOL)flag;
- (BOOL)configureCancelled;

/* STYLUS PARTITION LOCATION */
- (int)groovePartitionAtPoint:(const NXPoint *)aPoint inRegion:aRegion inGroove:aGroove;
- (int)groovePartitionAtPoint:(const NXPoint *)aPoint inRegion:aRegion inGrooveWithTag:(int)aTag;

/* DEBUGGING */
- showContents;

@end

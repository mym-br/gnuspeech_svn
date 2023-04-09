/*
 *    Filename:	TabletRegion.h 
 *    Created :	Thu Aug 19 00:43:29 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Fri Oct  1 23:36:17 1993"
 *
 * $Id: TabletRegion.h,v 1.8 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: TabletRegion.h,v $
 * Revision 1.8  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.7  1993/10/10  20:58:14  dale
 * *** empty log message ***
 *
 * Revision 1.6  1993/09/01  19:35:12  dale
 * *** empty log message ***
 *
 * Revision 1.5  1993/08/31  04:51:27  dale
 * Modified initialization slightly, and parameters required.
 *
 * Revision 1.4  1993/08/27  08:08:08  dale
 * Added calculations for creation of meaningful grooves.
 *
 * Revision 1.3  1993/08/27  03:51:06  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/08/25  05:42:14  dale
 * *** empty log message ***
 *
 * Revision 1.1  1993/08/24  02:08:33  dale
 * Initial revision
 *
 */

#import <objc/Object.h>
#import <appkit/graphics.h>

@interface TabletRegion:Object
{
    NXRect boundingRect;
    NXPoint upperLeft, lowerLeft, upperRight, lowerRight;
    id grooveList;        // the list of grooves for the region
    int numGrooves;       // number of grooves in region
    int orientation;      // vertical , horizontal, or square region
    int tag;              // region definition tag associated with region
    float grooveGap;      // gap between grooves in the region
    float grooveOffset;   // offset to the next groove in the region
}

/* INITIALIZING AND FREEING */
- initUpperLeft:(NXPoint *)ul lowerLeft:(NXPoint *)ll upperRight:(NXPoint *)ur 
    lowerRight:(NXPoint *)lr tag:(int)aTag;
- free;

/* BOUNDING RECTANGLE METHODS */
- getBoundingRect:(NXRect *)aRect forPoints:(NXPoint *)point1 :(NXPoint *)point2;
- getBoundingRect:(NXRect *)aRect forUpperLeft:(NXPoint *)ul lowerLeft:(NXPoint *)ll 
    upperRight:(NXPoint *)ur lowerRight:(NXPoint *)lr;

/* GENERAL QUERY METHODS */
- (NXPoint)origin;
- (NXCoord)originX;
- (NXCoord)originY;
- (NXSize)size;
- (NXCoord)width;
- (NXCoord)height;
- (NXRect)boundingRect;
- (int)numGrooves;
- (int)orientation;
- (int)tag;
- (float)grooveGap;
- (float)grooveOffset;
- grooveList;
- grooveAt:(unsigned int)index;

/* REGION SET METHODS */
- setTag:(int)aTag; 
- setGrooveOffset:(float)anOffset;
- setGrooveGap:(float)aGap;

/* POINT LOCATION QUERY */
- (BOOL)inRegion:(const NXPoint *)aPoint;
- (BOOL)isPoint:(const NXPoint *)aPoint inGrooveAt:(unsigned int)index;
- (BOOL)isPoint:(const NXPoint *)aPoint inGroove:groove;
- (BOOL)isPoint:(const NXPoint *)aPoint inRect:(const NXRect *)aRect;

/* REGION ATTRIBUTE METHODS */
- (int)groovesForRegionWithTag:(int)aTag;
- (int)orientationForRegionWithTag:(int)aTag;
- (int)partitionsForGrooveWithTag:(int)gTag inRegionWithTag:(int)rTag;

/* DEBUGGING */
- showContents;

@end

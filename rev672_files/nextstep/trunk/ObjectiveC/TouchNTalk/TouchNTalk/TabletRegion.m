/*
 *    Filename:	TabletRegion.m 
 *    Created :	Sun Aug 22 11:28:30 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Tue Jul 26 11:08:15 1994"
 *
 * $Id: TabletRegion.m,v 1.12 1994/07/26 20:11:02 dale Exp $
 *
 * $Log: TabletRegion.m,v $
 * Revision 1.12  1994/07/26  20:11:02  dale
 * *** empty log message ***
 *
 * Revision 1.11  1994/06/15  19:32:35  dale
 * Added length saftey margin for groove lengths.
 *
 * Revision 1.10  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.9  1994/05/28  21:24:37  dale
 * *** empty log message ***
 *
 * Revision 1.8  1993/10/10  20:58:14  dale
 * *** empty log message ***
 *
 * Revision 1.7  1993/09/04  17:49:22  dale
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

#import <appkit/nextstd.h>
#import <objc/List.h>
#import <sys/param.h>
#import "Publisher.tproj.h"
#import "TabletRegion.h"
#import "TabletGroove.h"

@implementation TabletRegion


/* INITIALIZING AND FREEING *************************************************************************/


/* This method is the designated initializer for the class. The arguments are the raw tablet 
 * coordinates. These are stored as they are without any processing in the corresponding instance
 * variables for referece and for creation of each individual groove bounding rectangle in the region.
 * The bounding rectangle for the region is generated from these points by obtaining the bounding
 * rectangle for the points, and then applying a safety value to increase the area of the bounding
 * rectangle slightly. If the orientation of the region is TNT_VERTICAL_SHAPE we add the width safety
 * value to the width of the region, and length saftey value to the height of the region. Conversely,
 * if the region orientation is TNT_HORIZONTAL_SHAPE we add the width safety value to the height of 
 * the region and length safety to the width of the region. aTag is the tag (tablet region 
 * definitions) associated with the region.
 */
- initUpperLeft:(NXPoint *)ul lowerLeft:(NXPoint *)ll upperRight:(NXPoint *)ur 
    lowerRight:(NXPoint *)lr tag:(int)aTag;
{
    NXRect grooveRect;          // working rect for generating grooves
    NXPoint point1, point2;     // working points for generating grooves
    id groove;                  // working groove for determining gap between grooves
    int i, partitions;

    [super init];
    upperLeft = *ul; upperRight = *ur; 
    lowerLeft = *ll; lowerRight = *lr;
    tag = aTag;   // region tag as definined in the tablet region definitions
    [self getBoundingRect:&boundingRect forUpperLeft:ul lowerLeft:ll upperRight:ur lowerRight:lr];
    orientation = [self orientationForRegionWithTag:tag];
    numGrooves = [self groovesForRegionWithTag:tag];

    // Get the boundingRect for the groove and the groove offset to the next groove in the region. If
    // the orientation is TNT_SQUARE_SHAPE we do not make any safety additions. Also, if the region 
    // has a TNT_VERTICAL_SHAPE orientation we use the x coordinates for the offset. Conversely, if 
    // the region has a TNT_HORIZONTAL_SHAPE orientation we use the y coordinates for the offset. If 
    // the region has a TNT_SQUARE_SHAPE orientation we use the default offset of 0.0. When getting 
    // offsets we make sure we do not lose any precision by using floats in the calculation. This is 
    // necessary if there is a large number of grooves in order to avoid rounding errors.

    grooveOffset = 0.0;   // catch-all initialization
    if (orientation == TNT_VERTICAL_SHAPE) {
	boundingRect.origin.x -= TNT_WIDTH_SAFETY;
	boundingRect.size.width += (TNT_WIDTH_SAFETY << 1);    

	// add length safety margin
	boundingRect.origin.y -= TNT_LENGTH_SAFETY;
	boundingRect.size.height += (TNT_LENGTH_SAFETY << 1);    
	if (numGrooves > 1) {
	    grooveOffset = ABS(upperLeft.x - upperRight.x) / (float)(numGrooves - 1);
	}
    } else if (orientation == TNT_HORIZONTAL_SHAPE) {
	boundingRect.origin.y -= TNT_WIDTH_SAFETY;
	boundingRect.size.height += (TNT_WIDTH_SAFETY << 1);    

	// add length saftey margin
	boundingRect.origin.x -= TNT_LENGTH_SAFETY;
	boundingRect.size.width += (TNT_LENGTH_SAFETY << 1);    
	if (numGrooves > 1) {
	    grooveOffset = ABS(upperLeft.y - lowerLeft.y) / (float)(numGrooves - 1);
	}
    }

    // initialize groove list for this region
    grooveList = [[List allocFromZone:[self zone]] initCount:numGrooves];

    for (i = 0; i < numGrooves; i++) {

	// If the orientation == TNT_VERTICAL_SHAPE, get the basic bounding rectangle for the groove 
	// based on the upper left and lower left end points of the region, the groove offset, and the
	// loop iteration. We then adjust the width and height of the groove with TNT_WIDTH_SAFETY and
	// TNT_LENGTH_SAFETY respectively. If the orientation == TNT_HORIZONTAL_SHAPE, get the basic 
	// bounding rectangle for the groove based on the upper left and upper right end points of the
	// region, the groove offset, and the loop iteration. We then adjust the height and width of 
	// the groove with TNT_WIDTH_SAFETY and TNT_LENGTH_SAFETY respectively. Finally, if the 
	// orientation == TNT_SQUARE_SHAPE, use the boundingRect previously initialized as the groove.
	// Lastly, we create the groove data object, and insert it into the grooveList object with the
	// correct number of partitions for that groove. Note that the initial assignment of 
	// boundingRect to grooveRect loads the y origin and height for vertical orientations, and the
	// x origin and width for horizontal orientations.
	
	grooveRect = boundingRect;   // catch-all initialization
	if (orientation == TNT_VERTICAL_SHAPE) {
	    point1 = upperLeft; point1.x += grooveOffset * i; point1.y += TNT_LENGTH_SAFETY;
	    point2 = lowerLeft; point2.x += grooveOffset * i; point2.y -= TNT_LENGTH_SAFETY;
	    [self getBoundingRect:&grooveRect forPoints:&point1 :&point2];
	    grooveRect.origin.x -= TNT_WIDTH_SAFETY;
	    grooveRect.size.width += (TNT_WIDTH_SAFETY << 1);
	} else if (orientation == TNT_HORIZONTAL_SHAPE) {
	    point1 = upperLeft; point1.y -= grooveOffset * i; point1.x -= TNT_LENGTH_SAFETY;
	    point2 = upperRight; point2.y -= grooveOffset * i; point1.x += TNT_LENGTH_SAFETY;
	    [self getBoundingRect:&grooveRect forPoints:&point1 :&point2];
	    grooveRect.origin.y -= TNT_WIDTH_SAFETY;
	    grooveRect.size.height += (TNT_WIDTH_SAFETY << 1);
	}
	partitions = [self partitionsForGrooveWithTag:i+1 inRegionWithTag:tag];
	[grooveList addObject:[[TabletGroove allocFromZone:[self zone]] initRect:&grooveRect
									partitions:partitions
									tag:i+1]];
    }

    grooveGap = 0.0;   // catch-all initialization

    // get the gap between grooves in the region
    if (orientation == TNT_VERTICAL_SHAPE) {
	if (numGrooves > 1) {
	    groove = [grooveList objectAt:0];
	    grooveGap = [[grooveList objectAt:1] originX] - ([groove originX] + [groove width]);
	}
    } else if (orientation == TNT_HORIZONTAL_SHAPE) {
	if (numGrooves > 1) {
	    groove = [grooveList objectAt:1];
	    grooveGap = [[grooveList objectAt:0] originY] - ([groove originY] + [groove height]);
	}
    } 
    return self;
}

/* This method calls the designated initializer with all coordinates set at 0.0, and the region 
 * TNT_DEADZONE. This method should not be called. Use the designated initializer instead. Returns 
 * what the designated initializer returns.
 */
- init
{
    NXPoint ul = {0,0}, ll = {0,0}, ur = {0,0}, lr = {0,0};
    return [self initUpperLeft:&ul lowerLeft:&ll upperRight:&ur lowerRight:&lr tag:TNT_DEADZONE];
}

- free
{
    [[grooveList freeObjects] free];
    return [super free];
}


/* BOUNDING RECTANGLE METHODS ***********************************************************************/


/* Gets the largest bounding rectangle that can be formed from the points provided, and places it in
 * aRect. Returns self.
 */
- getBoundingRect:(NXRect *)aRect forPoints:(NXPoint *)point1 :(NXPoint *)point2
{
    aRect->origin.x = MIN(point1->x, point2->x);
    aRect->origin.y = MIN(point1->y, point2->y);
    aRect->size.width = ABS(point1->x - point2->x);
    aRect->size.height = ABS(point1->y - point2->y);
    return self;
}

/* Gets the largest bounding rectangle that can be formed from the points provided, and places it in
 * aRect. Returns self.
 */
- getBoundingRect:(NXRect *)aRect forUpperLeft:(NXPoint *)ul lowerLeft:(NXPoint *)ll 
    upperRight:(NXPoint *)ur lowerRight:(NXPoint *)lr;
{
    aRect->origin.x = MIN(ul->x, ll->x);
    aRect->origin.y = MIN(ll->y, lr->y);
    aRect->size.width = MAX(ABS(aRect->origin.x - ur->x), 
			    ABS(aRect->origin.x - lr->x));
    aRect->size.height = MAX(ABS(aRect->origin.y - ul->y),
			     ABS(aRect->origin.y - ur->y));
    return self;
}


/* GENERAL QUERY METHODS ****************************************************************************/


- (NXPoint)origin
{
    return boundingRect.origin;
}

- (NXCoord)originX
{
    return boundingRect.origin.x;
}

- (NXCoord)originY
{
    return boundingRect.origin.y;
}

- (NXSize)size
{
    return boundingRect.size;
}

- (NXCoord)width
{
    return boundingRect.size.width;
}

- (NXCoord)height
{
    return boundingRect.size.height;
}

- (NXRect)boundingRect
{
    return boundingRect;
}

- (int)numGrooves
{
    return numGrooves;
}

- (int)orientation
{
    return orientation;
}

- (int)tag
{
    return tag;
}

- (float)grooveGap
{
    return grooveGap;
}

- (float)grooveOffset
{
    return grooveOffset;
}

- grooveList
{
    return grooveList;
}

- grooveAt:(unsigned int)index
{
    return [grooveList objectAt:index];
}


/* REGION SET METHODS *******************************************************************************/


- setTag:(int)aTag
{
    tag = aTag;
    return self;
}

- setGrooveOffset:(float)anOffset
{
    grooveOffset = anOffset;
    return self;
}

- setGrooveGap:(float)aGap
{
    grooveGap = aGap;
    return self;
}


/* POINT LOCATION QUERY *****************************************************************************/


- (BOOL)inRegion:(const NXPoint *)aPoint
{
    if ([self isPoint:aPoint inRect:&boundingRect]) {
	return YES;
    } else {
	return NO;
    }
}

- (BOOL)isPoint:(const NXPoint *)aPoint inGrooveAt:(unsigned int)index
{
    NXRect aRect = [[self grooveAt:index] boundingRect];

    if ([self isPoint:aPoint inRect:&aRect]) {
	return YES;
    } else {
	return NO;
    }
}

- (BOOL)isPoint:(const NXPoint *)aPoint inGroove:aGroove
{
    NXRect aRect = [aGroove boundingRect];

    if ([self isPoint:aPoint inRect:&aRect]) {
	return YES;
    } else {
	return NO;
    }
}

/* Returns YES if aPoint is inside aRect, otherwise returns NO. If aPoint lies on a border of aRect,
 * then the point is considered to lie within the rectangle.
 */
- (BOOL)isPoint:(const NXPoint *)aPoint inRect:(const NXRect *)aRect;
{
    if (aPoint->x >= aRect->origin.x &&
	aPoint->x <= aRect->origin.x + aRect->size.width &&
	aPoint->y >= aRect->origin.y &&
	aPoint->y <= aRect->origin.y + aRect->size.height) {
	return YES;
    } else {
	return NO;
    }
}


/* REGION ATTRIBUTE METHODS *************************************************************************/


/* Returns the number of grooves in the region identified by regionTag. If region is an invalid 
 * region, returns TNT_NO_GROOVES.
 */
- (int)groovesForRegionWithTag:(int)regionTag
{
    switch (regionTag) {
      case TNT_SOFTAREA:
	return TNT_SOFTAREA_GROOVES; break;
      case TNT_LEFTHOLO:
	return TNT_LEFTHOLO_GROOVES; break;
      case TNT_TOPHOLO:
	return TNT_TOPHOLO_GROOVES; break;
      case TNT_RIGHTAREA:
	return TNT_RIGHTAREA_GROOVES; break;
      case TNT_TACTILEAREA:
	return TNT_TACTILEAREA_GROOVES; break;
      case TNT_SILAREA:
	return TNT_SILAREA_GROOVES; break;
      case TNT_PREVAREA:
      case TNT_NEXTAREA:
	return TNT_NEXTAREA_GROOVES; break;   // or alternatively TNT_PREVAREA_GROOVES
      default:
	return TNT_NO_GROOVES; break;
    }
}

/* Returns the orientation of the region identified by regionTag. One of TNT_VERTICAL_SHAPE, 
 * TNT_HORIZONTAL_SHAPE, or TNT_SQUARE_SHAPE is returned. If region is an invalid region, returns 
 * TNT_NO_SHAPE.
 */
- (int)orientationForRegionWithTag:(int)regionTag
{
    switch (regionTag) {
      case TNT_SOFTAREA:
      case TNT_LEFTHOLO:
      case TNT_RIGHTAREA:
	return TNT_VERTICAL_SHAPE; break;
      case TNT_TOPHOLO:
      case TNT_TACTILEAREA:
      case TNT_SILAREA:
	return TNT_HORIZONTAL_SHAPE; break;
      case TNT_PREVAREA:
      case TNT_NEXTAREA:
	return TNT_SQUARE_SHAPE; break;
      default:
	return TNT_NO_SHAPE; break;
    }
}

/* Returns the number of partitions for the groove identified by grooveTag in the region identified by
 * regionTag. If the groove or region tags are invalid, returns TNT_NO_PARTS.
 */
- (int)partitionsForGrooveWithTag:(int)grooveTag inRegionWithTag:(int)regionTag
{
    switch (regionTag) {
      case TNT_SOFTAREA:
	return TNT_SOFTAREA_PARTS; break;
      case TNT_LEFTHOLO:
	return TNT_LEFTHOLO_PARTS; break;
      case TNT_TOPHOLO:
	if (grooveTag == TNT_PAGE_LOCATOR || grooveTag == TNT_BOOKMARK_HOLO) {
	    return TNT_PAGELOCATOR_PARTS;
	} else if (grooveTag == TNT_HORIZ_PAGESCROLL) {
	    return TNT_HORIZ_PAGESCROLL_PARTS;
	}
      case TNT_RIGHTAREA:
	return  TNT_RIGHTAREA_PARTS; break;
      case TNT_TACTILEAREA:
	return TNT_TACTILEAREA_PARTS; break;
      case TNT_SILAREA:
	return  TNT_SILAREA_PARTS; break;
      case TNT_PREVAREA:
      case TNT_NEXTAREA:
	return TNT_NEXTAREA_PARTS; break;   // or alternatively TNT_PREVAREA_PARTS
      default:
	return TNT_NO_PARTS; break;
    }
}


/* DEBUGGING ****************************************************************************************/


- showContents
{
    int i;

    printf("Bounding Rect: origin: (%.1f,%.1f) width: %.1f height: %.1f\n", boundingRect.origin.x,
	   boundingRect.origin.y, boundingRect.size.width, boundingRect.size.height);
    printf("Upper left: (%.1f,%.1f) Upper right: (%.1f,%.1f)\n", upperLeft.x, upperLeft.y, 
	   upperRight.x, upperRight.y);
    printf("Lower left: (%.1f,%.1f) Lower right: (%.1f,%.1f)\n", lowerLeft.x, lowerLeft.y, 
	   lowerRight.x, lowerRight.y);
    printf("Number of grooves: %d\n", numGrooves);
    printf("Orientation: %d\n", orientation);
    printf("Tag: %d\n", tag);
    printf("Groove gap: %.1f\n", grooveGap);
    printf("Groove offset: %.1f\n", grooveOffset);

    for (i = 0; i < numGrooves; i++) {
	printf("\nGroove: %d\n", i+1); 
	[[grooveList objectAt:i] showContents];
    }
    return self;
}

@end

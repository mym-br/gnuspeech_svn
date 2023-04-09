/*
 *    Filename:	TabletGroove.m 
 *    Created :	Sun Aug 22 23:09:04 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Tue Jul 26 11:07:24 1994"
 *
 * $Id: TabletGroove.m,v 1.9 1994/07/26 20:11:02 dale Exp $
 *
 * $Log: TabletGroove.m,v $
 * Revision 1.9  1994/07/26  20:11:02  dale
 * *** empty log message ***
 *
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
 * Added partition instance variable and query/set methods.
 *
 * Revision 1.4  1993/08/27  08:08:08  dale
 * Added query methods.
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

#import <libc.h>
#import "Publisher.tproj.h"
#import "TabletGroove.h"

@implementation TabletGroove


/* INITIALZING AND FREEING **************************************************************************/


/* This method is the designated initializer for the class. Returns self. */
- initRect:(NXRect *)aRect partitions:(int)parts tag:(int)aTag
{
    boundingRect = *aRect;
    partitions = parts;
    tag = aTag;
    return self;
}

- init
{
    NXRect aRect = {0.0, 0.0, 0.0, 0.0};
    return [self initRect:&aRect partitions:TNT_NO_PARTS tag:TNT_DEADZONE];
}

- free
{
    return [super free];
}


/* QUERY METHODS ************************************************************************************/


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

- (int)partitions
{
    return partitions;
}

- (int)tag
{
    return tag;
}


/* SET METHODS **************************************************************************************/


- setPartitions:(int)parts
{
    partitions = parts;
    return self;
}

- setTag:(int)aTag
{
    tag = aTag;
    return self;
}


/* DEBUGGING ****************************************************************************************/


- showContents
{
    printf("Bounding Rect: origin: (%.1f,%.1f) width: %.1f height: %.1f\n", boundingRect.origin.x,
	   boundingRect.origin.y, boundingRect.size.width, boundingRect.size.height);
    printf("Partitions: %d\n", partitions);
    printf("Tag: %d\n", tag);
    return self;
}

@end

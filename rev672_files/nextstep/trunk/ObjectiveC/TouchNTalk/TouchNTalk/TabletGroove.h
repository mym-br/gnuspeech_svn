/*
 *    Filename:	TabletGroove.h 
 *    Created :	Thu Aug 19 00:44:43 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Wed Sep  8 22:13:37 1993"
 *
 * $Id: TabletGroove.h,v 1.8 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: TabletGroove.h,v $
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

#import <objc/Object.h>
#import <appkit/graphics.h>

@interface TabletGroove:Object
{
    NXRect boundingRect;
    int partitions;        // number of paritions for groove
    int tag;               // groove number (NOT index)
}

/* INITIALZING AND FREEING */
- initRect:(NXRect *)aRect partitions:(int)parts tag:(int)aTag;
- init;
- free;

/* QUERY METHODS */
- (NXPoint)origin;
- (NXCoord)originX;
- (NXCoord)originY;
- (NXSize)size;
- (NXCoord)width;
- (NXCoord)height;
- (NXRect)boundingRect;
- (int)partitions;
- (int)tag;

/* SET METHODS */
- setPartitions:(int)parts;
- setTag:(int)aTag;

/* DEBUGGING */
- showContents;

@end

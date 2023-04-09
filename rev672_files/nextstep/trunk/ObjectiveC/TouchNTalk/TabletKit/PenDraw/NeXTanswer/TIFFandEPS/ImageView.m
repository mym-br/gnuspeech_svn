/*  ImageView.m
 *  Purpose: When a new TIFF or EPS image is opened, a window is created and
 * 	an instance of this class -- ImageView -- is installed as the contentView
 * 	for the window.  This ties the NXImage instance together with the view.
 *
 *  You may freely copy, distribute, and reuse the code in this example.
 *  NeXT disclaims any warranty of any kind, expressed or  implied, as to its fitness
 *  for any particular use.
 *
 */

#import "ImageView.h"

@implementation ImageView : View

- initFromImage: newImage
{
    NXRect imageRect = {{0.0, 0.0}, {0.0, 0.0}};
    [newImage getSize:&imageRect.size];

    [super initFrame:&imageRect];
    anImage = newImage;
    return self;
}

- image
{
    return anImage;
}

- drawSelf:(NXRect *)rects :(int)rectCount
{
    NXPoint pt = {0.0, 0.0};
    
    NXSetColor(NX_COLORWHITE);
    NXRectFill(rects);
    [anImage composite: NX_SOVER  toPoint: &pt];
    return self;
}

- free
{
    [anImage free];
    return [super free];
}

@end

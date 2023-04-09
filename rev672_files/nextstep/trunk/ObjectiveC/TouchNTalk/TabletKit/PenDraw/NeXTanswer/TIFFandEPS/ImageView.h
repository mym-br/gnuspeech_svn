/*  ImageView.h
 *  Purpose: When a new TIFF or EPS image is opened, a window is created and
 * 	an instance of this class -- ImageView -- is installed as the contentView
 * 	for the window.  This ties the NXImage instance together with the view.
 *
 *  You may freely copy, distribute, and reuse the code in this example.
 *  NeXT disclaims any warranty of any kind, expressed or  implied, as to its fitness
 *  for any particular use.
 *
 */

#import <appkit/appkit.h>

@interface ImageView:View
{
    id	anImage;
}

- initFromImage: newImage;
- image;
- drawSelf:(NXRect *)rects :(int)rectCount;
- free;

@end

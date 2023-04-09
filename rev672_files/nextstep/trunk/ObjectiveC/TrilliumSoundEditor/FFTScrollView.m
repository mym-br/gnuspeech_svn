
#import "FFTScrollView.h"
#import "FFTScaleView.h"
#import "FFTTitleView.h"
#import "FFTView.h"

@implementation FFTScrollView

/*===========================================================================

	Method: initFrame:
	Purpose: To initialize the View and subViews

===========================================================================*/
- initFrame:(const NXRect *)frameRect
{
NXRect scaleRect, clipRect;

	[super initFrame:frameRect];

	/* Set display attributes */
	[self setBorderType:NX_LINE];
	[self setHorizScrollerRequired:YES];

	/* alloc and init a scale view instance.  Add to subView List */
	NXSetRect(&scaleRect, 0.0, 0.0, 0.0, 0.0);
	scaleView = [[FFTScaleView alloc] initFrame:&scaleRect];
	[self addSubview:scaleView];

	/* alloc and init a title view instance.  Add to subView List */
	NXSetRect(&scaleRect, 2.0, 2.0, frameRect->size.width-4.0, frameRect->size.height - 330.0);
	titleView = [[FFTTitleView alloc] initFrame:&scaleRect];
	[self addSubview:titleView];

	/* alloc and init a FFT view instance.  Make Doc View */
	NXSetRect(&clipRect, 0.0, 0.0, 500.0, 256.0+50.0);
	if ([self setDocView:[[FFTView alloc] initFrame:&clipRect]] != nil)
		printf("FFTScrollView - initFrame:, There's a doc view you should get rid of!\n");

	[[self docView] setTitleView:titleView];

	[self setBackgroundGray:NX_WHITE];
	[self tile];	/* hack? */

	return self;
}

/*===========================================================================

	Method: drawSelf::
	Purpose: Automatically called.  This function clears the view for 
		subsequent drawing.

===========================================================================*/
- drawSelf:(const NXRect *)rects :(int)rectCount
{
	PSsetgray(NX_WHITE);
	PSrectfill(NX_X(&bounds),NX_Y(&bounds),NX_WIDTH(&bounds),NX_HEIGHT(&bounds));

	[super drawSelf:rects:rectCount];

	return self;
}

/*===========================================================================

	Method: tile
	Purpose: Hack to avoid a bug(?) or feature(?). 

===========================================================================*/
- tile
{
NXRect scaleRect, clipRect;

	[super tile];

	[contentView getFrame:&clipRect];
	NXDivideRect(&clipRect, &scaleRect, 50.0, NX_XMIN);
	[contentView setFrame:&clipRect];
	[scaleView setFrame:&scaleRect];

  return self;
}

/*===========================================================================

	Method: printPSCode
	Purpose: Set up and print post script code of the FFT.

===========================================================================*/
- printPSCode:sender
{
	/* Turn off some things to make output look better */
	[self setAutodisplay:NO];
	[self setBorderType:NX_NONE];
	[self setHorizScrollerRequired:NO];

	/* Send code */
	[super printPSCode:sender];

	/* Reinstate original settings */
	[self setBorderType:NX_LINE];
	[self setHorizScrollerRequired:YES];
	[self setAutodisplay:YES];

	return self;
}

/*===========================================================================

	Method: scaleView
	Purpose: return the id of the ScaleView
	Returns:
		(id) scaleView instance variable.

===========================================================================*/
- scaleView
{
	return scaleView;
}

/*===========================================================================

	Method: titleView
	Purpose: return the id of the TitleView
	Returns:
		(id) titleView instance variable.

===========================================================================*/
- titleView
{
	return titleView;
}

@end

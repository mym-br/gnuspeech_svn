
#import <appkit/appkit.h>
#import "FFTScaleView.h"
#import "FFTTitleView.h"

/*===========================================================================

	Object: FFTScrollView
	Purpose: Highest View in the ScrollView Hierarchy.  This view has 
		three sub views.  They are scaleView, titleView and FFTView.
		NOTE: FFTView is the "docView" of this scrollview, so its 
		instance variable is in the superclass.

	Author: Craig-Richard Taube-Schock
	Date: Nov. 1, 1993

History:
	Nov. 23, 1993.  Documentation Completed.

===========================================================================*/

@interface FFTScrollView:ScrollView
{
	FFTScaleView	*scaleView;
	FFTTitleView	*titleView;
}

- initFrame:(const NXRect *)frameRect;
- drawSelf:(const NXRect *)rects :(int)rectCount;
- tile;
- printPSCode:sender;

- scaleView;
- titleView;

@end

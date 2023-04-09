
#import "FFTController.h"
#import "WindowController.h"
#import "FFTScrollView.h"
#import "FFTTitleView.h"
#import "FFTView.h"
#import "FFT.h"

/*===========================================================================

	File: FFT.m
	Author: Craig-Richard Taube-Schock

===========================================================================*/

@implementation FFTController

/*===========================================================================

	Method: init
	Purpose: Initialize instance variables

===========================================================================*/
- init
{
	/* initialize fft pointer */
	myFFT = nil;
	return self;
}

/*===========================================================================

	Method: window
	Purpose: return the id of the current window.
	Returns: (id) window instance variable. (Set in Interface Builder)

===========================================================================*/
- window
{
	return window;
}

/*===========================================================================

	Method: getScrollView
	Purpose: return the id of the scroll view in Window.
	Returns (id) displayScrollView instance variable.  (Set in Interface
		Builder).

===========================================================================*/
- getScrollView
{
	return displayScrollView;
}

/*===========================================================================

	Method: setFFT
	Purpose: set an fft object

===========================================================================*/
- setFFT: anFFT
{
	myFFT = anFFT;
	return self;
}

/*===========================================================================

	Method: updateDisplay
	Purpose: To notify the three subviews under displayScrollView of the
		current FFT.

===========================================================================*/
- updateDisplay
{
	[[displayScrollView scaleView] setFFT: myFFT];
	[[displayScrollView docView] setFFT: myFFT];
	[[displayScrollView titleView] setFFT: myFFT];
	return self;
}

/*===========================================================================

	Method: fft
	Purpose: return the id of the current FFT object
	Returns:
		(id) myFFT instance variable.

===========================================================================*/
- fft
{
	return myFFT;
}

@end


@implementation FFTController(WindowDelegate) 

/*===========================================================================

	Method: windowDidBecomeKey
	Purpose: Called automatically when a window becomes the Key window.
		This method notifies "windowManager" that this FFT has 
		become Key so that the control panel can be updated.

===========================================================================*/
- windowDidBecomeKey:sender
{
	[windowManager setCurrentFFTController: self];
	return self;
}

/*===========================================================================

	Method: windowDidBecomeMain
	Purpose: Called automatically when this window becomes the Main
		window.  Currently, no action need be taken, but future 
		versions may require something to be done in this method.

===========================================================================*/
- windowDidBecomeMain:sender
{

	return self;
}

/*===========================================================================

	Method: windowWillClose
	Purpose: Called automatically when the window is closed.  All objects
		are sent free messages.

===========================================================================*/
- windowWillClose:sender
{
	[[displayScrollView scaleView] free];
	[[displayScrollView docView] free];
	[[displayScrollView titleView] free];
	[myFFT free];
	return self;
}

/*===========================================================================

	Method: windowWillMiniaturize toMiniWindow: 
	Purpose: Called automatically when the window is miniaturized.  
		Currently, nothing is done, but some nifty kind of mini-
		window display could probably be worked up!  
		Bells and Whistles so to speak.

===========================================================================*/
- windowWillMiniaturize:sender toMiniwindow:miniwindow
{
	return self;
}

@end



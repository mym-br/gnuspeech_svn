
#import <appkit/appkit.h>

/*===========================================================================

	Object: FFTController
	Purpose: To facilitate communication between FFT objects and display
		objects.

	NOTE: This function is the Window Delegate for FFT display windows.

	Author: Craig-Richard Taube-Schock
	Date: Nov. 1, 1993

History:
	Nov. 23, 1993.  Documentation Completed.

===========================================================================*/

@interface FFTController:Object
{
	id	myFFT;
	id	windowManager;
	id	window;
	id	displayScrollView;
}

- init;

- window;
- getScrollView;

- updateDisplay;
- setFFT: anFFT;
- fft;



@end


@interface FFTController(WindowDelegate) 

- windowDidBecomeKey:sender;
- windowDidBecomeMain:sender;
- windowWillClose:sender;
- windowWillMiniaturize:sender toMiniwindow:miniwindow;

@end




#import <appkit/appkit.h>

#define SIZE64		0
#define SIZE128		1
#define SIZE256		2
#define SIZE512		3
#define SIZE1024	4
#define SIZE2048	5

#define WINDSQUARE	0
#define WINDHAN		1
#define WINDKB		2

/*===========================================================================

	Object: WindowController
	Purpose: Controls communication between the sound file (TSRView) and
		 the FFT displays (FFTController instances).

	Author: Craig-Richard Taube-Schock
	Date: Nov. 1, 1993

History:
	Nov. 23, 1993.  Documentation Completed.

===========================================================================*/


@interface WindowController:Object
{
	id	infoWindow;

	id	displaySwitch;
	id	freqInterval;
	id	freqResolution;
	id	maxFFTValueField;
	id	newFFT;
	id	numSamplesField;
	id	numWindowsField;
	id	samplingRateField;
	id	scaleMax;
	id	scaleMin;
	id	scalingSliderMax;
	id	scalingSliderMin;
	id	timeInterval;
	id	timeResolution;
	id	windowShape;
	id	windowShapeCoef;
	id	windowSize;
	id	windowSlide;

	id	currentFFTController;
	id	myWindow;

	int	FFTNum, offset;
}

- init;
- appDidInit:sender;

- displayInfoWindow:sender;

- setWindowSizeMenu:(int) entry;
- setWindowSlideValue: (int) samples;
- setSamplingRate: (int) rate;
- setNumSamples: (int) samples;
- setNumWindows: (int) windows;
- setMaxFFTValue: (float) value;
- setWindowShapeMenu: (int) entry;
- setWindowCoef: (float) value;

- changeMinSlider:sender;
- changeMaxSlider:sender;
- changeGridTime:sender;
- changeGridFreq:sender;
- gridDisplay:sender;

- (int) getWindowSize;
- (int) getWindowShape;

- setCurrentFFTController: sender;
- updateControlPanel: sender;
- localUpdateControlPanel:sender;
- updateControlPanelSize:sender;

- doAnalysis:sender;

- newDocument: sender;
- newDocument: (char *) soundData size: (int) dataSize samplingRate: (int) rate name: (char *) name;

- setIntStuff: sender;

- logScale:sender;
- linearScale:sender;

@end

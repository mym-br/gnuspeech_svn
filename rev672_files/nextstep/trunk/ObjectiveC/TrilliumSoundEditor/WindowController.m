
#import "WindowController.h"
#import "FFTController.h"
#import "FFTView.h"
#import "FFT.h"

/*===========================================================================

	File: WindowController.m
	Author: Craig-Richard Taube-Schock

===========================================================================*/


@implementation WindowController

/*===========================================================================

	Method: init
	Purpose: Initialize instance variables

===========================================================================*/
- init
{
	FFTNum = offset = 0;
	return self;
}

/*===========================================================================

	Method: appDidInit:
	Purpose: Automatically sent when all objects within the application
		are instantiated and initialized.  Currently, no action is
		taken when this method is invoked.

===========================================================================*/
- appDidInit:sender
{
	return self;
}

- displayInfoWindow:sender
{
	if (!infoWindow)
	{
		[NXApp loadNibSection:"Info.nib" owner:self];
	}
	[infoWindow makeKeyAndOrderFront:self];
	return self;
}

/*===========================================================================

	Method: setWindowSizeMenu
	Purpose: Set the windowSize menu on the control panel.

===========================================================================*/
- setWindowSizeMenu:(int) entry
{
char buf[256];

	switch(entry)
	{
		case 64:
		case SIZE64: sprintf(buf, "64");
				break;
		case 128:
		case SIZE128: sprintf(buf, "128");
				break;
		case 256:
		case SIZE256: sprintf(buf, "256");
				break;
		case 512:
		case SIZE512: sprintf(buf, "512");
				break;
		case 1024:
		case SIZE1024: sprintf(buf, "1024");
				break;
		case 2048:
		case SIZE2048: sprintf(buf, "2048");
				break;
	}
	[windowSize setTitle:buf];
	return self;
}

/*===========================================================================

	Method: getWindowSize
	Purpose: return the value of the windowSize pop-up-menu on the 
		control panel

===========================================================================*/
- (int) getWindowSize
{
int tempSize = 0 ;
id temp;

	temp = [windowSize selectedCell];
	switch (atoi([temp title]))
	{
		case 64:
		case SIZE64: tempSize = 64;
			     break;
		case 128: 
		case SIZE128: tempSize = 128;
			     break;
		case 256:
		case SIZE256: tempSize = 256;
			     break;
		case 512:
		case SIZE512: tempSize = 512;
			     break;
		case 1024:
		case SIZE1024: tempSize = 1024;
			     break;
		case 2048:
		case SIZE2048: tempSize = 2048;
			     break;

		default: printf("UNKNOWN SIZE!!!\n");
			 break;
	}

	return tempSize;
}

/*===========================================================================

	The next set of methods set values/fields in the control panel.

===========================================================================*/
- setWindowSlideValue: (int) samples
{
	[windowSlide setIntValue: samples];
	return self; 
}

- setSamplingRate: (int) rate
{
	[samplingRateField setIntValue: rate];
	return self; 
}

- setNumSamples: (int) samples
{
	[numSamplesField setIntValue: samples];
	return self; 
}

- setNumWindows: (int) windows
{
	[numWindowsField setIntValue: windows];
	return self; 
}

- setMaxFFTValue: (float) value
{
	[maxFFTValueField setFloatValue: value];
	return self; 
}

/*===========================================================================

	Method: setWindowShapeMenu
	Purpose: set the pop-up-menu for window shape.

===========================================================================*/
- setWindowShapeMenu: (int) entry
{
char buf[256];

	switch(entry)
	{
		case WINDSQUARE:sprintf(buf,"Square");
				break;
		case WINDHAN: sprintf(buf,"Hanning");
				break;
		case WINDKB: sprintf(buf,"Kaiser-Bessel");
				break;
	}

	[windowShape setTitle:buf];

	return self; 
}

/*===========================================================================

	Method: getWindowShape
	Purpose: returns the currently selected window shape for FFT 
		analysis

===========================================================================*/
- (int) getWindowShape;
{
char *tempString;
int retValue;

	tempString = [[windowShape selectedCell] title];

	switch(tempString[0])
	{
		case 'S': retValue = WINDSQUARE;
			  break;
		case 'H': retValue = WINDHAN;
			  break;
		case 'K': retValue = WINDKB;
			  break;
	}

	return retValue; 
}

- setWindowCoef: (float) value
{
	[windowShapeCoef setFloatValue: value];
	return self;
}

/*===========================================================================

	Method: setCurrentFFTController
	Purpose: This message is sent from an instance of FFTController.
		When an FFT window becomes key, it sends its FFTController
		id to this object so that the control panel can be updated 
		to reflect the currently selected fft window.

===========================================================================*/
- setCurrentFFTController: sender
{
id temp;
char buf[256];

	currentFFTController = sender;
	temp = [currentFFTController window];
	sprintf(buf, "FFT Control Panel : %s", [temp title]);
	[myWindow setTitle: buf];
	if ([currentFFTController fft] == nil)
	{
		/* Error. Do nothing yet. */
	}
	else
	{
		[self updateControlPanel: self];
	}
	return self;
}


/*===========================================================================

	Method: newDocument:
	Purpose: used for testing.  Do not use.  Will cause application to 
		crash if you don't know what it's doing. :-)

	Note: Every application must have a method like this... one that 
		causes the application to crash if called :-).

===========================================================================*/
- newDocument: sender
{
FILE *fp;
char sound[48000];

        fp = fopen ("zero.snd", "r");
        fread(sound, 1, 18112, fp);
        fclose(fp);

	[self newDocument: sound size:18112 samplingRate: 11025 name:"Self Test"];

	return self;
}

/*===========================================================================

	Method: newDocument: size: samplingRate: name:
	Purpose: An FFT analysis was requested.  Accept the request, 
		instantiate necessary objects and dispatch data to the
		correct objects.

===========================================================================*/
- newDocument: (char *) soundData size: (int) dataSize samplingRate: (int) rate name:(char *) name
{
id temp;
NXRect frame;
char buf[256];
int tempSize, tempShape;

	/* Instantiate an FFT display window from the nib files */
	if ([NXApp loadNibSection:"Document.nib" owner:self] == nil)
		return nil;

	/* See Interface builder Documentation to understand how this works */
	if (newFFT)
	{
		/* Set up the Window Title */
		temp = [newFFT window];
		[temp getFrame:&frame];
		NX_X(&frame) += offset;
		NX_Y(&frame) -= offset;
		if ( (offset += 24.0) > 100.0)
			offset = 0.0;
  
		sprintf(buf, [temp title], ++FFTNum);
		[temp setTitle:buf];
		[temp placeWindowAndDisplay:&frame];
		[temp makeKeyAndOrderFront:self];

		/* Now Do FFT SetUp */
		temp = [[FFT alloc] init];
		[temp setSamplingRate: rate];
		[temp setSoundData: (short *) soundData dataSize: dataSize];
		[temp setWindowSlide:[windowSlide intValue]];
		[temp setFFTName: name];

		[newFFT setFFT:temp];


		tempSize = [self getWindowSize];
		[temp setBinSize: tempSize];

		switch([self getWindowShape])
		{
			case WINDSQUARE: [temp setWindowNone];
				     break;
			case WINDHAN: [temp setWindowHanning];
				     break;
			case WINDKB: [temp setWindowKB: [windowShapeCoef floatValue]];
				     break;
		}

		/* Do the analysis */
		[temp doAnalysis];
		[currentFFTController updateDisplay];
		[self updateControlPanel: self];
	}
	else
	{
		printf("ERROR!!!  No NewFFT\n");
	}

	return self;
}

/*===========================================================================

	Method: updateControlPanel:
	Purpose: To update the control panel when data has changed.

===========================================================================*/
- updateControlPanel: sender
{
FFT *temp;
float tempFloat;

	temp = [currentFFTController fft];
	if (temp)
	{
		[numWindowsField setIntValue: [temp numberOfWindows]];
		[numSamplesField setIntValue: [temp soundDataSize]/2];
		[windowShapeCoef setFloatValue: [temp windowCoef]];

		[windowSlide setIntValue: [temp windowSlide]];
		[self setWindowSizeMenu: [temp binSize]];
		[self setWindowShapeMenu: [temp windowType]];

		tempFloat = (float) [temp samplingRate];
		[freqResolution setFloatValue: tempFloat/(float)[temp binSize]];

		tempFloat/=1000.0;
		[timeResolution setFloatValue: (float)[temp windowSlide]/tempFloat];
		[samplingRateField setFloatValue: tempFloat];

		[maxFFTValueField setFloatValue: [temp maxFFTData]];

	}

	return self;
}

- localUpdateControlPanel:sender
{
FFT *temp;
float tempFloat;

	temp = [currentFFTController fft];
	if (temp)
	{
		[numWindowsField setIntValue: [temp numberOfWindows]];
		[numSamplesField setIntValue: [temp soundDataSize]/2];

		tempFloat = (float) [temp samplingRate];
		[freqResolution setFloatValue: tempFloat/(float)[self getWindowSize]];

		tempFloat/=1000.0;
		[timeResolution setFloatValue: [windowSlide floatValue]/tempFloat];
		[samplingRateField setFloatValue: tempFloat];

	}
	return self;
}

- updateControlPanelSize: sender
{
FFT *temp;
float tempFloat;
int tempInt;

	temp = [currentFFTController fft];
	if (temp)
	{
		tempFloat = (float) [temp samplingRate];
		switch([[sender selectedCell] tag])
		{
			case SIZE64: tempInt = 64;
				break;
			case SIZE128: tempInt = 128;
				break;
			case SIZE256: tempInt = 256;
				break;
			case SIZE512: tempInt = 512;
				break;
			case SIZE1024: tempInt = 1024;
				break;
			case SIZE2048: tempInt = 2048;
				break;
		}
		[freqResolution setFloatValue: tempFloat/(float)tempInt];

	}
	return self;
}

- setIntStuff: sender
{
	printf("Value:%d\n", [sender intValueAt:0]);
	return self;
}

/*===========================================================================

	Method: doAnalysis:
	Purpose: This method reads data from the control panel and sends 
		it to an FFT object.  The FFT object is then sent a 
		doAnalysis message so that the FFT can be computed.

===========================================================================*/
- doAnalysis:sender
{
id temp;

	/* Get current FFT object */
	temp = [currentFFTController fft];

	if (!temp)
		return nil;

	/* Get control information and send it to the FFT object */
	[temp setWindowSlide:[windowSlide intValue]];
	[temp setBinSize: [self getWindowSize]];

	switch([self getWindowShape])
	{
		case WINDSQUARE: [temp setWindowNone];
			     break;
		case WINDHAN: [temp setWindowHanning];
			     break;
		case WINDKB: [temp setWindowKB: [windowShapeCoef floatValue]];
			     break;
	}

	/* Do the analysis, and update all displays */
	[temp doAnalysis];
	[currentFFTController updateDisplay];
	[self updateControlPanel:self];

	return self;
}

/*===========================================================================

	Method: changeMinSlider
	Purpose: change scaling when scaling sliders are moved.
	NOTE: If the bitmap is large, scaling slider movement can be very
		slow.  A subclass of slider may have to be implemented to
		send this message only when the mouseUp message is detected.

===========================================================================*/
- changeMinSlider:sender
{
id temp;
float tempValue;

	temp = [[currentFFTController getScrollView] docView];
	tempValue = [sender floatValue];
	[scaleMin setFloatValue:tempValue];
	[temp setMinScale:tempValue];

	return self;
}

/*===========================================================================

	Method: changeMaxSlider:
	Purpose: change scaling when max scale slider is moved
	NOTE: If the bitmap is large, scaling slider movement can be very
		slow.  A subclass of slider may have to be implemented to
		send this message only when the mouseUp message is detected.

===========================================================================*/
- changeMaxSlider:sender
{
id temp;
float tempValue;

	temp = [[currentFFTController getScrollView] docView];
	tempValue = [sender floatValue];
	[scaleMax setFloatValue:tempValue];
	[temp setMaxScale:tempValue];

	return self;
}

/*===========================================================================

	Method: changeGridTime:
	Purpose: This object receives a message from the time interval
		field on the control panel.  It's value is taken and sent
		to the current FFT object.

===========================================================================*/
- changeGridTime:sender
{
id temp;
float tempValue;

	temp = [[currentFFTController getScrollView] docView];
	tempValue = [sender floatValue];
	[temp setTimeInterval:tempValue/1000.0];

	return self;
}

/*===========================================================================

	Method:
	Purpose: This object receives a message from the frequency interval
		field on the control panel.  It's value is taken and sent
		to the current FFT object.

===========================================================================*/
- changeGridFreq:sender
{
id temp;
float tempValue;

	temp = [[currentFFTController getScrollView] docView];
	tempValue = [sender floatValue];
	[temp setFreqInterval:tempValue];

	return self;
}

/*===========================================================================

	Method: gridDisplay:
	Purpose: turns grid display on/off depending on state of the switch
		on the Control panel.

===========================================================================*/
- gridDisplay:sender
{
id temp;

	temp = [[currentFFTController getScrollView] docView];
	[temp setDisplayGrid: [sender state]];

	return self;
}

/*===========================================================================

	Method: logScale:
	Purpose: sets a log scale based on the radio buttons on the control
		panel

===========================================================================*/
- logScale:sender
{
	[[[currentFFTController getScrollView] docView] setScaleLinear:FALSE];
	return self;
}

/*===========================================================================

	Method: linearScale:
	Purpose: sets a linear scale based on the radio buttons on the control
		panel

===========================================================================*/
- linearScale:sender
{
	[[[currentFFTController getScrollView] docView] setScaleLinear:TRUE];
	return self;
}

@end

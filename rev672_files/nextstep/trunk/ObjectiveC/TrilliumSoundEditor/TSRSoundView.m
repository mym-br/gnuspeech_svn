#import "TSRSoundView.h"
#import "WindowController.h"
#import <appkit/Application.h>
#import <appkit/Slider.h>
#import <dpsclient/event.h>
#import <bsd/sys/param.h>
#import <appkit/OpenPanel.h>
#import <string.h>
#import <soundkit/Sound.h>
#import <appkit/graphics.h>
#import <dpsclient/psops.h>
#import <dpsclient/event.h>
#import <math.h>
#import <architecture/byte_order.h>
#import <appkit/NXCursor.h>

/*===========================================================================

	File: FFT.m
	Author: Craig-Richard Taube-Schock

===========================================================================*/

@implementation TSRSoundView

/*===========================================================================

	Method:
	Purpose:

===========================================================================*/
- initFrame:(const NXRect *)frameRect
{
int newViewOrder[3] = {LEFT, STEREO, RIGHT};
NXImage *tempImage;


	self = [super initFrame:frameRect];
	[self allocateGState];

	bcopy(frameRect, &totalFrame, sizeof(NXRect));

	[self setViewOrder: newViewOrder];
	[self setMaxStereoProportion: 0.80];
	[self setMinStereoProportion: 0.10];
	[self setStereoProportion:0.1];
	[self setFlipped: YES];


	/* Allocate Cursor Images */
	tempImage = [[NXImage alloc] initFromSection: "UpDown.tiff"];
	if (!tempImage)
		printf("CANNOT ALLOCATE IMAGE\n");

	UpDown = [[NXCursor alloc] initFromImage: tempImage];

	tempImage = [[NXImage alloc] initFromSection: "AllDirections.tiff"];
	if (!tempImage)
		printf("CANNOT ALLOCATE IMAGE\n");

	AllDirections = [[NXCursor alloc] initFromImage: tempImage];

	tempImage = [[NXImage alloc] initFromSection: "LeftRight.tiff"];
	if (!tempImage)
		printf("CANNOT ALLOCATE IMAGE\n");

	LeftRight = [[NXCursor alloc] initFromImage: tempImage];

	[self initVars];
	[self display];

	return self;
}


/*===========================================================================

	Method: initVars
	Purpose: to initialize variables outside of the init function.
		Called when a new sound File is to be loaded.

===========================================================================*/
- initVars
{
	if (leftChannelSamples) 
		free(leftChannelSamples);
	if (rightChannelSamples) 
		free(rightChannelSamples);

	rightChannelSamples = leftChannelSamples = NULL;

	if (stereoOps) free(stereoOps);
	stereoOps = NULL;
		
	if (stereoDataPath) free(stereoDataPath);
	stereoDataPath = NULL;
	stereoNumOps = 0;

	leftStartWindow = rightStartWindow = 0;

	leftSamplesPerWindow = rightSamplesPerWindow = 1;
	leftSampleScale = rightSampleScale = 32768;
	leftStartSelect = rightStartSelect = 0;
	leftEndSelect = rightEndSelect = 0;
	leftMaxStartWindow = rightMaxStartWindow = 0;

	numSamples = maxSample = 0;

	return self;
}

/*===========================================================================

	Method: loadSoundFile:
	Purpose: called as an action method.  Displays an OpenPanel and 
		loads the selected sound file.

===========================================================================*/
- loadSoundfile:sender
{
char *types[] = {"snd", 0};
const char * const *fnames;
const char *directory;
char buf[MAXPATHLEN+1];

	[[OpenPanel new] allowMultipleFiles:NO];
	if ([[OpenPanel new] runModalForTypes:types])
	{
		fnames = [[OpenPanel new] filenames];
		directory = [[OpenPanel new] directory];
		while (*fnames)
		{
			strcpy(buf, directory);
			strcat(buf, "/");
			strcat(buf, *fnames);
			[self loadFile:buf];
			[[self window] setTitle:buf];
			fnames++;
		}
	}
	return self;
}

/*===========================================================================

	Method: loadFile: (char *) 
	Purpose: To load a sound file given a filename.

	NOTE: Uses the sound object to load the file.  This is the easiest,
	but the sound object is too slow to work with (for this object) so
	this is the only place the sound object is used.

===========================================================================*/
- loadFile:(char *) filename
{
int i, j;
short *soundData = NULL;
unsigned char *soundCharData = NULL;

	maxSample = 0;
	sound = [[Sound alloc] initFromSoundfile: filename];
	if (sound)
	{
		/* Clear instance variables */
		[self initVars];

		/* Set instance variables based on loaded sound */
		numSamples = [sound sampleCount];
		samplingRate = [sound samplingRate];

		/* Malloc space for sound data */
		leftChannelSamples = (short *) malloc ((sizeof(short)*numSamples) + 10);

		if ([sound channelCount]>1)
			rightChannelSamples = (short *) malloc ((sizeof(short)*numSamples) + 10);
		
		/* If sound data is 16 bit linear, load it in */
		if ([sound dataFormat] == SND_FORMAT_LINEAR_16)
		{
			soundData = (short *) [sound data];

			j = 0;
			/* Stereo */
			if (rightChannelSamples)
				for ( i = 0 ; i<[sound sampleCount]*2; i++)
				{
					leftChannelSamples[j] = NXSwapBigShortToHost(soundData[i]);

					i++;
					rightChannelSamples[j] = NXSwapBigShortToHost(soundData[i]);

					if (leftChannelSamples[j]>maxSample)
						maxSample = leftChannelSamples[j];
					if (rightChannelSamples[j]>maxSample)
						maxSample = rightChannelSamples[j];
					j++;
				}
			else
			/* Mono */
				for ( i = 0 ; i<[sound sampleCount]; i++)
				{
					leftChannelSamples[j] = NXSwapBigShortToHost(soundData[i]);
					if (leftChannelSamples[j]>maxSample)
						maxSample = leftChannelSamples[j];
					j++;
				}

		}

		/* Special 8-bit format for Rick Jenkins Output files.  Perhaps a user-defined format should be used. */
		else if ([sound dataFormat] == SND_FORMAT_LINEAR_8)
		{
			soundCharData = (char *) [sound data];

			j = 0;
			if (rightChannelSamples)
				for ( i = 0 ; i<[sound sampleCount]*2; i++)
				{
					leftChannelSamples[j] = (short) (soundCharData[i]<<7);

					i++;
					rightChannelSamples[j] = (short) (soundCharData[i]<<7);

					if (leftChannelSamples[j]>maxSample)
						maxSample = leftChannelSamples[j];
					if (rightChannelSamples[j]>maxSample)
						maxSample = rightChannelSamples[j];
					j++;
				}
			else
				for ( i = 0 ; i<[sound sampleCount]; i++)
				{
					leftChannelSamples[j] = (short) (soundCharData[i]<<7);
					if (leftChannelSamples[j]>maxSample)
						maxSample = leftChannelSamples[j];
					j++;
				}
		}

		/* Format not supported */
		else
		{
			fprintf(stderr,"Sound Format not Supported\n");
		}

		/* Free sound object. We don't need no stinking sound object. */
		[sound free];

		/* Set the remainder of the display instance variables based on the loaded sound */
		[numSamplesField setIntValue:numSamples];
		maxSamplesForWindow = leftSamplesPerWindow = rightSamplesPerWindow = 
			ceil((double) numSamples / (double)(totalFrame.size.width-63.0));

		[leftScaleField setIntValue: leftSamplesPerWindow];
		[rightScaleField setIntValue: rightSamplesPerWindow];
		[durationField setDoubleValue: (double)(numSamples)/samplingRate];

	}

	/* Clear Cached Stereo Image */
	if (stereoNumOps)
		stereoNumOps = 0;

	if (stereoOps)
	{
		free(stereoOps);
		stereoOps = NULL;
	}

	if (stereoDataPath)
	{
		free(stereoDataPath);
		stereoDataPath = NULL;
	}

	/* Display the sound file */
	[self display];

	return self;
}

/*===========================================================================

	Method: drawSelf::
	Purpose: Actually draw the images.
		Clear the View
		Draw the right channel
		Draw the left channel
		Draw the stereo channel

===========================================================================*/
- drawSelf:(NXRect *)rects :(int)rectCount
{

	[self clearView];
	[self drawRightChannel];
	[self drawLeftChannel];
	[self drawStereoChannel];

	return self;
}

/*===========================================================================

	Method: clearView
	Purpose: Clear the display space.

===========================================================================*/
- clearView
{
	PSsetgray(NX_WHITE);
	PSrectfill(0.0, 0.0, totalFrame.size.width, totalFrame.size.height);
	PSstroke();
	return self;
}

/*===========================================================================

	Method: updateGrid
	Purpose: Called when display framework has changed.  Display 
		framework is calculated and re-displayed.

===========================================================================*/
- updateGrid
{
float channelHeight, stereoHeight, temp;
float currentOrigin = 0.0;
int i;

	temp = totalFrame.size.height-(totalFrame.size.height*stereoProportion);
	channelHeight = (float)(ceil((double)(temp/2.0)));
	stereoHeight = totalFrame.size.height - (channelHeight*2.0);

	if (stereoNumOps)
		stereoNumOps = 0;
	if (stereoOps)
	{
		free(stereoOps);
		stereoOps = NULL;
	}
	if (stereoDataPath)
	{
		free(stereoDataPath);
		stereoDataPath = NULL;
	}

	for (i = 0; i<3; i++)
		switch(viewOrder[i])
		{
			case LEFT: 
			case RIGHT:viewOrigins[i] = currentOrigin;
				   viewHeights[i] = channelHeight;
				   currentOrigin += channelHeight;
				   break;

			case STEREO:viewOrigins[i] = currentOrigin;
				   viewHeights[i] = stereoHeight;
				   currentOrigin += stereoHeight;
				   break;
		}

	return self;
}

/*===========================================================================

	Method: drawLeftChannel
	Purpose: draw the left channel

	NOTE: OPTIMIZED. UGLY.
		You should read up on DPSDoUserPath if you wish to understand
		what is going on here.

===========================================================================*/
- drawLeftChannel
{
NXRect tempRect;
float midLine = 0.0, tempHeight = 0.0;
float tempStart, tempWidth;
int sampleWidth;
int numOps, i;
short *data = NULL, boundingBox[4];
char *ops = NULL;

	/* Get an index into the display framework data structures */
	for (i = 0; i<3; i++)
		if (viewOrder[i] == LEFT) break;

	/* Draw a pretty white bezel display for the left channel */
	NXSetRect(&tempRect, 0.0, viewOrigins[i], 60.0, viewHeights[i]);
	NXDrawWhiteBezel(&tempRect, &tempRect);

	NXSetRect(&tempRect, 60.0, viewOrigins[i], totalFrame.size.width-60.0, viewHeights[i]);
	NXDrawWhiteBezel(&tempRect, &tempRect);
	PSstroke();

	/* BTW... there is a bug here.  To be fixed soon. */
	sampleWidth = (int)(totalFrame.size.width)*leftSamplesPerWindow;
	if (((leftStartSelect>leftStartWindow) && (leftStartSelect<leftStartWindow+sampleWidth)) ||
		((leftEndSelect>leftStartWindow) && (leftEndSelect<leftStartWindow+sampleWidth)))
	{
		tempStart = (float)((leftStartSelect - leftStartWindow)/leftSamplesPerWindow)+63.0;
		tempWidth = (float)((leftEndSelect - leftStartSelect)/leftSamplesPerWindow);

		if (tempStart<63.0)
		{
			tempWidth = tempWidth - (63.0 - tempStart);
			tempStart = 63.0;
		}
		if (tempWidth+tempStart>totalFrame.size.width)
			tempWidth = totalFrame.size.width - tempStart;
		NXSetRect(&tempRect, tempStart, viewOrigins[i]+2.0, tempWidth, viewHeights[i]-4.0);
		PSsetgray(NX_LTGRAY);
		NXRectFill(&tempRect);
	}

	/* Get midline of this channel */
	midLine = viewOrigins[i] + (viewHeights[i]*0.5);

	/* Display text "Left" */
	PSsetgray(NX_BLACK);
	PSmoveto(12.0, midLine+5.0);
	PSshow("Left");
	PSstroke();

	/* Draw Midline */
	PSmoveto(62.0, midLine);
	PSlineto(totalFrame.size.width-2.0, midLine);
	PSstroke();

	/* Prepare for DPS Userpath calculation */
	boundingBox[0] = (short) 60;
	boundingBox[1] = (short) 0;
	boundingBox[2] = (short) totalFrame.size.width;
	boundingBox[3] = (short) totalFrame.size.height;

	tempHeight = (viewHeights[i]-4.0)/2.0;

	if (leftChannelSamples)
	{
		PSsetgray(NX_BLACK);

		/* Calculate User Path */
		[self getMonoPath: LEFT data: &data numOps:&numOps ops: &ops height: tempHeight midLine: midLine];

		/* Display User Path */
		DPSDoUserPath(data, numOps * 2, dps_short, ops, numOps, boundingBox, dps_ustroke);

		/* Free Temporary variables malloced in "getMonoPath".  See! I told you this was optimized. */
		if (data) free(data);
		if (ops) free(ops);
	}

	return self;
}

/*===========================================================================

	Method: drawRightChannel 
	Purpose: display right channel

	NOTE: SAME as drawLeftChannel but some values changed to reflect the
		right channel. Code is duplicated to avoid unncessary "if"
		statements which would undoubtedly be needed if 
		"drawLeftChannel" and "drawRightChannel" were in one method.

===========================================================================*/
- drawRightChannel
{
NXRect tempRect;
float midLine = 0.0, tempHeight = 0.0;
float tempStart, tempWidth;
int sampleWidth;
int numOps, i;
short *data = NULL, boundingBox[4];
char *ops = NULL;

	for (i = 0; i<3; i++)
		if (viewOrder[i] == RIGHT) break;

	tempRect.origin.x = 0.0;
	tempRect.origin.y = viewOrigins[i];
	tempRect.size.width = 60.0;
	tempRect.size.height = viewHeights[i];
	NXDrawWhiteBezel(&tempRect, &tempRect);

	tempRect.origin.x = 60.0;
	tempRect.size.width = totalFrame.size.width-60.0;
	NXDrawWhiteBezel(&tempRect, &tempRect);
	PSstroke();

	/* There is a bug in here too! */
	sampleWidth = (int)(totalFrame.size.width)*leftSamplesPerWindow;
	if (((rightStartSelect>rightStartWindow) && (rightStartSelect<rightStartWindow+sampleWidth)) ||
		((rightEndSelect>rightStartWindow) && (rightEndSelect<rightStartWindow+sampleWidth)))
	{
		tempStart = (float)((rightStartSelect - rightStartWindow)/rightSamplesPerWindow)+63.0;
		tempWidth = (float)((rightEndSelect - rightStartSelect)/rightSamplesPerWindow);

		if (tempStart<63.0)
		{
			tempWidth = tempWidth - (63.0 - tempStart);
			tempStart = 63.0;
		}
		if (tempWidth+tempStart>totalFrame.size.width)
			tempWidth = totalFrame.size.width - tempStart;
		NXSetRect(&tempRect, tempStart, viewOrigins[i]+2.0, tempWidth, viewHeights[i]-4.0);
		PSsetgray(NX_LTGRAY);
		NXRectFill(&tempRect);
	}

	midLine = viewOrigins[i] + (viewHeights[i]*0.5);

	PSsetgray(NX_BLACK);
	PSmoveto(12.0, midLine+5.0);
	PSshow("Right");
	PSstroke();

	PSmoveto(62.0, midLine);
	PSlineto(totalFrame.size.width-2.0, midLine);
	PSstroke();

	boundingBox[0] = (short) 60;
	boundingBox[1] = (short) 0;
	boundingBox[2] = (short) totalFrame.size.width;
	boundingBox[3] = (short) totalFrame.size.height;

	tempHeight = (viewHeights[i]-4.0)/2.0;

	if (rightChannelSamples)
	{
		PSsetgray(NX_BLACK);

		[self getMonoPath: RIGHT data: &data numOps:&numOps ops: &ops height: tempHeight midLine: midLine];
		DPSDoUserPath(data, numOps * 2, dps_short, ops, numOps, boundingBox, dps_ustroke);
		if (data) free(data);
		if (ops) free(ops);
	}

	return self;
}

/*===========================================================================

	Method: drawStereoChannel
	Purpose: To Draw the stereo field in the display.

	NOTE: For optimisation purposes, graphic data is cached.

===========================================================================*/
- drawStereoChannel
{
NXRect tempRect;
float midLine = 0.0, tempHeight = 0.0;
int i;
short boundingBox[4];
float tempWidth, tempStart;

	for (i = 0; i<3; i++)
		if (viewOrder[i] == STEREO) break;

	tempRect.origin.x = 0.0;
	tempRect.origin.y = viewOrigins[i];
	tempRect.size.width = 60.0;
	tempRect.size.height = viewHeights[i];
	NXDrawWhiteBezel(&tempRect, &tempRect);

	tempRect.origin.x = 60.0;
	tempRect.size.width = totalFrame.size.width-60.0;
	NXDrawWhiteBezel(&tempRect, &tempRect);
	PSstroke();

	midLine = viewOrigins[i] + (viewHeights[i]*0.5);

	PSsetgray(NX_BLACK);
	PSmoveto(12.0, midLine+5.0);
	PSshow("Stereo");
	PSstroke();

	PSmoveto(62.0, midLine);
	PSlineto(totalFrame.size.width-2.0, midLine);
	PSstroke();

	/* Draw Slider buttons in Stereo Space */
	if (leftChannelSamples)
	{

		tempStart = (float)(leftStartWindow/maxSamplesForWindow);
		tempWidth = (totalFrame.size.width-65.0)*(float)(leftSamplesPerWindow)/maxSamplesForWindow;
		NXSetRect(&tempRect, 63.0+tempStart, midLine-2.0-(viewHeights[i]*0.33), tempWidth, (viewHeights[i]*0.33));
		NXDrawButton(&tempRect, &tempRect);
	}
	if (rightChannelSamples)
	{
		tempStart = (float)(rightStartWindow/maxSamplesForWindow);
		tempWidth = (totalFrame.size.width-65.0)*(float)(rightSamplesPerWindow)/maxSamplesForWindow;
		NXSetRect(&tempRect, 63.0 + tempStart, midLine+2.0, tempWidth, (viewHeights[i]*0.33));
		NXDrawButton(&tempRect, &tempRect);
	}

	/* Prepare for DPS User Path */
	boundingBox[0] = (short) 60;
	boundingBox[1] = (short) 0;
	boundingBox[2] = (short) totalFrame.size.width;
	boundingBox[3] = (short) totalFrame.size.height;

	tempHeight = (viewHeights[i]-4.0)/2.0;

	if (leftChannelSamples)
	{
		PSsetgray(NX_BLACK);

		/* If stereo image is not cached, calculate and cache */
		if (!stereoDataPath)
		{
			[self getStereoPath: &stereoDataPath numOps:&stereoNumOps ops: &stereoOps height:tempHeight midLine: midLine];
		}

		/* Display Stereo Path */
		DPSDoUserPath(stereoDataPath, stereoNumOps * 2, dps_short, stereoOps, stereoNumOps, boundingBox, dps_ustroke);
	}
	return self;
}

/*===========================================================================

	Method: setMinStereoProportion
	Purpose: The stereo field size can be changed in size in proportion
		to the size of the view.  The extent to which the stereo
		field can be changed is limited by the instance variables
		"MinStereoProportion" and "MaxStereoProportion".  
		MinStereoProportion indicates the smallest size the stereo
		field can occupy and this value cannot be less that 10%
		and cannot be greater than 80%.

===========================================================================*/
- setMinStereoProportion: (float) value
{
	if (value<0.1) MinStereoProportion = 0.1;
	else
	if (value>0.8) MinStereoProportion = 0.8;
	else
		MinStereoProportion = value;

	return self;
}

/*===========================================================================

	Method: setMaxStereoProportion
	Purpose: The stereo field size can be changed in size in proportion
		to the size of the view.  The extent to which the stereo
		field can be changed is limited by the instance variables
		"MinStereoProportion" and "MaxStereoProportion".  
		MaxStereoProportion indicates the largest size the stereo
		field can occupy and this value cannot be less that 10%
		and cannot be greater than 80%.

===========================================================================*/
- setMaxStereoProportion: (float) value;
{
	if (value<0.1) MaxStereoProportion = 0.1;
	else
	if (value>0.8) MaxStereoProportion = 0.8;
	else
		MaxStereoProportion = value;

	return self;
}

/*===========================================================================

	Method: setStereoProportion
	Purpose: "stereoProportion" is an instance variable which controls
		how large the stereo field is in terms of proportion of
		the size of the view.  stereoProportion cannot be larger
		than "MaxStereoProportion" and cannot be less than
		"MinStereoProportion".

===========================================================================*/
- setStereoProportion: (float) value
{
	stereoProportion = value;
	if (stereoProportion > MaxStereoProportion) stereoProportion = MaxStereoProportion;
	else
	if (stereoProportion < MinStereoProportion) stereoProportion = MinStereoProportion;

	[self updateGrid];
	return self;
}

/*===========================================================================

	Method: setProportionSlider:
	Purpose: set the stereo proportion from a slider.  Used only in 
		testing.

===========================================================================*/
- setProportionSlider:sender
{
	stereoProportion = [sender floatValue];

	if (stereoProportion > MaxStereoProportion) stereoProportion = MaxStereoProportion;
	else
	if (stereoProportion < MinStereoProportion) stereoProportion = MinStereoProportion;

	[self updateGrid];
	[self display];
	return self;
}

/*===========================================================================

	Method: setViewOrder
	Purpose: Sets the order in which the Stereo, Left Channel, and Right
		channel fields are displayed.  The General Setup will always
		be LEFT, STEREO, RIGHT, but, hey!  Variety is the spice of
		life.

===========================================================================*/
- setViewOrder: (int *) newViewOrder
{
	viewOrder[0] = newViewOrder[0];
	viewOrder[1] = newViewOrder[1];
	viewOrder[2] = newViewOrder[2];

	return self;
}

#define MOVE_MASK NX_MOUSEUPMASK|NX_MOUSEDRAGGEDMASK

/*===========================================================================

	Method: mouseDown
	Purpose: BEWARE!! You are entering OPTIMIZED CODE TERRITORY. 
		Because mouse movements and interface must be updated as
		quickly as possible, this code is optimized.  This code
		handles all mouse events for the interface.

	NOTE: The programmer should understand the implications of the 
		[self lockFocus] and [self unlockFocus] methods before
		attempting to understand this code.  These functions are
		documented in the NextStep Developer Documentation under
		"GeneralRef/02_ApplicationKit/Classes/View.rtf".

===========================================================================*/
- mouseDown:(NXEvent *)theEvent
{
int i;
float row, column;
float startRow, startColumn;
NXPoint mouseDownLocation = theEvent->location;

	/* Get information about the original location of the mouse event */
	mouseDownLocation = theEvent->location;
	[self convertPoint:&mouseDownLocation fromView:nil];
	startRow = row = mouseDownLocation.y;
	startColumn = column = mouseDownLocation.x;
	for (i = 0 ; i<3 ; i++)
	{
		if (row<(viewOrigins[i]+viewHeights[i])) break;
	}

	/* Single click mouse events */
	if (theEvent->data.mouse.click == 1)
	{
		[self lockFocus];
		switch(viewOrder[i])
		{
			case LEFT: [self windowSelect:LEFT index: i row: row column:column];
				break;
			case RIGHT: [self windowSelect:RIGHT index: i row: row column:column];
				break;
			case STEREO: [self windowScroll: i row: row column:column];
				break;
		}
		[self unlockFocus];
	}

	/* Double Click mouse events */
	if (theEvent->data.mouse.click == 2)
	{
		[self lockFocus];
		switch(viewOrder[i])
		{
			case LEFT: [self channelScale: LEFT index: i row: row column: column]; 
				break;
			case RIGHT: [self channelScale: RIGHT index: i row: row column: column]; 
				break;
			case STEREO: [self stereoWindowUpdate: i row: row column:column];
				break;
		}
		[self unlockFocus];
	}
	return self;

}

/*===========================================================================

	Method: stereoWindowUpdate
	Purpose: To update the stereoProportion instance variable through
		a mouse double-click and drag.

===========================================================================*/
- stereoWindowUpdate: (int) index row: (float) row column:(float) column
{
int oldEventMask;
NXPoint mouseDownLocation;
NXEvent newEvent;
float delta, originalProportion, tempHeight;

	originalProportion = stereoProportion;
	tempHeight = viewHeights[index];

	oldEventMask = [[self window] addToEventMask:NX_MOUSEDRAGGEDMASK];
	while(1)
	{
		DPSGetEvent(DPSGetCurrentContext(), &newEvent, NX_ALLEVENTS, NX_FOREVER, 16);
		mouseDownLocation = newEvent.location;
		[self convertPoint:&mouseDownLocation fromView:nil];
		delta = row-mouseDownLocation.y;
		delta /= tempHeight;
		[self setStereoProportion: delta+originalProportion];
		[self drawLeftChannel];
		[self drawRightChannel];
		[self drawStereoChannel];
		[window flushWindow];

		if (newEvent.type == NX_LMOUSEUP) break;
	}
	[[self window] setEventMask:oldEventMask];

	return self;
}

/*===========================================================================

	Method: windowScroll row: column:
	Purpose: To scroll a channel (left or right) based on a single 
		click and drag in the stereo field.

	NOTE: Again, this method is optimized.

===========================================================================*/
- windowScroll: (int) index row: (float) row column:(float) column
{
int oldEventMask, originalStart, *newStart, channel, samplesPerWindow, *maxStart;
NXPoint mouseDownLocation;
NXEvent newEvent;
float delta, tempMidLine;

	/* Set up temporary calculation variables */
	tempMidLine = viewOrigins[index] + (viewHeights[index]*0.5);
	if (row<tempMidLine)
	{
		channel = LEFT;
		originalStart = leftStartWindow;
		samplesPerWindow = leftSamplesPerWindow;
		newStart = &leftStartWindow;
		maxStart = &leftMaxStartWindow;
	}
	else
	{
		channel = RIGHT;
		originalStart = rightStartWindow;
		samplesPerWindow = rightSamplesPerWindow;
		newStart = &rightStartWindow;
		maxStart = &rightMaxStartWindow;
	}

	oldEventMask = [[self window] addToEventMask:NX_MOUSEDRAGGEDMASK];
	while(1)
	{
		DPSGetEvent(DPSGetCurrentContext(), &newEvent, NX_ALLEVENTS, NX_FOREVER, 16);
		mouseDownLocation = newEvent.location;
		[self convertPoint:&mouseDownLocation fromView:nil];
		delta = mouseDownLocation.x - column;
		*newStart = (int) (delta*maxSamplesForWindow) + originalStart;

		if (*newStart<0) *newStart = 0;
		if (*newStart>*maxStart) *newStart = *maxStart;

		if (channel == LEFT) 
			[self drawLeftChannel];
		else
			[self drawRightChannel];

		[self drawStereoChannel];
		[window flushWindow];

		if (newEvent.type == NX_LMOUSEUP) break;
	}
	[[self window] setEventMask:oldEventMask];

	return self;
}

#define HORIZONTAL 1
#define VERTICAL 2

/*===========================================================================

	Method: channelScale index: row: column:
	Purpose: Called when a used double-clicks in the left or right
		channel.  The mouse cursor is updated to reflect the effect
		of mouse drags.  The user can change the amplitude scaling of
		the channel by up-down mouse drags and can change the time
		scaling through left-right mouse drags.  Originally, both
		functions could be performed at the same time, but users
		complained that this was too difficult to use.  Therefore,
		if the user's first mouse drag is more horizontal than
		vertical, time scaling will be adjusted.  If the first
		drag is more vertical than horizontal, amplitude scaling
		will be adjusted.  The mouse cursor is updated to reflect
		which function is being used.

===========================================================================*/
- channelScale:(int)channel index: (int) i row: (float) row column: (float) column
{
int oldEventMask, originalSamples, originalScale, *newSamplesPerWindow, *newSampleScale, *maxStart, *startWindow;
int direction = (-1);
NXPoint mouseDownLocation;
NXEvent newEvent;
float delta, tempHeight;

	[AllDirections set];
	tempHeight = viewHeights[i];

	if (channel == LEFT)
	{
		originalSamples = leftSamplesPerWindow;
		originalScale = leftSampleScale;
		newSamplesPerWindow = &leftSamplesPerWindow;
		newSampleScale = &leftSampleScale;
		maxStart = &leftMaxStartWindow;
		startWindow = &leftStartWindow;
	}
	else
	{
		originalSamples = rightSamplesPerWindow;
		originalScale = rightSampleScale;
		newSamplesPerWindow = &rightSamplesPerWindow;
		newSampleScale = &rightSampleScale;
		maxStart = &rightMaxStartWindow;
		startWindow = &rightStartWindow;
	}

	oldEventMask = [[self window] addToEventMask:NX_MOUSEDRAGGEDMASK];
	while(1)
	{
		DPSGetEvent(DPSGetCurrentContext(), &newEvent, NX_ALLEVENTS, NX_FOREVER, 16);
		mouseDownLocation = newEvent.location;
		[self convertPoint:&mouseDownLocation fromView:nil];

		/* First drag.  Horizontal or Veritcal? */
		if (direction == (-1))
		{
			if( fabs((double)(mouseDownLocation.x - column)) > 
				fabs((double)(mouseDownLocation.y - row)))
			{
				direction = HORIZONTAL;
				[LeftRight set];
			}
			else
			{
				direction = VERTICAL;
				[UpDown set];
			}
		}

		/* Time scaling */
		if (direction == HORIZONTAL)
		{
//			if ((mouseDownLocation.y - row)>10.0);
			delta = mouseDownLocation.x - column;
			*newSamplesPerWindow = (int) (delta*0.3) + originalSamples;
			if (*newSamplesPerWindow<1) *newSamplesPerWindow = 1;
			if (*newSamplesPerWindow>maxSamplesForWindow) 
				*newSamplesPerWindow = maxSamplesForWindow;
			*maxStart = numSamples - (*newSamplesPerWindow*(int)(totalFrame.size.width-63.0));			
			if (*maxStart<0) *maxStart = 0;

			if (*startWindow>*maxStart)
			{
				*startWindow = *maxStart;
				[self drawStereoChannel];
			}

//			printf("maxStart = %d\n", *maxStart);
		}
		else
		/* Amplitude scaling */
		{
			delta = mouseDownLocation.y - row;
			*newSampleScale = (int) (delta*32768/tempHeight) + originalScale;
			if (*newSampleScale<1) *newSampleScale = 1;
			if (*newSampleScale>32768) *newSampleScale = 32768;
		}

		if (channel == LEFT) 
			[self drawLeftChannel];
		else
			[self drawRightChannel];

		[self drawStereoChannel];
		[window flushWindow];

		if (newEvent.type == NX_LMOUSEUP) break;
	}
	[[self window] setEventMask:oldEventMask];

	/* Set the mouse cursor back to normal */
	[NXArrow set];
	return self;
}

/*===========================================================================

	Method: windowSelect: index: row: column:
	Purpose: Users can select portions of the sound data by single
		clicking in either the left channel or right channel and 
		dragging left or right.  This method takes care of managing 
		the selection process as well as displaying feedback about
		the selection.

===========================================================================*/
- windowSelect:(int) channel index:(int) i row:(float) row column:(float) column
{
int oldEventMask, *selectEnd, sampleStart, samplesPerWindow;
id  endSam, endTime;
NXPoint mouseDownLocation;
NXEvent newEvent;
float delta;

	if (column<60.0) return self;		/* Hack */

	/* Set up temporary calculation variables based on channel */
	if (channel == LEFT)
	{
		sampleStart = leftStartWindow;
		samplesPerWindow = leftSamplesPerWindow;
		selectEnd = &leftEndSelect;
		leftStartSelect = sampleStart + ((int) (column-62.0) * samplesPerWindow);
		if (leftStartSelect<0) leftStartSelect = 0;

		[leftSamStartField setIntValue: leftStartSelect];
		[leftTimeStartField setDoubleValue: (double)leftStartSelect * (1.0/samplingRate)];
		endSam = leftSamEndField;
		endTime = leftTimeEndField;

	}
	else
	{
		sampleStart = rightStartWindow;
		samplesPerWindow = rightSamplesPerWindow;
		selectEnd = &rightEndSelect;
		rightStartSelect = sampleStart + ((int) (column-62.0) * samplesPerWindow);
		if (rightStartSelect<0) rightStartSelect = 0;


		[rightSamStartField setIntValue: rightStartSelect];
		[rightTimeStartField setDoubleValue: (double)rightStartSelect * (1.0/samplingRate)];

		endSam = rightSamEndField;
		endTime = rightTimeEndField;

	}

	oldEventMask = [[self window] addToEventMask:NX_MOUSEDRAGGEDMASK];

	/* Perform selection process */
	while(1)
	{
		DPSGetEvent(DPSGetCurrentContext(), &newEvent, NX_ALLEVENTS, NX_FOREVER, 16);
		mouseDownLocation = newEvent.location;
		[self convertPoint:&mouseDownLocation fromView:nil];

		delta = mouseDownLocation.x - 62.0;

		*selectEnd = sampleStart+((int)delta * samplesPerWindow);


		if (*selectEnd>numSamples) *selectEnd = numSamples;
		[endSam setIntValue: *selectEnd];
		[endTime setDoubleValue: (double)(*selectEnd) * (1.0/samplingRate)];
		if (channel == LEFT) 
			[self drawLeftChannel];
		else
			[self drawRightChannel];

		[window flushWindow];

		if (newEvent.type == NX_LMOUSEUP) break;
	}
	[[self window] setEventMask:oldEventMask];

	return self;

}

/*===========================================================================

	Method: fullScaleLeft:
	Purpose: Zoom out (x-axis) of the left channel

===========================================================================*/
- fullScaleLeft:sender
{
	leftSamplesPerWindow = maxSamplesForWindow;
	[self display];
	return self;
}

/*===========================================================================

	Method: fullScaleRight:
	Purpose: Zoom out (x-axis) of the right channel

===========================================================================*/
- fullScaleRight:sender
{
	rightSamplesPerWindow = maxSamplesForWindow;
	return self;
}


/*===========================================================================

	Method: normalizeScaleLeft:
	Purpose: normalize Amplitude scale of the left channel

===========================================================================*/
- normalizeScaleLeft:sender
{
int i;
short max = 0;

	if (!leftChannelSamples) return self;
	for (i = 0; i<numSamples; i++)
	{
		if ((leftChannelSamples[i] > max) || (-leftChannelSamples[i] > max))
		{
			max = leftChannelSamples[i];
			if (max<0) max = (-max);
		}
	}
	leftSampleScale = max;

	[self display];
	return self;
}

/*===========================================================================

	Method: normalizeScaleRight:
	Purpose: normalize Amplitude scale of the right channel

===========================================================================*/
- normalizeScaleRight:sender
{
int i;
short max = 0;

	if (!rightChannelSamples) return self;
	for (i = 0; i<numSamples; i++)
	{
		if ((rightChannelSamples[i] > max) || (rightChannelSamples[i] < -max))
			max = rightChannelSamples[i];
	}
	if (max<0) max = (-max);
	rightSampleScale = max;

	[self display];
	return self;
}


/*===========================================================================

	The Following Methods are planned, but are currently unimplemented.

===========================================================================*/
- windowStartLeft:sender
{

	return self;
}

- windowStartRight:sender
{

	return self;
}


- syncLeftRightAmplitude:sender
{

	return self;
}

- syncLeftRightWidth:sender
{

	return self;
}

- syncLeftRightStart:sender
{

	return self;
}

- syncLeftRightEnd:sender
{

	return self;
}

/*===========================================================================

	Method: getStereoPath numOps: ops: height: midLine:
	Purpose: Calculate the DPS User Path for the stereo channel.

		See "POSTSCRIPT Language: Reference Manual" by Adobe Systems
		to understand the User Path operator.
		ISBN: 0-201-10174-2

		See also NextStep developer Documentation regarding the
		DPSDoUserPath() function.
		

===========================================================================*/
- getStereoPath: (short **) data numOps:(int *) numOps ops: (char **) ops height:(float) height midLine:(float) midLine
{
int i, j, k, max;
short *tempData;
float temp;
char *tempOps;

	/* Malloc DPS User Path data space.  These arrays are cached for the Stereo channel to 
	   facilitate faster re-display of the stereo channel.
	*/
	(*data) = malloc((int)totalFrame.size.width * 4 * sizeof(short)+5);
	(*ops) = malloc((int)totalFrame.size.width * 2 * sizeof(char)+5);

	tempData = (*data);
	tempOps = (*ops);

	tempData[0] = 61;
	tempData[1] = (short) midLine;
	tempOps[0] = dps_moveto;

	*numOps = 1;
	i = 0;

	/* Calculate the graphics path for the positive side of the waveform */
	for (k=0; k<(int)(totalFrame.size.width-62.0) ; k++)
	{
		max = 0;
		for (j = 0; j<maxSamplesForWindow; j++)
		{
			if (i<numSamples)
			{
				if (leftChannelSamples[i]>max) max = leftChannelSamples[i];
				if (rightChannelSamples)
					if (rightChannelSamples[i]>max) max = rightChannelSamples[i];
				i++;
			}
		}

		if (max<0) max = 0;
		if (max>maxSample) max = maxSample;

		tempData[(*numOps) * 2] = k+60;
		temp = (float)max*height/(float)maxSample;
		tempData[(*numOps) * 2 + 1] = ((short)(midLine)) - (short)(temp);
		if (tempData[(*numOps) * 2 + 1]<0) tempData[(*numOps) * 2 + 1] = 0;
		tempOps[(*numOps)++] = dps_lineto;
	}

	tempData[(*numOps)*2] = 61;
	tempData[(*numOps)*2+1] = (short) midLine;
	tempOps[(*numOps)++] = dps_moveto;

	i = 0;

	/* Calculate the graphics path for the negative side of the waveform */
	for (k=0; k<(int)(totalFrame.size.width-62.0) ; k++)
	{
		max = 0;
		for (j = 0; j<maxSamplesForWindow; j++)
		{
			if (i<numSamples)
			{
				if (leftChannelSamples[i]<max) max = leftChannelSamples[i];
				if (rightChannelSamples)
					if (rightChannelSamples[i]<max) max = rightChannelSamples[i];
				i++;
			}
		}

		if (max>0) max = 0;
		if (max<-maxSample) max = -maxSample;
		tempData[(*numOps) * 2] = k+60;
		temp = (float)max*height/(float)maxSample;
		tempData[(*numOps) * 2 + 1] = ((short)(midLine)) - (short)(temp);
		if (tempData[(*numOps) * 2 + 1]<0) tempData[(*numOps) * 2 + 1] = 0;
		tempOps[(*numOps)++] = dps_lineto;
	}
	return self;
}

/*===========================================================================

	Method: getMonoPath data: numOps: ops: height: midLine:
	Purpose: Calculate the DPS User Path for either the the left channel 
		or the right channel. 

		See "POSTSCRIPT Language: Reference Manual" by Adobe Systems
		to understand the User Path operator.
		ISBN: 0-201-10174-2

		See also NextStep developer Documentation regarding the
		DPSDoUserPath() function.
		

===========================================================================*/
- getMonoPath: (int) channel data: (short **) data numOps:(int *) numOps ops: (char **) ops 
	height:(float) height midLine:(float) midLine
{
int i, j, k, max;
int samplesForWindow, startSample, sampleScale;
short *soundData, *tempData;
float temp;
char *tempOps;

	/* Set up temporary variables based on channel */
	if (channel == LEFT)
	{
		soundData = leftChannelSamples;
		samplesForWindow = leftSamplesPerWindow;
		startSample = leftStartWindow;
		sampleScale = leftSampleScale;
	}
	else
	{
		soundData = rightChannelSamples;
		samplesForWindow = rightSamplesPerWindow;
		startSample = rightStartWindow;
		sampleScale = rightSampleScale;
	}

	/* Malloc DPS User Path temporary storage space */
	(*data) = malloc((int)totalFrame.size.width * 4 * sizeof(short)+10);
	(*ops) = malloc((int)totalFrame.size.width * 2 * sizeof(char)+10);

	tempData = (*data);
	tempOps = (*ops);

	tempData[0] = 61;
	tempData[1] = (short) midLine;
	tempOps[0] = dps_moveto;

	*numOps = 1;
	i = startSample;

	/* Calculate positive side of waveform */
	for (k=0; k<(int)(totalFrame.size.width-62.0) ; k++)
	{
		max = 0;
		for (j = 0; j<samplesForWindow; j++)
		{
			if (i<numSamples)
			{
				if (soundData[i]>max) max = soundData[i];
				i++;
			}
		}

		if (max<0) max = 0;
		if (max>maxSample) max = maxSample;

		tempData[(*numOps) * 2] = k+60;
		temp = (float)max*height/(float)sampleScale;
		if (temp>height)temp = height;

		tempData[(*numOps) * 2 + 1] = ((short)(midLine)) - (short)(temp);
		if (tempData[(*numOps) * 2 + 1]<0) tempData[(*numOps) * 2 + 1] = 0;
		tempOps[(*numOps)++] = dps_lineto;
	}

	tempData[(*numOps)*2] = 61;
	tempData[(*numOps)*2+1] = (short) midLine;
	tempOps[(*numOps)++] = dps_moveto;

	i = startSample;

	/* Calculate negative side of waveform */
	for (k=0; k<(int)(totalFrame.size.width-62.0) ; k++)
	{
		max = 0;
		for (j = 0; j<samplesForWindow; j++)
		{
			if (i<numSamples)
			{
				if (soundData[i]<max) max = soundData[i];
				i++;
			}
		}

		if (max>0) max = 0;
		if (max<-maxSample) max = -maxSample;
		tempData[(*numOps) * 2] = k+60;
		temp = (float)max*height/(float)sampleScale;
		if (-temp>height) temp = -height;

		tempData[(*numOps) * 2 + 1] = ((short)(midLine)) - (short)(temp);
		if (tempData[(*numOps) * 2 + 1]<0) tempData[(*numOps) * 2 + 1] = 0;
		tempOps[(*numOps)++] = dps_lineto;
	}
	return self;

}

/*===========================================================================

	Method: fftLeftChannel
	Purpose: Send sound data for the left channel and perform an fft
		on it.

===========================================================================*/
- fftLeftChannel:sender
{
char buf[1024];
	if (leftChannelSamples)
	{
		sprintf(buf, "%s (Left Channel)", [[self window] title]);
		[windowController newDocument: (char *) leftChannelSamples size: numSamples*2 
			samplingRate: (int) samplingRate name: buf ];
	}

	return self;
}

/*===========================================================================

	Method: fftRightChannel
	Purpose: Send sound data for the right channel and perform an fft
		on it.


===========================================================================*/
- fftRightChannel:sender
{
char buf[1024];
	if (rightChannelSamples)
	{
		sprintf(buf, "%s (Right Channel)", [[self window] title]);
		[windowController newDocument: (char *) rightChannelSamples size: numSamples*2 
			samplingRate: (int) samplingRate name: buf ];
	}
	return self;
}

/*===========================================================================

	Method: fftLeftSelection
	Purpose: send selected sound data from the left channel to an FFT
		Object and perform an FFT on it.

===========================================================================*/
- fftLeftSelection:sender
{
char buf[2048];

	if (leftChannelSamples)
	{
		if (leftStartSelect == leftEndSelect) return self;
		sprintf(buf, "%s (Left Channel)   Samples: %d - %d", [[self window] title], leftStartSelect, leftEndSelect);
		[windowController newDocument: (char *) &leftChannelSamples[leftStartSelect]
			size: (leftEndSelect-leftStartSelect) *2 samplingRate: (int) samplingRate
			name: buf ];
	}

	return self;
}

/*===========================================================================

	Method: fftRightSelection
	Purpose: send selected sound data from the right channel to an FFT
		Object and perform an FFT on it.

===========================================================================*/
- fftRightSelection:sender
{
char buf[2048];

	if (rightChannelSamples)
	{
		if (rightStartSelect == rightEndSelect) return self;
		sprintf(buf, "%s (Right Channel)   Samples: %d - %d", [[self window] title], rightStartSelect, rightEndSelect);
		[windowController newDocument: (char *) &rightChannelSamples[rightStartSelect]
			size: (rightEndSelect-rightStartSelect) *2 samplingRate: (int) samplingRate
			name: buf];
	}
	return self;
}




@end

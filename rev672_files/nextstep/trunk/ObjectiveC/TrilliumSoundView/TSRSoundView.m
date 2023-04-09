#import "TSRSoundView.h"
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

@implementation TSRSoundView

- initFrame:(const NXRect *)frameRect
{
int newViewOrder[3] = {LEFT, STEREO, RIGHT};
//int newViewOrder[3] = {STEREO, RIGHT, LEFT};

	self = [super initFrame:frameRect];
	[self allocateGState];

	bcopy(frameRect, &totalFrame, sizeof(NXRect));

	[self setViewOrder: newViewOrder];
	[self setMaxStereoProportion: 0.80];
	[self setMinStereoProportion: 0.10];
	[self setStereoProportion:0.5];
	[self setFlipped: YES];

	[self initVars];
	[self display];

	return self;
}


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

	numSamples = maxSample = 0;

	return self;
}

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

- loadFile:(char *) filename
{
int i, j;
short *soundData;

	maxSample = 0;
	sound = [[Sound alloc] initFromSoundfile: filename];
	if (sound)
	{
		[self initVars];
		numSamples = [sound sampleCount];
		samplingRate = [sound samplingRate];

		leftChannelSamples = (short *) malloc ((sizeof(short)*numSamples) + 10);

		if ([sound channelCount]>1)
			rightChannelSamples = (short *) malloc ((sizeof(short)*numSamples) + 10);
		
		soundData = (short *) [sound data];

		j = 0;
		if (rightChannelSamples)
			for ( i = 0 ; i<[sound sampleCount]*2; i++)
			{
				leftChannelSamples[j] = soundData[i];

				i++;
				rightChannelSamples[j] = soundData[i];

				if (leftChannelSamples[j]>maxSample)
					maxSample = leftChannelSamples[j];
				if (rightChannelSamples[j]>maxSample)
					maxSample = rightChannelSamples[j];
				j++;
			}
		else
			for ( i = 0 ; i<[sound sampleCount]; i++)
			{
				leftChannelSamples[j] = soundData[i];
				if (leftChannelSamples[j]>maxSample)
					maxSample = leftChannelSamples[j];
				j++;
			}

		[sound free];	
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

	[self display];

	return self;
}

- drawSelf:(NXRect *)rects :(int)rectCount
{

	[self clearView];
	[self drawRightChannel];
	[self drawLeftChannel];
	[self drawStereoChannel];

	return self;
}

- clearView
{
	PSsetgray(NX_WHITE);
	PSrectfill(0.0, 0.0, totalFrame.size.width, totalFrame.size.height);
	PSstroke();
	return self;
}

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

- drawLeftChannel
{
NXRect tempRect;
float midLine = 0.0, tempHeight = 0.0;
float tempStart, tempWidth;
int sampleWidth;
int numOps, i;
short *data = NULL, boundingBox[4];
char *ops = NULL;

	for (i = 0; i<3; i++)
		if (viewOrder[i] == LEFT) break;

	NXSetRect(&tempRect, 0.0, viewOrigins[i], 60.0, viewHeights[i]);
	NXDrawWhiteBezel(&tempRect, &tempRect);

	NXSetRect(&tempRect, 60.0, viewOrigins[i], totalFrame.size.width-60.0, viewHeights[i]);
	NXDrawWhiteBezel(&tempRect, &tempRect);
	PSstroke();

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

	midLine = viewOrigins[i] + (viewHeights[i]*0.5);

	PSsetgray(NX_BLACK);
	PSmoveto(12.0, midLine+5.0);
	PSshow("Left");
	PSstroke();

	PSmoveto(62.0, midLine);
	PSlineto(totalFrame.size.width-2.0, midLine);
	PSstroke();

	boundingBox[0] = (short) 60;
	boundingBox[1] = (short) 0;
	boundingBox[2] = (short) totalFrame.size.width;
	boundingBox[3] = (short) totalFrame.size.height;

	tempHeight = (viewHeights[i]-4.0)/2.0;

	if (leftChannelSamples)
	{
		PSsetgray(NX_BLACK);

		[self getMonoPath: LEFT data: &data numOps:&numOps ops: &ops height: tempHeight midLine: midLine];
		DPSDoUserPath(data, numOps * 2, dps_short, ops, numOps, boundingBox, dps_ustroke);
		if (data) free(data);
		if (ops) free(ops);
	}

	return self;
}

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


	if (leftChannelSamples)
	{

		tempStart = (float)(leftStartWindow/maxSamplesForWindow);
//		printf("LSW: %d LSPW: %d Temp: %f\n", leftStartWindow, leftSamplesPerWindow, tempStart);

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
	boundingBox[0] = (short) 60;
	boundingBox[1] = (short) 0;
	boundingBox[2] = (short) totalFrame.size.width;
	boundingBox[3] = (short) totalFrame.size.height;

	tempHeight = (viewHeights[i]-4.0)/2.0;

	if (leftChannelSamples)
	{
		PSsetgray(NX_BLACK);
		if (!stereoDataPath)
		{
			[self getStereoPath: &stereoDataPath numOps:&stereoNumOps ops: &stereoOps height:tempHeight midLine: midLine];
		}
		DPSDoUserPath(stereoDataPath, stereoNumOps * 2, dps_short, stereoOps, stereoNumOps, boundingBox, dps_ustroke);
	}
	return self;
}

- setMinStereoProportion: (float) value
{
	if (value<0.1) MinStereoProportion = 0.1;
	else
	if (value>0.8) MinStereoProportion = 0.8;
	else
		MinStereoProportion = value;

	return self;
}

- setMaxStereoProportion: (float) value;
{
	if (value<0.1) MaxStereoProportion = 0.1;
	else
	if (value>0.8) MaxStereoProportion = 0.8;
	else
		MaxStereoProportion = value;

	return self;
}

- setStereoProportion: (float) value
{
	stereoProportion = value;
	if (stereoProportion > MaxStereoProportion) stereoProportion = MaxStereoProportion;
	else
	if (stereoProportion < MinStereoProportion) stereoProportion = MinStereoProportion;

	[self updateGrid];
	return self;
}

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

- setViewOrder: (int *) newViewOrder
{
	viewOrder[0] = newViewOrder[0];
	viewOrder[1] = newViewOrder[1];
	viewOrder[2] = newViewOrder[2];

	return self;
}

#define MOVE_MASK NX_MOUSEUPMASK|NX_MOUSEDRAGGEDMASK

- mouseDown:(NXEvent *)theEvent
{
int i;
float row, column;
float startRow, startColumn;
NXPoint mouseDownLocation = theEvent->location;

	mouseDownLocation = theEvent->location;
	[self convertPoint:&mouseDownLocation fromView:nil];
	startRow = row = mouseDownLocation.y;
	startColumn = column = mouseDownLocation.x;
//	printf("MouseDown: column: %f  data:%f\n", column, mouseDownLocation.x);
	for (i = 0 ; i<3 ; i++)
	{
		if (row<(viewOrigins[i]+viewHeights[i])) break;
	}
	if (theEvent->data.mouse.click == 1)
	{
		switch(viewOrder[i])
		{
			case LEFT: [self windowSelect:LEFT index: i row: row column:column];
				break;
			case RIGHT: [self windowSelect:RIGHT index: i row: row column:column];
				break;
			case STEREO: [self windowScroll: i row: row column:column];
				break;
		}
	}
	if (theEvent->data.mouse.click == 2)
	{
		switch(viewOrder[i])
		{
			case LEFT: [self channelScale: LEFT index: i row: row column: column]; 
				break;
			case RIGHT: [self channelScale: RIGHT index: i row: row column: column]; 
				break;
			case STEREO: [self stereoWindowUpdate: i row: row column:column];
				break;
		}
	}
	return self;

}

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
		[self display];
		if (newEvent.type == NX_LMOUSEUP) break;
	}
	[[self window] setEventMask:oldEventMask];

	return self;
}

- windowScroll: (int) index row: (float) row column:(float) column
{
int oldEventMask, originalStart, *newStart, channel, samplesPerWindow;
NXPoint mouseDownLocation;
NXEvent newEvent;
float delta, tempMidLine;

	tempMidLine = viewOrigins[index] + (viewHeights[index]*0.5);
	if (row<tempMidLine)
	{
		channel = LEFT;
		originalStart = leftStartWindow;
		samplesPerWindow = leftSamplesPerWindow;	
		newStart = &leftStartWindow;
	}
	else
	{
		channel = RIGHT;
		originalStart = rightStartWindow;
		samplesPerWindow = rightSamplesPerWindow;
		newStart = &rightStartWindow;
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
//		printf("delta: %f column: %f orig: %d\n", delta, column, originalStart);

		[self display];
		if (newEvent.type == NX_LMOUSEUP) break;
	}
	[[self window] setEventMask:oldEventMask];

	return self;
}

- channelScale:(int)channel index: (int) i row: (float) row column: (float) column
{
int oldEventMask, originalSamples, originalScale, *newSamplesPerWindow, *newSampleScale;
NXPoint mouseDownLocation;
NXEvent newEvent;
float delta, tempHeight;

	tempHeight = viewHeights[i];

	if (channel == LEFT)
	{
		originalSamples = leftSamplesPerWindow;
		originalScale = leftSampleScale;
		newSamplesPerWindow = &leftSamplesPerWindow;
		newSampleScale = &leftSampleScale;
	}
	else
	{
		originalSamples = rightSamplesPerWindow;
		originalScale = rightSampleScale;
		newSamplesPerWindow = &rightSamplesPerWindow;
		newSampleScale = &rightSampleScale;
	}

	oldEventMask = [[self window] addToEventMask:NX_MOUSEDRAGGEDMASK];
	while(1)
	{
		DPSGetEvent(DPSGetCurrentContext(), &newEvent, NX_ALLEVENTS, NX_FOREVER, 16);
		mouseDownLocation = newEvent.location;
		[self convertPoint:&mouseDownLocation fromView:nil];
		delta = mouseDownLocation.x - column;
		*newSamplesPerWindow = (int) (delta*0.3) + originalSamples;
		if (*newSamplesPerWindow<1) *newSamplesPerWindow = 1;
		if (*newSamplesPerWindow>maxSamplesForWindow) *newSamplesPerWindow = maxSamplesForWindow;

		delta = mouseDownLocation.y - row;
		*newSampleScale = (int) (delta*32768/tempHeight) + originalScale;
		if (*newSampleScale<1) *newSampleScale = 1;
		if (*newSampleScale>32768) *newSampleScale = 32768;


//		printf("delta: %f column: %f orig: %d\n", delta, column, originalStart);

		[self display];

		if (newEvent.type == NX_LMOUSEUP) break;
	}
	[[self window] setEventMask:oldEventMask];

	return self;
}

- windowSelect:(int) channel index:(int) i row:(float) row column:(float) column
{
int oldEventMask, *selectEnd, sampleStart, samplesPerWindow;
id  endSam, endTime;
NXPoint mouseDownLocation;
NXEvent newEvent;
float delta;

	if (column<60.0) return self;
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
	while(1)
	{
		DPSGetEvent(DPSGetCurrentContext(), &newEvent, NX_ALLEVENTS, NX_FOREVER, 16);
		mouseDownLocation = newEvent.location;
		[self convertPoint:&mouseDownLocation fromView:nil];

		delta = mouseDownLocation.x - 62.0;

		*selectEnd = sampleStart+((int)delta * samplesPerWindow);

//		printf("delta: %f column: %f orig: %d\n", delta, column, originalStart);

		if (*selectEnd>numSamples) *selectEnd = numSamples;
		[endSam setIntValue: *selectEnd];
		[endTime setDoubleValue: (double)(*selectEnd) * (1.0/samplingRate)];

		[self display];
		if (newEvent.type == NX_LMOUSEUP) break;
	}
	[[self window] setEventMask:oldEventMask];

	return self;

}

- fullScaleLeft:sender
{
	leftSamplesPerWindow = maxSamplesForWindow;
	[self display];
	return self;
}

- fullScaleRight:sender
{
	rightSamplesPerWindow = maxSamplesForWindow;
	return self;
}


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

- (short *) extractChannel: (int) channel fromSample: (int) startSample toSample:(int) endSample
{
short *requestedData = NULL;
	return requestedData;
}

- putChannel: (int) channel fromSample: (int) startSample totalSamples: (int) totalSamples fromSoundData: (short *) inputData
		toBuffer: (short *) outputData;
{
	return self;
}

- getStereoPath: (short **) data numOps:(int *) numOps ops: (char **) ops height:(float) height midLine:(float) midLine
{
int i, j, k, max;
short *soundData, *tempData;
float temp;
char *tempOps;

	(*data) = malloc((int)totalFrame.size.width * 4 * sizeof(short)+5);
	(*ops) = malloc((int)totalFrame.size.width * 2 * sizeof(char)+5);

	tempData = (*data);
	tempOps = (*ops);

	tempData[0] = 61;
	tempData[1] = (short) midLine;
	tempOps[0] = dps_moveto;

	*numOps = 1;
	i = 0;

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

- getMonoPath: (int) channel data: (short **) data numOps:(int *) numOps ops: (char **) ops 
	height:(float) height midLine:(float) midLine
{
int i, j, k, max;
int samplesForWindow, startSample, sampleScale;
short *soundData, *tempData;
float temp;
char *tempOps;

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
	(*data) = malloc((int)totalFrame.size.width * 4 * sizeof(short)+10);
	(*ops) = malloc((int)totalFrame.size.width * 2 * sizeof(char)+10);

	tempData = (*data);
	tempOps = (*ops);

	tempData[0] = 61;
	tempData[1] = (short) midLine;
	tempOps[0] = dps_moveto;

	*numOps = 1;
	i = startSample;

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

- fftLeftChannel:sender
{
	[windowController newDocument: (char *) leftChannelSamples size: numSamples 
		samplingRate: (int) samplingRate name: [[self window] title]];

	return self;
}

- fftRightChannel:sender
{
	return self;
}

- fftLeftSelection:sender
{
	return self;
}

- fftRightSelection:sender
{
	return self;
}




@end

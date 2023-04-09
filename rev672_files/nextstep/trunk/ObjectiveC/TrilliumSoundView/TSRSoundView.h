
#import <appkit/View.h>

#define STEREO	(0)
#define LEFT	(1)
#define RIGHT	(2)

/*===========================================================================

	File: TSRSoundView.h

===========================================================================*/

@interface TSRSoundView:View
{

		/* Frame For Display */
	NXRect totalFrame;

		/* Num windows for file (based on time scaling) */
	int leftNumWindowsInFile, rightNumWindowsInFile;

		/* Num samples per Window */
	int leftSamplesPerWindow, rightSamplesPerWindow;
	int maxSamplesForWindow;

	int leftStartWindow, rightStartWindow;
	int leftSampleScale, rightSampleScale;

		/* View Ordering.  Origins and Heights and Maintenance Variables. */
	int viewOrder[3];
	float viewOrigins[3], viewHeights[3];

		/* Sound Data */
	id sound;			/* Used sparingly.  Awful to work with! */
	double samplingRate;		/* Sampling Rate */
	short maxSample;		/* Sample value farthest from the centre line */
	int numSamples;			/* Number of samples in File */
	short *leftChannelSamples;	/* Pointer to samples in Left channel */
	short *rightChannelSamples;	/* Pointer to samples in Right Channel */

		/* Stereo Proportion Variables */
	float MaxStereoProportion, MinStereoProportion;
	float stereoProportion;
	int stereoReduction;

		/* PS code for stereo Signal.  Kept in memory to speed up drawing */
	short *stereoDataPath;
	char *stereoOps;
	int stereoNumOps;

		/* Selection Variables */
	int leftStartSelect, leftEndSelect;
	int rightStartSelect, rightEndSelect;

	id	windowController;

	id	numSamplesField;
	id	leftScaleField;
	id	rightScaleField;	
	id	durationField;	
	id	leftSamStartField;
	id	rightSamStartField;
	id	leftSamEndField;
	id	rightSamEndField;
	id	leftTimeStartField;
	id	rightTimeStartField;
	id	leftTimeEndField;
	id	rightTimeEndField;


}

- initFrame:(const NXRect *)frameRect;

- initVars;
- loadSoundfile:sender;
- loadFile:(char *) filename;

- clearView;
- drawLeftChannel;
- drawRightChannel;
- drawStereoChannel;

- setMinStereoProportion: (float) value;
- setMaxStereoProportion: (float) value;

- setStereoProportion: (float) value;
- setViewOrder: (int *) newViewOrder;
- setProportionSlider:sender;
- updateGrid;

- mouseDown:(NXEvent *)theEvent;
- stereoWindowUpdate: (int) index row: (float) row column:(float) column;
- windowScroll:(int) index row: (float) row column:(float) column;
- channelScale:(int) channel index: (int) i row: (float) row column: (float) column;
- windowSelect:(int) channel index: (int) i row: (float) row column: (float) column;

- initFrame:(const NXRect *)frameRect;
- drawSelf:(NXRect *)rects :(int)rectCount;

- fullScaleLeft:sender;
- fullScaleRight:sender;

- normalizeScaleLeft:sender;
- normalizeScaleRight:sender;

- windowStartLeft:sender;
- windowStartRight:sender;

- syncLeftRightAmplitude:sender;
- syncLeftRightWidth:sender;
- syncLeftRightStart:sender;
- syncLeftRightEnd:sender;

- fftLeftChannel:sender;
- fftRightChannel:sender;
- fftLeftSelection:sender;
- fftRightSelection:sender;

- (short *) extractChannel: (int) channel fromSample: (int) startSample toSample:(int) endSample;
- putChannel: (int) channel fromSample: (int) startSample totalSamples: (int) totalSamples fromSoundData: (short *) inputData
		toBuffer: (short *) outputData;

- getStereoPath: (short **) data numOps:(int *) numOps ops: (char **) ops height:(float) height midLine:(float) midLine;
- getMonoPath:(int) channel data: (short **) data numOps:(int *) numOps ops: (char **) ops height:(float) height midLine:(float) midLine;
@end

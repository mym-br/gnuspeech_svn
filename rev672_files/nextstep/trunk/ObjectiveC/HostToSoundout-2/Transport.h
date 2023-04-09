/*
 * A controller object for a DSPRecorder.
 */

#import <dpsclient/dpsclient.h>
#import <sound/soundstruct.h>
#import <soundkit/Sound.h>
#import "DACPlayer.h"

#define	SND_RATE_HIGH_TAG	0
#define	SND_RATE_LOW_TAG	1

#define	MIN_FREQ	20.0
#define MAX_FREQ	4000.0
#define MIN_AMP		0.0
#define MAX_AMP		1.0

@interface Transport:Object
{
  id statusWindow;		/* Where we display the current status */
  id sizeField;			/* region size text field */
  id countField;		/* region count text field */
  id freqSlider;		/* frequency and amplitude controls */
  id freqField;
  id ampSlider;
  id ampField;
  id srateField;		/* set the sampling rate */

  DPSTimedEntry statusTE;	/* Timed entry to update status window */
  DACPlayer *dacPlayer;		/* The DACPlayer object */
  double frequency;		/* frequency in Hertz */
  double amplitude;		/* amplitude from 0-1.0 */
  short sampleAmplitude;	/* amplitude scaled from -32K to 32K */
  short sampleValue;		/* current value of sample output */
  short sampleDelta;		/* change in sampleValue at each tick */
}

/*
 * Standard methods needed by the IB to initialize the instance variables.
 */
+ new;
- setStatusWindow:anObject;
- setSizeField:anObject;
- setCountField:anObject;
- setFreqSlider:anObject;
- setFreqField:anObject;
- setAmpSlider:anObject;
- setAmpField:anObject;
- setSrateField:anObject;

- appDidInit:sender;
/*
 * appDidInit is called as a delegate from NXApp after all the connections
 * have been made.  This does whatever initialization we need.
 */

/* user methods */
- stop:sender;
- pause:sender;
- play:sender;
- setFrequency:sender;
- setAmplitude:sender;

/* Internal methods */
- setFreqInternal:(float)f;
- setAmpInternal:(float)a;
- updateStatus;

/* Delegate methods */
- willPlay :player;
- didPlay :player;
- playData :player :(char *)region :(int)nbytes;

@end





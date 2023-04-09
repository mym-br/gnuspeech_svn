#import <libc.h>
#import <appkit/Application.h>
#import <appkit/TextField.h>
#import <soundkit/Sound.h>
#import <sound/soundstruct.h>
#import "Transport.h"
#import "DACPlayer.h"
#import "errors.h"
#import <math.h>

/*
 * UpdateStatus is called via a timed entry every second.  It simply
 * dispatches to the updateStatus method for the Transport object.
 */
void UpdateStatus (DPSTimedEntry te, double timeNow, void *data)
{
  [(id)data updateStatus];
}

@implementation Transport:Object

+ new
{
  self = [super new];

  /* Create a timed entry to update the status window every second. */
  statusTE = DPSAddTimedEntry(1.0, &UpdateStatus, self, NX_BASETHRESHOLD);

  dacPlayer = [DACPlayer new];
  [dacPlayer setDelegate :self];

  return self;
}

/* standard IB outlet initialations */
- setStatusWindow:anObject {statusWindow = anObject; return self;}
- setSizeField:anObject {sizeField = anObject; return self;}
- setCountField:anObject {countField = anObject; return self;}
- setFreqSlider:anObject {freqSlider = anObject; return self;}
- setFreqField:anObject {freqField = anObject; return self;}
- setAmpSlider:anObject {ampSlider = anObject; return self;}
- setAmpField:anObject {ampField = anObject; return self;}
- setSrateField:anObject {srateField = anObject; return self;}

- stop:sender;
{
  [dacPlayer stop];
  return self;
}

- pause:sender
{
  [dacPlayer pause];
  return self;
}

- play:sender
{
  [dacPlayer run];
  return self;
}

- setFrequency:sender
{
  return [self setFreqInternal:[sender doubleValue]];
}

- setAmplitude:sender
{
  return [self setAmpInternal:[sender doubleValue]];
}


- appDidInit:sender;
/*
 * appDidInit is called as a delegate from NXApp after all the connections
 * have been made.  This does whatever initialization we need.
 */
{
  [self setFreqInternal:440.0];
  [self setAmpInternal:0.5];
  return self;
}

/**
 ** Internal methods.
 **/


- setFreqInternal:(float)f;
{
  frequency = MAX(MIN(f,MAX_FREQ),MIN_FREQ);
  [freqField setDoubleValue:frequency];
  [freqSlider setDoubleValue:frequency];
  /*
   * reset the sampleValue and sampleDelta.  This will cause a discontinuity,
   * but due to the way we generate triangle waves, this is the safest.
   */
  sampleValue = 0;
  sampleDelta = 4 * sampleAmplitude * frequency / [dacPlayer samplingRate];

  return self;
}

- setAmpInternal:(float)a;
{
  amplitude = MAX(MIN(a,MAX_AMP),MIN_AMP);
  /*
   * limit amplitude to 2^14 to leave a good safety margin.  The
   * triangle wave algorithm we use is sloppy about overflow.
   */
  sampleAmplitude = amplitude * (1<<14);
  [ampField setDoubleValue:amplitude];
  [ampSlider setDoubleValue:amplitude];
  /* see comment above in setFreqInternal */
  sampleValue = 0;
  sampleDelta = 4 * sampleAmplitude * frequency / [dacPlayer samplingRate];

  return self;
}

- updateStatus
/*
 * Update the status display.  Called every second via a timed entry. 
 */
{
  Pla_state_t state = [dacPlayer state];
  int nbytes = [dacPlayer bytesPlayed];
  char *stateName;
  char msg[100];

  if (state == PLA_STOPPED) stateName = 	"stopped";
  else if (state == PLA_PAUSED) stateName = 	"paused";
  else if (state == PLA_RUNNING) stateName =    "running";
  else stateName = 				"unknown";

  sprintf(msg,"%s, %d bytes read\n",stateName,nbytes);
  [statusWindow setStringValue:msg];

  return self;
}



/**
 ** Delegate methods called from the DACPlayer object
 **/



- willPlay :player
/*
 * Called when the Player is about to start playing data.
 */
{
  id srateCell;
  int region_size, region_count;

  sampleValue = 0;

  /* prohibit changes to size and count field while running */
  [sizeField setEnabled:NO];
  [countField setEnabled:NO];
  [srateField setEnabled:NO];

  /* set the current region size and count */
  region_size = [sizeField intValue] * vm_page_size;
  region_count = [countField intValue];
  [dacPlayer setupRegions:region_size:region_count];

  /* set the sampling rate */ 
  srateCell = [srateField selectedCell];
  [dacPlayer setSamplingRate:(([srateCell tag] == SND_RATE_HIGH_TAG)?
			       SND_RATE_HIGH:SND_RATE_LOW)];

  /* make sure that freq and amp are set up for this sampling rate */
  [self setFreqInternal:frequency];
  [self setAmpInternal:amplitude];

  return self;
}

- didPlay :player;
/*
 * Called when the Player stops.
 */
{
  /* re-enable changes to size and count field */
  [sizeField setEnabled:YES];
  [countField setEnabled:YES];
  [srateField setEnabled:YES];

  return self;
}

- playData :player :(char *)region :(int)nbytes
/*
 * Called whenever the Player wants more data.  This is the inner loop where
 * all the sound is created.  In some other application, we could read sound
 * data from a file or from memory.  In this case, we just synthesize a simple
 * triangle wave at a given frequency and amplitude.
 */
{
  int i, nsamples = nbytes/sizeof(short);
  short *dstSamples = (short *)region;

  /* Voici, c'est l'inner loop..  */
  for (i=0; i<nsamples; i+=2) {
    /* write the value twice for a stero output stream. */
    *dstSamples++ = sampleValue;
    *dstSamples++ = sampleValue;

    /* generate next value of sampleValue */
    sampleValue += sampleDelta;
    if (sampleValue > sampleAmplitude) {
      sampleDelta = -sampleDelta;
      sampleValue = 2*sampleAmplitude - sampleValue;
    } else if (sampleValue < -sampleAmplitude) {
      sampleDelta = -sampleDelta;
      sampleValue = -2*sampleAmplitude - sampleValue;
    }
  }

  return self;
}

@end







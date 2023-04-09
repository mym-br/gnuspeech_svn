/*
 * DACPlayer.m
 * Implementation of an object to play sound over the soundout device.
 * Author: Robert D. Poor, NeXT Technical Support
 * Copyright 1989 NeXT, Inc.  Next, Inc. is furnishing this software
 * for example purposes only and assumes no liability for its use.
 *
 * Edit history (most recent edits first)
 *
 * 06-Dec-89 Rob Poor: Created.
 *
 * End of edit history
 */

#import <mach.h>
#import <stdio.h>
#import <servers/netname.h>
#import <appkit/Application.h>
#import <appkit/Panel.h>
#import <sound/accesssound.h>
#import <sound/sounddriver.h>
#import <sound/soundstruct.h>
#import "DACPlayer.h"
#import "errors.h"

/* 
 * HandleDACMessage is called courtesy of the DPSAddPort mechanism
 * whenever a message arrives from the sound driver.  userData is bound
 * to the DACPlayer object itself.
 */
static void HandleDACMessage(msg_header_t *msg, void *userData)
{
  int k_err;
  snddriver_handlers_t *handlers;

  handlers = [(DACPlayer *)userData msgHandlers];
  /* handlers = (DACPlayer *)userData->msgHandlers; */
  k_err = snddriver_reply_handler(msg, handlers);
  check_snddriver_error(k_err,"Cannot parse message from DAC");
}

/*
 * Following are the routines that snddriver_reply_handler will
 * dispatch to. Note that in each case, the DACPlayer object itself
 * will be passed as the first argument.
 */

static void DACCompletedMsg(void *arg, int tag)
{
  [(id)arg handleCompleted];
}

/*
 * The dispatch table that snddriver_reply_handler uses.
 */
const static snddriver_handlers_t dacHandlers = {
  (void *)0,
  (int) 0,
  NULL,			/* DACStartedMsg */
  DACCompletedMsg,
  NULL,			/* DACAbortedMsg */
  NULL,			/* DACPausedMsg */
  NULL,			/* DACResumedMsg */
  NULL,			/* DACOverflowMsg */
  NULL,
  NULL,
  NULL,
  NULL
  };
  

@implementation DACPlayer:Player

/*
 * Create a new DACPlayer object.
 */
+ new
{
  self = [super new];

  msgHandlers = dacHandlers;	/* Copy the static structure */
  msgHandlers.arg = self;	/* Install self as arg to handler functions */
  samplingRate = SND_RATE_HIGH;

  return self;
}

- prepare
{
  port_t arbitration_port;
  port_t dev_port;
  int i, r, protocol;

  [self stop];			/* make sure playing has stopped first. */

  /* Craig: Updated acquisition calling sequence */
  r = SNDAcquire(SND_ACCESS_DSP|SND_ACCESS_OUT,10,0,0,
                     NULL_NEGOTIATION_FUN,0,&devicePort,&ownerPort);
//  check_snddriver_error(r,"Cannot become owner of sound-out resources");

  /* 
   * Tell the delegate (if any) that we are about to start playing.
   * Call it here in case the delegate wants to set the samplingRate.
   */
  if (delegate && [delegate respondsTo:@selector(willPlay:)]) {
    [delegate willPlay :self];
  }

  /* set up the DMA read stream  */
  protocol = 0;				
  r = snddriver_stream_setup(devicePort,
			     ownerPort,
			     ((samplingRate == SND_RATE_HIGH)?
				SNDDRIVER_STREAM_TO_SNDOUT_44:
				SNDDRIVER_STREAM_TO_SNDOUT_22),
			     READ_BUF_SIZE,
			     BYTES_PER_16BIT,
			     LOW_WATER,
			     HIGH_WATER,
			     &protocol,		/* ignored for sndout */
			     &streamPort);
  check_snddriver_error(r,"Cannot set up stream to sound-out");

  /* allocate a port for the replies */
  r = port_allocate(task_self(),&replyPort);
  check_mach_error(r,"Cannot allocate reply port");

  /* Start the DMA stream in a paused state */
  r = snddriver_stream_control(streamPort,0,SNDDRIVER_PAUSE_STREAM);
  check_snddriver_error(r,"can't do initial pause");

  /*
   * Queue up the initial DMA buffers before starting.
   */
  /*
   * Setting the state to PLA_RUNNING is a hack for the benefit of
   * updateStream.  Currently, updateStream will enqueue a region iff
   * the state = PLA_RUNNING.  We use this mechanism so that the
   * delegate can stop the player from within the playData::: method.
   * Perhaps we should design a better way...
   */
  playerState = PLA_RUNNING;
  bytesPlayed = 0;
  regionIndex = 0;
  for (i=0;i<regionCount;i++) {
    [self updateStream];
  }
  playerState = PLA_PAUSED;

  DPSAddPort(replyPort,		
	     HandleDACMessage,		/* function to call */
	     MSG_SIZE_MAX,	
	     self,			/* first arg to HandleDACMessage */
	     NX_RUNMODALTHRESHOLD	/* priority */
	     );

  return self;
}

- run
{
  int r;

  if (playerState == PLA_RUNNING) {
    return nil;
  } else if (playerState == PLA_STOPPED) {
    [self prepare];
  } /* else playerState == PLA_PAUSED */

  /* Resume the DMA stream. */
  r = snddriver_stream_control(streamPort,0,SNDDRIVER_RESUME_STREAM);
  check_snddriver_error(r,"Can't resume the DMA stream");

  playerState = PLA_RUNNING;
  return self;
}

- pause
{
  int r;

  if (playerState == PLA_PAUSED) {
    return nil;
  } else if (playerState == PLA_STOPPED) {
    return [self prepare];
  } /* else playerState == PLA_RUNNING */

  r = snddriver_stream_control(streamPort, 
			       WRITE_TAG, 
			       SNDDRIVER_PAUSE_STREAM);
  check_snddriver_error(r,"Call to pause stream failed");

  playerState = PLA_PAUSED;
  return self;
}

- stop
{
  int r;

  if (playerState == PLA_STOPPED) return nil;

  playerState = PLA_STOPPED;

  /* flush any outstanding buffers */
  r = snddriver_stream_control(streamPort,
			       WRITE_TAG,
			       SNDDRIVER_ABORT_STREAM);
  check_snddriver_error(r,"Couldn't abort stream");
  SNDRelease(SND_ACCESS_DSP|SND_ACCESS_OUT, &devicePort, &ownerPort);

  /* 
   * Tell the delegate (if any) that we stopped playing.
   */
  if (delegate && [delegate respondsTo:@selector(didPlay:)]) {
    [delegate didPlay :self];
  }

  return self;
}

/*
 * Get and Set the sampling rate.
 */
- (double)samplingRate
{
  return samplingRate;
}

- setSamplingRate :(double)sampling_rate
{
  if ((sampling_rate == SND_RATE_LOW) || (sampling_rate == SND_RATE_HIGH)) {
    samplingRate = sampling_rate;
  } else {
    NXRunAlertPanel("Alert",
		    "sampling rate must be %f or %f",
		    NULL,NULL,NULL,SND_RATE_LOW,SND_RATE_HIGH);
    samplingRate = SND_RATE_LOW;
  }

  return self;
}

/*
 * Internal methods.
 */

- (snddriver_handlers_t *)msgHandlers
{
  return &msgHandlers;
}

/*
 * handleCompleted is called whenever we get a completed message
 * from the driver.
 */
- handleCompleted
{
  return [self updateStream];
}

/*
 * updateStream is called whenever we get a 'region completed' message from
 * the driver.  (It is also called at initialization time.)  updateStream
 * allocates a buffer, passes the buffer to the delegate, and enqueue the
 * buffer in the write stream.
 */
- updateStream
{
  int r;
  char *currentRegion;
  
  currentRegion = (char *)regions[regionIndex++];
  if (regionIndex == regionCount) regionIndex = 0;

  bytesPlayed += regionSize;

  /* let the delegate have its way with the buffer */
  if (delegate && [delegate respondsTo:@selector(playData:::)]) {
    [delegate playData :self :currentRegion :regionSize];
  }
  
  /* The delegate may have stopped the recorder.  Quit now if so... */
  if (playerState != PLA_RUNNING) return nil;

  /* enqueue the buffer in the DMA stream to the DACs */
  r = snddriver_stream_start_writing
      (streamPort,			/* port */
       currentRegion,			/* data to be played */
       regionSize/sizeof(short),	/* number of samples to play */
       WRITE_TAG,			/* tag for this region */
       FALSE,				/* preempt */
       FALSE,				/* deallocate on completion*/
       FALSE,				/* send msg when started */
       TRUE,				/* send msg when completed */
       FALSE,				/* send msg when aborted */
       FALSE,				/* send msg when paused */
       FALSE,				/* send msg when resumed */
       FALSE,				/* send msg when overflowed */
       replyPort			/* port for the above messages */
       );
  check_snddriver_error(r,"Cannot enqueue write request");
  return self;
}

@end



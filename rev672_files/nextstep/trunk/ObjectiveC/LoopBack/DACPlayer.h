#import <sound/sounddriver.h>
#import <sound/soundstruct.h>
#import "Player.h"

/* Tag for DMA messages going to sndout */
#define WRITE_TAG	2

#define HIGH_WATER	((512+256)*1024)
#define LOW_WATER	(512 * 1024)
#define BYTES_PER_16BIT	2
#define REGION_SIZE	HIGH_WATER
#define READ_BUF_SIZE	(vm_page_size / BYTES_PER_16BIT)

@interface DACPlayer:Player
{
  snddriver_handlers_t msgHandlers;
  port_t devicePort;
  port_t ownerPort;
  port_t streamPort;
  port_t replyPort;
  double samplingRate;
}

+ new;
- prepare;		/* Prepare to play, state => PLA_PAUSED */
- run;			/* Start playback, state => PLA_RUNNING */
- pause;		/* Pause the playback, state => PLA_PAUSED */
- stop;			/* Stop playing, state => PLA_STOPPED */

			/* Get and set the sampling rate.  Must be 44100 or 22050 */
- (double)samplingRate;
- setSamplingRate :(double)sampling_rate;

			/* Internal methods */
- (snddriver_handlers_t *)msgHandlers;
- handleCompleted;
- updateStream;

@end




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
	id 	statusWindow;		/* Where we display the current status */
	id 	filenameField;

	DPSTimedEntry statusTE;		/* Timed entry to update status window */
	DACPlayer *dacPlayer;		/* The DACPlayer object */

	char *samples;			/* Pointer to samples read from file */
	int byteIndex;			/* Index into samples */
	int dataSize;			/* size of sample space */
}

+ new;

- appDidInit:sender;

- stop:sender;
- pause:sender;
- play:sender;

- updateStatus;

- loadFromFile:(char *) filename;
- setFilename:sender;

/* Delegate methods */
- willPlay :player;
- didPlay :player;
- playData :player :(char *)region :(int)nbytes;

@end

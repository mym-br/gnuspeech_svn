#import <libc.h>
#import <appkit/Application.h>
#import <appkit/TextField.h>
#import <soundkit/Sound.h>
#import <sound/soundstruct.h>
#import "Transport.h"
#import "DACPlayer.h"
#import "errors.h"
#import <math.h>

/*===========================================================================

	UpdateStatus is called via a timed entry every second.  It simply
	dispatches to the updateStatus method for the Transport object.

===========================================================================*/
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

	samples = NULL;
	byteIndex = 0;
	dataSize = 0;

	return self;
}

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
	if (!samples)
	{
		NXRunAlertPanel("No Sound File", "No Sound file to play.", "OK", 
				NULL, NULL);
		return self;
	}
	byteIndex = 0;
	[dacPlayer run];
	return self;
}

- appDidInit:sender;
{
	[self loadFromFile:"Homer.snd"];
	return self;
}


- updateStatus  /* Update the status display.  Called every second via a timed entry. */
{
	Pla_state_t state = [dacPlayer state];
	int nbytes = [dacPlayer bytesPlayed];
	char *stateName;
	char msg[100];

	if (state == PLA_STOPPED) stateName =      "stopped";
	else if (state == PLA_PAUSED) stateName =  "paused";
	else if (state == PLA_RUNNING) stateName = "running";
	else stateName = 			   "unknown";

	sprintf(msg,"%s, %d bytes read\n",stateName,nbytes);
	[statusWindow setStringValue:msg];

	return self;
}

- loadFromFile:(char *) filename
{
FILE *fp;
SNDSoundStruct header;

	if (samples) 
		free(samples);

	fp = fopen(filename, "r");
	if (!fp)
	{
		NXRunAlertPanel("Sound File Read Error", "Cannot find file: %s", "OK", 
				NULL, NULL, filename);
		return self;
	}

	fread(&header,sizeof(header),1,fp);

	if (header.magic!=SND_MAGIC)
	{
		NXRunAlertPanel("Sound File Read Error", "\"%s\" is not a sound file.", "OK", 
				NULL, NULL, filename);
		return self;
	}

	switch(header.samplingRate)
	{
		case (int)SND_RATE_CODEC:
				NXRunAlertPanel("Sampling Rate Error", "File is in CODEC format.", "OK",
					NULL, NULL, filename);
				fclose(fp);
				return self;

		case (int)SND_RATE_HIGH:
				NXRunAlertPanel("Sampling Rate Error", "File is in 44100 format.", "OK",
					NULL, NULL, filename);
				fclose(fp);
				return self;
	}

	dataSize = header.dataSize;
	samples = (char *) malloc(header.dataSize);

	fseek(fp, header.dataLocation, SEEK_SET);
	fread(samples, 1, header.dataSize, fp);

	fclose(fp);
	return self;
}

- setFilename:sender
{
	[self loadFromFile:[filenameField stringValueAt:0]];
	return self;
}

/* Delegate methods called from the DACPlayer object */

- willPlay :player	/* Called when the Player is about to start playing data. */
{
id srateCell;
int region_size, region_count;

	[dacPlayer setupRegions:2*vm_page_size:15];

	/* set the sampling rate */ 
	[dacPlayer setSamplingRate:SND_RATE_LOW];

	return self;
}

- didPlay :player;		/* Called when the Player stops. */
{
	return self;
}

/*===========================================================================

	Called whenever the Player wants more data.  This is the inner loop where
	all the sound is created.  In some other application, we could read sound
	data from a file or from memory.  In this case, we just synthesize a simple
	triangle wave at a given frequency and amplitude.

===========================================================================*/
- playData :player :(char *)region :(int)nbytes
{
int temp;

	if ((nbytes+byteIndex)<dataSize)
	{
		bcopy(&samples[byteIndex], region, nbytes);
		byteIndex+=nbytes;
	}
	else
	{
		temp = dataSize-byteIndex;
		bcopy(&samples[byteIndex], region, temp);
		bcopy(samples, &region[temp], nbytes-temp);
		byteIndex = nbytes-temp;
	}

	return self;
}

@end


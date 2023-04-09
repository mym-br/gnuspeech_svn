/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/SoundData.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

# Revision 1.1.1.1  1994/05/20  00:22:05  len
# Initial archive of TRM interactive Synthesizer.
#

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "SoundData.h"
#import "dsp_control.h"
#include <math.h>

@implementation SoundData

- init
{
    /*  DO REGULAR INITIALIZATION  */
    [super init];

    /*  INITIALIZE DATA TO EMPTY  */
    soundData = NULL;
    soundDataSize = 0;
    largestMagnitude = 0.0;

    return self;
}



- (void)dealloc
{
    /*  FREE BUFFER, IF NECESSARY  */
    [self freeSoundData];

    /*  DO REGULAR FREE  */
    { [super dealloc]; return; };
}



- (void)freeSoundData
{
    /*  FREE BUFFER, IF NECESSARY  */
    if (soundData) {
	cfree((char *)soundData);
	soundDataSize = 0;
	largestMagnitude = 0.0;
    } 
}



- (void)fillAndConvertStereoSoundData:(const short int *)data stereoDataSize:(int)size
{
    int i, j;

    /*  FREE OLD BUFFER, IF NECESSARY  */
    [self freeSoundData];

    /*  RETURN IMMEDIATELY IF INVALID POINTER, OR SIZE OF ZERO  */
    if ((data == NULL) || (size == 0))
	return;

    /*  DETERMINE BUFFER SIZE (REMEMBER: CONVERTING STEREO TO MONO)  */
    soundDataSize = size / 2;

    /*  ALLOCATE THE BUFFER (FLOATS)  */
    soundData = (float *)calloc(soundDataSize, sizeof(float));

    /*  COPY THE LEFT CHANNEL TO THE NEW BUFFER, CONVERT TO FLOAT,
        NORMALIZE RANGE TO BETWEEN -1 AND +1, RECORD LARGEST MAGNITUDE  */
    largestMagnitude = 0.0;
    for (i = 0, j = 0; i < size; i+=2, j++) {
	float magnitude;
	soundData[j] = (float)data[i] / MAX_SAMPLE_SIZE;
	magnitude = fabs(soundData[j]);
	if (magnitude > largestMagnitude)
	    largestMagnitude = magnitude;
    } 
}



- (const float *)soundData
{
    return (const float *)soundData;
}



- (int)soundDataSize
{
    return soundDataSize;
}



- (BOOL)haveSoundData
{
    if (soundData)
	return YES;
    else
	return NO;
}



- (float)largestMagnitude
{
    return largestMagnitude;
}

@end

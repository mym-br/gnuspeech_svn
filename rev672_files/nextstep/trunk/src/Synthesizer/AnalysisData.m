/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/AnalysisData.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

# Revision 1.1.1.1  1994/05/20  00:22:03  len
# Initial archive of TRM interactive Synthesizer.
#

******************************************************************************/

#import "AnalysisData.h"
#import "SoundData.h"
#import "AnalysisWindow.h"
#import "fft.h"


@implementation AnalysisData

- init
{
    /*  DO REGULAR INITIALIZATION  */
    [super init];

    /*  INITIALIZE DATA TO EMPTY  */
    analysisData = NULL;
    windowSize = 0;

    /*  CREATE ANALYSIS WINDOW  */
    analysisWindow = [[AnalysisWindow alloc] init];

    return self;
}



- (void)dealloc
{
    /*  FREE BUFFER, IF NECESSARY  */
    [self freeAnalysisData];

    /*  FREE ANALYSIS WINDOW  */
    [analysisWindow release];

    /*  DO REGULAR FREE  */
    [super dealloc];
}



- (void)freeAnalysisData
{
    /*  FREE BUFFER, IF NECESSARY  */
    if (analysisData) {
	cfree((char *)analysisData);
	windowSize = 0;
    } 
}



- (void)analyzeSoundData:soundDataObj windowSize:(int)size windowType:(int)type alpha:(float)alpha beta:(float)beta normalizeAmplitude:(BOOL)normalize
{
    const float *sound, *window;
    float scale, *temp;
    int i, j, dataPoints, numberFrames;

    /*  FREE OLD BUFFER, IF NECESSARY  */
    [self freeAnalysisData];

    /*  RETURN IMMEDIATELY IF EMPTY SOUND DATA OBJECT  */
    if (![soundDataObj haveSoundData])
	return;

    /*  FIND THE NUMBER OF DATA POINTS WHICH WILL BE ANALYZED  */
    dataPoints = [soundDataObj soundDataSize];

    /*  SET WINDOW SIZE (MUST BE EQUAL OR SMALL THAN THE NUMBER OF DATA POINTS  */
    windowSize = size <= dataPoints ? size : dataPoints;

    /*  DETERMINE THE NUMBER OF FRAMES WHICH WILL BE ANALYZED  */
    numberFrames = dataPoints / windowSize;

    /*  SET THE ANALYSIS WINDOW  */
    [analysisWindow setWindowType:type alpha:alpha beta:beta size:windowSize];

    /*  ALLOCATE A TEMPORARY BUFFER  */
    temp = (float *)calloc(windowSize, sizeof(float));

    /*  ALLOCATE THE OUTPUT ANALYSIS BUFFER (1/2 WINDOW SIZE, SINCE SPECTRUM ONLY)  */
    analysisData = (float *)calloc(windowSize/2, sizeof(float));

    /*  CALCULATE THE AMPLITUDE SCALE  */
    if (normalize && ([soundDataObj largestMagnitude] > 0.0))
	scale = 1.0 / [soundDataObj largestMagnitude];
    else
	scale = 1.0;

    /*  ANALYSIS LOOP;  NOTE THAT WE AVERAGE FFT'S OF EACH FRAME  */
    sound = [soundDataObj soundData];
    window = [analysisWindow windowBuffer];
    for (i = 0; i < numberFrames; i++) {
	int framePos = i * windowSize;

	/*  COPY SOUND DATA INTO TEMP BUFFER, APPLYING SCALING AND WINDOW  */
	for (j = 0; j < windowSize; j++)
	    temp[j] = sound[framePos+j] * scale * window[j];

	/*  DO FFT;  ANALYSIS DONE IN PLACE IN TEMP BUFFER  */
	realfft(temp, windowSize);

	/*  COPY SPECTRUM TO OUTPUT BUFFER, APPLY AVERAGING  */
	for (j = 0; j < (windowSize/2); j++)
	    analysisData[j] += (temp[j] / (float)numberFrames);
    }

#if 0
    /*  COPY SOUND DATA INTO ANALYSIS BUFFER, AND APPLY WINDOW AND SCALING  */
    sound = [soundDataObj soundData];
    window = [analysisWindow windowBuffer];
    for (i = 0; i < windowSize; i++)
	analysisData[i] = sound[i] * scale * window[i];

    /*  DO FFT;  ANALYSIS DONE IN PLACE  */
    realfft(analysisData, windowSize);
#endif

#if 0
    /* temp print  */
    fprintf(stdout, "windowSize = %-d\n", windowSize);
    fprintf(stdout, "scale = %f  largestMagnitude = %f\n",
	    scale, [soundDataObj largestMagnitude]);
    for (i = 0; i < windowSize/2; i++)
	fprintf(stdout, "%3d  %.8f\n", i, analysisData[i]);
#endif

    /*  FREE THE TEMPORARY BUFFER  */
    cfree((char *)temp); 
}



- (const float *)analysisData
{
    return (const float *)analysisData;
}



- (int)windowSize
{
    return windowSize;
}



- (int)spectrumSize
{
    return (windowSize / 2);
}



- (BOOL)haveAnalyzedData
{
    if (analysisData)
	return YES;
    else
	return NO;
}


@end

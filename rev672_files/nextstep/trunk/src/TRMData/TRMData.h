/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:54 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/TRMData/TRMData.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
 * Revision 1.1.1.1  1994/07/14  19:02:40  len
 * Initial archive of TRMData.[hm]
 *

******************************************************************************/


/*  HEADER FILES  ************************************************************/
#import <appkit/appkit.h>


/*  GLOBAL DEFINES  **********************************************************/
#define PHARYNX_SECTIONS     3
#define VELUM_SECTIONS       1
#define ORAL_SECTIONS        5
#define NASAL_SECTIONS       5



@interface TRMData:Object
{
    /*  GLOTTAL SOURCE PARAMETERS  */
    int waveform;
    int showAmplitude;
    int harmonicsScale;
    int unit;
    int pitch;
    int cents;
    float breathiness;
    int glotVol;
    float tp;
    float tnMin;
    float tnMax;
    
    /*  NOISE SOURCE PARAMETERS  */
    int fricVol;
    float fricPos;
    int fricCF;
    int fricBW;
    int NoiseSourceResponseScale;
    int aspVol;
    int modulation;
    int mixOffset;

    /*  THROAT PARAMETERS  */
    int throatVol;
    int throatCutoff;
    int throatResponseScale;

    /*  RESONANT SYSTEM PARAMETERS  */
    double pharynxDiameter[PHARYNX_SECTIONS];
    double velumDiameter[VELUM_SECTIONS];
    double oralDiameter[ORAL_SECTIONS];
    double nasalDiameter[NASAL_SECTIONS];
    double lossFactor;
    double apScale;
    double mouthCoef;
    double noseCoef;
    int mouthResponseScale;
    int noseResponseScale;
    double temperature;
    double length;
    double sampleRate;
    double actualLength;
    int controlPeriod;

    /*  CONTROLLER PARAMETERS  */
    int volume;
    double balance;
    int channels;
    int controlRate;

    /*  ANALYSIS PARAMETERS  */
    BOOL normalizeInput;
    int binSize;
    int windowType;
    float alpha;
    float beta;
    int grayLevel;
    int magnitudeScale;
    float linearUpperThreshold;
    float linearLowerThreshold;
    int logUpperThreshold;
    int logLowerThreshold;
    BOOL spectrographGrid;
    BOOL spectrumGrid;
}

- init;
- initFromFile:(const char *)path;

- readFromFile:(const char *)path;
- writeToFile:(const char *)path;


- (float)glotPitch;
- setGlotPitch:(float)value;
- (float)glotVol;
- setGlotVol:(float)value;

- (float)aspVol;
- setAspVol:(float)value;

- (float)fricVol;
- setFricVol:(float)value;
- (float)fricPos;
- setFricPos:(float)value;
- (float)fricCF;
- setFricCF:(float)value;
- (float)fricBW;
- setFricBW:(float)value;

- (float)r1;
- setR1:(float)value;
- (float)r2;
- setR2:(float)value;
- (float)r3;
- setR3:(float)value;
- (float)r4;
- setR4:(float)value;
- (float)r5;
- setR5:(float)value;
- (float)r6;
- setR6:(float)value;
- (float)r7;
- setR7:(float)value;
- (float)r8;
- setR8:(float)value;

- (float)velum;
- setVelum:(float)value;


- (int)controlRate;
- setControlRate:(int)value;

- (float)volume;
- setVolume:(float)value;
- (int)channels;
- setChannels:(int)value;
- (float)balance;
- setBalance:(float)value;

- (int)waveform;
- setWaveform:(int)value;
- (float)tp;
- setTp:(float)value;
- (float)tnMin;
- setTnMin:(float)value;
- (float)tnMax;
- setTnMax:(float)value;
- (float)breathiness;
- setBreathiness:(float)value;

- (float)length;
- setLength:(float)value;
- (float)temperature;
- setTemperature:(float)value;
- (float)lossFactor;
- setLossFactor:(float)value;

- (float)apScale;
- setApScale:(float)value;
- (float)mouthCoef;
- setMouthCoef:(float)value;
- (float)noseCoef;
- setNoseCoef:(float)value;

- (float)n1;
- setN1:(float)value;
- (float)n2;
- setN2:(float)value;
- (float)n3;
- setN3:(float)value;
- (float)n4;
- setN4:(float)value;
- (float)n5;
- setN5:(float)value;

- (float)throatCutoff;
- setThroatCutoff:(float)value;
- (float)throatVol;
- setThroatVol:(float)value;

- (int)modulation;
- setModulation:(int)value;
- (float)mixOffset;
- setMixOffset:(float)value;

@end

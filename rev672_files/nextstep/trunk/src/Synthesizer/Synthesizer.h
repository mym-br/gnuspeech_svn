/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/Synthesizer.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.5  1994/10/04  18:37:35  len
 * Changed nose and mouth aperture filter coefficients, so now specified
 * as Hz values (which scale appropriately as the tube length changes), rather
 * than arbitrary coefficient values (which don't scale).
 *
 * Revision 1.4  1994/09/19  03:05:29  len
 * Resectioned the TRM to 10 sections in 8 regions.  Also
 * changed friction injection to be continous from sections
 * 3 to 10.
 *
 * Revision 1.3  1994/09/13  21:42:34  len
 * Folded in optimizations made in synthesizer.asm.
 *
 * Revision 1.2  1994/07/13  03:39:58  len
 * Added Mono/Stereo sound output option and changed file format.
 *
 * Revision 1.1.1.1  1994/05/20  00:21:54  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import <AppKit/AppKit.h>
#ifdef HAVE_DSP
#import <dsp/dsp.h>                /*  needed for instance variables, below  */
#endif
#import "ResonantSystem.h"


/*  GLOBAL DEFINES  **********************************************************/
#define TABLE_INC_INT      0
#define TABLE_INC_FRAC     1
#define SOURCE_VOLUME      2
#define MASTER_VOLUME      3
#define BALANCE            4
#define CHANNELS           5
#define WAVEFORM_TYPE      6
#define TP                 7
#define TN_MIN             8
#define TN_MAX             9
#define BREATHINESS        10
#define PULSE_MODULATION   11
#define CROSSMIX_FACTOR    12
#define ASP_VOLUME         13
#define CENTER_FREQUENCY   14
#define BANDWIDTH          15
#define FRICATION_VOLUME   16
#define FRICATION_POSITION 17
#define DAMPING            18

#define OPC_1              19
#define OPC_2              20
#define OPC_3              21
#define ALPHA_L            22
#define ALPHA_R            23
#define ALPHA_T            24
#define OPC_4              25
#define OPC_5              26
#define OPC_6              27
#define OPC_7              28
#define OPC_REFL           29
#define OPC_RAD            30

#define NC_1               31
#define NC_2               32
#define NC_3               33
#define NC_4               34
#define NC_5               35
#define NC_REFL            36
#define NC_RAD             37

#define MOUTH_COEFF        38
#define NOSE_COEFF         39
#define TIME_REG_INT       40
#define TIME_REG_FRAC      41
#define THROAT_CUTOFF      42
#define THROAT_VOLUME      43

#define TABLESIZE          44



@interface Synthesizer:NSObject
{
    BOOL loading;
    BOOL running;

    double pharynxRadius[PHARYNX_REGIONS];
    double oralRadius[ORAL_REGIONS];
    double noseRadius[NOSE_REGIONS];

    double pharynxCoefficient[PHARYNX_REGIONS];
    double alpha0Coefficient, alpha1Coefficient, alpha2Coefficient;
    double oralCoefficient[ORAL_REGIONS];
    double noseCoefficient[NOSE_REGIONS];

    double apertureScaling;

    double sampleRate;
    int    tableSize;
    float  pitch;
    float  centerFrequency;
    float  bandwidth;

    float  tp;
    float  tn;
    int    topHarmonic;

    float  throatCutoff;
    float  mouthApertureCoefficient;
    float  noseApertureCoefficient;

#ifdef HAVE_DSP
    DSPFix24 datatable[TABLESIZE];
#endif
}

- (void)beginLoading;
- (void)endLoading;
- (void)beginRunning:button :(BOOL)analysisEnabled;
- (void)endRunning:button;

- (void)batchLoadParameters;
- (void)dispatchDatatable;

- (void)setMasterVolume:(int)value;
- (void)setBalance:(double)value;

- (void)setChannels:(int)value;

- (void)setBreathiness:(float)value;
- (void)setSourceVolume:(int)value;
- (void)setPitch:(float)value;
- (void)setRiseTime:(float)rtValue fallTimeMin:(float)ftMinValue fallTimeMax:(float)ftMaxValue;
- (void)setWaveformType:(int)value;

- (void)setFricationVolume:(int)value;
- (void)setFricationPosition:(float)value;
- (void)setFricationCenterFrequency:(int)value;
- (void)setFricationBandwidth:(int)value;
- (void)setAspirationVolume:(int)value;
- (void)setPulseModulation:(int)value;
- (void)setCrossmixOffset:(int)value;

- (void)setThroatCutoff:(int)value;
- (void)setThroatVolume:(int)value;

- (void)setMouthFilterCoefficient:(double)value;
- (void)setNoseFilterCoefficient:(double)value;

- (void)setActualLength:(double)length sampleRate:(double)rate controlPeriod:(int)period;
- (void)setDampingFactor:(double)value;
- (void)setApertureScaling:(double)value;
- (void)setPharynxSection:(int)section toDiameter:(double)value;
- (void)setVelumSection:(int)section toDiameter:(double)value;
- (void)setOralSection:(int)section toDiameter:(double)value;
- (void)setNasalSection:(int)section toDiameter:(double)value;

- (void)fillSoundData:soundDataObject;

@end

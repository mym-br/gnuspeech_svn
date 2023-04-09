/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/Synthesizer.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

# Revision 1.5  1994/10/04  18:37:36  len
# Changed nose and mouth aperture filter coefficients, so now specified
# as Hz values (which scale appropriately as the tube length changes), rather
# than arbitrary coefficient values (which don't scale).
#
# Revision 1.4  1994/09/19  03:05:31  len
# Resectioned the TRM to 10 sections in 8 regions.  Also
# changed friction injection to be continous from sections
# 3 to 10.
#
# Revision 1.3  1994/09/13  21:42:36  len
# Folded in optimizations made in synthesizer.asm.
#
# Revision 1.2  1994/07/13  03:40:00  len
# Added Mono/Stereo sound output option and changed file format.
#
# Revision 1.1.1.1  1994/05/20  00:21:58  len
# Initial archive of TRM interactive Synthesizer.
#

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "Synthesizer.h"
#import "GlottalSource.h"
#import "SoundData.h"
#import "dsp_control.h"
#import "conversion.h"
#include <math.h>


@implementation Synthesizer

- init
{
    /*  DO REGULAR INITIALIZATION  */
    self = [super init];

    /*  INITIALIZE THE DSP SYNTHESIZER  */
    initialize_synthesizer();

    return self;
}



- (void)dealloc
{
    /*  FREE UP MEMORY USED BY DSP SYNTHESIZER  */
    free_synthesizer();

    /*  DO REGULAR FREE  */
    { [super dealloc]; return; };
}



- (void)beginLoading
{
    /*  TURN ON LOADING FLAG  */
    loading = YES; 
}



- (void)endLoading
{
    /*  TURN OFF LOADING FLAG  */
    loading = NO;

    /*  DO DELAYED BATCH LOAD  */
    if (running)
	[self batchLoadParameters]; 
}



- (void)beginRunning:button :(BOOL)analysisEnabled
{
    /*  GET CONTROL OF THE DSP/SOUND DEVICES  */
    if (grab_and_initialize_DSP(analysisEnabled) == ST_ERROR) {
	/*  PUT UP ALERT PANEL, IF DSP IN USE  */
	NSRunAlertPanel(@"Alert", @"The Sound and/or DSP hardware is already in use.", @"OK", nil, nil);
	/*  TURN BUTTON OFF  */
	[button setState:0];
	return;
    }

    /*  TURN ON RUNNING FLAG  */
    running = YES;

    /*  DO BATCH LOAD OF ALL PARAMETERS  */
    [self batchLoadParameters];

    /*  START THE SYNTHESIZER  */
    start_synthesizer(); 
}



- (void)endRunning:button
{
    /*  SET RUNNING FLAG TO OFF  */
    running = NO;
    
    /*  STOP THE SYNTHESIZER  */
    stop_synthesizer();

    /*  RELINQUISH OWNERSHIP OF THE DSP/DAC  */
    relinquish_DSP(); 
}



- (void)batchLoadParameters
{
    #if !VARIABLE_GP
    if (write_bandlimited_gp(tp, tn, topHarmonic, ROLLOFF_FACTOR) == ST_ERROR) {
	NSLog(@"Error dispatching wavetable to DSP.");
	exit(-1);
    }
    #endif

    [self dispatchDatatable]; 
}



- (void)dispatchDatatable
{
    /*  RETURN IMMEDIATELY IF SYNTH NOT RUNNING  */
    if (!running)
	return;

#ifdef HAVE_DSP    
    /*  SEND THE DATA TABLE TO THE DSP  */
    if (write_datatable(datatable, TABLESIZE) == ST_ERROR) {
	NSLog(@"Error dispatching datatable to DSP.");
	exit(-1);
    } 
#endif
}



- (void)setMasterVolume:(int)value
{
#ifdef HAVE_DSP    
    /*  CALCULATE & STORE SCALED MASTER VOLUME  */
    datatable[MASTER_VOLUME] = DSPFloatToFix24(scaledVolume(value));
#endif
    
    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- (void)setBalance:(double)value
{
#ifdef HAVE_DSP    
    /*  STORE BALANCE  */
    datatable[BALANCE] = DSPFloatToFix24(value);
#endif
    
    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- (void)setChannels:(int)value
{
#ifdef HAVE_DSP    
    /*  STORE THE NUMBER OF CHANNELS  */
    datatable[CHANNELS] = DSPIntToFix24(value);
#endif

    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- (void)setBreathiness:(float)value
{
#ifdef HAVE_DSP    
    /*  CALCULATE & STORE BREATHINESS  */
    datatable[BREATHINESS] = DSPFloatToFix24(value/100.0);
#endif
    
    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- (void)setSourceVolume:(int)value
{
#ifdef HAVE_DSP    
    /*  CALCULATE & STORE SCALED SOURCE VOLUME  */
    datatable[SOURCE_VOLUME] = DSPFloatToFix24(scaledVolume(value));
#endif
    
    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- calculateTableIncrement
{
    float x = tableSize * frequency(pitch) / (OVERSAMPLE * sampleRate);
#ifdef HAVE_DSP    
    datatable[TABLE_INC_INT] = DSPIntToFix24((int)x);
    datatable[TABLE_INC_FRAC] = DSPFloatToFix24(x - (float)((int)x));
#endif

    return self;
}



- (void)setPitch:(float)value
{
    /*  STORE THE PITCH  */
    pitch = value;

    /*  CALCULATE & STORE TABLE INCREMENT  */
    [self calculateTableIncrement];

    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- (void)setRiseTime:(float)rtValue fallTimeMin:(float)ftMinValue fallTimeMax:(float)ftMaxValue
{
    /*  CALCULATE & STORE GLOTTAL PULSE PARAMETERS  */
#ifdef HAVE_DSP    
    datatable[TP] = DSPFloatToFix24(rtValue/100.0);
    datatable[TN_MIN] = DSPFloatToFix24(ftMinValue/100.0);
    datatable[TN_MAX] = DSPFloatToFix24(ftMaxValue/100.0);
    #if !VARIABLE_GP
    tp = rtValue/100.0;
    tn = ftMinValue/100.0;
    topHarmonic = (int)ftMaxValue;  // actually top harmonic value
    #endif

    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading) {
        #if !VARIABLE_GP
	if (write_bandlimited_gp(tp, tn, topHarmonic, ROLLOFF_FACTOR) == ST_ERROR) {
	    NSLog(@"Error dispatching wavetable to DSP.");
	    exit(-1);
	}
        #endif
	[self dispatchDatatable];
    } 
#endif
}



- (void)setWaveformType:(int)value
{
#ifdef HAVE_DSP    
    /*  STORE WAVEFORM TYPE  */
    datatable[WAVEFORM_TYPE] = DSPIntToFix24(value);
#endif

    /*  STORE NEW WAVEFORM TABLE SIZE  */
    if (value == WAVEFORMTYPE_SINE)
	tableSize = SINE_TABLE_SIZE;
    else
	tableSize = GP_TABLE_SIZE;

    /*  RECALCULATE TABLE INCREMENT  */
    [self calculateTableIncrement];
    
    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- (void)setFricationVolume:(int)value
{
#ifdef HAVE_DSP    
    /*  CALCULATE & STORE SCALED FRICATION VOLUME  */
    datatable[FRICATION_VOLUME] = DSPFloatToFix24(scaledVolume(value));
#endif
    
    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- (void)setFricationPosition:(float)value
{
#ifdef HAVE_DSP    
    /*  CALCULATE & STORE SCALED FRICATION POSITION  */
    datatable[FRICATION_POSITION] = DSPFloatToFix24(value/POSITION_SCALE);
#endif
    
    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- calculateCenterFrequency
{
#ifdef HAVE_DSP    
    /*  CALCULATE SCALED CENTER FREQUENCY  */
    datatable[CENTER_FREQUENCY] = DSPFloatToFix24(centerFrequency/sampleRate);    
#endif

    return self;
}



- (void)setFricationCenterFrequency:(int)value
{
    /*  STORE CENTER FREQUENCY VALUE  */
    centerFrequency = (float)value;

    /*  CALCULATE SCALED CENTER FREQUENCY  */
    [self calculateCenterFrequency];
    
    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- calculateBandwidth
{
#ifdef HAVE_DSP    
    /*  CALCULATE SCALED BANDWIDTH  */
    datatable[BANDWIDTH] = DSPFloatToFix24((float)bandwidth/sampleRate);
#endif

    return self;
}



- (void)setFricationBandwidth:(int)value
{
    /*  STORE BANDWIDTH  */
    bandwidth = (float)value;

    /*  CALCULATE SCALED BANDWIDTH  */
    [self calculateBandwidth];

    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- (void)setAspirationVolume:(int)value
{
#ifdef HAVE_DSP    
    /*  CALCULATE & STORE SCALED ASPIRATION VOLUME  */
    datatable[ASP_VOLUME] = DSPFloatToFix24(scaledVolume(value));
#endif
    
    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- (void)setPulseModulation:(int)value
{
#ifdef HAVE_DSP    
    /*  STORE PULSE MODULATION FLAG  */
    datatable[PULSE_MODULATION] = DSPIntToFix24(value);
#endif
    
    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- (void)setCrossmixOffset:(int)value
{
#ifdef HAVE_DSP    
    /*  CALCULATE & STORE SCALED CROSSMIX FACTOR  */
    datatable[CROSSMIX_FACTOR] =
	DSPFloatToFix24( (float)(1.0/(amplitude((double)value)*CROSSMIX_FACTOR_SCALE)) );
#endif
    
    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- calculateThroatCutoff
{
#ifdef HAVE_DSP    
    /*  CALCULATE SCALED BANDWIDTH  */
    datatable[THROAT_CUTOFF] = DSPFloatToFix24((float)throatCutoff/sampleRate);
#endif
    return self;
}



- (void)setThroatCutoff:(int)value
{
    /*  RECORD CUTOFF FREQUENCY  */
    throatCutoff = (float)value;

    /*  CALCULATE THE CUTOFF FACTOR  */
    [self calculateThroatCutoff];

    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- (void)setThroatVolume:(int)value
{
#ifdef HAVE_DSP    
    /*  CALCULATE & STORE SCALED MASTER VOLUME  */
    datatable[THROAT_VOLUME] = DSPFloatToFix24(scaledVolume(value));
#endif
    
    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- calculateMouthFilterCoefficient
{
    float nyquist = sampleRate / 2.0;

#ifdef HAVE_DSP    
    /*  CALCULATE SCALED COEFFICIENT  */
    datatable[MOUTH_COEFF] =
	DSPFloatToFix24((nyquist - mouthApertureCoefficient) / nyquist);
#endif
    return self;
}



- (void)setMouthFilterCoefficient:(double)value;
{
    /*  RECORD MOUTH FILTER COEFFICIENT  */
    mouthApertureCoefficient = value;

    /*  CALCULATE SCALED COEFFICIENT  */
    [self calculateMouthFilterCoefficient];

    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable];
}



- calculateNoseFilterCoefficient
{
    float nyquist = sampleRate / 2.0;

#ifdef HAVE_DSP    
    /*  CALCULATE SCALED COEFFICIENT  */
    datatable[NOSE_COEFF] =
	DSPFloatToFix24((nyquist - noseApertureCoefficient) / nyquist);
#endif

    return self;
}



- (void)setNoseFilterCoefficient:(double)value;
{
    /*  RECORD MOUTH FILTER COEFFICIENT  */
    noseApertureCoefficient = value;

    /*  CALCULATE SCALED COEFFICIENT  */
    [self calculateNoseFilterCoefficient];

    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable];
}



- (void)setActualLength:(double)length sampleRate:(double)rate controlPeriod:(int)period
{
    double timeRegisterIncrement;
    int integerPart, fractionalPart;

    /*  RECORD SAMPLE RATE  */
    sampleRate = rate;

    /*  CALCULATE NEW TIME REGISTER INCREMENT  */
    timeRegisterIncrement =
	rint(pow(2.0,FRACTION_BITS) * sampleRate / OUTPUT_SRATE);
    integerPart = (int)(timeRegisterIncrement / pow(2.0,M_BITS));
    fractionalPart =
	(int)(timeRegisterIncrement - ((double)integerPart * pow(2.0,M_BITS)));
#ifdef HAVE_DSP
    datatable[TIME_REG_INT] = integerPart;
    datatable[TIME_REG_FRAC] = fractionalPart;
#endif

    /*  UPDATE EVERYTHING THAT RELIES ON THE SAMPLE RATE  */
    [self calculateTableIncrement];
    [self calculateCenterFrequency];
    [self calculateBandwidth];
    [self calculateThroatCutoff];
    [self calculateMouthFilterCoefficient];
    [self calculateNoseFilterCoefficient];

    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- (void)setDampingFactor:(double)value
{
#ifdef HAVE_DSP    
    /*  CALCULATE AND STORE DAMPING FACTOR  */
    datatable[DAMPING] = DSPDoubleToFix24(value);
#endif

    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- printRadiiAndCoefficients
{
    int i;

    /*  PRINT PHARYNX RADII  */
    for (i = 0; i < PHARYNX_REGIONS; i++)
	printf("%f ", pharynxRadius[i]);
    printf("\n");

    /*  PRINT PHARYNX COEFFICIENTS  */
    printf("    ");
    for (i = 0; i < PHARYNX_REGIONS; i++)
	printf("%f ", pharynxCoefficient[i]);
    printf("\n");

    /*  PRINT ALPHA COEFFICIENTS  */
    printf("alpha = %f  %f  %f\n", alpha0Coefficient, 
	   alpha1Coefficient, alpha2Coefficient);

    /*  PRINT ORAL RADII  */
    for (i = 0; i < ORAL_REGIONS; i++)
	printf("%f ", oralRadius[i]);
    printf("\n");

    /*  PRINT ORAL COEFFICIENTS  */
    printf("    ");
    for (i = 0; i < ORAL_REGIONS; i++)
	printf("%f ", oralCoefficient[i]);
    printf("\n");

    /*  PRINT NOSE RADII  */
    for (i = 0; i < NOSE_REGIONS; i++)
	printf("%f ", noseRadius[i]);
    printf("\n");

    /*  PRINT NOSE COEFFICIENTS  */
    printf("    ");
    for (i = 0; i < NOSE_REGIONS; i++)
	printf("%f ", noseCoefficient[i]);
    printf("\n");

    /*  PRINT CONVERTED DATATABLE  */
#ifdef HAVE_DSP
    for (i = 0; i < TABLESIZE; i++)
	printf("datatable[%-d] = 0x%x\n", i, datatable[i]);
    printf("\n");
#endif

    return self;
}



- calculateCoefficients
{
    int i;
    double r0_2, r1_2, r2_2, sum;


    /*  CALCULATE PHARYNX COEFFICIENTS (JUNCTIONS 0-1, 1-2)  */
    for (i = 0; i < (PHARYNX_REGIONS-1); i++) {
	r0_2 = pharynxRadius[i] * pharynxRadius[i];
	r1_2 = pharynxRadius[i+1] * pharynxRadius[i+1];

	if ((r0_2 == 0.0) && (r1_2 == 0.0))
	    pharynxCoefficient[i] = 0.0;
	else
	    pharynxCoefficient[i] = (r0_2 - r1_2) / (r0_2 + r1_2);

#ifdef HAVE_DSP
	datatable[OPC_1 + i] = DSPDoubleToFix24(pharynxCoefficient[i]);
#endif
    }

    /*  CALCULATE COEFFICIENT BETWEEN PHARYNX AND ORAL CAVITIES  */
    r0_2 = pharynxRadius[2] * pharynxRadius[2];
    r1_2 = oralRadius[0] * oralRadius[0];

    if ((r0_2 == 0.0) && (r1_2 == 0.0))
	pharynxCoefficient[2] = 0.0;
    else
	pharynxCoefficient[2] = (r0_2 - r1_2) / (r0_2 + r1_2);

#ifdef HAVE_DSP
    datatable[OPC_3] = DSPDoubleToFix24(pharynxCoefficient[2]);
#endif

    /*  CALCULATE ALPHA COEFFICIENTS FOR 3-WAY JUNCTION  */
    r0_2 = r1_2 = oralRadius[0] * oralRadius[0];
    r2_2 = noseRadius[0] * noseRadius[0];
    sum = 1.0 / (r0_2 + r1_2 + r2_2);     // be sure to scale Junction P by 2 in dsp
    alpha0Coefficient = sum * r0_2;
    alpha1Coefficient = sum * r1_2;
    alpha2Coefficient = sum * r2_2;

#ifdef HAVE_DSP
    datatable[ALPHA_L] = DSPDoubleToFix24(alpha0Coefficient);
    datatable[ALPHA_R] = DSPDoubleToFix24(alpha1Coefficient);
    datatable[ALPHA_T] = DSPDoubleToFix24(alpha2Coefficient);
#endif

    /*  CALCULATE ORAL COEFFICIENTS  */
    for (i = 0; i < (ORAL_REGIONS-1); i++) {
	r0_2 = oralRadius[i] * oralRadius[i];
	r1_2 = oralRadius[i+1] * oralRadius[i+1];

	if ((r0_2 == 0.0) && (r1_2 == 0.0))
	    oralCoefficient[i] = 0.0;
	else
	    oralCoefficient[i] = (r0_2 - r1_2) / (r0_2 + r1_2);

#ifdef HAVE_DSP
	datatable[OPC_4 + i] = DSPDoubleToFix24(oralCoefficient[i]);
#endif
    }

    /*  CALCULATE END COEFFICIENT FOR MOUTH */
    r0_2 = oralRadius[ORAL_REGIONS-1] * oralRadius[ORAL_REGIONS-1];
    r1_2 = apertureScaling * apertureScaling;
    oralCoefficient[ORAL_REGIONS-1] = (r0_2 - r1_2) / (r0_2 + r1_2);
#ifdef HAVE_DSP
    datatable[OPC_REFL] = DSPDoubleToFix24(oralCoefficient[ORAL_REGIONS-1]);
    datatable[OPC_RAD] = DSPDoubleToFix24(oralCoefficient[ORAL_REGIONS-1] + 1.0);
#endif

    /*  CALCULATE NOSE COEFFICIENTS  */
    for (i = 0; i < (NOSE_REGIONS-1); i++) {
	r0_2 = noseRadius[i] * noseRadius[i];
	r1_2 = noseRadius[i+1] * noseRadius[i+1];

	if ((r0_2 == 0.0) && (r1_2 == 0.0))
	    noseCoefficient[i] = 0.0;
	else
	    noseCoefficient[i] = (r0_2 - r1_2) / (r0_2 + r1_2);

#ifdef HAVE_DSP
	datatable[NC_1 + i] = DSPDoubleToFix24(noseCoefficient[i]);
#endif
    }

    /*  CALCULATE END COEFFICIENT FOR NOSE */
    r0_2 = noseRadius[NOSE_REGIONS-1] * noseRadius[NOSE_REGIONS-1];
    r1_2 = apertureScaling * apertureScaling;
    noseCoefficient[NOSE_REGIONS-1] = (r0_2 - r1_2) / (r0_2 + r1_2);
#ifdef HAVE_DSP
    datatable[NC_REFL] = DSPDoubleToFix24(noseCoefficient[NOSE_REGIONS-1]);
    datatable[NC_RAD] = DSPDoubleToFix24(noseCoefficient[NOSE_REGIONS-1] + 1.0);
#endif
    return self;
}



- (void)setApertureScaling:(double)value
{
    /*  RECORD APERTURE SCALING RADIUS  */
    apertureScaling = value / 2.0;

    /*  CALCULATE THE SCATTERING JUNCTION COEFFICIENTS  */
    [self calculateCoefficients];

    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- (void)setPharynxSection:(int)section toDiameter:(double)value
{
    /*  CALCULATE & RECORD THE RADIUS OF THE SECTION  */
    pharynxRadius[section] = value / 2.0;

    /*  UPDATE THE SCATTERING COEFFICIENTS  */
    [self calculateCoefficients];

    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- (void)setVelumSection:(int)section toDiameter:(double)value
{
    /*  CALCULATE & STORE SECTION RADIUS  */
    /*  REMEMBER THAT VELUM SECTION IS PART OF NASAL TRACT  */
    noseRadius[section] = value / 2.0;

    /*  CALCULATE COEFFICIENTS  */
    [self calculateCoefficients];

    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- (void)setOralSection:(int)section toDiameter:(double)value
{
    /*  CALCULATE & STORE SECTION RADIUS  */
    oralRadius[section] = value / 2.0;

    /*  CALCULATE COEFFICIENTS  */
    [self calculateCoefficients];

    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- (void)setNasalSection:(int)section toDiameter:(double)value
{
    /*  CALCULATE & STORE SECTION RADIUS  */
    /*  REMEMBER THAT VELUM SECTION IS PART OF NASAL TRACT  */
    noseRadius[VELUM_REGIONS+section] = value / 2.0;

    /*  CALCULATE COEFFICIENTS  */
    [self calculateCoefficients];

    /*  DO UPDATE IF SYNTHESIZER IS RUNNING, BUT NOT LOADING  */
    if (running & !loading)
	[self dispatchDatatable]; 
}



- (void)fillSoundData:soundDataObject
{
    [soundDataObject fillAndConvertStereoSoundData:stereoSoundBuffer() stereoDataSize:DMA_OUT_SIZE]; 
}
@end

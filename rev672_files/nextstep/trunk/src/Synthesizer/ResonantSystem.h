/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/ResonantSystem.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.2  1994/09/19  03:05:25  len
 * Resectioned the TRM to 10 sections in 8 regions.  Also
 * changed friction injection to be continous from sections
 * 3 to 10.
 *
 * Revision 1.1.1.1  1994/05/20  00:21:45  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

#import <AppKit/AppKit.h>

#define PHARYNX_REGIONS     3
#define VELUM_REGIONS       1
#define ORAL_REGIONS        5
#define NASAL_REGIONS       5
#define NOSE_REGIONS        (VELUM_REGIONS+NASAL_REGIONS)
#define TOTAL_SECTIONS      10


@interface ResonantSystem:NSObject
{
    id	actualLengthField;
    id	apertureMatrix;
    id	controlPeriodField;
    id	dampingFactorField;
    id	lengthField;
    id  lengthFieldCM;
    id	lengthSlider;
    id	lossFactorField;
    id	lossFactorSlider;
    id  mouthFilterField;
    id  mouthFilterSlider;
    id	mouthFrequencyResponse;
    id	mouthSwitch;
    id	nasalMatrix;
    id	nasalSection1;
    id	nasalSection2;
    id	nasalSection3;
    id	nasalSection4;
    id	nasalSection5;
    id  noseFilterField;
    id  noseFilterSlider;
    id	noseFrequencyResponse;
    id	noseSwitch;
    id	oralMatrix1;
    id	oralMatrix2;
    id	oralSection1;
    id	oralSection2;
    id	oralSection3;
    id	oralSection4;
    id	oralSection5;
    id	pharynxMatrix;
    id	pharynxSection1;
    id	pharynxSection2;
    id	pharynxSection3;
    id	sampleRateField;
    id	temperatureField;
    id  temperatureFieldDegree;
    id  temperatureFieldCelsius;
    id	temperatureSlider;
    id	velumMatrix;
    id	velumSection;
    id  positionView;

    id  resonantSystemWindow;
    id  throat;
    id  noiseSource;
    id  synthesizer;
    id  controller;

    double pharynxDiameter[PHARYNX_REGIONS];
    double velumDiameter[VELUM_REGIONS];
    double oralDiameter[ORAL_REGIONS];
    double nasalDiameter[NASAL_REGIONS];

    double lossFactor;
    double apertureScaling;

    double mouthFilterCoefficient;
    double noseFilterCoefficient;

    int mouthResponseScale;
    int noseResponseScale;

    double temperature;
    double length;
    double sampleRate;
    double actualLength;
    int    controlPeriod;
}

- (void)defaultInstanceVariables;
- (void)calculateSampleRate;

- (void)awakeFromNib;
- (void)displayAndSynthesizeIvars;

- (void)saveToStream:(NSArchiver *)typedStream;
- (void)openFromStream:(NSArchiver *)typedStream;

- (void)pharynxSectionMoved:sender;
- (void)pharynxMatrixEntered:sender;

- (void)velumSectionMoved:sender;
- (void)velumMatrixEntered:sender;

- (void)oralSectionMoved:sender;
- (void)oralMatrix1Entered:sender;
- (void)oralMatrix2Entered:sender;

- (void)nasalSectionMoved:sender;
- (void)nasalMatrixEntered:sender;

- (void)lengthSliderMoved:sender;
- (void)lengthFieldEntered:sender;

- (void)temperatureSliderMoved:sender;
- (void)temperatureFieldEntered:sender;

- (void)lossFactorSliderMoved:sender;
- (void)lossFactorFieldEntered:sender;

- (void)apertureMatrixEntered:sender;

- (void)noseSwitchPushed:sender;
- (void)mouthSwitchPushed:sender;

- (void)mouthFilterFieldEntered:sender;
- (void)mouthFilterSliderMoved:sender;

- (void)noseFilterFieldEntered:sender;
- (void)noseFilterSliderMoved:sender;

- (void)adjustSampleRate;
- (double)sampleRate;

- (void)injectFricationAt:(float)position;

- (void)windowWillMiniaturize:sender;
- (void)setTitle:(NSString *)path;
@end

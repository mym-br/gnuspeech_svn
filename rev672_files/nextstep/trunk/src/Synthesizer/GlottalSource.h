/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/GlottalSource.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.1.1.1  1994/05/20  00:21:40  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

#import <AppKit/AppKit.h>


/*  GLOBAL DEFINES  **********************************************************/
#define WAVEFORMTYPE_GP   0
#define WAVEFORMTYPE_SINE 1


@interface GlottalSource:NSObject
{
    id	breathinessField;
    id	breathinessSlider;
    id	frequencyField;
    id	parameterForm;
    id  parameterPercent;
    id	parameterView;
    id	pitchField;
    id	pitchSlider;
    id  pitchMaxField;
    id  pitchMinField;
    id	scaleView;
    id	showAmplitudeSwitch;
    id	harmonicsSwitch;
    id	harmonicsView;
    id	unitButton;
    id	volumeField;
    id	volumeSlider;
    id	waveshapeView;
    id  glottalSourceWindow;
    id  waveformTypeSwitch;
    id  noiseSource;
    id	synthesizer;
    id  controller;

    int waveformType;
    int showAmplitude;
    int harmonicsScale;

    int unit;
    int pitch;
    int cents;

    float breathiness;
    int volume;

    float riseTime;
    float fallTimeMin;
    float fallTimeMax;
}

- (void)defaultInstanceVariables;

- (void)awakeFromNib;
- (void)displayAndSynthesizeIvars;

- (void)saveToStream:(NSArchiver *)typedStream;
- (void)openFromStream:(NSArchiver *)typedStream;

- (void)breathinessEntered:sender;
- (void)breathinessSliderMoved:sender;

- (void)waveformTypeSwitchPushed:sender;

- (void)riseTimeEntered:sender;
- (void)fallTimeMinEntered:sender;
- (void)fallTimeMaxEntered:sender;

- (void)frequencyEntered:sender;
- (void)pitchEntered:sender;
- (void)pitchSliderMoved:sender;
- (void)showAmplitudeSwitchPushed:sender;
- (void)harmonicsSwitchPushed:sender;
- (void)unitButtonPushed:sender;
- (void)volumeEntered:sender;
- (void)volumeSliderMoved:sender;

- (void)displayWaveformAndHarmonics;
- (int)glottalVolume;

- (void)windowWillMiniaturize:sender;

@end

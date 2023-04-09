/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/NoiseSource.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.1.1.1  1994/05/20  00:21:50  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

#import <AppKit/AppKit.h>

@interface NoiseSource:NSObject
{
    id	aspirationField;
    id	aspirationSlider;
    id	bandpassView;
    id	bandwidthField;
    id	bandwidthSlider;
    id	centerFrequencyField;
    id	centerFrequencySlider;
    id	crossmixOffsetField;
    id  crossmixOffsetDB;
    id	crossmixView;
    id	fricationVolumeField;
    id	fricationVolumeSlider;
    id	noiseSourceWindow;
    id	positionField;
    id	positionSlider;
    id	pulseModulationSwitch;
    id	scaleSwitch;
    id  pureField;
    id  pulsedField;
    id  glottalSource;
    id  resonantSystem;
    id  synthesizer;
    id  controller;

    int fricationVolume;
    float fricationPosition;
    int centerFrequency;
    int bandwidth;
    int responseScale;
    int aspirationVolume;
    int pulseModulation;
    int crossmixOffset;
}

- (void)defaultInstanceVariables;

- (void)awakeFromNib;
- (void)displayAndSynthesizeIvars;

- (void)saveToStream:(NSArchiver *)typedStream;
- (void)openFromStream:(NSArchiver *)typedStream;

- (void)fricationVolumeEntered:sender;
- (void)fricationVolumeSliderMoved:sender;
- (void)positionEntered:sender;
- (void)positionSliderMoved:sender;
- (float)fricationPosition;
- (void)centerFrequencyEntered:sender;
- (void)centerFrequencySliderMoved:sender;
- (void)bandwidthEntered:sender;
- (void)bandwidthSliderMoved:sender;
- (void)scaleSwitchPushed:sender;

- (void)aspirationEntered:sender;
- (void)aspirationSliderMoved:sender;

- (void)pulseModulationSwitchPushed:sender;
- (void)crossmixOffsetEntered:sender;

- (void)setGlottalVolume:sender;

- (void)adjustToNewSampleRate;
- (void)windowWillMiniaturize:sender;

@end

#import "Controller.h"
#import "Tone.h"


@implementation Controller

- init
{
    /*  DO REGULAR SUPERCLASS INITIALIZATION  */
    self = [super init];

    /*  INSTANTIATE AN INSTANCE OF THE TONE CLASS  */
    tone = [[Tone alloc] init];

    return self;
}



- free
{
    /*  FREE TONE INSTANCE  */
    [tone free];

    /*  DO REGULAR SUPERCLASS FREE  */
    return [super free];
}



- awakeFromNib
{
    /*  SET THE SLIDERS AND FIELDS TO TONE DEFAULT VALUES  */
    [volumeField setFloatValue:[tone volume]];
    [volumeSlider setFloatValue:[tone volume]];

    [frequencyField setFloatValue:[tone frequency]];
    [frequencySlider setFloatValue:[tone frequency]];

    [balanceField setFloatValue:[tone stereoBalance]];
    [balanceSlider setFloatValue:[tone stereoBalance]];

    [harmonicsSlider setMaxValue:HARMONICS_MAX];
    [harmonicsField setIntValue:[tone numberHarmonics]];
    [harmonicsSlider setIntValue:[tone numberHarmonics]];

    [rampTimeField setFloatValue:[tone rampTime]];
    [rampTimeSlider setFloatValue:[tone rampTime]];

    return self;
}



- volumeSliderMoved:sender
{
    /*  SET VALUE OF VOLUME FIELD  */
    [volumeField setFloatValue:[sender floatValue]];

    /*  SET VOLUME OF THE TONE  */
    [tone setVolume:[sender floatValue]];

    return self;
}



- frequencySliderMoved:sender
{
    /*  SET VALUE OF FREQUENCY FIELD  */
    [frequencyField setFloatValue:[sender floatValue]];

    /*  SET FREQUENCY OF THE TONE  */
    [tone setFrequency:[sender floatValue]];

    return self;
}



- balanceSliderMoved:sender
{
    /*  SET VALUE OF FIELD  */
    [balanceField setFloatValue:[sender floatValue]];

    /*  SET BALANCE OF THE TONE  */
    [tone setStereoBalance:[sender floatValue]];

    return self;
}



- harmonicsSliderMoved:sender
{
    /*  SET VALUE OF FIELD  */
    [harmonicsField setIntValue:[sender intValue]];

    /*  SET HARMONICS OF THE TONE  */
    [tone setNumberHarmonics:[sender intValue]];

    return self;
}



- rampTimeSliderMoved:sender
{
    /*  SET VALUE OF FIELD  */
    [rampTimeField setFloatValue:[sender floatValue]];

    /*  SET RAMP TIME OF THE TONE  */
    [tone setRampTime:[sender floatValue]];

    return self;
}



- playButtonPushed:sender
{
    int state = [sender state];

    if (state) {
	if ([tone playTone] == nil) {
	    NXRunAlertPanel("Alert", "DSP/Sound hardware in use.", "OK",
			    NULL, NULL);
	    [sender setState:0];
	}
    }
    else
	[tone stopTone];

    return self;
}

@end

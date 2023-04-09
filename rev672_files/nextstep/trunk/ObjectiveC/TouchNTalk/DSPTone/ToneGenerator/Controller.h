
#import <appkit/appkit.h>

@interface Controller:Object
{
    id	volumeField;
    id	volumeSlider;
    id	frequencyField;
    id	frequencySlider;
    id  balanceField;
    id  balanceSlider;
    id  harmonicsField;
    id  harmonicsSlider;
    id  rampTimeField;
    id  rampTimeSlider;

    id  tone;
}

- init;
- free;

- volumeSliderMoved:sender;
- frequencySliderMoved:sender;
- balanceSliderMoved:sender;
- harmonicsSliderMoved:sender;
- rampTimeSliderMoved:sender;
- playButtonPushed:sender;

@end

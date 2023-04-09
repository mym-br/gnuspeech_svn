#import <appkit/appkit.h>

@interface Preferences:Object
{
    id  mySpeaker;
    id  preferencesWindow;

    id  vtlOffsetSlider;
    id  vtlOffsetField;
    id  breathinessSlider;
    id  breathinessField;
    id  speedSlider;
    id  speedField;
    id  volumeSlider;
    id  volumeField;
    id  channelsPopUp;
    id  balanceSlider;
    id  balanceField;
    id  balanceLabel;
    id  pitchOffsetSlider;
    id  pitchOffsetField;
    id  intonationMatrix;
    id  voiceTypeMatrix;
}

- awakeFromNib;

- vtlOffsetSliderMoved:sender;
- vtlOffsetFieldEntered:sender;

- breathinessSliderMoved:sender;
- breathinessFieldEntered:sender;

- speedSliderMoved:sender;
- speedFieldEntered:sender;

- volumeSliderMoved:sender;
- volumeFieldEntered:sender;

- channelsSelected:sender;
- displayChannels:(int)value;

- balanceSliderMoved:sender;
- balanceFieldEntered:sender;

- pitchOffsetSliderMoved:sender;
- pitchOffsetFieldEntered:sender;

- intonationSelected:sender;

- voiceTypeSelected:sender;

- setUserDefaults:sender;
- reset:sender;
- revertToSaved:sender;

@end

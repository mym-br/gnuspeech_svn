#import "Preferences.h"
#import "BigMouth.h"
#import <TextToSpeech/TextToSpeech.h>


@implementation Preferences

- awakeFromNib
{
    float value;
    int mask;


    /*  GET OBJECT THAT DOES SPEAKING  */
    mySpeaker = [NXApp ttsInstance];
    
    /*  SET MINIWINDOW ICONS  */
    [preferencesWindow setMiniwindowIcon:"mouth.tiff"];

    /*  TURN OFF DISPLAY WHILE INITIALIZING SUBVIEWS  */
    [preferencesWindow disableDisplay];
    
    /*  SET DISPLAY FORMAT OF FIELDS  */
    [vtlOffsetField setFloatingPointFormat:YES left:1 right:2];
    [breathinessField setFloatingPointFormat:NO left:1 right:1];
    [volumeField setFloatingPointFormat:YES left:2 right:1];
    [balanceField setFloatingPointFormat:YES left:1 right:2];
    [speedField setFloatingPointFormat:NO left:1 right:2];
    [pitchOffsetField setFloatingPointFormat:YES left:2 right:1];

    /*  SET THE CONTROL PANEL TO DEFAULTS (TTS INIT LOADS THESE AUTOMATICALLY)  */
    value = [mySpeaker vocalTractLengthOffset];
    [vtlOffsetSlider setFloatValue:value];
    [vtlOffsetField setFloatValue:value];

    value = [mySpeaker breathiness];
    [breathinessSlider setFloatValue:value];
    [breathinessField setFloatValue:value];

    value = [mySpeaker volume];
    [volumeSlider setFloatValue:value];
    [volumeField setFloatValue:value];

    [self displayChannels:[mySpeaker numberChannels]];

    value = [mySpeaker balance];
    [balanceSlider setFloatValue:value];
    [balanceField setFloatValue:value];

    value = [mySpeaker speed];
    [speedSlider setFloatValue:value];
    [speedField setFloatValue:value];

    value = [mySpeaker pitchOffset];
    [pitchOffsetSlider setFloatValue:value];
    [pitchOffsetField setFloatValue:value];

    mask = [mySpeaker intonation];
    if (TTS_INTONATION_MICRO & mask)
	[intonationMatrix selectCellAt:0:0];
    if (TTS_INTONATION_MACRO & mask)
	[intonationMatrix selectCellAt:1:0];
    if (TTS_INTONATION_DECLIN & mask)
	[intonationMatrix selectCellAt:2:0];
    if (TTS_INTONATION_CREAK & mask)
	[intonationMatrix selectCellAt:3:0];
    if (TTS_INTONATION_RANDOMIZE & mask)
	[intonationMatrix selectCellAt:4:0];

    [voiceTypeMatrix selectCellAt:[mySpeaker voiceType]:0];

    /*  DISPLAY CHANGES TO SUBVIEWS OF WINDOW  */
    [preferencesWindow reenableDisplay];
    [preferencesWindow displayIfNeeded];

    return self;
}



- vtlOffsetSliderMoved:sender
{
    /*  GET VALUE FROM SLIDER  */
    float value = [sender floatValue];

    /*  SET THE FIELD TO THIS VALUE  */
    [vtlOffsetField setFloatValue:value];

    /*  IF MOUSE UP, SET THE VOICE TO THIS VALUE  */
    if ([NXApp currentEvent]->type == NX_LMOUSEUP)
	[mySpeaker setVocalTractLengthOffset:value];

    return self;
}



- vtlOffsetFieldEntered:sender
{
    /*  GET VALUE FROM FIELD  */
    float value = [sender floatValue];

    /*  MAKE SURE VALUE IN RANGE  */
    if (value < TTS_VTL_OFFSET_MIN) {
	value = TTS_VTL_OFFSET_MIN;
	[sender setFloatValue:value];
    }
    else if (value > TTS_VTL_OFFSET_MAX) {
	value = TTS_VTL_OFFSET_MAX;
	[sender setFloatValue:value];
    }

    /*  SET SLIDER TO THIS VALUE  */
    [vtlOffsetSlider setFloatValue:value];

    /*  SET VOICE TO VALUE ENTERED  */
    [mySpeaker setVocalTractLengthOffset:value];

    return self;
}



- breathinessSliderMoved:sender
{
    /*  GET VALUE FROM SLIDER  */
    float value = [sender floatValue];

    /*  SET THE FIELD TO THIS VALUE  */
    [breathinessField setFloatValue:value];

    /*  IF MOUSE UP, SET THE VOICE TO THIS VALUE  */
    if ([NXApp currentEvent]->type == NX_LMOUSEUP)
	[mySpeaker setBreathiness:value];

    return self;
}



- breathinessFieldEntered:sender
{
    /*  GET VALUE FROM FIELD  */
    float value = [sender floatValue];

    /*  MAKE SURE VALUE IN RANGE  */
    if (value < TTS_BREATHINESS_MIN) {
	value = TTS_BREATHINESS_MIN;
	[sender setFloatValue:value];
    }
    else if (value > TTS_BREATHINESS_MAX) {
	value = TTS_BREATHINESS_MAX;
	[sender setFloatValue:value];
    }

    /*  SET SLIDER TO THIS VALUE  */
    [breathinessSlider setFloatValue:value];

    /*  SET VOICE TO VALUE ENTERED  */
    [mySpeaker setBreathiness:value];

    return self;
}



- speedSliderMoved:sender
{
    /*  GET VALUE FROM SLIDER  */
    float value = [sender floatValue];

    /*  SET THE FIELD TO THIS VALUE  */
    [speedField setFloatValue:value];

    /*  IF MOUSE UP, SET THE VOICE TO THIS VALUE  */
    if ([NXApp currentEvent]->type == NX_LMOUSEUP)
	[mySpeaker setSpeed:value];

    return self;
}



- speedFieldEntered:sender
{
    /*  GET VALUE FROM FIELD  */
    float value = [sender floatValue];

    /*  MAKE SURE VALUE IN RANGE  */
    if (value < TTS_SPEED_MIN) {
	value = TTS_SPEED_MIN;
	[sender setFloatValue:value];
    }
    else if (value > TTS_SPEED_MAX) {
	value = TTS_SPEED_MAX;
	[sender setFloatValue:value];
    }

    /*  SET SLIDER TO THIS VALUE  */
    [speedSlider setFloatValue:value];

    /*  SET VOICE TO VALUE ENTERED  */
    [mySpeaker setSpeed:value];

    return self;
}



- volumeSliderMoved:sender
{
    /*  GET VALUE FROM SLIDER  */
    float value = [sender floatValue];

    /*  SET THE FIELD TO THIS VALUE  */
    [volumeField setFloatValue:value];

    /*  IF MOUSE UP, SET THE VOICE TO THIS VALUE  */
    if ([NXApp currentEvent]->type == NX_LMOUSEUP)
	[mySpeaker setVolume:value];

    return self;
}



- volumeFieldEntered:sender
{
    /*  GET VALUE FROM FIELD  */
    float value = [sender floatValue];

    /*  MAKE SURE VALUE IN RANGE  */
    if (value < TTS_VOLUME_MIN) {
	value = TTS_VOLUME_MIN;
	[sender setFloatValue:value];
    }
    else if (value > TTS_VOLUME_MAX) {
	value = TTS_VOLUME_MAX;
	[sender setFloatValue:value];
    }

    /*  SET SLIDER TO THIS VALUE  */
    [volumeSlider setFloatValue:value];

    /*  SET VOICE TO VALUE ENTERED  */
    [mySpeaker setVolume:value];

    return self;
}


- channelsSelected:sender
{
    /*  GET THE TAG VALUE OF THE BUTTON  */
    int value = [[sender selectedCell] tag];

    /*  ENABLE OR DISABLE STEREO BALANCE CONTROLS  */
    if (value == 1) {
	[balanceField setEnabled:NO];
	[balanceSlider setEnabled:NO];
	[balanceLabel setTextGray:NX_DKGRAY];
    }
    else {
	[balanceField setEnabled:YES];
	[balanceSlider setEnabled:YES];
	[balanceLabel setTextGray:NX_BLACK];
    }

    /*  SET VOICE TO VALUE ENTERED  */
    [mySpeaker setNumberChannels:value];

    return self;
}



- displayChannels:(int)value
{
    /*  SET THE POPUP BUTTON TO THE CORRECT POSITION  */
    [[[channelsPopUp target] itemList] selectCellWithTag:value];
    [channelsPopUp setTitle:[[[[channelsPopUp target] itemList] selectedCell] title]];

    /*  ENABLE OR DISABLE ASSOCIATED BALANCE CONTROLS  */
    if (value == 1) {
	[balanceField setEnabled:NO];
	[balanceSlider setEnabled:NO];
	[balanceLabel setTextGray:NX_DKGRAY];
    }
    else {
	[balanceField setEnabled:YES];
	[balanceSlider setEnabled:YES];
	[balanceLabel setTextGray:NX_BLACK];
    }

    return self;
}



- balanceSliderMoved:sender
{
    /*  GET VALUE FROM SLIDER  */
    float value = [sender floatValue];

    /*  SET THE FIELD TO THIS VALUE  */
    [balanceField setFloatValue:value];

    /*  IF MOUSE UP, SET THE VOICE TO THIS VALUE  */
    if ([NXApp currentEvent]->type == NX_LMOUSEUP)
	[mySpeaker setBalance:value];

    return self;
}



- balanceFieldEntered:sender
{
    /*  GET VALUE FROM FIELD  */
    float value = [sender floatValue];

    /*  MAKE SURE VALUE IN RANGE  */
    if (value < TTS_BALANCE_MIN) {
	value = TTS_BALANCE_MIN;
	[sender setFloatValue:value];
    }
    else if (value > TTS_BALANCE_MAX) {
	value = TTS_BALANCE_MAX;
	[sender setFloatValue:value];
    }

    /*  SET SLIDER TO THIS VALUE  */
    [balanceSlider setFloatValue:value];

    /*  SET VOICE TO VALUE ENTERED  */
    [mySpeaker setBalance:value];

    return self;
}



- pitchOffsetSliderMoved:sender
{
    /*  GET VALUE FROM SLIDER  */
    float value = [sender floatValue];

    /*  SET THE FIELD TO THIS VALUE  */
    [pitchOffsetField setFloatValue:value];

    /*  IF MOUSE UP, SET THE VOICE TO THIS VALUE  */
    if ([NXApp currentEvent]->type == NX_LMOUSEUP)
	[mySpeaker setPitchOffset:value];

    return self;
}



- pitchOffsetFieldEntered:sender
{
    /*  GET VALUE FROM FIELD  */
    float value = [sender floatValue];

    /*  MAKE SURE VALUE IN RANGE  */
    if (value < TTS_PITCH_OFFSET_MIN) {
	value = TTS_PITCH_OFFSET_MIN;
	[sender setFloatValue:value];
    }
    else if (value > TTS_PITCH_OFFSET_MAX) {
	value = TTS_PITCH_OFFSET_MAX;
	[sender setFloatValue:value];
    }

    /*  SET SLIDER TO THIS VALUE  */
    [pitchOffsetSlider setFloatValue:value];

    /*  SET VOICE TO VALUE ENTERED  */
    [mySpeaker setPitchOffset:value];

    return self;
}



- intonationSelected:sender
{
    int intonationMask;

    /*  CREATE BIT MASK USING SELECTED CELLS OF MATRIX  */
    intonationMask = ([[sender cellAt:0:0] state] * TTS_INTONATION_MICRO)  |
	             ([[sender cellAt:1:0] state] * TTS_INTONATION_MACRO)  |
	             ([[sender cellAt:2:0] state] * TTS_INTONATION_DECLIN) |
		     ([[sender cellAt:3:0] state] * TTS_INTONATION_CREAK)  |
		     ([[sender cellAt:4:0] state] * TTS_INTONATION_RANDOMIZE);

    /*  SET THE VOICE WITH THIS VALUE  */
    [mySpeaker setIntonation:intonationMask];

    return self;
}



- voiceTypeSelected:sender
{
    /*  SET THE VOICE WITH THE SELECTED VOICE TYPE  */
    [mySpeaker setVoiceType:[sender selectedRow]];

    return self;
}



- setUserDefaults:sender
{
    char buffer[24];
    int intonationMask;


    /*  CREATE BIT MASK USING SELECTED CELLS OF MATRIX  */
    intonationMask = ([[intonationMatrix cellAt:0:0] state] * TTS_INTONATION_MICRO)  |
	             ([[intonationMatrix cellAt:1:0] state] * TTS_INTONATION_MACRO)  |
	             ([[intonationMatrix cellAt:2:0] state] * TTS_INTONATION_DECLIN) |
		     ([[intonationMatrix cellAt:3:0] state] * TTS_INTONATION_CREAK)  |
		     ([[intonationMatrix cellAt:4:0] state] * TTS_INTONATION_RANDOMIZE);
    sprintf(buffer, "0x%x", intonationMask);
    NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_INTONATION, buffer);

    /*  SET OTHER DEFAULTS USING VALUES IN FIELDS  */
    sprintf(buffer, "%.2f", [vtlOffsetField floatValue]);
    NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_VTL_OFFSET, buffer);

    sprintf(buffer, "%.2f", [breathinessField floatValue]);
    NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_BREATHINESS, buffer);

    sprintf(buffer, "%.2f", [speedField floatValue]);
    NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_SPEED, buffer);

    sprintf(buffer, "%.2f", [pitchOffsetField floatValue]);
    NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_PITCH_OFFSET, buffer);

    sprintf(buffer, "%.2f", [volumeField floatValue]);
    NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_VOLUME, buffer);

    /*  SET NUMBER CHANNELS  */
    sprintf(buffer, "%-d", [[[[channelsPopUp target] itemList] selectedCell] tag]);
    NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_CHANNELS, buffer);

    sprintf(buffer, "%.2f", [balanceField floatValue]);
    NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_BALANCE, buffer);

    sprintf(buffer, "%-d", [voiceTypeMatrix selectedRow]);
    NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_VOICE_TYPE, buffer);

    return self;
}



- reset:sender
{
    /*  TURN OFF DISPLAY WHILE INITIALIZING SUBVIEWS  */
    [preferencesWindow disableDisplay];

    /*  SET THE CONTROL PANEL AND TTS OBJECT TO NEUTRAL (NOT USER) DEFAULTS  */
    [vtlOffsetSlider setFloatValue:TTS_VTL_OFFSET_DEF];
    [vtlOffsetField setFloatValue:TTS_VTL_OFFSET_DEF];
    [mySpeaker setVocalTractLengthOffset:TTS_VTL_OFFSET_DEF];

    [breathinessSlider setFloatValue:TTS_BREATHINESS_DEF];
    [breathinessField setFloatValue:TTS_BREATHINESS_DEF];
    [mySpeaker setBreathiness:TTS_BREATHINESS_DEF];

    [volumeSlider setFloatValue:TTS_VOLUME_DEF];
    [volumeField setFloatValue:TTS_VOLUME_DEF];
    [mySpeaker setVolume:TTS_VOLUME_DEF];

    [self displayChannels:TTS_CHANNELS_DEF];
    [mySpeaker setNumberChannels:TTS_CHANNELS_DEF];

    [balanceSlider setFloatValue:TTS_BALANCE_DEF];
    [balanceField setFloatValue:TTS_BALANCE_DEF];
    [mySpeaker setBalance:TTS_BALANCE_DEF];

    [speedSlider setFloatValue:TTS_SPEED_DEF];
    [speedField setFloatValue:TTS_SPEED_DEF];
    [mySpeaker setSpeed:TTS_SPEED_DEF];

    [pitchOffsetSlider setFloatValue:TTS_PITCH_OFFSET_DEF];
    [pitchOffsetField setFloatValue:TTS_PITCH_OFFSET_DEF];
    [mySpeaker setPitchOffset:TTS_PITCH_OFFSET_DEF];

    if (TTS_INTONATION_MICRO & TTS_INTONATION_DEF)
	[intonationMatrix selectCellAt:0:0];
    if (TTS_INTONATION_MACRO & TTS_INTONATION_DEF)
	[intonationMatrix selectCellAt:1:0];
    if (TTS_INTONATION_DECLIN & TTS_INTONATION_DEF)
	[intonationMatrix selectCellAt:2:0];
    if (TTS_INTONATION_CREAK & TTS_INTONATION_DEF)
	[intonationMatrix selectCellAt:3:0];
    if (TTS_INTONATION_RANDOMIZE & TTS_INTONATION_DEF)
	[intonationMatrix selectCellAt:4:0];
    [mySpeaker setIntonation:TTS_INTONATION_DEF];

    [voiceTypeMatrix selectCellAt:TTS_VOICE_TYPE_DEF:0];
    [mySpeaker setVoiceType:TTS_VOICE_TYPE_DEF];

    /*  DISPLAY CHANGES TO SUBVIEWS OF WINDOW  */
    [preferencesWindow reenableDisplay];
    [preferencesWindow displayIfNeeded];

    return self;
}



- revertToSaved:sender
{
    const char *value;
    float floatValue;
    int intValue;


    /*  TURN OFF DISPLAY WHILE INITIALIZING SUBVIEWS  */
    [preferencesWindow disableDisplay];

    /*  SET THE CONTROL PANEL AND TTS OBJECT TO STORED USER DEFAULTS  */
    if ((value = NXReadDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_VTL_OFFSET)) != NULL) {
	floatValue = atof(value);
	[vtlOffsetSlider setFloatValue:floatValue];
	[vtlOffsetField setFloatValue:floatValue];
	[mySpeaker setVocalTractLengthOffset:floatValue];
    }

    if ((value = NXReadDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_BREATHINESS)) != NULL) {
	floatValue = atof(value);
	[breathinessSlider setFloatValue:floatValue];
	[breathinessField setFloatValue:floatValue];
	[mySpeaker setBreathiness:floatValue];
    }

    if ((value = NXReadDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_VOLUME)) != NULL) {
	floatValue = atof(value);
	[volumeSlider setFloatValue:floatValue];
	[volumeField setFloatValue:floatValue];
	[mySpeaker setVolume:floatValue];
    }

    if ((value = NXReadDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_CHANNELS)) != NULL) {
	intValue = strtol(value,NULL,0);
	[self displayChannels:intValue];
	[mySpeaker setNumberChannels:intValue];
    }

    if ((value = NXReadDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_BALANCE)) != NULL) {
	floatValue = atof(value);
	[balanceSlider setFloatValue:floatValue];
	[balanceField setFloatValue:floatValue];
	[mySpeaker setBalance:floatValue];
    }

    if ((value = NXReadDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_SPEED)) != NULL) {
	floatValue = atof(value);
	[speedSlider setFloatValue:floatValue];
	[speedField setFloatValue:floatValue];
	[mySpeaker setSpeed:floatValue];
    }

    if ((value = NXReadDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_PITCH_OFFSET)) != NULL) {
	floatValue = atof(value);
	[pitchOffsetSlider setFloatValue:floatValue];
	[pitchOffsetField setFloatValue:floatValue];
	[mySpeaker setPitchOffset:floatValue];
    }

    if ((value = NXReadDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_INTONATION)) != NULL) {
	intValue = strtol(value,NULL,0);
	if (TTS_INTONATION_MICRO & intValue)
	    [intonationMatrix selectCellAt:0:0];
	else
	    [[intonationMatrix selectCellAt:0:0] setIntValue:0];

	if (TTS_INTONATION_MACRO & intValue)
	    [intonationMatrix selectCellAt:1:0];
	else
	    [[intonationMatrix selectCellAt:1:0] setIntValue:0];

	if (TTS_INTONATION_DECLIN & intValue)
	    [intonationMatrix selectCellAt:2:0];
	else
	    [[intonationMatrix selectCellAt:2:0] setIntValue:0];

	if (TTS_INTONATION_CREAK & intValue)
	    [intonationMatrix selectCellAt:3:0];
	else
	    [[intonationMatrix selectCellAt:3:0] setIntValue:0];

	if (TTS_INTONATION_RANDOMIZE & intValue)
	    [intonationMatrix selectCellAt:4:0];
	else
	    [[intonationMatrix selectCellAt:4:0] setIntValue:0];

	[mySpeaker setIntonation:intValue];
    }

    if ((value = NXReadDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_VOICE_TYPE)) != NULL) {
	intValue = strtol(value,NULL,0);
	[voiceTypeMatrix selectCellAt:intValue:0];
	[mySpeaker setVoiceType:intValue];
    }

    /*  DISPLAY CHANGES TO SUBVIEWS OF WINDOW  */
    [preferencesWindow reenableDisplay];
    [preferencesWindow displayIfNeeded];

    return self;
}

@end

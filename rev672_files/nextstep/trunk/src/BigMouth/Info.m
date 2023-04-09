#import "Info.h"
#import <TextToSpeech/TextToSpeech.h>


@implementation Info

- noveltyInfo:sender
{
    id tempSpeaker;

    /*  ALLOCATE A TEXT-TO-SPEECH OBJECT  */
    if ((tempSpeaker = [[TextToSpeech alloc] init]) == nil)
	return self;

    /*  SET THE VOICE DEEP AND SLOW  */
    [tempSpeaker setVoiceType:TTS_VOICE_TYPE_MALE];
    [tempSpeaker setPitchOffset:-9.0];
    [tempSpeaker setVocalTractLengthOffset:1.0];
    [tempSpeaker setSpeed:0.65];

    /*  SPEAK INFORMATION  */
    [tempSpeaker speakText:"BigMouth!"];

    /*  FREE THE TTS OBJECT  */
    [tempSpeaker free];

    return self;
}

@end

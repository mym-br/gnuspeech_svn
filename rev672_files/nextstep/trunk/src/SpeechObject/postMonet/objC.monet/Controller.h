/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:52 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/SpeechObject/postMonet/objC.monet/Controller.h,v $
$State: Exp $

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import <objc/Object.h>
#import "TextToSpeech.h"



@interface Controller:Object
{
    id	inputField1;
    id  inputField2;
    id	outputField;
    TextToSpeech *mySpeaker;
}

- appDidInit:sender;
- appWillTerminate:sender;


- setOutputSampleRate:sender;
- outputSampleRate:sender;

- setNumberChannels:sender;
- numberChannels:sender;

- setBalance:sender;
- balance:sender;

- setSpeed:sender;
- speed:sender;

- setIntonation:sender;
- intonation:sender;

- setVoiceType:sender;
- voiceType:sender;

- setPitchOffset:sender;
- pitchOffset:sender;

- setVocalTractLengthOffset:sender;
- vocalTractLengthOffset:sender;

- setBreathiness:sender;
- breathiness:sender;

- setVolume:sender;
- volume:sender;


- setDictionaryOrder:sender;
- dictionaryOrder:sender;

- setAppDictPath:sender;
- appDictPath:sender;

- setUserDictPath:sender;
- userDictPath:sender;


- speakText:sender;
- speakTextToFile:sender;
- speakStream:sender;
- speakStreamToFile:sender;
- setEscapeCharacter:sender;
- escapeCharacter:sender;
- setBlock:sender;
- block:sender;
- setSoftwareSynthesizer:sender;
- softwareSynthesizer:sender;


- pauseImmediately:sender;
- pauseAfterCurrentUtterance:sender;
- continue:sender;
- eraseAllSound:sender;
- eraseCurrentUtterance:sender;


- serverVersion:sender;
- dictionaryVersion:sender;


/*  HIDDEN METHODS  */
- setPriority:sender;
- getPriority:sender;

- setQuantum:sender;
- getQuantum:sender;

- setPolicy:sender;
- getPolicy:sender;

- setSilencePrefill:sender;
- getSilencePrefill:sender;

- serverPID:sender;
- inactiveServerKill:sender;
- inactiveKillQuery:sender;
- requestServerRestart:sender;
- registeredHostID:sender;
- demoMode:sender;
- expiryDate:sender;

- pronunciation:sender;
- linePronunciation:sender;

- getRhythmInfo:sender;

@end

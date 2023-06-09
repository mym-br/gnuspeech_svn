
/* Generated by Interface Builder */

#import <objc/Object.h>

@interface Controller:Object
{
    id	inputField;
    id	outputField;
    id  mySpeaker;
}

- appDidInit:sender;
- appWillTerminate:sender;

- setSpeedButton:sender;
- speedButton:sender;

- setElasticityButton:sender;
- elasticityButton:sender;

- setIntonationButton:sender;
- intonationButton:sender;

- setVoiceTypeButton:sender;
- voiceTypeButton:sender;

- setPitchOffsetButton:sender;
- pitchOffsetButton:sender;

- setVolumeButton:sender;
- volumeButton:sender;

- setBalanceButton:sender;
- balanceButton:sender;


- setDictionaryOrderButton:sender;
- dictionaryOrderButton:sender;

- setAppDictPathButton:sender;
- appDictPathButton:sender;

- setUserDictPathButton:sender;
- userDictPathButton:sender;


- speakTextButton:sender;
- speakStreamButton:sender;
- setEscapeCharacterButton:sender;
- escapeCharacterButton:sender;
- setBlockButton:sender;
- blockButton:sender;


- pauseImmediatelyButton:sender;
- pauseAfterCurrentWordButton:sender;
- pauseAfterCurrentUtteranceButton:sender;
- continueButton:sender;
- eraseAllSoundButton:sender;
- eraseAllWordsButton:sender;
- eraseCurrentUtteranceButton:sender;


- serverVersionButton:sender;
- dictionaryVersionButton:sender;


- linePronunciationButton:sender;
- pronunciationButton:sender;

@end

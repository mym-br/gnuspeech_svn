#import <objc/Object.h>
#import <sys/param.h>
#import <mach/mach.h>
#import <streams/streams.h>
#import "TTS_types.h"


@interface TextToSpeech:Object
{
	int    SpeechIdentifier;
	port_t outPort;
	port_t localPort;
	task_t serverTaskPort;
        float  speed;
	int    elasticity;
        int    intonation;
        int    voiceType;
        float  pitchOffset;
        float  volume;
        float  balance;
        short  dictionaryOrder[4];
        char   appDictPath[MAXPATHLEN];
        char   userDictPath[MAXPATHLEN];
        char   escapeCharacter;
	int    block;
	char   version[256];
	char   dictVersion[256];
	id     syncMessagesDestination;
        SEL    syncMessagesSelector;
        int    syncMessages;
	int    syncRate;
	id     realTimeMessagesDestination;
	SEL    realTimeMessagesSelector;
	int    realTimeMessages;
	char   *tts_p;
	char   *tts_lp;
	char   *streamMem;
	char   *localBuffer;
}

/*  INTERNAL METHODS  */
- (int)restartServer;

/*  CREATING AND FREEING THE OBJECT  */
- init;
- free;

/*  VOICE QUALITY METHODS  */
- (int)setSpeed:(float)speedValue;
- (float)speed;
- (int)setElasticity:(int)elasticityType;
- (int)elasticity;
- (int)setIntonation:(int)intonationMask;
- (int)intonation;
- (int)setVoiceType:(int)voiceType;
- (int)voiceType;
- (int)setPitchOffset:(float)offsetValue;
- (float)pitchOffset;
- (int)setVolume:(float)volumeLevel;
- (float)volume;
- (int)setBalance:(float)balanceValue;
- (float)balance;

/*  DICTIONARY CONTROL METHODS  */
- (int)setDictionaryOrder:(const short *)order;
- (const short *)dictionaryOrder;
- (int)setAppDictPath:(const char *)path;
- (const char *)appDictPath;
- (int)setUserDictPath:(const char *)path;
- (const char *)userDictPath;

/*  TEXT INPUT METHODS  */
- (int)speakText:(const char *)text;
- (int)speakText:(const char *)text toFile:(const char *)path;
- (int)speakStream:(NXStream *)stream;
- (int)speakStream:(NXStream *)stream toFile:(const char *)path;
- (int)setEscapeCharacter:(char)character;
- (char)escapeCharacter;
- (int)setBlock:(BOOL)flag;
- (BOOL)block;

/*  REAL-TIME METHODS  */
- (int)pauseImmediately;
- (int)pauseAfterCurrentWord;
- (int)pauseAfterCurrentUtterance;
- (int)continue;
- (int)eraseAllSound;
- (int)eraseAllWords;
- (int)eraseCurrentUtterance;

/*  VERSION METHODS  */
- (const char *)serverVersion;
- (const char *)dictionaryVersion;

/*  SYNC MESSAGING METHODS  */
- sendSyncMessagesTo:destinationObject:(SEL)aSelector;
- syncMessagesDestination;
- (SEL)syncMessagesSelector;
- (int)setSyncRate:(int)rate;
- (int)syncRate;
- setSyncMessages:(BOOL)flag;
- (BOOL)syncMessages;

/*  REAL-TIME MESSAGING METHODS  */
- sendRealTimeMessagesTo:destinationObject:(SEL)aSelector;
- realTimeMessagesDestination;
- (SEL)realTimeMessagesSelector;
- setRealTimeMessages:(BOOL)flag;
- (BOOL)realTimeMessages;

/*  ARCHIVING METHODS  */
- read:(NXTypedStream *)stream;
- write:(NXTypedStream *)stream;
- awake;

/*  OVERRIDDEN METHODS  */
- notImplemented:(SEL)aSelector;

@end

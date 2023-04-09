/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:53 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/SpeechObject/postMonet/objC.monet/TextToSpeech.h,v $
$State: Exp $

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "TTS_types.h"
#import <objc/Object.h>
#import <sys/param.h>
#import <mach/mach_types.h>
#import <streams/streams.h>



@interface TextToSpeech:Object
{
    @private
	int    SpeechIdentifier;
        float  serverVersionNumber;
	port_t outPort;
	port_t localPort;
	task_t serverTaskPort;

        float  sampleRate;
        int    channels;
        float  balance;
        float  speed;
        int    intonation;
        int    voiceType;
        float  pitchOffset;
        float  vtlOffset;
        float  breathiness;
        float  volume;

        short  dictionaryOrder[4];
        char   appDictPath[MAXPATHLEN];
        char   userDictPath[MAXPATHLEN];

        char   escapeCharacter;
	int    block;
        int    softwareSynthesizer;

	char   version[256];
	char   dictVersion[256];

	char   *tts_p;
	char   *tts_lp;
	char   *streamMem;
	char   *localBuffer;
}

/*  INTERNAL METHODS  */
- (tts_error_t)restartServer;

/*  CREATING AND FREEING THE OBJECT  */
- init;
- free;

/*  VOICE QUALITY METHODS  */
- (tts_error_t)setOutputSampleRate:(float)rateValue;
- (float)outputSampleRate;
- (tts_error_t)setNumberChannels:(int)channelsValue;
- (int)numberChannels;
- (tts_error_t)setBalance:(float)balanceValue;
- (float)balance;
- (tts_error_t)setSpeed:(float)speedValue;
- (float)speed;
- (tts_error_t)setIntonation:(int)intonationMask;
- (int)intonation;
- (tts_error_t)setVoiceType:(int)type;
- (int)voiceType;
- (tts_error_t)setPitchOffset:(float)offsetValue;
- (float)pitchOffset;
- (tts_error_t)setVocalTractLengthOffset:(float)offsetValue;
- (float)vocalTractLengthOffset;
- (tts_error_t)setBreathiness:(float)breathinessValue;
- (float)breathiness;
- (tts_error_t)setVolume:(float)volumeLevel;
- (float)volume;

/*  DICTIONARY CONTROL METHODS  */
- (tts_error_t)setDictionaryOrder:(const short *)order;
- (const short *)dictionaryOrder;
- (tts_error_t)setAppDictPath:(const char *)path;
- (const char *)appDictPath;
- (tts_error_t)setUserDictPath:(const char *)path;
- (const char *)userDictPath;

/*  TEXT INPUT METHODS  */
- (tts_error_t)speakText:(const char *)text;
- (tts_error_t)speakText:(const char *)text toFile:(const char *)path;
- (tts_error_t)speakStream:(NXStream *)stream;
- (tts_error_t)speakStream:(NXStream *)stream toFile:(const char *)path;
- (tts_error_t)setEscapeCharacter:(char)character;
- (char)escapeCharacter;
- (tts_error_t)setBlock:(BOOL)flag;
- (BOOL)block;
- (tts_error_t)setSoftwareSynthesizer:(BOOL)flag;
- (BOOL)softwareSynthesizer;

/*  REAL-TIME METHODS  */
- (tts_error_t)pauseImmediately;
- (tts_error_t)pauseAfterCurrentUtterance;
- (tts_error_t)continue;
- (tts_error_t)eraseAllSound;
- (tts_error_t)eraseCurrentUtterance;

/*  VERSION METHODS  */
- (const char *)serverVersion;
- (const char *)dictionaryVersion;

/*  ERROR REPORTING METHODS  */
- (const char *)errorMessage:(tts_error_t)errorNumber;

/*  ARCHIVING METHODS  */
- read:(NXTypedStream *)stream;
- write:(NXTypedStream *)stream;
- awake;

@end

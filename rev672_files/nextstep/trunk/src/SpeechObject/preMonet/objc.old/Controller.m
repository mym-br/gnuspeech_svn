/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:53 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/SpeechObject/preMonet/objc.old/Controller.m,v $
$State: Exp $

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "Controller.h"
#import "TextToSpeech.h"
#import "TextToSpeechPron.h"
#import "TextToSpeechRhythm.h"
#import "TextToSpeechDemo.h"
#import "TextToSpeechPriority.h"
#import <appkit/appkit.h>
#import <streams/streams.h>



@implementation Controller

- appDidInit:sender
{
    /*  TRY TO INSTANTIATE TEXT-TO-SPEECH OBJECT  */
    mySpeaker = [[TextToSpeech alloc] init];
    if (mySpeaker == nil) {
	NXRunAlertPanel ("Cannot connect",
			 "Too many clients, or TTS_server cannot be started.",
			 "OK", NULL, NULL);
	[NXApp terminate:self];
    }
    return self;
}

- appWillTerminate:sender
{
    /*  FREE TEXT-TO-SPEECH OBJECT;  FREES UP A CLIENT SLOT  */
    [mySpeaker free];
    return self;
}



- setOutputSampleRate:sender
{
    [outputField setIntValue:[mySpeaker setOutputSampleRate:[inputField1 floatValue]]];
    return self;
}

- outputSampleRate:sender
{
    [outputField setFloatValue:[mySpeaker outputSampleRate]];
    return self;
}



- setNumberChannels:sender
{
    [outputField setIntValue:[mySpeaker setNumberChannels:[inputField1 intValue]]];
    return self;
}

- numberChannels:sender
{
    [outputField setIntValue:[mySpeaker numberChannels]];
    return self;
}



- setBalance:sender
{
    [outputField setIntValue:[mySpeaker setBalance:[inputField1 floatValue]]];
    return self;
}

- balance:sender
{
    [outputField setFloatValue:[mySpeaker balance]];
    return self;
}



- setSpeed:sender
{
    [outputField setIntValue:[mySpeaker setSpeed:[inputField1 floatValue]]];
    return self;
}

- speed:sender
{
    [outputField setFloatValue:[mySpeaker speed]];
    return self;
}



- setIntonation:sender
{
    [outputField setIntValue:[mySpeaker setIntonation:[inputField1 intValue]]];
    return self;
}

- intonation:sender
{
    [outputField setIntValue:[mySpeaker intonation]];
    return self;
}



- setVoiceType:sender
{
    [outputField setIntValue:[mySpeaker setVoiceType:[inputField1 intValue]]];
    return self;
}

- voiceType:sender
{
    [outputField setIntValue:[mySpeaker voiceType]];
    return self;
}



- setPitchOffset:sender
{
    [outputField setIntValue:[mySpeaker setPitchOffset:[inputField1 floatValue]]];
    return self;
}

- pitchOffset:sender
{
    [outputField setFloatValue:[mySpeaker pitchOffset]];
    return self;
}



- setVocalTractLengthOffset:sender
{
    [outputField setIntValue:[mySpeaker	setVocalTractLengthOffset:
					[inputField1 floatValue]]];
    return self;
}

- vocalTractLengthOffset:sender
{
    [outputField setFloatValue:[mySpeaker vocalTractLengthOffset]];
    return self;
}



- setBreathiness:sender
{
    [outputField setIntValue:[mySpeaker setBreathiness:[inputField1 floatValue]]];
    return self;
}

- breathiness:sender
{
    [outputField setFloatValue:[mySpeaker breathiness]];
    return self;
}



- setVolume:sender
{
    [outputField setIntValue:[mySpeaker setVolume:[inputField1 floatValue]]];
    return self;
}

- volume:sender
{
    [outputField setFloatValue:[mySpeaker volume]];
    return self;
}



- setDictionaryOrder:sender
{
    short order[4];
    char *c_ptr;
    int i;

    /*  GET THE INPUT STRING  */
    c_ptr = (char *)[inputField1 stringValue];

    /*  GET NEXT FOUR NUMBERS  */
    for (i = 0; i < 4; i++)
	order[i] = (short)strtol(c_ptr, &c_ptr, 0);

    /*  SEND ORDER TO TTS OBJECT, DISPLAY RETURN VALUE  */
    [outputField setIntValue:[mySpeaker setDictionaryOrder:order]];

    return self;
}

- dictionaryOrder:sender
{
    const short int *order;
    char buffer[64];

    /*  GET ORDER FROM SERVER  */
    order = [mySpeaker dictionaryOrder];

    /*  FORMAT AND DISPLAY  */
    sprintf(buffer,"%-d  %-d  %-d  %-d",order[0],order[1],order[2],order[3]);
    [outputField setStringValue:buffer];

    return self;
}



- setAppDictPath:sender
{
    [outputField setIntValue:[mySpeaker setAppDictPath:[inputField1 stringValue]]];
    return self;
}

- appDictPath:sender
{
    [outputField setStringValue:[mySpeaker appDictPath]];
    return self;
}



- setUserDictPath:sender
{
    [outputField setIntValue:[mySpeaker setUserDictPath:[inputField1 stringValue]]];
    return self;
}

- userDictPath:sender
{
    [outputField setStringValue:[mySpeaker userDictPath]];
    return self;
}



- speakText:sender
{
    [outputField setIntValue:[mySpeaker speakText:[inputField1 stringValue]]];
    return self;
}

- speakTextToFile:sender
{
    [outputField setIntValue:[mySpeaker speakText:[inputField1 stringValue]
					toFile:[inputField2 stringValue]]];
    return self;
}

- speakStream:sender
{
    NXStream *stream;

    /*  MEMORY MAP SPECIFIED INPUT FILE TO MEMORY STREAM  */
    if ((stream = NXMapFile([inputField1 stringValue], NX_READONLY)) == NULL) {
	[outputField setStringValue:"Cannot find or read specified file."];
	return self;
    }

    /*  SPEAK MEMORY STREAM  */
    [outputField setIntValue:[mySpeaker speakStream:stream]];

    /*  CLOSE THE MEMORY STREAM, INCLUDING ALL MEMORY IT USES  */
    NXCloseMemory(stream, NX_FREEBUFFER);

    return self;
}

- speakStreamToFile:sender
{
    NXStream *stream;

    /*  MEMORY MAP SPECIFIED INPUT FILE TO MEMORY STREAM  */
    if ((stream = NXMapFile([inputField1 stringValue], NX_READONLY)) == NULL) {
	[outputField setStringValue:"Cannot find or read specified file."];
	return self;
    }

    /*  SPEAK MEMORY STREAM  */
    [outputField setIntValue:[mySpeaker speakStream:stream
					toFile:[inputField2 stringValue]]];
		 

    /*  CLOSE THE MEMORY STREAM, INCLUDING ALL MEMORY IT USES  */
    NXCloseMemory(stream, NX_FREEBUFFER);

    return self;
}

- setEscapeCharacter:sender
{
    [outputField setIntValue:[mySpeaker setEscapeCharacter:*[inputField1 stringValue]]];
    return self;
}

- escapeCharacter:sender
{
    char c, buffer[64];

    /*  GET THE ESCAPE CHARACTER  */
    c = [mySpeaker escapeCharacter];

    /*  FORMAT AND DISPLAY  */
    sprintf(buffer,"%c = 0x%-X",c,(unsigned)c);
    [outputField setStringValue:buffer];

    return self;
}

- setBlock:sender
{
    [outputField setIntValue:[mySpeaker setBlock:[inputField1 intValue]]];
    return self;
}

- block:sender
{
    [outputField setIntValue:[mySpeaker block]];
    return self;
}



- pauseImmediately:sender
{
    [outputField setIntValue:[mySpeaker pauseImmediately]];
    return self;
}

- pauseAfterCurrentUtterance:sender
{
    [outputField setIntValue:[mySpeaker pauseAfterCurrentUtterance]];
    return self;
}

- continue:sender
{
    [outputField setIntValue:[mySpeaker continue]];
    return self;
}

- eraseAllSound:sender
{
    [outputField setIntValue:[mySpeaker eraseAllSound]];
    return self;
}

- eraseCurrentUtterance:sender
{
    [outputField setIntValue:[mySpeaker eraseCurrentUtterance]];
    return self;
}



- serverVersion:sender
{
    [outputField setStringValue:[mySpeaker serverVersion]];
    return self;
}



- dictionaryVersion:sender
{
    [outputField setStringValue:[mySpeaker dictionaryVersion]];
    return self;
}



/*  HIDDEN METHODS  */
- setPriority:sender
{
    [mySpeaker setPriority:[inputField1 intValue]];
    [outputField setStringValue:""];
    return self;
}

- getPriority:sender
{
    [outputField setIntValue:[mySpeaker getPriority]];
    return self;
}



- setQuantum:sender
{
    [mySpeaker setQuantum:[inputField1 intValue]];
    [outputField setStringValue:""];
    return self;
}

- getQuantum:sender
{
    [outputField setIntValue:[mySpeaker getQuantum]];
    return self;
}



- setPolicy:sender
{
    [mySpeaker setPolicy:[inputField1 intValue]];
    [outputField setStringValue:""];
    return self;
}

- getPolicy:sender
{
    [outputField setIntValue:[mySpeaker getPolicy]];
    return self;
}



- setSilencePrefill:sender
{
    [mySpeaker setSilencePrefill:[inputField1 intValue]];
    [outputField setStringValue:""];
    return self;
}

- getSilencePrefill:sender
{
    [outputField setIntValue:[mySpeaker getSilencePrefill]];
    return self;
}



- serverPID:sender
{
    [outputField setIntValue:[mySpeaker serverPID]];
    return self;
}

- inactiveServerKill:sender
{
    [mySpeaker inactiveServerKill:(BOOL)[inputField1 intValue]];
    [outputField setStringValue:""];
    return self;
}

- inactiveKillQuery:sender
{
    [outputField setIntValue:(int)[mySpeaker inactiveKillQuery]];
    return self;
}

- requestServerRestart:sender
{
    [mySpeaker requestServerRestart];
    [outputField setStringValue:""];
    return self;
}



- registeredHostID:sender
{
    [outputField setIntValue:[mySpeaker registeredHostId]];
    return self;
}

- demoMode:sender
{
    [outputField setIntValue:[mySpeaker demoMode]];
    return self;
}

- expiryDate:sender
{
    [outputField setIntValue:[mySpeaker expiryDate]];
    return self;
}



- pronunciation:sender
{
    short int dictionary;
    const char *returnedString;
    char displayString[1024];

    returnedString =
	[mySpeaker pronunciation:[inputField1 stringValue]:&dictionary:0xdeafbabe];
    sprintf(displayString, "%s  (dictionary = %-d)", returnedString, dictionary);
    [outputField setStringValue:displayString];
    
    return self;
}

- linePronunciation:sender
{
    [outputField setStringValue:[mySpeaker linePronunciation:[inputField1 stringValue]
					   :0xdeafbabe]];
    return self;
}



- getRhythmInfo:sender
{
    char *returnedString;

    returnedString = [mySpeaker getRhythmInfo:[inputField1 stringValue]];
    [outputField setStringValue:returnedString];
    free(returnedString);
    
    return self;
}

@end

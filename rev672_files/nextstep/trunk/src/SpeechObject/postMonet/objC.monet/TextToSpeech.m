/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:53 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/SpeechObject/postMonet/objC.monet/TextToSpeech.m,v $
$State: Exp $


$Log: not supported by cvs2svn $

******************************************************************************/

/*  IMPORTED HEADER FILES  ***************************************************/
#import "TextToSpeech.h"
#import "SpeechMessages.h"
#import "MessageStructs.h"
#import "Messages.h"
#import <stdio.h>
#import <strings.h>
#import <stdlib.h>
#import <ctype.h>
#import <sys/file.h>
#import <sys/types.h>
#import <libc.h>
#import <sys/param.h>
#import <mach/mach.h>
#import <mach/mach_error.h>
#import <servers/netname.h>
#import <defaults/defaults.h>
#import <appkit/Application.h>
#import <appkit/nextstd.h>


/*  LOCAL DEFINES  ***********************************************************/

#define TTS_CLASS_VERSION  1       /*  INCREMENT FOR EACH NEW CLASS VERSION  */

#define TTS_SERVER_1_0     1.0     /*  ADD A DEFINE FOR EACH SERVER UPGRADE  */
#define TTS_SERVER_1_07    1.07
#define TTS_SERVER_1_08    1.08
#define TTS_SERVER_2_0     2.0

#define TTS_SUCCESS        0
#define TTS_FAILURE        (-1)
#define TTS_NO_KILL        0
#define TTS_KILL           1

#define STRINGIFY(s) STR(s)
#define STR(s) #s

#define POLL_REPEAT_COUNT  5000



@implementation TextToSpeech

/*****************************************************************************/
/******************************  CLASS METHODS  ******************************/
/*****************************************************************************/

+ initialize
{
    /*  SET THE CLASS VERSION, FOR THIS CLASS ONLY (NOT ANY SUBCLASS)  */
    if (self == [TextToSpeech class]) {
	[TextToSpeech setVersion:TTS_CLASS_VERSION];
    }

    return self;
}



/*****************************************************************************/
/****************************  INSTANCE METHODS  *****************************/
/*****************************************************************************/

/*  INTERNAL METHODS  ********************************************************/

- (int)initLocalPort
{
    /*  ALLOCATE A NEW PORT  */
    if (port_allocate(task_self(), &localPort) != KERN_SUCCESS) {
	NXLogError("TTS client:  Could not allocate local reply port.");
	return(TTS_FAILURE);
    }

    /*  RETURN SUCCESS  */
    return(TTS_SUCCESS);
}



- (int)connectSpeechPort:(int)killOldServer
{
    int i;

    /*  IF SERVER RUNNING, CONNECT TO SPEECH PORT, ELSE START SERVER, AND
	THEN CONNECT.  IF KILL OPTION, THEN GO INTO LAUNCH WITHOUT CHECKING
	NETNAME SERVER  */
    if (killOldServer || (netname_look_up(name_server_port, "",
					  SPEECH_PORT_NAME,
					  &outPort) != NETNAME_SUCCESS)) {
	char serverPath[MAXPATHLEN];
	const char *systemPathPtr;
	int fd, number_files;

	/*  FORK NEW PROCESS  */
	switch(vfork()) {
	  case -1:   /*  FORK ERROR  */
	    NXLogError("TTS client:  Cannot start TTS_Server (vfork error).");
	    return(TTS_FAILURE);
	    break;
	  case 0:    /*  CHILD  */
	    /*  CLOSE INHERITED FILES IN CHILD PROCESS  */
	    number_files = getdtablesize();
	    for (fd = 3; fd < number_files; fd++)
		close(fd);

	    /*  CLOSE INHERITED PORT IN CHILD PROCESS  */
	    port_deallocate(task_self(), localPort);

	    /*  LOOK IN ROOT'S DEFAULT DATABASE FOR SYSTEM PATH  */
	    NXSetDefaultsUser(TTS_NXDEFAULT_ROOT_USER);
	    if ((systemPathPtr =
		 NXReadDefault(TTS_NXDEFAULT_OWNER,
			       TTS_NXDEFAULT_SYSTEM_PATH)) == NULL) {
		NXLogError("TTS client:  Could not find systemPath in root's defaults database.");
		exit(TTS_FAILURE);
	    }
	    
	    /*  CREATE COMPLETE PATHNAME FOR SERVER  */
	    sprintf(serverPath, "%s/%s", systemPathPtr, TTS_SERVER_NAME);
	    
	    /*  MAKE SURE SERVER IS EXECUTABLE  */
	    if (access(serverPath, X_OK)) {
		NXLogError("TTS client:  TTS_Server not found or not executable.");
		exit(TTS_FAILURE);
	    }

	    /*  OVERLAY PROCESS SPACE WITH SERVER IMAGE  */
	    execl(serverPath, TTS_SERVER_NAME, 0);

	    /*  THESE ARE INVOKED ONLY IF execl FAILS  */
	    NXLogError("TTS client:  Cannot start TTS_Server (execl error).");
	    _exit(TTS_FAILURE);

	    break;
	  default:   /*  PARENT  */
	    /*  GIVE SOME TIME TO ALLOW SERVER TO START UP  */
	    sleep(1);

	    /*  POLL THE SPEECH PORT TO CONNECT  */
	    for (i = 0; i < POLL_REPEAT_COUNT; i++) {
		/*  RETURN ONCE CONNECTED TO THE SPEECH PORT  */
		if (netname_look_up(name_server_port, "", SPEECH_PORT_NAME,
				    &outPort) == NETNAME_SUCCESS)
		    return(TTS_SUCCESS);
	    }

	    /*  IF HERE, NO CONNECTION COULD BE MADE IN A
		REASONABLE AMOUNT OF TIME  */
	    NXLogError("TTS client:  Cannot connect to TTS_Server.");
	    return(TTS_FAILURE);

	    break;
	}
    }

    /*  RETURN SUCCESS  */
    return(TTS_SUCCESS);
}



- (int)initiateConnection
{
    int_msg_t message;

    /*  TELL SERVER WE WISH TO USE ITS SERVICES */
    if (send_simple_message(outPort, localPort, NEW_SPEAKER, 0)
	!= SEND_SUCCESS) {
	NXLogError("TTS client:  TTS_Server hung while in initiateConnection.");
	return(TTS_FAILURE);
    }

    /*  WAIT FOR REPLY  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS) {
	NXLogError("TTS client:  TTS_Server hung while in initiateConnection.");
	return(TTS_FAILURE);
    }

    /*  SET INSTANCE VARIABLE  */
    SpeechIdentifier = message.data;

    /*  IF NO CLIENT SLOTS, RETURN ERROR CODE  */
    if ((SpeechIdentifier < 0) || (SpeechIdentifier >= TTS_CLIENT_SLOTS_MAX)) {
	NXLogError("TTS client:  No available client slots in server.");
	return(TTS_FAILURE);
    }

    /*  RETURN SUCCESS  */
    return(TTS_SUCCESS);
}



- (int)setTaskPorts
{
    int_msg_t message;

    /*  GIVE THE SERVER THE CLIENT'S TASK PORT  */
    if (send_int_message(outPort, localPort, SET_TASK_PORTS,
			 SpeechIdentifier, (int)getpid()) != SEND_SUCCESS) {
	NXLogError("TTS client:  TTS_Server hung while in setTaskPorts.");
	return(TTS_FAILURE);
    }
    
    /*  GET THE SERVER'S TASK PORT  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS) {
	NXLogError("TTS client:  TTS_Server hung while in setTaskPorts.");
	return(TTS_FAILURE);
    }

    /*  SET INSTANCE VARIABLE  */
    serverTaskPort = (task_t)message.data;

    /*  RETURN SUCCESS  */
    return(TTS_SUCCESS);
}



- setServerToInstanceVariables
{
    /*  SET VARIABLES IN SERVER USING INSTANCE VARIABLES  */
    [self setOutputSampleRate:sampleRate];
    [self setNumberChannels:channels];
    [self setBalance:balance];
    [self setSpeed:speed];
    [self setIntonation:intonation];
    [self setVoiceType:voiceType];
    [self setPitchOffset:pitchOffset];
    [self setVocalTractLengthOffset:vtlOffset];
    [self setBreathiness:breathiness];
    [self setVolume:volume];

    [self setDictionaryOrder:dictionaryOrder];
    [self setAppDictPath:appDictPath];
    [self setUserDictPath:userDictPath];

    [self setEscapeCharacter:escapeCharacter];
    [self setBlock:block];
    [self setSoftwareSynthesizer:softwareSynthesizer];

    return self;
}



- ConnectToServer
{
    /*  INITIALIZE A LOCAL REPLY PORT FOR THE SERVER  */
    if ([self initLocalPort] != TTS_SUCCESS)
	return(nil);

    /*  FIND THE SPEECH PORT AND CONNECT TO IT, STARTING UP SERVER IF NECESSARY  */
    if ([self connectSpeechPort:TTS_NO_KILL] != TTS_SUCCESS) {
	port_deallocate(task_self(), localPort);
	return(nil);
    }

    /*  TRY TO GET A CLIENT SLOT ON SERVER  */
    if ([self initiateConnection] != TTS_SUCCESS) {
	port_deallocate(task_self(), localPort);
	return(nil);
    }

    /*  GET TASK PORT OF SERVER (NEEDED FOR SERVER RESTART)  */
    if ([self setTaskPorts] != TTS_SUCCESS) {
	port_deallocate(task_self(), localPort);
	return(nil);
    }

    /*  GET THE CURRENT SERVER VERSION NUMBER  */
    [self serverVersion];
    if (version != NULL)
	serverVersionNumber = atof(version);
    else
	serverVersionNumber = 1.0;

    return self;
}



- (tts_error_t)restartServer
{
    port_t tempPort;

    if (netname_look_up(name_server_port, "",
			SPEECH_PORT_NAME, &tempPort) != NETNAME_SUCCESS) {
	/*  SERVER HAS BEEN KILLED; FORK A NEW SERVER WITHOUT THE KILL OPTION  */
	if ([self connectSpeechPort:TTS_NO_KILL] != TTS_SUCCESS) {
	    NXLogError("TTS client:  TTS_Server killed.  Cannot restart.");
	    return(TTS_SERVER_HUNG);
	}
    }
    else {
	if (tempPort == outPort) {
	    /*  SERVER IS HUNG;  RESTART WITH THE KILL OPTION  */
	    if ([self connectSpeechPort:TTS_KILL] != TTS_SUCCESS) {
		NXLogError("TTS client:  TTS_Server hung.  Cannot restart.");
		return(TTS_SERVER_HUNG);
	    }
	}
	else {
	    /*  SERVER RESTARTED BY SOMEBODY ELSE  */
	    outPort = tempPort;
	}
    }

    /*  TRY TO GET A CLIENT SLOT ON SERVER  */
    if ([self initiateConnection] != TTS_SUCCESS) {
	NXLogError("TTS client:  TTS_Server hung or killed.  Cannot restart.");
	return(TTS_SERVER_HUNG);
    }
    
    /*  GET TASK PORT OF SERVER (NEEDED FOR SERVER RESTART)  */
    if ([self setTaskPorts] != TTS_SUCCESS) {
	NXLogError("TTS client:  TTS_Server hung or killed.  Cannot restart.");
	return(TTS_SERVER_HUNG);
    }

    /*  REINITIALIZE THE SERVER WITH INSTANCE VARIABLES  */
    [self setServerToInstanceVariables];

    /*  IF HERE, SERVER SUCCESSFULLY RESTARTED  */
    return(TTS_SERVER_RESTARTED);
}



/*  CREATING AND FREEING THE OBJECT  *****************************************/

- init
{
    /*  STORAGE FOR NXDEFAULTS NAMES AND VALUES  */
    const NXDefaultsVector TextToSpeechDefaults = {
        {TTS_NXDEFAULT_SAMPLE_RATE,    STRINGIFY(TTS_SAMPLE_RATE_DEF)},
        {TTS_NXDEFAULT_CHANNELS,       STRINGIFY(TTS_CHANNELS_DEF)},
        {TTS_NXDEFAULT_BALANCE,        STRINGIFY(TTS_BALANCE_DEF)},
        {TTS_NXDEFAULT_SPEED,          STRINGIFY(TTS_SPEED_DEF)},
        {TTS_NXDEFAULT_INTONATION,     STRINGIFY(TTS_INTONATION_DEF)},
        {TTS_NXDEFAULT_VOICE_TYPE,     STRINGIFY(TTS_VOICE_TYPE_DEF)},
        {TTS_NXDEFAULT_PITCH_OFFSET,   STRINGIFY(TTS_PITCH_OFFSET_DEF)},
        {TTS_NXDEFAULT_VTL_OFFSET,     STRINGIFY(TTS_VTL_OFFSET_DEF)},
        {TTS_NXDEFAULT_BREATHINESS,    STRINGIFY(TTS_BREATHINESS_DEF)},
        {TTS_NXDEFAULT_VOLUME,         STRINGIFY(TTS_VOLUME_DEF)},
        {TTS_NXDEFAULT_USER_DICT_PATH, ""},
        {NULL,                         NULL},
    };
    char defaultValue[12];


    /*  INIT SUPER OBJECT  */
    if ([super init] == nil) {
	[super free];
	return(nil);
    }

    /*  CONNECT TO THE SERVER  */
    if ([self ConnectToServer] == nil) {
	[super free];
	return(nil);
    }

    /*  CREATE DEFAULTS REGISTRATION TABLE, USING USER'S DEFAULTS IF SET,
	OR WITH DEFINED DEFAULTS  */
    NXRegisterDefaults(TTS_NXDEFAULT_OWNER, TextToSpeechDefaults);

    /*  INITIALIZE ALL INSTANCE VARIABLES EXCEPT SpeechIdentifier &
	serverVersionNumber TO DEFAULTS  */
    sampleRate = atof(NXGetDefaultValue(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_SAMPLE_RATE));
    channels = atoi(NXGetDefaultValue(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_CHANNELS));
    balance = atof(NXGetDefaultValue(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_BALANCE));
    speed = atof(NXGetDefaultValue(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_SPEED));
    intonation =
	strtol(NXGetDefaultValue(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_INTONATION),NULL,0);
    voiceType = atoi(NXGetDefaultValue(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_VOICE_TYPE));
    pitchOffset =
	atof(NXGetDefaultValue(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_PITCH_OFFSET));
    vtlOffset = atof(NXGetDefaultValue(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_VTL_OFFSET));
    breathiness = atof(NXGetDefaultValue(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_BREATHINESS));
    volume = atof(NXGetDefaultValue(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_VOLUME));

    dictionaryOrder[0] = TTS_NUMBER_PARSER;
    dictionaryOrder[1] = TTS_USER_DICTIONARY;
    dictionaryOrder[2] = TTS_APPLICATION_DICTIONARY;
    dictionaryOrder[3] = TTS_MAIN_DICTIONARY;
    appDictPath[0] = '\0';
    strcpy(userDictPath,
	   NXGetDefaultValue(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_USER_DICT_PATH));

    escapeCharacter = TTS_ESCAPE_CHARACTER_DEF;
    block = (int)NO;
    softwareSynthesizer = (int)NO;

    version[0] = '\0';
    dictVersion[0] = '\0';

    tts_p = NULL;
    tts_lp = NULL;
    streamMem = NULL;
    localBuffer = NULL;


    /*  SET VARIABLES IN SERVER USING INSTANCE VARIABLES  */
    /*  IF INSTANCE VARIABLE OUT OF RANGE, PUT LEGAL VALUE INTO DEFAULTS DATABASE  */
    if ([self setOutputSampleRate:sampleRate] == TTS_OUT_OF_RANGE) {
	sprintf(defaultValue,"%.2f",sampleRate);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_SAMPLE_RATE, defaultValue);
    }
    if ([self setNumberChannels:channels] == TTS_OUT_OF_RANGE) {
	sprintf(defaultValue,"%-d",channels);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_CHANNELS, defaultValue);
    }
    if ([self setBalance:balance] == TTS_OUT_OF_RANGE) {
	sprintf(defaultValue,"%.2f",balance);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_BALANCE, defaultValue);
    }
    if ([self setSpeed:speed] == TTS_OUT_OF_RANGE) {
	sprintf(defaultValue,"%.2f",speed);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_SPEED, defaultValue);
    }
    if ([self setIntonation:intonation] == TTS_OUT_OF_RANGE) {
	sprintf(defaultValue,"0x%-x",(unsigned)intonation);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_INTONATION, defaultValue);
    }
    if ([self setVoiceType:voiceType] == TTS_OUT_OF_RANGE) {
	sprintf(defaultValue,"%-d",voiceType);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_VOICE_TYPE, defaultValue);
    }
    if ([self setPitchOffset:pitchOffset] == TTS_OUT_OF_RANGE) {
	sprintf(defaultValue,"%.2f",pitchOffset);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_PITCH_OFFSET, defaultValue);
    }
    if ([self setVocalTractLengthOffset:vtlOffset] == TTS_OUT_OF_RANGE) {
	sprintf(defaultValue,"%.2f",vtlOffset);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_VTL_OFFSET, defaultValue);
    }
    if ([self setBreathiness:breathiness] == TTS_OUT_OF_RANGE) {
	sprintf(defaultValue,"%.2f",breathiness);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_BREATHINESS, defaultValue);
    }
    if ([self setVolume:volume] == TTS_OUT_OF_RANGE) {
	sprintf(defaultValue,"%.2f",volume);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_VOLUME, defaultValue);
    }

    [self setDictionaryOrder:dictionaryOrder];
    [self setAppDictPath:appDictPath];
    if ([self setUserDictPath:userDictPath] == TTS_NO_FILE) {
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_USER_DICT_PATH, userDictPath);
    }

    [self setEscapeCharacter:escapeCharacter];
    [self setBlock:(BOOL)block];
    [self setSoftwareSynthesizer:(BOOL)softwareSynthesizer];


    /*  RETURN ID OF SELF  */
    return self;
}



- freeInstanceMemory
{
    /*  DEALLOCATE LOCAL REPLY PORT  */
    port_deallocate(task_self(), localPort);

    /*  DEALLOCATE MEMORY FOR HIDDEN METHODS, IF NECESSARY  */
    if (tts_p != NULL)
	free(tts_p);

    if (tts_lp != NULL)
	free(tts_lp);

    if (streamMem != NULL)
	free(streamMem);

    if (localBuffer != NULL)
	free(localBuffer);

    return self;
}



- free
{
    /*  TELL SERVER WE ARE FINISHED WITH ITS SERVICES  */
    send_simple_message(outPort, localPort, CLOSE_SPEAKER, SpeechIdentifier);

    /*  FREE ALL LOCAL MALLOCED MEMORY  */
    [self freeInstanceMemory];

    /*  FREE SUPER OBJECT  */
    [super free];

    /*  RETURN NIL  */
    return(nil);
}



/*  VOICE QUALITY METHODS  ***************************************************/

- (tts_error_t)setOutputSampleRate:(float)rateValue
{
    tts_error_t error = TTS_OK;

    /*  RETURN ERROR IF THE SERVER CAN'T HANDLE THIS MESSAGE  */
    if (serverVersionNumber < TTS_SERVER_2_0)
	return(TTS_OBSOLETE_SERVER);

    /*  CHECK RANGE OF ARGUMENT  */
    if ((rateValue != TTS_SAMPLE_RATE_LOW) && (rateValue != TTS_SAMPLE_RATE_HIGH)) {
	error = TTS_OUT_OF_RANGE;
	rateValue = TTS_SAMPLE_RATE_DEF;
    }

    /*  SET VALUE OF INSTANCE VARIABLE  */
    sampleRate = rateValue;

    /*  SET VALUE OF THE OUTPUT SAMPLE RATE IN THE SERVER  */
    if (send_float_message(outPort, localPort, SET_SAMPLE_RATE,
			   SpeechIdentifier, rateValue) != SEND_SUCCESS) 
	error = [self restartServer];
    
    return(error);
}



- (float)outputSampleRate
{
    float_msg_t message;

    /*  RETURN DEFAULT VALUE IF THE SERVER CAN'T HANDLE THIS MESSAGE  */
    if (serverVersionNumber < TTS_SERVER_2_0)
	return(TTS_SAMPLE_RATE_DEF);

    /*  QUERY SERVER FOR OUTPUT SAMPLE RATE VALUE  */
    if (send_simple_message(outPort, localPort, GET_SAMPLE_RATE,
			    SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return(sampleRate);
    }
    
    /*  WAIT FOR DATA MESSAGE FROM SERVER  */
    if (receive_float_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return(sampleRate);
    }
    
    /*  SET INSTANCE VARIABLE WITH RETURNED VALUE  */
    sampleRate = message.data;

    /*  RETURN VALUE OF THE OUTPUT SAMPLE RATE  */
    return(message.data);
}



- (tts_error_t)setNumberChannels:(int)channelsValue
{
    tts_error_t error = TTS_OK;

    /*  RETURN ERROR IF THE SERVER CAN'T HANDLE THIS MESSAGE  */
    if (serverVersionNumber < TTS_SERVER_2_0)
	return(TTS_OBSOLETE_SERVER);

    /*  CHECK RANGE OF ARGUMENT  */
    if ((channelsValue < TTS_CHANNELS_1) || (channelsValue > TTS_CHANNELS_2)) {
	error = TTS_OUT_OF_RANGE;
	channelsValue = TTS_CHANNELS_DEF;
    }

    /*  SET VALUE OF INSTANCE VARIABLE  */
    channels = channelsValue;

    /*  SET VALUE OF THE NUMBER OF CHANNELS IN THE SERVER  */
    if (send_int_message(outPort, localPort, SET_CHANNELS,
			 SpeechIdentifier, channelsValue) != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (int)numberChannels
{
    int_msg_t message;

    /*  RETURN DEFAULT VALUE IF THE SERVER CAN'T HANDLE THIS MESSAGE  */
    if (serverVersionNumber < TTS_SERVER_2_0)
	return(TTS_CHANNELS_DEF);

    /*  QUERY SERVER FOR NUMBER OF CHANNELS  */
    if (send_simple_message(outPort, localPort, GET_CHANNELS,
			    SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return(channels);
    }

    /*  AWAIT RETURN MESSAGE WITH REQUESTED DATA  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return(channels);
    }

    /*  SET INSTANCE VARIABLE WITH RETURNED VALUE  */
    channels = message.data;

    /*  RETURN VALUE OF THE NUMBER OF CHANNELS  */
    return(message.data);
}



- (tts_error_t)setBalance:(float)balanceValue
{
    tts_error_t error = TTS_OK;

    /*  CHECK RANGE OF ARGUMENT  */
    if (balanceValue < TTS_BALANCE_MIN) {
	error = TTS_OUT_OF_RANGE;
	balanceValue = TTS_BALANCE_MIN;
    }
    else if (balanceValue > TTS_BALANCE_MAX) {
	error = TTS_OUT_OF_RANGE;
	balanceValue = TTS_BALANCE_MAX;
    }

    /*  SET VALUE OF INSTANCE VARIABLE  */
    balance = balanceValue;

    /*  SET VALUE OF BALANCE IN THE SERVER  */
    if (send_float_message(outPort, localPort, SET_BALANCE,
			   SpeechIdentifier, balanceValue) != SEND_SUCCESS) 
	error = [self restartServer];
    
    return(error);
}



- (float)balance
{
    float_msg_t message;

    /*  QUERY SERVER FOR BALANCE VALUE  */
    if (send_simple_message(outPort, localPort, GET_BALANCE,
			    SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return(balance);
    }
    
    /*  WAIT FOR DATA MESSAGE FROM SERVER  */
    if (receive_float_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return(balance);
    }
    
    /*  SET INSTANCE VARIABLE WITH RETURNED VALUE  */
    balance = message.data;

    /*  RETURN VALUE OF BALANCE  */
    return(message.data);
}



- (tts_error_t)setSpeed:(float)speedValue
{
    tts_error_t error = TTS_OK;

    /*  CHECK RANGE OF ARGUMENT  */
    if (speedValue < TTS_SPEED_MIN) {
	error = TTS_OUT_OF_RANGE;
	speedValue = TTS_SPEED_MIN;
    }
    else if (speedValue > TTS_SPEED_MAX) {
	error = TTS_OUT_OF_RANGE;
	speedValue = TTS_SPEED_MAX;
    }

    /*  SET VALUE OF INSTANCE VARIABLE  */
    speed = speedValue;

    /*  SET VALUE OF SPEED IN THE SERVER  */
    if (send_float_message(outPort, localPort, SET_SPEED,
			   SpeechIdentifier, speedValue) != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (float)speed
{
    float_msg_t message;

    /*  QUERY SERVER FOR SPEED VALUE  */
    if (send_simple_message(outPort, localPort, 
			    GET_SPEED, SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return(speed);
    }

    /*  AWAIT RETURN MESSAGE WITH REQUESTED DATA  */
    if (receive_float_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return(speed);
    }

    /*  SET INSTANCE VARIABLE WITH RETURNED VALUE  */
    speed = message.data;

    /*  RETURN VALUE OF SPEED  */
    return(message.data);
}



- (tts_error_t)setIntonation:(int)intonationMask
{
    tts_error_t error = TTS_OK;

    /*  CHECK RANGE OF ARGUMENT  */
    if ( (intonationMask < TTS_INTONATION_NONE) || 
	 (intonationMask > TTS_INTONATION_ALL) ) {
	error = TTS_OUT_OF_RANGE;
	intonationMask = TTS_INTONATION_DEF;
    }

    /*  SET VALUE OF INSTANCE VARIABLE  */
    intonation = intonationMask;

    /*  SET VALUE OF INTONATION MASK IN THE SERVER  */
    if (send_int_message(outPort, localPort, SET_INTONATION,
			 SpeechIdentifier, intonationMask) != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (int)intonation
{
    int_msg_t message;

    /*  QUERY USER FOR INTONATION  */
    if (send_simple_message(outPort, localPort, GET_INTONATION,
			    SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return(intonation);
    }

    /*  AWAIT RETURN MESSAGE WITH REQUESTED DATA  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return(intonation);
    }

    /*  SET INSTANCE VARIABLE WITH RETURNED VALUE  */
    intonation = message.data;

    /*  RETURN VALUE OF INTONATION  */
    return(message.data);
}



- (tts_error_t)setVoiceType:(int)type
{
    tts_error_t error = TTS_OK;

    /*  RETURN ERROR IF THE SERVER CAN'T HANDLE THIS MESSAGE  */
    if (serverVersionNumber < TTS_SERVER_2_0)
	return(TTS_OBSOLETE_SERVER);

    /*  CHECK RANGE OF ARGUMENT  */
    if ((type < TTS_VOICE_TYPE_MALE) || (type > TTS_VOICE_TYPE_BABY)) {
	error = TTS_OUT_OF_RANGE;
	type = TTS_VOICE_TYPE_DEF;
    }

    /*  SET VALUE OF INSTANCE VARIABLE  */
    voiceType = type;

    /*  SET VALUE OF VOICE TYPE IN THE SERVER  */
    if (send_int_message(outPort, localPort, SET_VOICE_TYPE,
			 SpeechIdentifier, voiceType) != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (int)voiceType
{
    int_msg_t message;

    /*  RETURN DEFAULT VALUE IF THE SERVER CAN'T HANDLE THIS MESSAGE  */
    if (serverVersionNumber < TTS_SERVER_2_0)
	return(TTS_VOICE_TYPE_DEF);

    /*  QUERY USER FOR VOICE TYPE  */
    if (send_simple_message(outPort, localPort, GET_VOICE_TYPE,
			    SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return(voiceType);
    }

    /*  AWAIT RETURN MESSAGE WITH REQUESTED DATA  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return(voiceType);
    }

    /*  SET INSTANCE VARIABLE WITH RETURNED VALUE  */
    voiceType = message.data;

    /*  RETURN VALUE OF VOICE TYPE  */
    return(message.data);
}



- (tts_error_t)setPitchOffset:(float)offsetValue
{
    tts_error_t error = TTS_OK;

    /*  CHECK RANGE OF ARGUMENT  */
    if (offsetValue < TTS_PITCH_OFFSET_MIN) {
	error = TTS_OUT_OF_RANGE;
	offsetValue = TTS_PITCH_OFFSET_MIN;
    }
    else if (offsetValue > TTS_PITCH_OFFSET_MAX) {
	error = TTS_OUT_OF_RANGE;
	offsetValue = TTS_PITCH_OFFSET_MAX;
    }

    /*  SET VALUE OF INSTANCE VARIABLE  */
    pitchOffset = offsetValue;

    /*  SET VALUE OF SPEED IN THE SERVER  */
    if (send_float_message(outPort, localPort, SET_PITCH_OFFSET,
			   SpeechIdentifier, offsetValue) != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (float)pitchOffset
{
    float_msg_t message;
    
    /*  QUERY SERVER FOR PITCH OFFSET VALUE  */
    if (send_simple_message(outPort, localPort, GET_PITCH_OFFSET,
			    SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return(pitchOffset);
    }
    
    /*  AWAIT RETURN MESSAGE WITH REQUESTED DATA  */
    if (receive_float_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return(pitchOffset);
    }

    /*  SET INSTANCE VARIABLE WITH RETURNED VALUE  */
    pitchOffset = message.data;

    /*  RETURN VALUE OF SPEED  */
    return(message.data);
}



- (tts_error_t)setVocalTractLengthOffset:(float)offsetValue
{
    tts_error_t error = TTS_OK;

    /*  RETURN ERROR IF THE SERVER CAN'T HANDLE THIS MESSAGE  */
    if (serverVersionNumber < TTS_SERVER_2_0)
	return(TTS_OBSOLETE_SERVER);

    /*  CHECK RANGE OF ARGUMENT  */
    if (offsetValue < TTS_VTL_OFFSET_MIN) {
	error = TTS_OUT_OF_RANGE;
	offsetValue = TTS_VTL_OFFSET_MIN;
    }
    else if (offsetValue > TTS_VTL_OFFSET_MAX) {
	error = TTS_OUT_OF_RANGE;
	offsetValue = TTS_VTL_OFFSET_MAX;
    }

    /*  SET VALUE OF INSTANCE VARIABLE  */
    vtlOffset = offsetValue;

    /*  SET VALUE OF VOCAL TRACT LENGTH OFFSET IN THE SERVER  */
    if (send_float_message(outPort, localPort, SET_VTL_OFFSET,
			   SpeechIdentifier, offsetValue) != SEND_SUCCESS) 
	error = [self restartServer];
    
    return(error);
}



- (float)vocalTractLengthOffset
{
    float_msg_t message;

    /*  RETURN DEFAULT VALUE IF THE SERVER CAN'T HANDLE THIS MESSAGE  */
    if (serverVersionNumber < TTS_SERVER_2_0)
	return(TTS_VTL_OFFSET_DEF);

    /*  QUERY SERVER FOR VOCAL TRACT LENGTH VALUE  */
    if (send_simple_message(outPort, localPort, GET_VTL_OFFSET,
			    SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return(vtlOffset);
    }
    
    /*  WAIT FOR DATA MESSAGE FROM SERVER  */
    if (receive_float_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return(vtlOffset);
    }
    
    /*  SET INSTANCE VARIABLE WITH RETURNED VALUE  */
    vtlOffset = message.data;

    /*  RETURN VALUE OF VOCAL TRACT LENGTH OFFSET  */
    return(message.data);
}



- (tts_error_t)setBreathiness:(float)breathinessValue
{
    tts_error_t error = TTS_OK;

    /*  RETURN ERROR IF THE SERVER CAN'T HANDLE THIS MESSAGE  */
    if (serverVersionNumber < TTS_SERVER_2_0)
	return(TTS_OBSOLETE_SERVER);

    /*  CHECK RANGE OF ARGUMENT  */
    if (breathinessValue < TTS_BREATHINESS_MIN) {
	error = TTS_OUT_OF_RANGE;
	breathinessValue = TTS_BREATHINESS_MIN;
    }
    else if (breathinessValue > TTS_BREATHINESS_MAX) {
	error = TTS_OUT_OF_RANGE;
	breathinessValue = TTS_BREATHINESS_MAX;
    }

    /*  SET VALUE OF INSTANCE VARIABLE  */
    breathiness = breathinessValue;

    /*  SET VALUE OF BREATHINESS IN THE SERVER  */
    if (send_float_message(outPort, localPort, SET_BREATHINESS,
			   SpeechIdentifier, breathinessValue) != SEND_SUCCESS) 
	error = [self restartServer];
    
    return(error);
}



- (float)breathiness
{
    float_msg_t message;

    /*  RETURN DEFAULT VALUE IF THE SERVER CAN'T HANDLE THIS MESSAGE  */
    if (serverVersionNumber < TTS_SERVER_2_0)
	return(TTS_BREATHINESS_DEF);

    /*  QUERY SERVER FOR BREATHINESS VALUE  */
    if (send_simple_message(outPort, localPort, GET_BREATHINESS,
			    SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return(breathiness);
    }
    
    /*  WAIT FOR DATA MESSAGE FROM SERVER  */
    if (receive_float_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return(breathiness);
    }
    
    /*  SET INSTANCE VARIABLE WITH RETURNED VALUE  */
    breathiness = message.data;

    /*  RETURN VALUE OF BREATHINESS  */
    return(message.data);
}



- (tts_error_t)setVolume:(float)volumeLevel
{
    tts_error_t error = TTS_OK;
 
    /*  CHECK RANGE OF ARGUMENT  */
    if (volumeLevel < TTS_VOLUME_MIN) {
	error = TTS_OUT_OF_RANGE;
	volumeLevel = TTS_VOLUME_MIN;
    }
    else if (volumeLevel > TTS_VOLUME_MAX) {
	error = TTS_OUT_OF_RANGE;
	volumeLevel = TTS_VOLUME_MAX;
    }

    /*  SET VALUE OF INSTANCE VARIABLE  */
    volume = volumeLevel;

    /*  SET VALUE OF VOLUME IN THE SERVER  */
    if (send_float_message(outPort, localPort, SET_VOLUME,
			   SpeechIdentifier, volumeLevel) != SEND_SUCCESS) 
	error = [self restartServer];
    
    return(error);
}



- (float)volume
{
    float_msg_t message;

    /*  QUERY SERVER FOR VOLUME VALUE  */
    if (send_simple_message(outPort, localPort, GET_VOLUME,
			    SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return(volume);
    }
    
    /*  WAIT FOR DATA MESSAGE FROM SERVER  */
    if (receive_float_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return(volume);
    }
    
    /*  SET INSTANCE VARIABLE WITH RETURNED VALUE  */
    volume = message.data;

    /*  RETURN VALUE OF VOLUME  */
    return(message.data);
}



/*  DICTIONARY CONTROL METHODS  **********************************************/

- (tts_error_t)setDictionaryOrder:(const short *)order
{
    int i, j;
    char c_temp[4];
    tts_error_t error = TTS_OK;

    /*  SET VALUE OF INSTANCE VARIABLE  */
    for (i = 0; i < 4; i++)
	dictionaryOrder[i] = order[i];

    /*  CHECK LEGALITY OF ARGUMENTS  */
    for (i = 0; i < 4; i++) {
	/*  CHECK RANGE OF ARGUMENTS  */
	if ((order[i] < TTS_EMPTY) || (order[i] > TTS_LETTER_TO_SOUND)) {
	    error = TTS_OUT_OF_RANGE;
	    dictionaryOrder[0] = TTS_NUMBER_PARSER;
	    dictionaryOrder[1] = TTS_USER_DICTIONARY;
	    dictionaryOrder[2] = TTS_APPLICATION_DICTIONARY;
	    dictionaryOrder[3] = TTS_MAIN_DICTIONARY;
	    break;
	}
	/*  MAKE SURE NON-EMPTY ENTRY IS NOT DUPLICATED  */
	for (j = (i+1); j < 4; j++) {
	    if ((order[i] == order[j]) && (order[i] != TTS_EMPTY)) {
		error = TTS_OUT_OF_RANGE;
		dictionaryOrder[0] = TTS_NUMBER_PARSER;
		dictionaryOrder[1] = TTS_USER_DICTIONARY;
		dictionaryOrder[2] = TTS_APPLICATION_DICTIONARY;
		dictionaryOrder[3] = TTS_MAIN_DICTIONARY;
		break;
	    }
	    /*  MAKE SURE NO TTS_EMPTY IN MIDDLE OF LIST  */
	    if ((order[i] == TTS_EMPTY) && (order[j] != TTS_EMPTY)) {
		error = TTS_OUT_OF_RANGE;
		dictionaryOrder[0] = TTS_NUMBER_PARSER;
		dictionaryOrder[1] = TTS_USER_DICTIONARY;
		dictionaryOrder[2] = TTS_APPLICATION_DICTIONARY;
		dictionaryOrder[3] = TTS_MAIN_DICTIONARY;
		break;
	    }
	}
    }

    /*  STUFF ORDER VALUES INTO CHARS  */
    for (i = 0; i < 4; i++)
	c_temp[i] = (char)dictionaryOrder[i];

    /*  SET DICTIONARY ORDER IN THE SERVER  */
    if (send_int_message(outPort, localPort, SET_DICT_ORDER,
			 SpeechIdentifier, *((int *)c_temp)) != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (const short *)dictionaryOrder
{
    int i;
    char *c_temp;
    int_msg_t message;

    /*  QUERY SERVER FOR DICTIONARY ORDER  */    
    if (send_simple_message(outPort, localPort, GET_DICT_ORDER,
			    SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return((const short *)dictionaryOrder);
    }

    /*  WAIT FOR DATA MESSAGE FROM SERVER  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return((const short *)dictionaryOrder);
    }

    /*  DECODE 4 CHARS, PUT INTO INSTANCE VARIABLE  */
    c_temp = (char *)&(message.data);
    for(i = 0; i < 4; i++)
	dictionaryOrder[i] = (short)c_temp[i];

    /*  RETURN POINTER TO DICTIONARY ORDER  */
    return((const short *)dictionaryOrder);
}




- (tts_error_t)setAppDictPath:(const char *)path
{
    tts_error_t error = TTS_OK;

    /*  CHECK ACCESS TO DICTIONARY, TO SEE IF IT EXISTS & IS READABLE  */
    if (access(path, R_OK) || (strlen(path) == 0)) {
	error = TTS_NO_FILE;
	appDictPath[0] = '\0';
    }
    else {
	/*  SET VALUE OF INSTANCE VARIABLE  */
	strcpy(appDictPath, path);
    }

    /*  SET APPLICATION DICTIONARY PATH IN THE SERVER  */
    if (send_string_message(outPort, localPort, SET_APP_DICT,
			    SpeechIdentifier, appDictPath) != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (const char *)appDictPath
{
    string_msg_t message;

    /*  INITIALIZE POINTER IN MESSAGE STRUCT TO NULL  */
    message.data = NULL;

    /*  QUERY SERVER FOR APPLICATION DICTIONARY PATH  */        
    if (send_simple_message(outPort, localPort, GET_APP_DICT,
			    SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return((const char *)appDictPath);
    }

    /*  WAIT FOR DATA MESSAGE FROM SERVER  */
    if (receive_string_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return((const char *)appDictPath);
    }

    /*  SET VALUE OF INSTANCE VARIABLE  */
    if (message.data != NULL)
	strcpy(appDictPath, message.data);

    /*  DEALLOCATE MEMORY USED TO RECEIVE MESSAGE FROM SERVER  */
    if (message.data != NULL)
	vm_deallocate(task_self(), (vm_address_t)message.data, strlen(message.data+2));

    /*  RETURN POINTER TO DICTIONARY PATH  */
    return((const char *)appDictPath);
}



- (tts_error_t)setUserDictPath:(const char *)path
{
    tts_error_t error = TTS_OK;

    /*  CHECK ACCESS TO DICTIONARY, TO SEE IF IT EXISTS & IS READABLE  */
    if (access(path, R_OK) || (strlen(path) == 0)) {
	error = TTS_NO_FILE;
	userDictPath[0] = '\0';
    }
    else {
	/*  SET VALUE OF INSTANCE VARIABLE  */
	strcpy(userDictPath, path);
    }

    /*  SET APPLICATION DICTIONARY PATH IN THE SERVER  */
    if (send_string_message(outPort, localPort, SET_USER_DICT,
			    SpeechIdentifier, userDictPath) != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (const char *)userDictPath
{
    string_msg_t message;

    /*  INITIALIZE POINTER IN MESSAGE STRUCT TO NULL  */
    message.data = NULL;

    /*  QUERY SERVER FOR USER DICTIONARY PATH NAME  */
    if (send_simple_message(outPort, localPort, GET_USER_DICT,
			    SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return((const char *)userDictPath);
    }

    /*  WAIT FOR DATA MESSAGE FROM SERVER  */
    if (receive_string_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return((const char *)userDictPath);
    }

    /*  SET VALUE OF INSTANCE VARIABLE  */
    if (message.data != NULL)
	strcpy(userDictPath, message.data);

    /*  DEALLOCATE MEMORY USED TO RECEIVE MESSAGE FROM SERVER  */
    if (message.data != NULL)
	vm_deallocate(task_self(), (vm_address_t)message.data, strlen(message.data+2));

    /*  RETURN POINTER TO DICTIONARY PATH  */
    return((const char *)userDictPath);
}



/*  TEXT INPUT METHODS  ******************************************************/

- (tts_error_t)speakText:(const char *)text
{
    int_msg_t message;
    tts_error_t error = TTS_OK;

    /*  IF NULL OR ZERO LENGTH STRING, RETURN IMMEDIATELY WITH ERROR CODE  */
    if ((text == NULL) || (strlen(text) == 0))
	return(TTS_PARSE_ERROR);

 restart:
    /*  SEND STRING TO BE SPOKEN  */
    if (send_string_message(outPort,localPort,SPEAKTEXT,
			    SpeechIdentifier, text) != SEND_SUCCESS) {
	if ((error = [self restartServer]) == TTS_SERVER_RESTARTED)
	    goto restart;
	else
	    return(error);
    }

    /*  WAIT FOR IMMEDIATE ACKNOWLEDGE  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS) {
	if ((error = [self restartServer]) == TTS_SERVER_RESTARTED)
	    goto restart;
	else
	    return(error);
    }
    
    
    /*  AWAIT RETURN ERROR CODE, BLOCKING IF REQUESTED  */
    if (!block) {
	/*  WAIT FOR REPLY WITH A LONG TIME OUT  */
	if (receive_int_message_long(localPort, &message) != RCV_SUCCESS) {
		return(TTS_SERVER_HUNG);
	}
    }
    else {
	/*  WAIT FOR REPLY WITH INFINITE TIMEOUT  */
	receive_int_message_block(localPort, &message);
    }

    /*  RETURN ERROR IF SERVER RESTARTED, ELSE RETURN NORMAL ERROR CODE  */
    if (error)
	return(error);
    else
	return(message.data);
}



- (tts_error_t)speakText:(const char *)text toFile:(const char *)path
{
    FILE *fopen(), *fd;
    char header[MAXPATHLEN + 68];
    int_msg_t message;
    tts_error_t error = TTS_OK;

    /*  IF ZERO LENGTH TEXT STRING, RETURN IMMEDIATELY WITH ERROR CODE  */
    if ((text == NULL) || (strlen(text) == 0))
	return(TTS_PARSE_ERROR);

    /*  CHECK FOR NULL POINTER, OR ZERO-LENGTH STRING, OR TOO LONG STRING FOR PATH  */
    if ((path == NULL) || (strlen(path) == 0) || (strlen(path) > (MAXPATHLEN-1)))
	return(TTS_INVALID_PATH);

    /*  MAKE SURE WE HAVE A VALID PATH  */
    if ((fd = fopen(path, "w")) == NULL)
	return(TTS_INVALID_PATH);
    fclose(fd);
    
    /*  CREATE THE HEADER:  THE USER AND GROUP IDS FOR THE USER, PLUS THE FILE PATH  */
    sprintf(header, "%-d\n%-d\n%s\n", getuid(), getgid(), path);

    /*  FREE OLD MEMORY, IF NECESSARY  */
    if (localBuffer != NULL)
	free(localBuffer);

    /*  ALLOCATE MEMORY TO HOLD THE HEADER PLUS TEXT  */
    localBuffer = (char *)malloc(strlen(header) + strlen(text) + 1);

    /*  CONCATENATE THE TEXT TO THE HEADER, AND PUT INTO LOCAL BUFFER  */
    strcpy(localBuffer, header);
    strcat(localBuffer, text);


 restart:
    /*  SEND STRING TO BE SPOKEN  */
    if (send_string_message(outPort,localPort,SPEAKTEXTTOFILE,
			    SpeechIdentifier, localBuffer) != SEND_SUCCESS) {
	if ((error = [self restartServer]) == TTS_SERVER_RESTARTED)
	    goto restart;
	else
	    return(error);
    }

    /*  WAIT FOR IMMEDIATE ACKNOWLEDGE  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS) {
	if ((error = [self restartServer]) == TTS_SERVER_RESTARTED)
	    goto restart;
	else
	    return(error);
    }
    
    /*  AWAIT RETURN ERROR CODE, BLOCKING IF REQUESTED  */
    if (!block) {
	/*  WAIT FOR REPLY WITH A LONG TIME OUT  */
	if (receive_int_message_long(localPort, &message) != RCV_SUCCESS) {
		return(TTS_SERVER_HUNG);
	}
    }
    else {
	/*  WAIT FOR REPLY WITH INFINITE TIMEOUT  */
	receive_int_message_block(localPort, &message);
    }

    /*  RETURN ERROR IF SERVER RESTARTED, ELSE RETURN NORMAL ERROR CODE  */
    if (error)
	return(error);
    else
	return(message.data);
}



- (tts_error_t)speakStream:(NXStream *)stream
{
    volatile tts_error_t error;
    char *streambuf;
    int length, max_length;

    /*  RETURN IMMEDIATELY IF STREAM IS NULL POINTER  */
    if (stream == NULL)
	return(TTS_ILLEGAL_STREAM);

    /*  GET MEMORY BUFFER ASSOCIATED WITH STREAM  */
    NX_DURING
	error = TTS_OK;
	NXGetMemoryBuffer(stream, &streambuf, &length, &max_length);
    NX_HANDLER
	if (NXLocalHandler.code == NX_illegalStream)
	    error = TTS_ILLEGAL_STREAM;
    NX_ENDHANDLER

    /*  IF STREAM ERROR, RETURN IMMEDIATELY  */
    if (error)
	return(error);

    /*  FREE OLD MEMORY, IF NECESSARY  */
    if (streamMem != NULL)
	free(streamMem);

    /*  ALLOCATE MEMORY TO HOLD CONTENTS OF STREAM  */
    streamMem = (char *)malloc(length + 1);

    /*  COPY CONTENTS OF STREAM TO LOCAL BUFFER, APPENDING A NULL  */
    bcopy(streambuf, streamMem, length);
    streamMem[length] = '\0';

    /*  DO SPEAKTEXT WITH LOCAL BUFFER  */
    return([self speakText:streamMem]);
}



- (tts_error_t)speakStream:(NXStream *)stream toFile:(const char *)path
{
    volatile tts_error_t error;
    char *streambuf;
    int length, max_length;

    /*  RETURN IMMEDIATELY IF STREAM IS NULL POINTER  */
    if (stream == NULL)
	return(TTS_ILLEGAL_STREAM);

    /*  GET MEMORY BUFFER ASSOCIATED WITH STREAM  */
    NX_DURING
	error = TTS_OK;
	NXGetMemoryBuffer(stream, &streambuf, &length, &max_length);
    NX_HANDLER
	if (NXLocalHandler.code == NX_illegalStream)
	    error = TTS_ILLEGAL_STREAM;
    NX_ENDHANDLER

    /*  IF STREAM ERROR, RETURN IMMEDIATELY  */
    if (error)
	return(error);

    /*  FREE OLD MEMORY, IF NECESSARY  */
    if (streamMem != NULL)
	free(streamMem);

    /*  ALLOCATE MEMORY TO HOLD CONTENTS OF STREAM  */
    streamMem = (char *)malloc(length + 1);

    /*  COPY CONTENTS OF STREAM TO LOCAL BUFFER, APPENDING A NULL  */
    bcopy(streambuf, streamMem, length);
    streamMem[length] = '\0';

    /*  DO SPEAKTEXT TO FILE WITH LOCAL BUFFER  */
    return([self speakText:streamMem toFile:path]);
}



- (tts_error_t)setEscapeCharacter:(char)character
{
    tts_error_t error = TTS_OK;

    /*  DO NOT ALLOW NULL OR NON-ASCII CHARACTER  */
    if ((character == '\0') || (!isascii(character))) {
	error = TTS_OUT_OF_RANGE;
	character = TTS_ESCAPE_CHARACTER_DEF;
    }

    /*  WARN USER IF CHAR IS PRINTABLE (INCLUDING SPACE)  */
    if (isprint(character))
	error = TTS_WARNING;

    /*  SET VALUE OF INSTANCE VARIABLE  */
    escapeCharacter = character;

    /*  SET ESCAPE CHARACTER IN THE SERVER  */
    if (send_int_message(outPort, localPort, SET_ESCAPE_CHAR,
			 SpeechIdentifier, (int)character) != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (char)escapeCharacter
{
    int_msg_t message;

    /*  QUERY SERVER FOR ESCAPE CHARACTER  */    
    if (send_simple_message(outPort, localPort, GET_ESCAPE_CHAR,
			    SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return(escapeCharacter);
    }

    /*  WAIT FOR DATA MESSAGE FROM SERVER  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return(escapeCharacter);
    }

    /*  SET VALUE OF INSTANCE VARIABLE  */
    escapeCharacter = (char)message.data;

    /*  RETURN VALUE OF ESCAPE CHARACTER  */
    return(escapeCharacter);
}



- (tts_error_t)setBlock:(BOOL)flag
{
    tts_error_t error = TTS_OK;

    /*  SET VALUE OF INSTANCE VARIABLE  */
    block = (int)flag;

    /*  SET VALUE IN THE SERVER  */
    if (send_int_message(outPort, localPort, SET_BLOCK,
			 SpeechIdentifier, (int)flag) != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (BOOL)block
{
    int_msg_t message;

    /*  QUERY SERVER FOR BLOCKING FLAG  */    
    if (send_simple_message(outPort, localPort, GET_BLOCK,
			    SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return((BOOL)block);
    }

    /*  WAIT FOR DATA MESSAGE FROM SERVER  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return((BOOL)block);
    }

    /*  SET VALUE OF INSTANCE VARIABLE  */
    block = message.data;

    /*  RETURN VALUE OF BLOCK  */
    return((BOOL)block);
}



- (tts_error_t)setSoftwareSynthesizer:(BOOL)flag
{
    tts_error_t error = TTS_OK;

    /*  RETURN ERROR IF THE SERVER CAN'T HANDLE THIS MESSAGE  */
    if (serverVersionNumber < TTS_SERVER_2_0)
	return(TTS_OBSOLETE_SERVER);

    /*  SET VALUE OF INSTANCE VARIABLE  */
    softwareSynthesizer = (int)flag;

    /*  SET VALUE IN THE SERVER  */
    if (send_int_message(outPort, localPort, SET_SOFT_SYNTH,
			 SpeechIdentifier, (int)flag) != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (BOOL)softwareSynthesizer
{
    int_msg_t message;

    /*  RETURN DEFAULT VALUE IF THE SERVER CAN'T HANDLE THIS MESSAGE  */
    if (serverVersionNumber < TTS_SERVER_2_0)
	return(0);

    /*  QUERY SERVER FOR SOFTWARE SYNTHESIZER FLAG  */    
    if (send_simple_message(outPort, localPort, GET_SOFT_SYNTH,
			    SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return((BOOL)softwareSynthesizer);
    }

    /*  WAIT FOR DATA MESSAGE FROM SERVER  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return((BOOL)softwareSynthesizer);
    }

    /*  SET VALUE OF INSTANCE VARIABLE  */
    softwareSynthesizer = message.data;

    /*  RETURN VALUE OF THE FLAG  */
    return((BOOL)softwareSynthesizer);
}



/*  REAL-TIME METHODS  *******************************************************/

- (tts_error_t)pauseImmediately
{
    int_msg_t message;

    /*  SEND PAUSE CODE  */
    if (send_simple_message(outPort, localPort, PAUSEIMMED,
			    SpeechIdentifier) != SEND_SUCCESS)
	return ([self restartServer]);

    /*  AWAIT RETURN CODE  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS)
	return ([self restartServer]);
    
    return(message.data);
}



- (tts_error_t)pauseAfterCurrentUtterance
{
    int_msg_t message;

    /*  SEND PAUSE CODE  */
    if (send_simple_message(outPort, localPort, PAUSEAFTERUTT,
			    SpeechIdentifier) != SEND_SUCCESS)
	return([self restartServer]);
    
    /*  AWAIT RETURN CODE  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS)
	return ([self restartServer]);
    
    return(message.data);
}



- (tts_error_t)continue
{
    int_msg_t message;

    /*  SEND CONTINUE CODE  */
    if (send_simple_message(outPort, localPort, CONTINUE,
			    SpeechIdentifier) != SEND_SUCCESS)
	return ([self restartServer]);
    
    /*  AWAIT RETURN CODE  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS)
	return ([self restartServer]);
    
    return(message.data);
}



- (tts_error_t)eraseAllSound
{
    int_msg_t message;

    /*  SEND ERASE CODE  */
    if (send_simple_message(outPort, localPort, ERASEALLSOUND,
			    SpeechIdentifier) != SEND_SUCCESS)
	return ([self restartServer]);
    
    /*  AWAIT RETURN CODE  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS)
	return ([self restartServer]);
    
    return(message.data);
}



- (tts_error_t)eraseCurrentUtterance
{
    int_msg_t message;

    /*  SEND ERASE CODE  */
    if (send_simple_message(outPort, localPort, ERASECURUTT,
			    SpeechIdentifier) != SEND_SUCCESS)
	return ([self restartServer]);
    
    /*  AWAIT RETURN CODE  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS)
	return ([self restartServer]);
    
    return(message.data);
}



/*  SERVER VERSION METHODS  **************************************************/

- (const char *)serverVersion
{
    string_msg_t message;

    /*  INITIALIZE POINTER IN MESSAGE STRUCT TO NULL  */
    message.data = NULL;

    /*  INITIALIZE version TO ALL ZEROS  */
    bzero(version, 256);

 restart:
    /*  QUERY SERVER FOR SERVER VERSION  */    
    if (send_simple_message(outPort, localPort, VERSION,
			    SpeechIdentifier) != SEND_SUCCESS) {
	if ([self restartServer] == TTS_SERVER_RESTARTED)
	    goto restart;
	else
	    return((const char *)version);
    }

    /*  WAIT FOR DATA MESSAGE FROM SERVER  */
    if (receive_string_message(localPort, &message) != RCV_SUCCESS) {
	if ([self restartServer] == TTS_SERVER_RESTARTED)
	    goto restart;
	else
	    return((const char *)version);
    }

    /*  COPY DATA FROM MESSAGE IN version  */
    if (message.data != NULL)
	strcpy(version, message.data);

    /*  DEALLOCATE MEMORY USED TO RECEIVE MESSAGE FROM SERVER  */
    if (message.data != NULL)
	vm_deallocate(task_self(), (vm_address_t)message.data, strlen(message.data+2));

    /*  RETURN POINTER TO SERVER VERSION  */
    return((const char *)version);
}



- (const char *)dictionaryVersion
{
    string_msg_t message;

    /*  INITIALIZE POINTER IN MESSAGE STRUCT TO NULL  */
    message.data = NULL;

    /*  INITIALIZE dictVersion TO ALL ZEROS  */
    bzero(dictVersion, 256);

 restart:
    /*  QUERY SERVER FOR DICTIONARY VERSION  */    
    if (send_simple_message(outPort, localPort, DICTVERSION,
			    SpeechIdentifier) != SEND_SUCCESS) {
	if ([self restartServer] == TTS_SERVER_RESTARTED)
	    goto restart;
	else
	    return((const char *)dictVersion);
    }

    /*  WAIT FOR DATA MESSAGE FROM SERVER  */
    if (receive_string_message(localPort, &message) != RCV_SUCCESS) {
	if ([self restartServer] == TTS_SERVER_RESTARTED)
	    goto restart;
	else
	    return((const char *)dictVersion);
    }

    /*  COPY DATA FROM MESSAGE IN dictVersion  */
    if (message.data != NULL)
	strcpy(dictVersion, message.data);

    /*  DEALLOCATE MEMORY USED TO RECEIVE MESSAGE FROM SERVER  */
    if (message.data != NULL)
	vm_deallocate(task_self(), (vm_address_t)message.data, strlen(message.data+2));

    /*  RETURN POINTER TO SERVER VERSION  */
    return((const char *)dictVersion);
}



/*  ERROR REPORTING METHODS  *************************************************/
- (const char *)errorMessage:(tts_error_t)errorNumber
{
    char *message;

    switch (errorNumber) {
      case TTS_SERVER_HUNG:         message = "Server hung";          break;
      case TTS_SERVER_RESTARTED:    message = "Server restarted";     break;
      case TTS_OK:                  message = "No error";             break;
      case TTS_OUT_OF_RANGE:        message = "Out of range";         break;
      case TTS_SPEAK_QUEUE_FULL:    message = "Speak Queue full";     break;
      case TTS_PARSE_ERROR:         message = "Parse error";          break;
      case TTS_ALREADY_PAUSED:      message = "Already paused";       break;
      case TTS_UTTERANCE_ERASED:    message = "Utterance erased";     break;
      case TTS_NO_UTTERANCE:        message = "No utterance";         break;
      case TTS_NO_FILE:             message = "No file";              break;
      case TTS_WARNING:             message = "Warning";              break;
      case TTS_ILLEGAL_STREAM:      message = "Illegal stream";       break;
      case TTS_INVALID_PATH:        message = "Invalid path";         break;
      case TTS_OBSOLETE_SERVER:     message = "Obsolete server";      break;
      case TTS_DSP_TOO_SLOW:        message = "DSP too slow";         break;
      case TTS_SAMPLE_RATE_TOO_LOW: message = "Sample rate too low";  break;
      default:                      message = "Unknown error";        break;
    }

    return((const char *)message);
}



/*  ARCHIVING METHODS  *******************************************************/

- read:(NXTypedStream *)stream
{
    int archivedVersion;

    /*  MESSAGE SUPER  */
    [super read:stream];

    /*  GET THE VERSION NUMBER OF THE ARCHIVED TTS INSTANCE  */
    archivedVersion = NXTypedStreamClassVersion(stream, [[self class] name]);

    if (archivedVersion == 0) {    /*  OLD VERSION  */
	/*  OBSOLETE IVARS  */
	int elasticity;
	id  syncMessagesDestination;
        SEL syncMessagesSelector;
        int syncMessages;
	int syncRate;
	id  realTimeMessagesDestination;
	SEL realTimeMessagesSelector;
	int realTimeMessages;

	/*  READ ALL INSTANCE VARIABLES FROM STREAM, EXCEPT ID, PORT NAMES, MEMORY  */
	NXReadTypes(stream, "fiiifff", &speed, &elasticity, &intonation,
		    &voiceType, &pitchOffset, &volume, &balance);
	NXReadArray(stream, "s", 4, dictionaryOrder);
	NXReadArray(stream, "c", MAXPATHLEN, appDictPath);
	NXReadArray(stream, "c", MAXPATHLEN, userDictPath);
	NXReadType(stream, "c", &escapeCharacter);
	NXReadType(stream, "i", &block);
	syncMessagesDestination = NXReadObject(stream);
	NXReadTypes(stream, ":ii", &syncMessagesSelector, &syncMessages, &syncRate);
	realTimeMessagesDestination = NXReadObject(stream);
	NXReadTypes(stream, ":i", &realTimeMessagesSelector, &realTimeMessages);
	
	/*  SET ADDED IVARS TO DEFAULT VALUES  */
        vtlOffset = TTS_VTL_OFFSET_DEF;
	breathiness = TTS_BREATHINESS_DEF;
	sampleRate = TTS_SAMPLE_RATE_DEF;
	channels = TTS_CHANNELS_DEF;
	softwareSynthesizer = 0;
    }
    else if (archivedVersion == TTS_CLASS_VERSION) {    /*  CURRENT VERSION  */
	NXReadTypes(stream, "fiffiiffff", &sampleRate, &channels, &balance,
		     &speed, &intonation, &voiceType, &pitchOffset, &vtlOffset,
		     &breathiness, &volume);
	NXReadArray(stream, "s", 4, dictionaryOrder);
	NXReadArray(stream, "c", MAXPATHLEN, appDictPath);
	NXReadArray(stream, "c", MAXPATHLEN, userDictPath);
	NXReadTypes(stream, "cii", &escapeCharacter, &block, &softwareSynthesizer);
    }

    /*  SET TEMPORARY MEMORY TO NULL OR ZERO-LENGTH STRING  */
    version[0] = '\0';
    dictVersion[0] = '\0';
    tts_p = NULL;
    tts_lp = NULL;
    streamMem = NULL;
    localBuffer = NULL;

    return self;
}



- write:(NXTypedStream *)stream
{
    /*  MESSAGE SUPER  */
    [super write:stream];

    /*  WRITE ALL INSTANCE VARIABLES TO STREAM, EXCEPT EXCEPT IDS, PORT NAMES, MEMORY  */
    NXWriteTypes(stream, "fiffiiffff", &sampleRate, &channels, &balance,
		 &speed, &intonation, &voiceType, &pitchOffset, &vtlOffset,
		 &breathiness, &volume);
    NXWriteArray(stream, "s", 4, dictionaryOrder);
    NXWriteArray(stream, "c", MAXPATHLEN, appDictPath);
    NXWriteArray(stream, "c", MAXPATHLEN, userDictPath);
    NXWriteTypes(stream, "cii", &escapeCharacter, &block, &softwareSynthesizer);
    
    return self;
}



- awake
{
    /*  MESSAGE SUPER  */
    [super awake];

    /*  CONNECT TO SERVER, RETURNING NIL IF CONNECTION NOT POSSIBLE  */
    if ([self ConnectToServer] == nil)
	return(nil);

    /*  SET VARIABLES IN SERVER USING INSTANCE VARIABLES  */
    [self setServerToInstanceVariables];

    return self;
}

@end

/*  IMPORTED HEADER FILES  ***********************************************/
#import "TextToSpeech.h"
#import "SpeechMessages.h"
#import "MessageStructs.h"
#import "Messages.h"
#import <stdio.h>
#import <strings.h>
#import <stdlib.h>
#import <ctype.h>
#import <sys/file.h>
#import <libc.h>
#import <sys/param.h>
#import <mach.h>
#import <mach_error.h>
#import <servers/netname.h>
#import <defaults.h>
#import <appkit/Application.h>
#import <appkit/nextstd.h>



/*  LOCAL DEFINES  *******************************************************/
#define TTS_SUCCESS        0
#define TTS_FAILURE        (-1)
#define TTS_NO_KILL        0
#define TTS_KILL           1

#define STRINGIFY(s) STR(s)
#define STR(s) #s

#define POLL_REPEAT_COUNT  2000




@implementation TextToSpeech

/*************************************************************************/
/************************  OBJECTIVE C METHODS  **************************/
/*************************************************************************/


/*  INTERNAL METHODS  ****************************************************/

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

    /*  IF SERVER RUNNING, CONNECT TO SPEECH PORT, ELSE START SERVER, AND THEN CONNECT  */
    /*  IF KILL OPTION, THEN GO INTO LAUNCH WITHOUT CHECKING NETNAME SERVER  */
    if (killOldServer ||
	    (netname_look_up(name_server_port,"",SPEECH_PORT_NAME,&outPort) != NETNAME_SUCCESS)) {
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
	    port_deallocate(task_self(),localPort);

	    /*  LOOK IN ROOT'S DEFAULT DATABASE FOR SYSTEM PATH  */
	    NXSetDefaultsUser(TTS_NXDEFAULT_ROOT_USER);
	    if ((systemPathPtr = NXReadDefault(TTS_NXDEFAULT_OWNER,TTS_NXDEFAULT_SYSTEM_PATH))==NULL) {
		NXLogError("TTS client:  Could not find systemPath in root's defaults database.");
		exit(TTS_FAILURE);
	    }
	    
	    /*  CREATE COMPLETE PATHNAME FOR SERVER  */
	    sprintf(serverPath,"%s/%s",systemPathPtr,TTS_SERVER_NAME);
	    
	    /*  MAKE SURE SERVER IS EXECUTABLE  */
	    if (access(serverPath,X_OK)) {
		NXLogError("TTS client:  TTS_Server not found or not executable.");
		exit(TTS_FAILURE);
	    }

	    /*  OVERLAY PROCESS SPACE WITH SERVER IMAGE  */
	    execl(serverPath,TTS_SERVER_NAME,0);
	    /*  THESE ARE INVOKED ONLY IF execl FAILS  */
	    NXLogError("TTS client:  Cannot start TTS_Server (execl error).");
	    _exit(TTS_FAILURE);

	    break;
	  default:   /*  PARENT  */
	    /*  GIVE SOME TIME TO ALLOW SERVER TO START UP  */
	    sleep(1);

#if 0
	    /*  CONNECT TO THE SPEECH PORT  */
	    if (netname_look_up(name_server_port,"",SPEECH_PORT_NAME,&outPort) != NETNAME_SUCCESS) {
		NXLogError("TTS client:  Cannot connect to TTS_Server.");
		return(TTS_FAILURE);
	    }
#endif
	    /*  POLL THE SPEECH PORT TO CONNECT  */
	    for (i = 0; i < POLL_REPEAT_COUNT; i++) {
		/*  RETURN ONCE CONNECTED TO THE SPEECH PORT  */
		if (netname_look_up(name_server_port,"",SPEECH_PORT_NAME,&outPort) == NETNAME_SUCCESS)
		    return(TTS_SUCCESS);
	    }

	    /*  IF HERE, NO CONNECTION COULD BE MADE IN A REASONABLE AMOUNT OF TIME  */
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
    if (send_simple_message(outPort, localPort, NEW_SPEAKER, 0) != SEND_SUCCESS) {
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
    if (send_int_message(outPort, localPort, SET_TASK_PORTS, SpeechIdentifier, (int)getpid())
                                                                                != SEND_SUCCESS) {
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
    [self setSpeed:speed];
    [self setElasticity:elasticity];
    [self setIntonation:intonation];
    /*  MAKE THIS ACTIVE ONCE THE METHOD IS IMPLEMENTED  */
    #if 0
    [self setVoiceType:voiceType];
    #endif
    [self setPitchOffset:pitchOffset];
    [self setVolume:volume];
    [self setBalance:balance];
    [self setDictionaryOrder:dictionaryOrder];
    [self setAppDictPath:appDictPath];
    [self setUserDictPath:userDictPath];
    [self setEscapeCharacter:escapeCharacter];
    [self setBlock:(BOOL)block];
    /*  MAKE THESE ACTIVE ONCE THE METHODS ARE IMPLEMENTED  */
    #if 0
    [self sendSyncMessagesTo:syncMessagesDestination:syncMessagesSelector];
    [self setSyncMessages:syncMessages]
    [self setSyncRate:syncRate];
    [self sendRealTimeMessagesTo:realTimeMessagesDestination:realTimeMessagesSelector];
    [self setRealTimeMessages:realTimeMessages];
    #endif

    return(self);
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

    return(self);
}



- (int)restartServer
{
    port_t tempPort;

    if (netname_look_up(name_server_port,"",SPEECH_PORT_NAME,&tempPort) != NETNAME_SUCCESS) {
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



/*  CREATING AND FREEING THE OBJECT  *************************************/

- init
{
    /*  STORAGE FOR NXDEFAULTS NAMES AND VALUES  */
    const NXDefaultsVector TextToSpeechDefaults = {
        {TTS_NXDEFAULT_SPEED,          STRINGIFY(TTS_SPEED_DEF)},
        {TTS_NXDEFAULT_ELASTICITY,     STRINGIFY(TTS_ELASTICITY_DEF)},
        {TTS_NXDEFAULT_INTONATION,     STRINGIFY(TTS_INTONATION_DEF)},
        {TTS_NXDEFAULT_VOICE_TYPE,     STRINGIFY(TTS_VOICE_TYPE_DEF)},
        {TTS_NXDEFAULT_PITCH_OFFSET,   STRINGIFY(TTS_PITCH_OFFSET_DEF)},
        {TTS_NXDEFAULT_VOLUME,         STRINGIFY(TTS_VOLUME_DEF)},
        {TTS_NXDEFAULT_BALANCE,        STRINGIFY(TTS_BALANCE_DEF)},
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

    /*  INITIALIZE INSTANCE VARIABLES (EXCEPT SpeechIdentifier) TO DEFAULTS  */
    speed = atof(NXGetDefaultValue(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_SPEED));
    elasticity = atoi(NXGetDefaultValue(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_ELASTICITY));
    intonation = strtol(NXGetDefaultValue(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_INTONATION),NULL,0);
    voiceType = atoi(NXGetDefaultValue(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_VOICE_TYPE));
    pitchOffset = atof(NXGetDefaultValue(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_PITCH_OFFSET));
    volume = atof(NXGetDefaultValue(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_VOLUME));
    balance = atof(NXGetDefaultValue(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_BALANCE));
    dictionaryOrder[0] = TTS_NUMBER_PARSER;
    dictionaryOrder[1] = TTS_USER_DICTIONARY;
    dictionaryOrder[2] = TTS_APPLICATION_DICTIONARY;
    dictionaryOrder[3] = TTS_MAIN_DICTIONARY;
    appDictPath[0] = '\0';
    strcpy(userDictPath,NXGetDefaultValue(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_USER_DICT_PATH));
    escapeCharacter = TTS_ESCAPE_CHARACTER_DEF;
    block = (int)NO;
    version[0] = '\0';
    dictVersion[0] = '\0';
    syncMessagesDestination = nil;
    syncMessagesSelector = NULL;
    syncMessages = 0;
    syncRate = TTS_SYNC_RATE_DEF;
    realTimeMessagesDestination = nil;
    realTimeMessagesSelector = NULL;
    realTimeMessages = 0;
    tts_p = NULL;
    tts_lp = NULL;
    streamMem = NULL;

    /*  SET VARIABLES IN SERVER USING INSTANCE VARIABLES  */
    /*  IF INSTANCE VARIABLE OUT OF RANGE, PUT LEGAL VALUE INTO DEFAULTS DATABASE  */
    if ([self setSpeed:speed] == TTS_OUT_OF_RANGE) {
	sprintf(defaultValue,"%.2f",speed);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_SPEED, defaultValue);
    }
    if ([self setElasticity:elasticity] == TTS_OUT_OF_RANGE) {
	sprintf(defaultValue,"%-d",elasticity);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_ELASTICITY, defaultValue);
    }
    if ([self setIntonation:intonation] == TTS_OUT_OF_RANGE) {
	sprintf(defaultValue,"0x%-x",intonation);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_INTONATION, defaultValue);
    }
    /*  MAKE THIS ACTIVE ONCE THE METHOD IS IMPLEMENTED  */
    #if 0
    if ([self setVoiceType:voiceType] == TTS_OUT_OF_RANGE) {
	sprintf(defaultValue,"%-d",voiceType);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_VOICE_TYPE, defaultValue);
    }
    #endif
    if ([self setPitchOffset:pitchOffset] == TTS_OUT_OF_RANGE) {
	sprintf(defaultValue,"%.2f",pitchOffset);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_PITCH_OFFSET, defaultValue);
    }
    if ([self setVolume:volume] == TTS_OUT_OF_RANGE) {
	sprintf(defaultValue,"%.2f",volume);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_VOLUME, defaultValue);
    }
    if ([self setBalance:balance] == TTS_OUT_OF_RANGE) {
	sprintf(defaultValue,"%.2f",balance);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_BALANCE, defaultValue);
    }
    [self setDictionaryOrder:dictionaryOrder];
    [self setAppDictPath:appDictPath];
    if ([self setUserDictPath:userDictPath] == TTS_NO_FILE) {
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_USER_DICT_PATH, userDictPath);
    }
    [self setEscapeCharacter:escapeCharacter];
    [self setBlock:(BOOL)block];

    /*  MAKE THESE ACTIVE ONCE THE METHODS ARE IMPLEMENTED  */
    #if 0
    [self sendSyncMessagesTo:syncMessagesDestination:syncMessagesSelector];
    [self setSyncMessages:syncMessages]
    [self setSyncRate:syncRate];
    [self sendRealTimeMessagesTo:realTimeMessagesDestination:realTimeMessagesSelector];
    [self setRealTimeMessages:realTimeMessages];
    #endif

    /*  RETURN ID OF SELF  */
    return(self);
}



- free
{
    /*  TELL SERVER WE ARE FINISHED WITH ITS SERVICES  */
    send_simple_message(outPort, localPort, CLOSE_SPEAKER, SpeechIdentifier);
    
    /*  DEALLOCATE LOCAL REPLY PORT  */
    port_deallocate(task_self(), localPort);

    /*  DEALLOCATE MEMORY FOR HIDDEN METHODS, IF NECESSARY  */
    if (tts_p != NULL)
	free(tts_p);

    if (tts_lp != NULL)
	free(tts_lp);

    if (streamMem != NULL)
	free(streamMem);

    /*  FREE SUPER OBJECT  */
    [super free];

    /*  RETURN NIL  */
    return(nil);
}



/*  VOICE QUALITY METHODS  ***********************************************/

- (int)setSpeed:(float)speedValue
{
    int error = TTS_OK;

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
    if (send_float_message(outPort, localPort, SET_SPEED, SpeechIdentifier, speedValue)
                                                                        != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (float)speed
{
    float_msg_t message;

    /*  QUERY SERVER FOR SPEED VALUE  */
    if (send_simple_message(outPort, localPort, GET_SPEED, SpeechIdentifier) != SEND_SUCCESS) {
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



- (int)setElasticity:(int)elasticityType
{
    int error = TTS_OK;

    /*  CHECK RANGE OF ARGUMENT  */
    if ( (elasticityType != TTS_ELASTICITY_VARIABLE) &&
	 (elasticityType != TTS_ELASTICITY_UNIFORM) ) {
	error = TTS_OUT_OF_RANGE;
	elasticityType = TTS_ELASTICITY_DEF;
    }

    /*  SET VALUE OF INSTANCE VARIABLE  */
    elasticity = elasticityType;

    /*  SET VALUE OF ELASTICITY IN THE SERVER  */
    if (send_int_message(outPort, localPort, SET_ELASTICITY, SpeechIdentifier, elasticityType)
                                                                                != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (int)elasticity
{
    int_msg_t message;

    /*  QUERY USER FOR ELASTICITY TYPE  */
    if (send_simple_message(outPort, localPort, GET_ELASTICITY, SpeechIdentifier)
                                                                   != SEND_SUCCESS) {
	[self restartServer];
	return(elasticity);
    }

    /*  AWAIT RETURN MESSAGE WITH REQUESTED DATA  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return(elasticity);
    }

    /*  SET INSTANCE VARIABLE WITH RETURNED VALUE  */
    elasticity = message.data;

    /*  RETURN VALUE OF ELASTICITY  */
    return(message.data);
}



- (int)setIntonation:(int)intonationMask
{
    int error = TTS_OK;

    /*  CHECK RANGE OF ARGUMENT  */
    if ( (intonationMask < TTS_INTONATION_NONE) || 
	 (intonationMask > TTS_INTONATION_ALL) ) {
	error = TTS_OUT_OF_RANGE;
	intonationMask = TTS_INTONATION_DEF;
    }

    /*  SET VALUE OF INSTANCE VARIABLE  */
    intonation = intonationMask;

    /*  SET VALUE OF INTONATION MASK IN THE SERVER  */
    if (send_int_message(outPort, localPort, SET_INTONATION, SpeechIdentifier, intonationMask)
                                                                                != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (int)intonation
{
    int_msg_t message;

    /*  QUERY USER FOR INTONATION  */
    if (send_simple_message(outPort, localPort, GET_INTONATION, SpeechIdentifier)
                                                                   != SEND_SUCCESS) {
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



- (int)setVoiceType:(int)voiceType
{
    [self notImplemented:_cmd];
    return(TTS_WARNING);
}



- (int)voiceType
{
    [self notImplemented:_cmd];
    return(TTS_WARNING);
}



- (int)setPitchOffset:(float)offsetValue
{
    int error = TTS_OK;

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
    if (send_float_message(outPort, localPort, SET_PITCH_OFFSET, SpeechIdentifier, offsetValue)
                                                                                 != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (float)pitchOffset
{
    float_msg_t message;
    
    /*  QUERY SERVER FOR PITCH OFFSET VALUE  */
    if (send_simple_message(outPort, localPort, GET_PITCH_OFFSET, SpeechIdentifier)
                                                                     != SEND_SUCCESS) {
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



- (int)setVolume:(float)volumeLevel
{
    int error = TTS_OK;
 
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
    if (send_float_message(outPort, localPort, SET_VOLUME, SpeechIdentifier, volumeLevel)
                                                                          != SEND_SUCCESS) 
	error = [self restartServer];
    
    return(error);
}



- (float)volume
{
    float_msg_t message;

    /*  QUERY SERVER FOR VOLUME VALUE  */
    if (send_simple_message(outPort, localPort, GET_VOLUME, SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return(volume);
    }
    
    /*  AWAIT FOR DATA MESSAGE FROM SERVER  */
    if (receive_float_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return(volume);
    }
    
    /*  SET INSTANCE VARIABLE WITH RETURNED VALUE  */
    volume = message.data;

    /*  RETURN VALUE OF VOLUME  */
    return(message.data);
}



- (int)setBalance:(float)balanceValue
{
    int error = TTS_OK;

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
    if (send_float_message(outPort, localPort, SET_BALANCE, SpeechIdentifier, balanceValue)
                                                                             != SEND_SUCCESS) 
	error = [self restartServer];
    
    return(error);
}



- (float)balance
{
    float_msg_t message;

    /*  QUERY SERVER FOR BALANCE VALUE  */
    if (send_simple_message(outPort, localPort, GET_BALANCE, SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return(balance);
    }
    
    /*  AWAIT FOR DATA MESSAGE FROM SERVER  */
    if (receive_float_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return(balance);
    }
    
    /*  SET INSTANCE VARIABLE WITH RETURNED VALUE  */
    balance = message.data;

    /*  RETURN VALUE OF BALANCE  */
    return(message.data);
}



/*  DICTIONARY CONTROL METHODS  ******************************************/

- (int)setDictionaryOrder:(const short *)order
{
    int i, j;
    char c_temp[4];
    int error = TTS_OK;

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
    if (send_int_message(outPort, localPort, SET_DICT_ORDER, SpeechIdentifier, *((int *)c_temp))
                                                                                  != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (const short *)dictionaryOrder
{
    int i;
    char *c_temp;
    int_msg_t message;

    /*  QUERY SERVER FOR DICTIONARY ORDER  */    
    if (send_simple_message(outPort, localPort, GET_DICT_ORDER, SpeechIdentifier)
                                                                   != SEND_SUCCESS) {
	[self restartServer];
	return((const short *)dictionaryOrder);
    }

    /*  AWAIT FOR DATA MESSAGE FROM SERVER  */
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




- (int)setAppDictPath:(const char *)path
{
    int error = TTS_OK;

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
    if (send_string_message(outPort, localPort, SET_APP_DICT, SpeechIdentifier, appDictPath)
                                                                              != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (const char *)appDictPath
{
    string_msg_t message;

    /*  INITIALIZE POINTER IN MESSAGE STRUCT TO NULL  */
    message.data = NULL;

    /*  QUERY SERVER FOR APPLICATION DICTIONARY PATH  */        
    if (send_simple_message(outPort, localPort, GET_APP_DICT, SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return((const char *)appDictPath);
    }

    /*  AWAIT FOR DATA MESSAGE FROM SERVER  */
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



- (int)setUserDictPath:(const char *)path
{
    int error = TTS_OK;

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
    if (send_string_message(outPort, localPort, SET_USER_DICT, SpeechIdentifier, userDictPath)
                                                                                != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (const char *)userDictPath
{
    string_msg_t message;

    /*  INITIALIZE POINTER IN MESSAGE STRUCT TO NULL  */
    message.data = NULL;

    /*  QUERY SERVER FOR USER DICTIONARY PATH NAME  */
    if (send_simple_message(outPort, localPort, GET_USER_DICT, SpeechIdentifier) != SEND_SUCCESS) {
	[self restartServer];
	return((const char *)userDictPath);
    }

    /*  AWAIT FOR DATA MESSAGE FROM SERVER  */
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



/*  TEXT INPUT METHODS  **************************************************/

- (int)speakText:(const char *)text
{
    int_msg_t message;
    int error = TTS_OK;

    /*  IF ZERO LENGTH STRING, RETURN IMMEDIATELY WITH ERROR CODE  */
    if (strlen(text) == 0)
	return(TTS_PARSE_ERROR);

 restart:
    /*  SEND STRING TO BE SPOKEN  */
    if (send_string_message(outPort,localPort,SPEAKTEXT, SpeechIdentifier, text) != SEND_SUCCESS) {
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



- (int)speakStream:(NXStream *)stream
{
    volatile int error;
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



- (int)setEscapeCharacter:(char)character
{
    int error = TTS_OK;

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
    if (send_int_message(outPort, localPort, SET_ESCAPE_CHAR, SpeechIdentifier, (int)character)
                                                                                 != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (char)escapeCharacter
{
    int_msg_t message;

    /*  QUERY SERVER FOR ESCAPE CHARACTER  */    
    if (send_simple_message(outPort, localPort, GET_ESCAPE_CHAR, SpeechIdentifier)
                                                                   != SEND_SUCCESS) {
	[self restartServer];
	return(escapeCharacter);
    }

    /*  AWAIT FOR DATA MESSAGE FROM SERVER  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return(escapeCharacter);
    }

    /*  SET VALUE OF INSTANCE VARIABLE  */
    escapeCharacter = (char)message.data;

    /*  RETURN VALUE OF ESCAPE CHARACTER  */
    return(escapeCharacter);
}



- (int)setBlock:(BOOL)flag
{
    int error = TTS_OK;

    /*  SET VALUE OF INSTANCE VARIABLE  */
    block = (int)flag;

    /*  SET VALUE IN THE SERVER  */
    if (send_int_message(outPort, localPort, SET_BLOCK, SpeechIdentifier, (int)flag)
	                                                               != SEND_SUCCESS) 
	error = [self restartServer];

    return(error);
}



- (BOOL)block
{
    int_msg_t message;

    /*  QUERY SERVER FOR ESCAPE CHARACTER  */    
    if (send_simple_message(outPort, localPort, GET_BLOCK, SpeechIdentifier)
                                                                   != SEND_SUCCESS) {
	[self restartServer];
	return((BOOL)block);
    }

    /*  AWAIT FOR DATA MESSAGE FROM SERVER  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS) {
	[self restartServer];
	return((BOOL)block);
    }

    /*  SET VALUE OF INSTANCE VARIABLE  */
    block = message.data;

    /*  RETURN VALUE OF BLOCK  */
    return((BOOL)block);
}



/*  REAL-TIME METHODS  ***************************************************/

- (int)pauseImmediately
{
    int_msg_t message;

    /*  SEND PAUSE CODE  */
    if (send_simple_message(outPort, localPort, PAUSEIMMED, SpeechIdentifier) != SEND_SUCCESS)
	return ([self restartServer]);

    /*  AWAIT RETURN CODE  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS)
	return ([self restartServer]);
    
    return(message.data);
}



- (int)pauseAfterCurrentWord
{
    [self notImplemented:_cmd];
    return(TTS_WARNING);
}



- (int)pauseAfterCurrentUtterance
{
    int_msg_t message;

    /*  SEND PAUSE CODE  */
    if (send_simple_message(outPort, localPort, PAUSEAFTERUTT, SpeechIdentifier) != SEND_SUCCESS)
	return([self restartServer]);
    
    /*  AWAIT RETURN CODE  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS)
	return ([self restartServer]);
    
    return(message.data);
}



- (int)continue
{
    int_msg_t message;

    /*  SEND CONTINUE CODE  */
    if (send_simple_message(outPort, localPort, CONTINUE, SpeechIdentifier) != SEND_SUCCESS)
	return ([self restartServer]);
    
    /*  AWAIT RETURN CODE  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS)
	return ([self restartServer]);
    
    return(message.data);
}



- (int)eraseAllSound
{
    int_msg_t message;

    /*  SEND ERASE CODE  */
    if (send_simple_message(outPort, localPort, ERASEALLSOUND, SpeechIdentifier) != SEND_SUCCESS)
	return ([self restartServer]);
    
    /*  AWAIT RETURN CODE  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS)
	return ([self restartServer]);
    
    return(message.data);
}



- (int)eraseAllWords
{
    [self notImplemented:_cmd];
    return(TTS_WARNING);
}



- (int)eraseCurrentUtterance
{
    int_msg_t message;

    /*  SEND ERASE CODE  */
    if (send_simple_message(outPort, localPort, ERASECURUTT, SpeechIdentifier) != SEND_SUCCESS)
	return ([self restartServer]);
    
    /*  AWAIT RETURN CODE  */
    if (receive_int_message(localPort, &message) != RCV_SUCCESS)
	return ([self restartServer]);
    
    return(message.data);
}



/*  SERVER VERSION METHODS  **********************************************/

- (const char *)serverVersion
{
    string_msg_t message;

    /*  INITIALIZE POINTER IN MESSAGE STRUCT TO NULL  */
    message.data = NULL;

    /*  INITIALIZE version TO ALL ZEROS  */
    bzero(version, 256);

 restart:
    /*  QUERY SERVER FOR SERVER VERSION  */    
    if (send_simple_message(outPort, localPort, VERSION, SpeechIdentifier) != SEND_SUCCESS) {
	if ([self restartServer] == TTS_SERVER_RESTARTED)
	    goto restart;
	else
	    return((const char *)version);
    }

    /*  AWAIT FOR DATA MESSAGE FROM SERVER  */
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
    if (send_simple_message(outPort, localPort, DICTVERSION, SpeechIdentifier) != SEND_SUCCESS) {
	if ([self restartServer] == TTS_SERVER_RESTARTED)
	    goto restart;
	else
	    return((const char *)dictVersion);
    }

    /*  AWAIT FOR DATA MESSAGE FROM SERVER  */
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



/*  SYNC MESSAGING METHODS  **********************************************/

- sendSyncMessagesTo:destinationObject:(SEL)aSelector
{
    [self notImplemented:_cmd];
    return(nil);
}

- syncMessagesDestination
{
    [self notImplemented:_cmd];
    return(nil);
}

- (SEL)syncMessagesSelector
{
    [self notImplemented:_cmd];
    return(NULL);
}

- (int)setSyncRate:(int)rate
{
    [self notImplemented:_cmd];
    return(TTS_WARNING);
}

- (int)syncRate
{
    [self notImplemented:_cmd];
    return(TTS_WARNING);
}

- setSyncMessages:(BOOL)flag
{
    [self notImplemented:_cmd];
    return(0);
}

- (BOOL)syncMessages
{
    [self notImplemented:_cmd];
    return(TTS_WARNING);
}



/*  REAL-TIME MESSAGING METHODS  *****************************************/

- sendRealTimeMessagesTo:destinationObject:(SEL)aSelector
{
    [self notImplemented:_cmd];
    return(nil);
}

- realTimeMessagesDestination
{
    [self notImplemented:_cmd];
    return(nil);
}

- (SEL)realTimeMessagesSelector
{
    [self notImplemented:_cmd];
    return(NULL);
}

- setRealTimeMessages:(BOOL)flag
{
    [self notImplemented:_cmd];
    return(nil);
}

- (BOOL)realTimeMessages
{
    [self notImplemented:_cmd];
    return(0);
}



/*  ARCHIVING METHODS  ***************************************************/

- read:(NXTypedStream *)stream
{
    /*  MESSAGE SUPER  */
    [super read:stream];

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
    
    return(self);
}



- write:(NXTypedStream *)stream
{
    /*  MESSAGE SUPER  */
    [super write:stream];

    /*  WRITE ALL INSTANCE VARIABLES TO STREAM, EXCEPT EXCEPT ID, PORT NAMES, MEMORY  */
    NXWriteTypes(stream, "fiiifff", &speed, &elasticity, &intonation,
		 &voiceType, &pitchOffset, &volume, &balance);
    NXWriteArray(stream, "s", 4, dictionaryOrder);
    NXWriteArray(stream, "c", MAXPATHLEN, appDictPath);
    NXWriteArray(stream, "c", MAXPATHLEN, userDictPath);
    NXWriteType(stream, "c", &escapeCharacter);
    NXWriteType(stream, "i", &block);
    NXWriteObjectReference(stream, syncMessagesDestination);
    NXWriteTypes(stream, ":ii", &syncMessagesSelector, &syncMessages, &syncRate);
    NXWriteObjectReference(stream, realTimeMessagesDestination);
    NXWriteTypes(stream, ":i", &realTimeMessagesSelector, &realTimeMessages);
    
    return(self);
}



- awake
{
    /*  MESSAGE SUPER  */
    [super awake];

    /*  SET MEMORY TO NULL OR ZERO-LENGTH STRING  */
    version[0] = '\0';
    dictVersion[0] = '\0';
    tts_p = NULL;
    tts_lp = NULL;
    streamMem = NULL;

    /*  CONNECT TO SERVER, RETURNING NIL IF CONNECTION NOT POSSIBLE  */
    if ([self ConnectToServer] == nil)
	return(nil);

    /*  SET VARIABLES IN SERVER USING INSTANCE VARIABLES  */
    [self setServerToInstanceVariables];

    return self;
}



/*  OVERRIDDEN METHODS  **************************************************/

- notImplemented:(SEL)aSelector
{
    /*  TELL SERVER WE ARE FINISHED WITH ITS SERVICES  */
    send_simple_message(outPort, localPort, CLOSE_SPEAKER, SpeechIdentifier);
    
    /*  DEALLOCATE LOCAL REPLY PORT  */
    port_deallocate(task_self(), localPort);

    /*  DEALLOCATE MEMORY FOR HIDDEN METHODS, IF NECESSARY  */
    if (tts_p != NULL)
	free(tts_p);

    if (tts_lp != NULL)
	free(tts_lp);

    if (streamMem != NULL)
	free(streamMem);

    /*  DO NORMAL SUPER METHOD (CALLS error: AND ABORTS)  */
    [super notImplemented:aSelector];

    return self;
}



@end

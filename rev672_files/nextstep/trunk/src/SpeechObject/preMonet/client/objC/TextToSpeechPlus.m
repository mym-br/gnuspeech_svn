/*  IMPORTED HEADER FILES  ***********************************************/
#import <strings.h>
#import <stdlib.h>
#import "TextToSpeechPlus.h"
#import "SpeechMessages.h"
#import "MessageStructs.h"
#import "Messages.h"


/*  LOCAL DEFINES  *******************************************************/
#define TTS_P_SIZE         1024
#define TTS_LP_SIZE        8192



@implementation TextToSpeech(TextToSpeechPlus)


/*  HIDDEN METHODS  ******************************************************/

- (const char *)pronunciation:(const char *)word:(short *)dict:(int)password
{
    string_msg_t message;

    /*  INITIALIZE POINTER IN MESSAGE STRUCT TO NULL  */
    message.data = NULL;

    /*  INITIALIZE dict TO ZERO  */
    *dict = 0;
	
    /*  ALLOCATE MEMORY FOR PRONUNCIATION, IF NECESSARY (DONE ONLY ONCE)  */
    if (tts_p == NULL)
	tts_p = (char *)malloc(TTS_P_SIZE);

    /*  INITIALIZE MEMORY TO ALL ZEROS  */
    bzero(tts_p, TTS_P_SIZE);

    /*  GET PRON. ONLY IF PROPER PASSWORD, WORD EXISTS, LENGTH MAX IS 100  */
    if ((password == 0xdeafbabe) && (strlen(word) > 0) && (strlen(word) <= 100)) {
      restart:
	/*  QUERY SERVER FOR PRONUNCIATION  */
	if (send_string_message(outPort, localPort, GET_PRON, SpeechIdentifier, word)
	                                                              != SEND_SUCCESS) {
	    if ([self restartServer] == TTS_SERVER_RESTARTED)
		goto restart;
	    else
		return((const char *)tts_p);
	}

	/*  WAIT FOR RETURN MESSAGE FROM SERVER  */
	if (receive_string_message(localPort, &message) != RCV_SUCCESS) {
	    if ([self restartServer] == TTS_SERVER_RESTARTED)
		goto restart;
	    else
		return((const char *)tts_p);
	}

	/*  COPY DATA FROM REPLY MESSAGE TO LOCAL BUFFER  */
	if (message.data != NULL)
	    strncpy(tts_p, message.data, (TTS_P_SIZE-1));

	/*  FREE MEMORY USED TO RECEIVE MESSAGE DATA  */
	if (message.data != NULL)
	    vm_deallocate(task_self(), (vm_address_t)message.data, strlen(message.data+2));

	/*  FIRST BYTE INDICATES WHICH DICTIONARY PRONUNCIATION FOUND IN  */
	*dict = (short)tts_p[0];
    }

    /*  RETURN POINTER TO PRONUNCIATION  */
    return((const char *)&(tts_p[1]));
}



- (const char *)linePronunciation:(const char *)line:(int)password
{
    string_msg_t message;
    int_msg_t acknowledge;

    /*  INITIALIZE POINTER IN MESSAGE STRUCT TO NULL  */
    message.data = NULL;

    /*  ALLOCATE MEMORY FOR PRONUNCIATION, IF NECESSARY (DONE ONLY ONCE)  */
    if (tts_lp == NULL)
	tts_lp = (char *)malloc(TTS_LP_SIZE);

    /*  INITIALIZE MEMORY TO ALL ZEROS  */
    bzero(tts_lp, TTS_LP_SIZE);

    /*  RETRIEVE PRONUNCIATION ONLY IF PROPER PASSWORD GIVEN, AND LINE EXISTS  */
    if ((password == 0xdeafbabe) && (strlen(line) > 0)) {
      restart:
	/*  QUERY SERVER FOR PRONUNCIATION  */
	if (send_string_message(outPort, localPort, GET_LINE_PRON, SpeechIdentifier, line)
	                                                                   != SEND_SUCCESS) {
	    if ([self restartServer] == TTS_SERVER_RESTARTED)
		goto restart;
	    else
		return((const char *)tts_lp);
	}

	/*  WAIT FOR IMMEDIATE ACKNOWLEDGE  */
	if (receive_int_message(localPort, &acknowledge) != RCV_SUCCESS) {
	    if ([self restartServer] == TTS_SERVER_RESTARTED)
		goto restart;
	    else
		return((const char *)tts_lp);
	}

	/*  WAIT FOR RETURN MESSAGE FROM SERVER (WITH LONG TIME OUT)  */
	if (receive_string_message_long(localPort, &message) != RCV_SUCCESS) {
		return((const char *)tts_lp);
	}

	/*  COPY DATA FROM REPLY MESSAGE TO LOCAL BUFFER  */
	if (message.data != NULL)
	    strncpy(tts_lp, message.data, (TTS_LP_SIZE-1));

	/*  FREE MEMORY USED TO RECEIVE MESSAGE DATA  */
	if (message.data != NULL)
	    vm_deallocate(task_self(), (vm_address_t)message.data, strlen(message.data+2));
    }

    /*  RETURN POINTER TO PRONUNCIATION  */
    return((const char *)tts_lp);
}



@end

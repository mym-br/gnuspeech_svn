/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:54 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/SpeechObject/preMonet/objc.old/TextToSpeechRhythm.m,v $
$State: Exp $


$Log: not supported by cvs2svn $

******************************************************************************/

/*  IMPORTED HEADER FILES  ***************************************************/
#import <strings.h>
#import <stdlib.h>
#import <mach/message.h>
#import "TextToSpeechRhythm.h"
#import "SpeechMessages.h"
#import "MessageStructs.h"
#import "Messages.h"



@implementation TextToSpeech(TextToSpeechRhythm)

/*  HIDDEN METHODS  **********************************************************/

- (char *) getRhythmInfo:(const char *) text
{
char *temp;
int length, retValue;
string_msg_t message;

	/* Make request to Server and wait for a reply */
	send_string_message(outPort, localPort, GET_RHYTHM, SpeechIdentifier, text);
	retValue = receive_string_message(localPort, &message);
	while (retValue == RCV_TIMED_OUT)
		retValue = receive_string_message(localPort, &message);

	/* If there is a valid reply, copy it and return the pointer, otherwise return NULL */
	length = strlen(message.data);
	if (length)
	{
		temp = (char *) malloc(strlen(message.data)+2);
		strcpy(temp, message.data);
	}
	else 
		temp = NULL;

	/* Deallocate out of line memory */
	vm_deallocate(task_self(), (vm_address_t)message.data, strlen(message.data+2));

	return(temp);
}

@end

/*  IMPORTED HEADER FILES  ***********************************************/
#import <strings.h>
#import <stdlib.h>
#import <mach/message.h>
#import "TextToSpeechRhythm.h"
#import "SpeechMessages.h"
#import "MessageStructs.h"
#import "Messages.h"


/*  LOCAL DEFINES  *******************************************************/


@implementation TextToSpeech(TextToSpeechDemo)

/*  HIDDEN METHODS  ******************************************************/
- (unsigned int) registeredHostId
{
unsigned int regHostId;
int_msg_t message;

	send_simple_message(outPort, localPort, GET_REGHOST, SpeechIdentifier);
	receive_int_message(localPort, &message);
	regHostId = (unsigned int) message.data;
	return regHostId;
}

- (unsigned int) demoMode
{
unsigned int mode;
int_msg_t message;

	send_simple_message(outPort, localPort, GET_DEMOMODE, SpeechIdentifier);
	receive_int_message(localPort, &message);
	mode = (unsigned int) message.data;
	return mode;
}

- (unsigned int) expiryDate
{
unsigned int expDate;
int_msg_t message;

	send_simple_message(outPort, localPort, GET_EXPIRYDATE, SpeechIdentifier);
	receive_int_message(localPort, &message);
	expDate = (unsigned int) message.data;
	return expDate;
}
@end

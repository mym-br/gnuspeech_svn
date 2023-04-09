/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:53 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/SpeechObject/postMonet/objC.monet/TextToSpeechPriority.m,v $
$State: Exp $


$Log: not supported by cvs2svn $

******************************************************************************/

/*  IMPORTED HEADER FILES  ***************************************************/
#import <strings.h>
#import <stdlib.h>
#import <mach/message.h>
#import <mach/policy.h>
#import <bsd/libc.h>
#import "TextToSpeechPriority.h"
#import "SpeechMessages.h"
#import "MessageStructs.h"
#import "Messages.h"



@implementation TextToSpeech(TextToSpeechPriority)

/*  HIDDEN METHODS  **********************************************************/

- (int) getPriority
{
int_msg_t message;

	if (send_simple_message(outPort, localPort, GETPRIORITY, SpeechIdentifier) != SEND_SUCCESS)
		return (-1);
	else
		receive_int_message(localPort, &message);

	return (message.data);
}

- setPriority: (int) newPriority
{
	if (newPriority > 24) 
		newPriority = 24;
	else
	if (newPriority < 0)
		newPriority = 0;

	send_int_message(outPort, localPort, SETPRIORITY, SpeechIdentifier, newPriority);
	return self;
}

- (int) getQuantum
{
int_msg_t message;

	if (send_simple_message(outPort, localPort, GETQUANTUM, SpeechIdentifier) != SEND_SUCCESS)
		return (-1);
	else
		receive_int_message(localPort, &message);

	return (message.data);
}

- setQuantum: (int) newQuantum
{
	if (newQuantum > 350) 
		newQuantum = 350;
	else
	if (newQuantum < 15)		/* 15 is min quantum value */
		newQuantum = 15;

	send_int_message(outPort, localPort, SETQUANTUM, SpeechIdentifier, newQuantum);
	return self;
}

- (int) getPolicy
{
int_msg_t message;

	if (send_simple_message(outPort, localPort, GETPOLICY, SpeechIdentifier) != SEND_SUCCESS)
		return (-1);
	else
		receive_int_message(localPort, &message);

	return (message.data);
}

- setPolicy: (int) newPolicy
{
	if ( (newPolicy!=POLICY_FIXEDPRI) && (newPolicy!=POLICY_TIMESHARE))
		newPolicy = POLICY_TIMESHARE;

	send_int_message(outPort, localPort, SETPOLICY, SpeechIdentifier, newPolicy);

	return self;
}

- (int) getSilencePrefill
{
int_msg_t message;

	if (send_simple_message(outPort, localPort, GETPREFILL, SpeechIdentifier) != SEND_SUCCESS)
		return (-1);
	else
		receive_int_message(localPort, &message);

	return (message.data);
}

- setSilencePrefill:(int) newPrefill
{
	if (newPrefill > 5) 
		newPrefill = 5;
	else
	if (newPrefill < 1)		/* Must have at least 1 prefill silence. */
		newPrefill = 1;

	send_int_message(outPort, localPort, SETPREFILL, SpeechIdentifier, newPrefill);
	return self;
}

- (int) serverPID
{
int_msg_t message;

	if (send_simple_message(outPort, localPort, SERVERPID, SpeechIdentifier) != SEND_SUCCESS)
		return (-1);
	else
		receive_int_message(localPort, &message);

	return (message.data);
}

- inactiveServerKill:(BOOL) killFlag
{
	send_int_message(outPort, localPort, INACTIVEKILL, SpeechIdentifier, (int) killFlag);
	return self;
}

- (BOOL) inactiveKillQuery
{
int_msg_t message;

	if (send_simple_message(outPort, localPort, KILLQUERY, SpeechIdentifier) != SEND_SUCCESS)
		return (FALSE);
	else
		receive_int_message(localPort, &message);
	
	return ( (BOOL) message.data);
}

- requestServerRestart
{
	if (send_simple_message(outPort, localPort, RESTARTSERVER, SpeechIdentifier) != SEND_SUCCESS)
		return self;
	else
	{
		sleep(1);
		[self restartServer];
	}
	return self;
}

@end

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
#import <appkit/nextstd.h>

#include "MessageStructs.h"
#include "SpeechMessages.h"

port_t SpeechPort;

static char file_id[] = "@(#)Server Engine.  Author: Craig-Richard Schock. (C) Trillium, 1991, 1992.";

void	init_server();
int	poll_port();
void	close_port();

/*===========================================================================

This file was created June 18, 1991.

	This file is the compilation of previous code used in testing and
	the pronunciation daemon.  This file provides to the speech daemon
	programmer the low level messaging functions.  All receiving, 
	sending, enqueueing and dequeueing of messages is taken care of in
	this file and the file server_handler.c.

	The initial version of this file will not communicate with the main
	calculation thread, but this will soon have to be implemented.


===========================================================================*/


/*===========================================================================

	Function: init_server()

	Purpose: This function initializes the incoming port by which the 
		speech daemon will receive messages from user programs.

	Algorithm: This function allocated a port and then checks it in
		with the name server under the name "SpeechPort".

	Errors:  If a port cannot be allocated or if it cannot be 
		checked-in with the name server, a fatal error occurs. 
		The system documentation does not explain why such errors
		can occur, so corrective action cannot take place.

===========================================================================*/

void init_server()
{
kern_return_t error;

	/* Open port */
	if ((error = port_allocate(task_self(),&SpeechPort))!=KERN_SUCCESS)
	{
		mach_error("port_allocate failed", error); 
		exit(1);
	}

	/* Check port in with name server */
	error = netname_check_in(name_server_port, SPEECH_PORT_NAME, PORT_NULL, SpeechPort);
	if (error!=NETNAME_SUCCESS)
	{
		mach_error("netname_check_in failed", error); 
		exit(1);
	}		
}

/*
	Function: kill_servers()
	Purpose: Kill any multiple copies of the Text To Speech server which are 
		currently running.  (Except self).

*/
static inline char *dindex(char *buf, char *string);

kill_servers()
{
FILE            *fin;
char            buf[BUFSIZ];
int             pid;
int             mypid;
int             itspid;
int             n;
static char     *ps = "exec /bin/ps -ax";
static char	*name = "TTS_Server";

	if ((fin = popen(ps, "r")) == NULL) 
	{
		fprintf(stderr, "can't run %s\n", ps);
		return(1);
	}
	mypid = getpid();
	fgets(buf, BUFSIZ, fin);

	while (fgets(buf, BUFSIZ, fin) != NULL)
	{
		sscanf(buf, "%d", &pid);
		if ((pid != mypid) && (dindex(buf, name) != NULL))
			kill(pid, SIGKILL);
	}
	return(0);
}

static inline char *dindex(char *buf, char *string)
{
int len = strlen(string);

	for (; *buf; buf++)
		if (strncmp(buf, string, len) == 0)
			return (buf);
		return (NULL);
}




/*===========================================================================

	Function: poll_port()

	Purpose: This function gets a message from the message port (if one
		exists) and performs whatever task is necessary given the
		message.  Messages are defined in the file "SpeechMessages.h".

	Algorithm: This function calls msg_receive with a timeout of 0.0.
		(i.e. if no message is present, msg_receive will return 
		immediately).  Messages are then dispatched by the msg_id
		field in the message header.

===========================================================================*/
poll_port(block)
int block;
{
struct string_msg msg_header;			/* Incoming and reply messages */
msg_return_t ret_value;				/* msg_send and msg_receive return values */
int return_value = 0;
unsigned short *temp, *temp1;

	/* Receive message from port */
	msg_header.h.msg_local_port = SpeechPort;
	msg_header.h.msg_size = sizeof(struct string_msg)+100;
	if (block == TRUE)
		ret_value = msg_receive((msg_header_t *) &msg_header, MSG_OPTION_NONE, (msg_timeout_t) 0);
	else
		ret_value = msg_receive((msg_header_t *) &msg_header, RCV_TIMEOUT, (msg_timeout_t) 0);
	/* check and see if message has been received OK */
	if (ret_value == RCV_SUCCESS)
	{
		/* Act upon msg_id in message header */
		temp1 = temp = (unsigned short *) &msg_header.h.msg_id;
		(temp1++);
		switch(*temp)
		{
			/* Messages from 0-9 */
			case NEW_SPEAKER: 	/* New Speaker request */
				new_speaker(&msg_header, (int)(*temp1));
				break;
			case CLOSE_SPEAKER: 	/* Close Speaker Request */
				close_speaker(&msg_header, (int)(*temp1));
				break;
			case SET_TASK_PORTS: 	/* Set Task Variables */
				set_task_ports(&msg_header, (int)(*temp1));
				break;
			case DIAGNOSIS: 	/* Return a diagnostic */
				diagnosis(&msg_header, (int)(*temp1));
				break;
			case SERVER_HUP: 	/* Respond to HUP signal */
				server_hup(&msg_header, (int)(*temp1));
				break;

			/* Messages from 10-19 */
			case SET_APP_DICT: 	/* New Speaker request */
				set_app_dict(&msg_header, (int)(*temp1));
				break;
			case SET_USER_DICT: 	/* New Speaker request */
				set_user_dict(&msg_header, (int)(*temp1));
				break;
			case SET_SPEED:		/* Set speed */
				setspeed(&msg_header, (int)(*temp1));
				break;
			case SET_VOLUME:		/* Set volume */
				setvolume(&msg_header, (int)(*temp1));
				break;
			case SET_ERROR_PORT: 	/* Set error port */
				set_error_port(&msg_header, (int)(*temp1));
				break;
			case SET_DICT_ORDER: 	/* Set Dictionary Order */
				set_dict_order(&msg_header, (int)(*temp1));
				break;
			case SET_ESCAPE_CHAR: 	/* Set Escape Character */
				set_escape_char(&msg_header, (int)(*temp1));
				break;
			case SET_ELASTICITY: 	/* Set Elasticity */
		                set_elasticity(&msg_header, (int)(*temp1));
				break;
			case SET_INTONATION: 	/* Set Intonation */
                		set_intonation(&msg_header, (int)(*temp1));
				break;
			case SET_PITCH_OFFSET: 	/* Set Pitch Offset */
		                set_pitch_offset(&msg_header, (int)(*temp1));
				break;
			case SET_BALANCE: 	/* Set Balance */
                		set_balance(&msg_header, (int)(*temp1));
				break;
			case SET_BLOCK: 	/* Set Balance */
                		set_block(&msg_header, (int)(*temp1));
				break;

			/* Messages from 20-29 */
			case GET_APP_DICT:		/* Return current speed */
				get_app_dict(&msg_header, (int)(*temp1));
				break;
			case GET_USER_DICT:		/* Return current Volume */
				get_user_dict(&msg_header, (int)(*temp1));
				break;
			case GET_SPEED:		/* Return current speed */
				speed(&msg_header, (int)(*temp1));
				break;
			case GET_VOLUME:		/* Return current Volume */
				volume(&msg_header, (int)(*temp1));
				break;
			case GET_DICT_ORDER:	/* Return current speed */
				get_dict_order(&msg_header, (int)(*temp1));
				break;
			case GET_PRON:		/* Return current Volume */
				get_pron(&msg_header, (int)(*temp1));
				break;
			case GET_ESCAPE_CHAR:	/* Return escape char. */
				get_escape_char(&msg_header, (int)(*temp1));
				break;
			case GET_LINE_PRON:	/* Return Pronunciation for a line */
                		get_line_pron(&msg_header, (int)(*temp1));
				break;
			case GET_ELASTICITY:	/* Return Elasticity. */
		                get_elasticity(&msg_header, (int)(*temp1));
				break;
			case GET_INTONATION:	/* Return intonation. */
                		get_intonation(&msg_header, (int)(*temp1));
				break;
			case GET_PITCH_OFFSET:	/* Return Pitch offset. */
		                get_pitch_offset(&msg_header, (int)(*temp1));
				break;
			case GET_BALANCE:	/* Return Balance. */
		                get_balance(&msg_header, (int)(*temp1));
				break;
			case GET_BLOCK: 	/* Set Balance */
                		get_block(&msg_header, (int)(*temp1));
				break;
			case GET_RHYTHM: 	/* Set Balance */
                		get_rhythm(&msg_header, (int)(*temp1));
				break;
			case GET_REGHOST: 	/* Get Registered Host */
                		get_reghost(&msg_header, (int)(*temp1));
				break;
			case GET_DEMOMODE: 	/* Get Demo Mode */
                		get_demomode(&msg_header, (int)(*temp1));
				break;
			case GET_EXPIRYDATE: 	/* Get Expiry date for demo */
                		get_expiry_date(&msg_header, (int)(*temp1));
				break;

			/* Messages from 30-39 */
			case PAUSEIMMED:	/* Pause immediately */
				server_pause(&msg_header, (int)(*temp1));
				break;
			case PAUSEAFTERWORD:	/* Pause after next word */
				break;
			case PAUSEAFTERUTT:	/* Pause after current utterance */
				pauseafterutt(&msg_header, (int)(*temp1));
				break;
			case CONTINUE:		/* Continue from pause */
				scontinue(&msg_header, (int)(*temp1));
				break;
			case ERASEALLSOUND:	/* Erase current buffers */
				eraseallsound(&msg_header, (int)(*temp1));
				break;
			case SPEAKTEXT:		/* Speak this text */
				speaktext(&msg_header, (int)(*temp1));
				break;
			case ERASECURUTT:	/* Erase current buffers */
				erasecurutt(&msg_header, (int)(*temp1));
				break;
			case VERSION:		/* What is the version of the server? */
				version(&msg_header, (int)(*temp1));
				break;
			case DICTVERSION:	/* What is the version of the Dictionary? */
				dictversion(&msg_header, (int)(*temp1));
				break;
			case SPEAKTEXTTOFILE:	/* Speech output to file */
				speaktexttofile(&msg_header, (int)(*temp1));
				break;

			case SETPRIORITY:
				set_priority(&msg_header, (int)(*temp1));
				break;
			case GETPRIORITY:
				get_priority(&msg_header, (int)(*temp1));
				break;
			case SETQUANTUM:
				set_quantum(&msg_header, (int)(*temp1));
				break;
			case GETQUANTUM:
				get_quantum(&msg_header, (int)(*temp1));
				break;

			case SETPREFILL:
				set_prefill(&msg_header, (int)(*temp1));
				break;
			case GETPREFILL:
				get_prefill(&msg_header, (int)(*temp1));
				break;
			case SETPOLICY:
				set_policy(&msg_header, (int)(*temp1));
				break;
			case GETPOLICY:
				get_policy(&msg_header, (int)(*temp1));
				break;

			case SERVERPID:
				server_pid(&msg_header, (int)(*temp1));
				break;
			case INACTIVEKILL:
				inactive_kill(&msg_header, (int)(*temp1));
				break;
			case KILLQUERY:
				kill_query(&msg_header, (int)(*temp1));
				break;
			case RESTARTSERVER:
				restart_server(&msg_header, (int)(*temp1));
				break;

			default: NXLogError("Unknown message to server: %d", (int)(*temp));
				 break;
		}
		return_value = 1;
	}
	else
		switch(ret_value)
		{
			case RCV_INVALID_MEMORY:
/*				fprintf(stderr,"RCV_INVALID_MEMORY\n");*/
				break;
			case RCV_INVALID_PORT:
/*				fprintf(stderr,"RCV_INVALID_PORT\n");*/
				break;
			case RCV_TOO_LARGE:
/*				fprintf(stderr,"RCV_TOO_LARGE\n");*/
				break;
			case RCV_NOT_ENOUGH_MEMORY:
/*				fprintf(stderr,"RCV_NOT_ENOUGH_MEMORY\n");*/
				break;
			case RCV_TIMED_OUT:
/*				fprintf(stderr,"RCV_TIMED_OUT\n");*/
				break;
			case RCV_INTERRUPTED:
/*				fprintf(stderr,"RCV_INTERRUPTED\n");*/
				break;
			case RCV_PORT_CHANGE:
/*				fprintf(stderr,"RCV_PORT_CHANGE\n");*/
				break;
			default: fprintf(stderr,"Huh?\n");
				break;
		}

	return(return_value);
}

void close_port()
{
	port_deallocate(task_self(), SpeechPort);
}



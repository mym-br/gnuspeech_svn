#include <stdio.h>
#include <sys/file.h>
#include <sys/types.h>
#include <TextToSpeech/TTS_types.h>
#include <pwd.h>
#include "MessageStructs.h"
#include "server_structs.h"
#include "SpeechMessages.h"
#include "structs.h"
#include "serverDefaults.h"
#import "andMap.h"
#import <time.h>

extern port_t SpeechPort;

#define VERSION_STRING "1.08 Release, "__DATE__"."
static char file_id[] = "@(#)Server Handler. Author: Craig-Richard Schock. (C) Trillium, 1991, 1992, 1993.";

struct _user users[50];
unsigned char users_list[50];

int SYSPriority, SYSPolicy, SYSQuantum, SYSPrefill, SYSKill;

extern struct _speak_messages speak_messages[MAX_SPEAK_MESSAGES];
extern int in_speak_message, out_speak_message, message_queue_empty;
extern struct _calc_info calc_info;

extern int demoFlag;
extern int demoCount;

extern const char *lookup_word(const char *word, short *dict);
char *parse_speech_to_file();

/*===========================================================================

This file was created June 18, 1991.

	MODIFIED July 12, 1991.

	This file was modified to be a test file.  All messages and parameters
	can be tested using this file.
	When new messages are added, they should be tested here.

	The Current list of supported functions is as follows:

		new_speaker(msg_header, ident);			working
		close_speaker(msg_header, ident);		working
		set_app_dict(msg_header, ident);		working
		set_user_dict(msg_header, ident);		working
		setspeed(msg_header, ident);			working
		setvolume(msg_header, ident);			working
		set_error_port(msg_header, ident);		defunct
		set_dict_order(msg_header, ident);		working
		get_app_dict(msg_header, ident);		working
		get_user_dict(msg_header, ident);		working
		speed(msg_header, ident);			working
		volume(msg_header, ident);			working 
		get_dict_order(msg_header, ident);		working
		get_pron(msg_header, ident);			working
		get_escape_char(msg_header, ident);		working
		pause(msg_header, ident);			working modified
		pauseafterutt(msg_header, ident);		working
		scontinue(msg_header, ident);			working
		eraseallsound(msg_header, ident);		working
		erasecurutt(msg_header, ident);			working
		speaktext(msg_header, ident);			working
		version(msg_header, ident);			working

New Messages Added on April 29, 1992.

		set_elasticity(msg_header, ident);		working
		set_intonation(msg_header, ident);		working
		set_pitch_offset(msg_header, ident);		working
		set_balance(msg_header, ident);			working
		get_line_pron(msg_header, ident);		working
		get_elasticity(msg_header, ident);		working
		get_intonation(msg_header, ident);		working
		get_pitch_offset(msg_header, ident);		working
		get_balance(msg_header, ident);			working

New Messages Added on May 12, 1992.

		set_task_ports(msg_header, ident);		working

New Messages Added on May 15, 1992.

		diagnosis(msg_header, ident);			working

New Messages Added on May 27, 1992.

		set_block(msg_header, ident);			working
		get_block(msg_header, ident);			working

June 16, 1992

	Method pause(msg_header, ident) has been changed to 
		server_pause(msg_header, ident);
		because of conflicts in header file libc.h

New Message Added June 18, 1992.

		server_hup(msg_header, ident);			working

New Message Added July 8, 1992.

		dictversion(msg_header, ident);			working

New Message Added Feb 21, 1993.

		get_rhythm(msg_header, ident);			working

New Message Added July 22, 1993

		speaktexttofile(msg_header, ident);		working

New Messages Added December 17, 1993

		get_priority(msg_header, ident);		working
		set_priority(msg_header, ident);		working
		get_quantum(msg_header, ident);			working
		set_quantum(msg_header, ident);			working

New Messages Added January 12, 1994

		set_prefill(msg_header, ident);			working
		get_prefill(msg_header, ident);			working
		set_policy(msg_header, ident);			working
		get_policy(msg_header, ident);			working

New Messages Added January 13, 1994

		server_pid(msg_header, ident);			working
		inactive_kill(msg_header, ident);		working

New Messages Added September 26, 1994

		get_reghost(msg_header, ident);			working
		get_demomode(msg_header, ident);		working
		get_expiry_date(msg_header, ident);		working


	All functions should support at least 2 parameters.  The message to
	be handled and the identifier of the object which sent the message.
	Even though the speech identifier is in the message header, it is
	easier, and more computationally efficient, to have it as a 
	parameter.

===========================================================================*/

init_users()
{
int i;

	for(i = 0;i<50;i++)
		if (users_list[i] == (unsigned char) 1)
			if (kill(users[i].user_task, 0) == (-1)) 
				users_list[i] = (unsigned char) 0;

}

int active_users()
{
int i, temp = 0;

	for(i = 0;i<50;i++)
		if (users_list[i]) temp++;
	return(temp);

}

/* MESSAGES 0-9 */

void new_speaker(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
int i;

	/* search for an unused speaker identifier */
	for(i = 0;i<50;i++)
		if (users_list[i] == (unsigned char) 0) break;
	/* If all spots are full, return a -1 */
	if (i == 50) i = (-1);
	else
	{
		users[i].volume = 60.0;
		users[i].speed = 1.0;
		users[i].voice_type = 1;
		users[i].balance = 0.0;
		users[i].escape_character = 27;
		users[i].order[0] = 1;
		users[i].order[1] = 2;
		users[i].order[2] = 3;
		users[i].order[3] = 4;
		users[i].order[4] = 5;
		users_list[i] = (unsigned char) 1;
	}
	/* send reply message message */
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, i, i);

}

void close_speaker(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{

	/* Set user corresponding to ident to "inactive" */
	users_list[ident] = (unsigned char) 0;
}

set_task_ports(msg_header, ident)
struct int_msg *msg_header;
int ident;
{
	users[ident].user_task = msg_header->data;
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, SET_TASK_PORTS,
		0, (int) getpid());

}

diagnosis(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
char temp[1024];
char temp1[256];
int i, j;
struct passwd *temppswd;

	bzero(temp, 1024);
	bzero(temp1, 256);
	sprintf(temp1,"pid: %d\n", getpid());
	strcat(temp, temp1);

	i = getuid();
	temppswd = getpwuid(i);
	sprintf(temp1,"uid: %d  (%s)\n", i, temppswd->pw_name);
	strcat(temp, temp1);

	sprintf(temp1,"Calculations Status: %d\n", calc_info.status);
	strcat(temp, temp1);

	for(i = 0, j=0; i<50;i++)
		if (users_list[i]) j++;
	sprintf(temp1,"Connections: %d\n", j);
	strcat(temp, temp1);
	send_string_message(msg_header->h.msg_remote_port, PORT_NULL, DIAGNOSIS, ident, temp);
}

server_hup(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
/* Do not call the hup() function.  It is installed as a signal handler and calling
   directly may cause some stack frame problems. */

	close_port();
	init_server();
	init_tone_groups();
	init_users();
}

/* MESSAGES 10-19 */

void set_app_dict(msg_header, ident)
struct string_msg *msg_header;
int ident;
{

	if (msg_header->data!=NULL) 
	{
/*		if (users[ident].app !=NULL)*/
			preditor_close_dict(&users[ident].app);
		strcpy(users[ident].app_dict, msg_header->data);
		vm_deallocate(task_self(), (vm_address_t)msg_header->data,strlen(msg_header->data)+2);
		preditor_open_dict(&users[ident].app , users[ident].app_dict);
	}
}

void set_user_dict(msg_header, ident)
struct string_msg *msg_header;
int ident;
{
int retVal;

	if (msg_header->data!=NULL) 
	{
/*		if (users[ident].user !=NULL)*/
			preditor_close_dict(&users[ident].user);
		strcpy(users[ident].user_dict, msg_header->data);
		vm_deallocate(task_self(), (vm_address_t)msg_header->data,strlen(msg_header->data)+2);
		retVal = preditor_open_dict(&users[ident].user, users[ident].user_dict);
	}
}

void setspeed(msg_header, ident)
struct float_msg *msg_header;
int ident;
{
float speed;

	speed = (float) 1.0/msg_header->data;
	users[ident].speed = speed;
}

void setvolume(msg_header, ident)
struct float_msg *msg_header;
int ident;
{
float volume;

	volume = msg_header->data;
	users[ident].volume = volume;
}

void set_error_port(msg_header, ident)		/* Currently Defunct */
struct simple_msg *msg_header;
int ident;
{

	users[ident].error_port = msg_header->h.msg_remote_port;
}

void set_dict_order(msg_header, ident)
struct int_msg *msg_header;
int ident;
{
int i;
char *temp;

	temp = (char *) &msg_header->data;
	for(i = 0;i<4;i++)
		users[ident].order[i] = temp[i];
	users[ident].order[4] = 4;		/* 4 = McIlroy */

}

void set_escape_char(msg_header, ident)
struct int_msg *msg_header;
int ident;
{
	users[ident].escape_character = msg_header->data;
}

void set_elasticity(msg_header, ident)
struct int_msg *msg_header;
int ident;
{
	users[ident].elasticity = msg_header->data;
}

void set_intonation(msg_header, ident)
struct int_msg *msg_header;
int ident;
{
	users[ident].intonation = msg_header->data;
}

void set_pitch_offset(msg_header, ident)
struct float_msg *msg_header;
int ident;
{
	users[ident].pitch_offset = msg_header->data; /* Float */
}

void set_balance(msg_header, ident)
struct float_msg *msg_header;
int ident;
{
	users[ident].balance = msg_header->data;
}

set_block(msg_header, ident)
struct int_msg *msg_header;
int ident;
{
	users[ident].block = msg_header->data;
}

/* MESSAGES 20-29 */

void get_app_dict(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{

	send_string_message(msg_header->h.msg_remote_port, PORT_NULL, GET_APP_DICT, ident, users[ident].app_dict);
}

void get_user_dict(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{

	send_string_message(msg_header->h.msg_remote_port, PORT_NULL, GET_APP_DICT, ident, users[ident].user_dict);
}

void speed(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
float speed;

	speed = 1.0/users[ident].speed;
	send_float_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, speed);
}


void volume(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
float volume;

	volume = users[ident].volume;
	send_float_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, volume);
}

void get_dict_order(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
int *temp, i;
char temp1[5];

	for(i = 0;i<4; i++)
		temp1[i] = (char) users[ident].order[i];
	temp = (int *) temp1;
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, GET_DICT_ORDER, 0, *temp);

}

void get_pron(msg_header, ident)
struct string_msg *msg_header;
int ident;
{
char *temp, temp2[1024];
short base;

	set_escape_code((char) users[ident].escape_character);
	set_dict_data(users[ident].order, &users[ident].user,&users[ident].app);
	if (strlen(msg_header->data)) 
		temp = (char *) lookup_word(msg_header->data, &base);
	vm_deallocate(task_self(), (vm_address_t)msg_header->data,strlen(msg_header->data)+2);
	sprintf(temp2,"%c%s", (char)base, temp);
/*	printf("%s\n", temp);*/
	send_string_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, temp2);
}

void get_escape_char(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
int temp;

	temp = (int) users[ident].escape_character;
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, temp);

}

void get_line_pron(msg_header, ident)
struct string_msg *msg_header;
int ident;
{
char *temp, temp2[1024];
short base;
int retVal;

	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, 0);
	set_escape_code((char) users[ident].escape_character);
	set_dict_data(users[ident].order, &users[ident].user,&users[ident].app);
	retVal = parser(msg_header->data, &temp);
/*	printf("%s\n", temp);*/
	vm_deallocate(task_self(), (vm_address_t)msg_header->data,strlen(msg_header->data)+2);
	send_string_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, temp);

}

void get_elasticity(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
int elasticity;

	elasticity = users[ident].elasticity;
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, elasticity);

}

void get_intonation(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
int intonation ;

	intonation = users[ident].intonation;
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, intonation);

}

void get_pitch_offset(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
float pitch_offset;

	pitch_offset = users[ident].pitch_offset;
	send_float_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, pitch_offset);

}

void get_balance(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
float balance;

	balance = users[ident].balance;
	send_float_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, balance);
}

void get_block(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
int block;
	block = users[ident].block;
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, block);
}

/* MESSAGES 30-39 */
void server_pause(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
int temp;
int error = TTS_OK;


	if (calc_info.identifier == ident)
	{
		switch(calc_info.status)
		{
			case IDLE:	calc_info.status = PAUSED;
					break;
			case PAUSED:	error = TTS_ALREADY_PAUSED;
					break;
			case TO_BE_PAUSED:
					break;
			case RUNNING:
					calc_info.status = TO_BE_PAUSED;
					break;
			case ERASED:	break;
		}
	}
	else
	{
		temp = find_next_speak_message(ident);
		if (temp!=(-1))
			speak_messages[temp].status = PAUSED;
		else
			error = TTS_NO_UTTERANCE;
	}
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, error);
}

void pauseafterutt(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
int temp;
int error = TTS_OK;

	temp = find_next_speak_message(ident);
	if (temp!=(-1))
		speak_messages[temp].status = PAUSED;
	else
		error = TTS_NO_UTTERANCE;
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, error);
}

void scontinue(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
int temp;
int error = TTS_OK;

	if (calc_info.identifier==ident)
		continue_synth();
	else
	{
		temp = find_next_speak_message(ident);
		if (temp!=(-1))
			speak_messages[temp].status = IDLE;
		else
			error = TTS_NO_UTTERANCE;
	}

	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, error);
}

void eraseallsound(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
int error = TTS_OK;

	if (calc_info.identifier==ident)
	{
		if ((calc_info.status == PAUSED) || (calc_info.status == IDLE)) calc_info.status = ERASED;
		else
			calc_info.status = TO_BE_ERASED;
	}
	erase_all_utterances(ident);
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, error);
}

void erasecurutt(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
int error = TTS_OK;

	if (calc_info.identifier==ident)
	{
		if ((calc_info.status == PAUSED) || (calc_info.status == IDLE)) calc_info.status = ERASED;
		else
			calc_info.status = TO_BE_ERASED;
	}
	else error = TTS_NO_UTTERANCE;
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, error);

}

char *demoStrings[10] = {"The TextToSpeech Kit by Trillium Sound Research Incorporated.", 
"Call Trillium to register this demo.", 
"This is a demo of the TextToSpeech Kit by Trillium Sound Research.", 
"Space; the final frontier.  These are the voyagez of the Starship, Enterprise.", 
"Developers can incorporate speech into their applications with the Developer Kit.", 
"Call Trillium Sound Research at (4 0 3) 284-9278.", 
"We hope you are enjoying this demo of the TextToSpeech Kit.", 
"This is a demo.", 
"Get us out of here mr Chekov..", 
"Attention, Elvis has left the Building."
};
void speaktext(msg_header, ident)
struct string_msg *msg_header;
int ident;
{
char *temp, *temp1;
short *ord;
int x, retVal;
int error = TTS_OK;
int tempString;

	if (  ((in_speak_message+1)%MAX_SPEAK_MESSAGES) == out_speak_message)
	{
		/* Error, message queue full! */
		vm_deallocate(task_self(), (vm_address_t)msg_header->data,strlen(msg_header->data)+2);
		error = TTS_SPEAK_QUEUE_FULL;
	}
	else
	{
		send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, 0);
		set_escape_code((char) users[ident].escape_character);
		ord = (short *) &users[ident].order;
		x = set_dict_data(users[ident].order, &users[ident].user,&users[ident].app);
//		printf("%s\n", msg_header->data);
		if (demoFlag == (-1))
			retVal = parser("TextToSpeech Kit Demo by Trillium Sound Research Inc.", &temp);
		else
		if (demoFlag == (1))
		{
			demoCount--;
			if (demoCount<=0)
			{
				demoCount = random()%5+2;
				tempString = random()%10;
//				printf("DEMO: %s\n",demoStrings[tempString]);
				retVal = parser(demoStrings[tempString], &temp);
			}
			else
				retVal = parser(msg_header->data, &temp);
		}
		else
			retVal = parser(msg_header->data, &temp);
		if ((temp!=NULL) && (retVal<0))
		{
			temp1 = malloc(strlen(temp)+1);
			strcpy(temp1, temp);
			speak_messages[in_speak_message].ident = ident;
			speak_messages[in_speak_message].status = IDLE;
			speak_messages[in_speak_message].text  = temp1;
			speak_messages[in_speak_message].rhythm  = 0;
			speak_messages[in_speak_message].uid  = (-1);
			speak_messages[in_speak_message].gid  = (-1);
			speak_messages[in_speak_message].filePath  = NULL;
			in_speak_message = ((in_speak_message+1)%MAX_SPEAK_MESSAGES);
			message_queue_empty = FALSE;
		}
		else
		{
			error = TTS_PARSE_ERROR;
		}
		vm_deallocate(task_self(), (vm_address_t)msg_header->data,strlen(msg_header->data)+2);
	}
	if (!users[ident].block) send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, error);
	else users[ident].block_port = msg_header->h.msg_remote_port;
}

void version(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
char *temp, *temp1;

	send_string_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, VERSION_STRING);

}

void dictversion(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
char versionTemp[1024];

	sprintf(versionTemp, "V:%s\nC:%s", DictionaryVersion(), CompiledDictionaryVersion());
	send_string_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, versionTemp);

}

get_rhythm(msg_header, ident)
struct string_msg *msg_header;
int ident;
{
char *temp, *temp1;
short *ord;
int x, retVal;
int error = TTS_OK;

	if (  ((in_speak_message+1)%MAX_SPEAK_MESSAGES) == out_speak_message)
	{
		/* Error, message queue full! */
		vm_deallocate(task_self(), (vm_address_t)msg_header->data,strlen(msg_header->data)+2);
		error = TTS_SPEAK_QUEUE_FULL;
	}
	else
	{
/*		send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, 0);*/
		set_escape_code((char) users[ident].escape_character);
		ord = (short *) &users[ident].order;
		x = set_dict_data(users[ident].order, &users[ident].user,&users[ident].app);
//		printf("%s\n", msg_header->data);
		retVal = parser(msg_header->data, &temp);
		if ((temp!=NULL) && (retVal<0))
		{
			temp1 = malloc(strlen(temp)+1);
			strcpy(temp1, temp);
			speak_messages[in_speak_message].ident = ident;
			speak_messages[in_speak_message].status = IDLE;
			speak_messages[in_speak_message].text  = temp1;
			speak_messages[in_speak_message].rhythm  = 1;
			calc_info.rhythm_port  = msg_header->h.msg_remote_port;
	
			in_speak_message = ((in_speak_message+1)%MAX_SPEAK_MESSAGES);
			message_queue_empty = FALSE;
		}
		else
		{
			error = TTS_PARSE_ERROR;
		}
		vm_deallocate(task_self(), (vm_address_t)msg_header->data,strlen(msg_header->data)+2);
	}

}

speaktexttofile(msg_header, ident)
struct string_msg *msg_header;
int ident;
{
char *temp, *temp1, *temp2;
short *ord;
int x, retVal;
int error = TTS_OK;

	if ( (demoFlag == (1)) || (demoFlag == (-1)))
	{
		send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, 0);
		error = TTS_SPEAK_QUEUE_FULL;
		vm_deallocate(task_self(), (vm_address_t)msg_header->data,strlen(msg_header->data)+2);
	}
	else
	if (  ((in_speak_message+1)%MAX_SPEAK_MESSAGES) == out_speak_message)
	{
		/* Error, message queue full! */
		send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, 0);
		vm_deallocate(task_self(), (vm_address_t)msg_header->data,strlen(msg_header->data)+2);
		error = TTS_SPEAK_QUEUE_FULL;
	}
	else
	{
		send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, 0);
		set_escape_code((char) users[ident].escape_character);
		ord = (short *) &users[ident].order;
		x = set_dict_data(users[ident].order, &users[ident].user,&users[ident].app);
		temp2 = parse_speech_to_file(msg_header->data,
				&speak_messages[in_speak_message].uid,
				&speak_messages[in_speak_message].gid, 
				&speak_messages[in_speak_message].filePath);

//		printf("uid:%d\ngid:%d\npath:%s\n|%s|\n", 
//			speak_messages[in_speak_message].uid,
//			speak_messages[in_speak_message].gid, 
//			speak_messages[in_speak_message].filePath, temp2);
		retVal = parser(temp2, &temp);
		if ((temp!=NULL) && (retVal<0))
		{
			temp1 = malloc(strlen(temp)+1);
			strcpy(temp1, temp);
			speak_messages[in_speak_message].ident = ident;
			speak_messages[in_speak_message].status = IDLE;
			speak_messages[in_speak_message].text  = temp1;
			speak_messages[in_speak_message].rhythm  = 0;
			in_speak_message = ((in_speak_message+1)%MAX_SPEAK_MESSAGES);
			message_queue_empty = FALSE;
		}
		else
		{
			error = TTS_PARSE_ERROR;
		}
		vm_deallocate(task_self(), (vm_address_t)msg_header->data,strlen(msg_header->data)+2);
	}
	if (!users[ident].block) send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, error);
	else users[ident].block_port = msg_header->h.msg_remote_port;

//	printf("%s\n", msg_header->data);
}

char *parse_speech_to_file(string, uid, gid, path)
char *string, **path;
int *uid, *gid;
{
char temp[1024], *temp1;
int i;

	while(*string!='\000')
	{
		bzero(temp, 1024);
		i = 0;

		while(*string!='\n')
			temp[i++] = *(string++);
		string++;
		*uid = atoi(temp);

		bzero(temp, 1024);
		i = 0;
		while(*string!='\n')
			temp[i++] = *(string++);
		string++;
		*gid = atoi(temp);

		bzero(temp, 1024);
		i = 0;
		while(*string!='\n')
			temp[i++] = *(string++);

		temp1 = (char *) malloc(strlen(temp)+1);
		strcpy(temp1, temp);
		*path = temp1;

		string++;
		return(string);
	}
}

void get_priority(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, GETQUANTUM, ident, SYSPriority);

}

void set_priority(msg_header, ident)
struct int_msg *msg_header;
int ident;
{
kern_return_t		error;
struct host_sched_info	sched_info;
processor_set_t		default_set, default_set_priv;
int tempPriority;
char buffer[48];

	tempPriority = msg_header->data;
	error=processor_set_default(host_self(), &default_set);
	if (error!=KERN_SUCCESS)
	{
		mach_error("Error calling processor_set_default()", error);
		return;
	}

	error=host_processor_set_priv(host_priv_self(), default_set, &default_set_priv);
	if (error != KERN_SUCCESS)
	{
		mach_error("Call to host_processor_set_priv() failed", error);
		return;
	}

	error = thread_max_priority(thread_self(), default_set_priv, tempPriority);
	if (error != KERN_SUCCESS)
		mach_error("thread_max_priority() 1 call failed", error);

	error = thread_priority(thread_self(), tempPriority, FALSE);
	if (error != KERN_SUCCESS)
		mach_error("thread_priority() 2 call failed", error);

//	printf("SetPriority: %d\n", tempPriority);
	bzero(buffer,48);
	sprintf(buffer, "%d", tempPriority);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_PRIORITY, buffer);
	NXUpdateDefaults();

}

void get_quantum(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, GETQUANTUM, ident, SYSQuantum);
}

void set_quantum(msg_header, ident)
struct int_msg *msg_header;
int ident;
{
kern_return_t	error;
char buffer[48];

	if ((SYSPolicy!=POLICY_TIMESHARE) && (SYSPolicy!=POLICY_FIXEDPRI))
		SYSPolicy = POLICY_TIMESHARE;

	error=thread_policy(thread_self(), SYSPolicy, msg_header->data);
	if (error != KERN_SUCCESS)
	{
		mach_error("thread_policy() call failed: setting quantum", error);
		return;
	}

	SYSQuantum = msg_header->data;
//	printf("SetQuantum: %d\n", msg_header->data);

	bzero(buffer,48);
	sprintf(buffer, "%d", msg_header->data);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_QUANTUM, buffer);
	NXUpdateDefaults();

	return;
}

void set_prefill(msg_header, ident)
struct int_msg *msg_header;
int ident;
{
char buffer[48];

	SYSPrefill = msg_header->data;

	bzero(buffer,48);
	sprintf(buffer, "%d", msg_header->data);
	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_PREFILL, buffer);
	NXUpdateDefaults();

	return;
}

void get_prefill(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, GETPREFILL, ident, SYSPrefill);
}

void set_policy(msg_header, ident)
struct int_msg *msg_header;
int ident;
{
kern_return_t	error;
char buffer[48];

	if (SYSQuantum<15)
		SYSQuantum = 15;
	else
	if (SYSQuantum>350)
		SYSQuantum = 350;

	error=thread_policy(thread_self(), msg_header->data, SYSQuantum);
	if (error != KERN_SUCCESS)
	{
		mach_error("thread_policy() call failed: setting Fixed Pri", error);
		return;
	}

	bzero(buffer,48);
	switch(msg_header->data)
	{
		default:
		case POLICY_TIMESHARE:
			SYSPolicy = POLICY_TIMESHARE;
			strcpy(buffer,"POLICY_TIMESHARE");
			break;

		case POLICY_FIXEDPRI:
			SYSPolicy = POLICY_FIXEDPRI;
			strcpy(buffer,"POLICY_FIXEDPRI");
			break;
	}

	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_POLICY, buffer);
	NXUpdateDefaults();

	return;
}

void get_policy(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, GETPOLICY, ident, SYSPolicy);
}

void server_pid(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, SERVERPID, ident, (int) getpid());
}

void inactive_kill(msg_header, ident)
struct int_msg *msg_header;
int ident;
{
char buffer[48];

	SYSKill = msg_header->data;

	switch(SYSKill)
	{
		default:
		case TRUE: strcat(buffer,"YES");
			break;
		case FALSE:strcat(buffer,"NO");
			break;
	}

	NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_INACTIVE, buffer);
	NXUpdateDefaults();
}

void kill_query(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, KILLQUERY, ident, SYSKill);
}

void restart_server(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
	close_port();
	NXLogError("TTS_Server: Speech server restart requested.");
	exit(0);
}

#define XORTHING  0xD39FBA6E
#define XORTHING2 0xC71D92A4


char demoBuffer[64] = 
	{27, 190, 156, 200, 251, 1, 4, 36, 221, 198, 
	10, 90, 67, 15, 99, 231, 105, 37, 51, 1, 
	12, 197, 56, 100, 223, 100, 31, 136, 44, 45, 
	101, 227, 231, 195, 186, 17, 250, 236, 201, 199, 
	24, 21, 226, 254, 
/* Demo Mode */
#ifdef DEMO
	104, 233, 25, 191,
#else
	251, 1, 4, 36,
#endif
/* Reg hostid */
	0, 198, 27, 190, 
/* password */
	156, 200, 251, 1, 
/* Date Code */
	4, 36, 221, 198, 
/* Checksum */
#ifdef DEMO
	190, 116, 117, 23};
#else
	80, 140, 95, 124};
#endif

void get_reghost(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
unsigned int *temp;

	temp = (unsigned int *) &demoBuffer[44];
	if (*temp == 0xfb010424)
		send_int_message(msg_header->h.msg_remote_port, PORT_NULL, GET_REGHOST, ident, 0);

	temp = (unsigned int *) &demoBuffer[48];
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, KILLQUERY, ident, (*temp)^XORTHING);
}

void get_demomode(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
unsigned int *temp, *temp1, seed;
int returnValue;
int i;
unsigned int checksum = 0, *dummy;


	/* Calculate checksum */
	dummy = (unsigned int *) &demoBuffer[0];
	for (i = 0; i<15; i++)
	{
		checksum=checksum+(dummy[i]);
	}
	temp = (unsigned int *) &demoBuffer[60];


	temp = (unsigned int * ) &demoBuffer[44];
	if (*temp == 0xfb010424)
	{
		send_int_message(msg_header->h.msg_remote_port, PORT_NULL, GET_REGHOST, ident, 2);
		return;
	}

	temp = (unsigned int *) &demoBuffer[52];
	temp1 = (unsigned int *) &demoBuffer[48];
	seed = getSeedofHostid((*temp)^XORTHING, (*temp1)^XORTHING)^XORTHING;
	switch(seed)
	{
		default:
			returnValue = 10000;
			break;
		case SEED1:
			returnValue = 0;
			break;
		case SEED2:
			returnValue = 1;
			break;
		case SEED3:
			returnValue = 3;
			break;

	}

	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, KILLQUERY, ident, returnValue);
}

void get_expiry_date(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
unsigned int *temp, *temp1;
unsigned int seed;

	temp = (unsigned int *) &demoBuffer[44];
	if (*temp == 0xfb010424)
		send_int_message(msg_header->h.msg_remote_port, PORT_NULL, GET_REGHOST, ident, 0);

	temp = (unsigned int *) &demoBuffer[56];
	temp1 = (unsigned int *) &demoBuffer[48];

	seed = getSeedofHostid((*temp)^XORTHING2, (*temp1)^XORTHING);

	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, KILLQUERY, ident, seed^XORTHING2);
}

int check_validity(checksumOk)
int *checksumOk;
{
unsigned int *temp, *temp1, seed, seed1;
int i;
unsigned int checksum = 0, *dummy;
unsigned int hostid, hostid2;
struct tm *timeValue;
time_t tempTime;
int year, day, month;
unsigned int date;

	/* Calculate checksum */
	dummy = (unsigned int *) &demoBuffer[0];
	for (i = 0; i<15; i++)
	{
//		printf("%x  %x  %x\n", checksum, dummy[i], checksum+dummy[i]);
		checksum=checksum+(dummy[i]);
	}
	temp = (unsigned int *) &demoBuffer[60];
	if (checksum == (*temp))
		*checksumOk = 1;
	else
	{
		*checksumOk = 0;
		return 0;
	}

	temp = (unsigned int *) &demoBuffer[44];
	if (*temp == 0xfb010424)
		return 1;

	temp = (unsigned int *) &demoBuffer[52];
	temp1 = (unsigned int *) &demoBuffer[48];
	seed = getSeedofHostid((*temp)^XORTHING, (*temp1)^XORTHING)^XORTHING;
	seed1 = getSeed((*temp)^XORTHING)^XORTHING;
//	printf("Server %x  %x\n", seed, seed1);
	switch(seed)
	{
		default: 
//			printf("SERVER: Unregistered \n");
			return 0;
			break;
		case SEED1:/* Registered to Host */
//			printf("SERVER: Registered to Host\n");
			hostid = gethostid();
			temp = (unsigned int *) &demoBuffer[48];
			hostid2 = ((*temp)^XORTHING);
//			printf("Server: Host ids %x %x\n", hostid, hostid2);
			if (hostid == hostid2)
				return 1;
			else
				return 0;
			break;
		case SEED2:/* Registered to Site */
//			printf("SERVER: Registered to Site\n");
			return 1;
			break;
		case SEED3:
//			printf("SERVER: Time Limited\n");
			temp = (unsigned int *) &demoBuffer[56];
			date = getSeedofHostid((*temp)^XORTHING2, (*temp1)^XORTHING)^XORTHING2;
//			printf("Date %x\n", date);
			year  = (date&0x000000FF)+1990;
			day   = (date&0x000FF000)>>12;
			month = (date&0x00000F00)>>8;
			time(&tempTime);
			timeValue = localtime(&tempTime);
			if (year>timeValue->tm_year+1900)
				return (0);
			else
			if (year<timeValue->tm_year+1900)
				return (-1);
			else
			if (month>timeValue->tm_mon)
				return (0);
			else
			if (month<timeValue->tm_mon)
				return (-1);
			else
			if (day>=timeValue->tm_mday)
				return (0);
			else
				return (-1);
			break;

	}




}

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
#import <time.h>

extern port_t SpeechPort;

static char file_id[] = "@(#)Server Handler. Author: Craig-Richard Schock. (C) Trillium, 1991, 1992, 1993.";

struct _user users[50];
unsigned char users_list[50];

int SYSPriority, SYSPolicy, SYSQuantum, SYSPrefill, SYSKill;

extern struct _speak_messages speak_messages[MAX_SPEAK_MESSAGES];
extern int in_speak_message, out_speak_message, message_queue_empty;
extern struct _calc_info calc_info;

extern int demoFlag;
extern int demoCount;

extern struct _voiceConfig voices[MAX_VOICES];
extern float minBlack, minWhite;

extern const char *lookup_word(const char *word, short *dict);
char *parse_speech_to_file();

extern char *version_string;

extern char globalSystemPath[256];

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

		get_reghost(msg_header, ident);			OBSOLETE
		get_demomode(msg_header, ident);		working
		get_expiry_date(msg_header, ident);		OBSOLETE


Messages Made obsolete December 28, 1994

		set_elasticity(msg_header, ident);		obsolete
		get_elasticity(msg_header, ident);		obsolete

New Messages Added December 28, 1994

		set_voice_type(msg_header, ident);		working
		set_vtl_offset(msg_header, ident);		working
		set_breathiness(msg_header, ident);		working
		set_channels(msg_header, ident);		working
		set_sampling_rate(msg_header, ident);		working

		get_voice_type(msg_header, ident);		working
		get_vtl_offset(msg_header, ident);		working
		get_breathiness(msg_header, ident);		working
		get_channels(msg_header, ident);		working
		get_sampling_rate(msg_header, ident);		working


Modified Messages April 4, 1995

		speaktext(...);
		speaktexttofile(...);

		These messages have been modified to return an error
		if text cannot be  synthesized at the currently selected
		samplingrates or tube length.

New Message Added April 7, 1995

		set_soft_synth(msg_header, ident);           working
		get_soft_synth(msg_header, ident);           working

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
		users[i].voice_type = 0;
		users[i].balance = 0.0;
		users[i].vtlOffset = 0.0;
		users[i].pitch_offset = 0.0;
		users[i].breathiness = 0.5;
		users[i].samplingRate = 22050.0;
		users[i].channels = 2;
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
//	users[ident].elasticity = msg_header->data;
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
	checkBuffer(msg_header->data);		/* Swiss Hack */
	retVal = parser(msg_header->data, &temp);
//	printf("%s\n", temp);
	vm_deallocate(task_self(), (vm_address_t)msg_header->data,strlen(msg_header->data)+2);
	send_string_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, temp);

}

void get_elasticity(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
int elasticity;

//	elasticity = users[ident].elasticity;
	elasticity = 0;
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
		if ((calc_info.status == PAUSED) || (calc_info.status == IDLE))
			calc_info.status = ERASED;
		else
		{
			calc_info.status = TO_BE_ERASED;
//			printf("Status set TO_BE_ERASED\n");
		}
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
"Space; the final frontier.  These are the voyages of the Starship, Enterprise.", 
"Developers can incorporate speech into their applications with the Developer Kit.", 
"Call Trillium Sound Research at (4 0 3) 284-9278.", 
"We hope you are enjoying this demo of the TextToSpeech Kit.", 
"This is a demo.", 
"Mr Sulu, get us out of here.", 
"Attention; Elvis has left the Building."
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
int voice = users[ident].voice_type;
float vtl = users[ident].vtlOffset;

//	printf("Min: %f  Vocal Tract Length: %f\n", minBlack, vtl+voices[voice].meanLength);
	if (  ((in_speak_message+1)%MAX_SPEAK_MESSAGES) == out_speak_message)
	{
		send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, 0);
		/* Error, message queue full! */
		vm_deallocate(task_self(), (vm_address_t)msg_header->data,strlen(msg_header->data)+2);
		error = TTS_SPEAK_QUEUE_FULL;
	}
	else
#if m68k
	if ((vtl+voices[voice].meanLength) < minBlack)
	{
		send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, 0);
//		printf("Black hardware min: %f  actual: %f\n", minBlack, vtl+voices[voice].meanLength);
		vm_deallocate(task_self(), (vm_address_t)msg_header->data,strlen(msg_header->data)+2);
		error = TTS_DSP_TOO_SLOW;
	}
#elif i386
	if ((vtl+voices[voice].meanLength) < minWhite)
	{
		send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, 0);
		vm_deallocate(task_self(), (vm_address_t)msg_header->data,strlen(msg_header->data)+2);
		error = TTS_DSP_TOO_SLOW;
	}
#endif
	else
	{
		send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, 0);
		set_escape_code((char) users[ident].escape_character);
		ord = (short *) &users[ident].order;
		x = set_dict_data(users[ident].order, &users[ident].user,&users[ident].app);
//		printf("%s\n", msg_header->data);
		if (demoFlag != 0)
		{
			demoCount--;
			if ((demoCount<=0) || (demoFlag == (-1)))
			{
				demoCount = random()%4+2;
				tempString = random()%10;
//				printf("DEMO: %s\n",demoStrings[tempString]);
				checkBuffer(msg_header->data);		/* Swiss Hack */
				retVal = parser(demoStrings[tempString], &temp);
			}
			else
			{
				checkBuffer(msg_header->data);		/* Swiss Hack */
				retVal = parser(msg_header->data, &temp);
			}
		}
		else
		{
			checkBuffer(msg_header->data);		/* Swiss Hack */
			retVal = parser(msg_header->data, &temp);
		}
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
//			printf("Parser %d\n", retVal);
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

	send_string_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, version_string);

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
		checkBuffer(msg_header->data);		/* Swiss Hack */
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
int voice = users[ident].voice_type;
float vtl = users[ident].vtlOffset;

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
	if ((vtl+voices[voice].meanLength) <7.95)
	{
		send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, 0);
		vm_deallocate(task_self(), (vm_address_t)msg_header->data,strlen(msg_header->data)+2);
		error = TTS_DSP_TOO_SLOW;
	}
	else
	{
		if (((vtl+voices[voice].meanLength) <15.9) && (users[ident].samplingRate!=44100.0))
		{
			error = TTS_SAMPLE_RATE_TOO_LOW;
		}

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

		checkBuffer(msg_header->data);		/* Swiss Hack */
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
	exit(-7);
}

/* OBSOLETE */
void get_reghost(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
unsigned int *temp;

	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, GET_REGHOST, ident, 0);

}

/* Demo mode now checks a file in the systemPath directory.  Within that file is 
   an encrypted serial number.  If that number self-consistent based upon the encryption
   system, the server does not run in demo mode.  If the file is not there, standard
   demo mode is in place.  If the encrypted serial number is NOT consistent, the
   server runs in a strange mode where it babbles the same thing over and over again :-)

   demoMode == 0	non-demo mode
   demoMode == 1	demo mode
   demoMode == (-1)	baked mode

Craig - July 24, 1995

*/
void get_demomode(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{

	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, KILLQUERY, ident, demoFlag);
}


/* OBSOLETE */
void get_expiry_date(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, GET_REGHOST, ident, 0);
}

#define SERIALFILE	"SerialNumber"

int check_validity()
{
FILE *fp;
char tempPath[256];
int number;

	bzero(tempPath, 256);
	strcpy(tempPath, globalSystemPath);
	strcat(tempPath, "/");
	strcat(tempPath, SERIALFILE);


	fp = fopen(tempPath, "r");
	if (fp == NULL)
	{
//		printf("Cannot find file %s\n", tempPath);
		return 1;
	}

	fscanf(fp, "%x", &number);
	fclose(fp);

	if (consistent(number))
		return 0;
	else
		return (-1);
}

void set_voice_type(msg_header, ident)
struct int_msg *msg_header;
int ident;
{
int voiceType;

	voiceType = msg_header->data;
	users[ident].voice_type = voiceType;
}

void set_vtl_offset(msg_header, ident)
struct float_msg *msg_header;
int ident;
{
float vtlOffset;

	vtlOffset = msg_header->data;
	users[ident].vtlOffset = vtlOffset;
}

void set_breathiness(msg_header, ident)
struct float_msg *msg_header;
int ident;
{
float breathiness;

	breathiness = msg_header->data;
	users[ident].breathiness = breathiness;
}

void set_channels(msg_header, ident)
struct int_msg *msg_header;
int ident;
{
int channels;

	channels = msg_header->data;
	users[ident].channels = channels;
}

void set_sampling_rate(msg_header, ident)
struct float_msg *msg_header;
int ident;
{
float samplingRate;

	samplingRate = msg_header->data;
	users[ident].samplingRate = samplingRate;
}


void get_voice_type(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
int voiceType ;

	voiceType = users[ident].voice_type;
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, voiceType);
}

void get_vtl_offset(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
float vtlOffset;

	vtlOffset = users[ident].vtlOffset;
	send_float_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, vtlOffset);
}

void get_breathiness(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
float breathiness;

	breathiness = users[ident].breathiness;
	send_float_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, breathiness);
}

void get_channels(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
int channels;

	channels = users[ident].channels;
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, channels);
}

void get_sampling_rate(msg_header, ident)
struct simple_msg *msg_header;
int ident;
{
float samplingRate;

	samplingRate = users[ident].samplingRate;
	send_float_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, samplingRate);
}

void set_soft_synth(msg_header, ident)
struct int_msg *msg_header;
int ident;
{
int softwareSynthesis;

	softwareSynthesis = msg_header->data;
	users[ident].softwareSynthesis = softwareSynthesis;

}

void get_soft_synth(msg_header, ident)
struct int_msg *msg_header;
int ident;
{
int softwareSynthesis;

	softwareSynthesis = users[ident].softwareSynthesis;
	send_int_message(msg_header->h.msg_remote_port, PORT_NULL, 0, ident, softwareSynthesis);

}

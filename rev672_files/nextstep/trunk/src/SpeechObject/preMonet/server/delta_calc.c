#import <stdio.h>
#ifdef V2
#import <mach.h>
#import "synthesizer_module.h"
#endif
#ifdef V3
#import <mach/mach.h>
#import "synthesizer_module.h"
#endif

#import <math.h>
#import <TextToSpeech/TTS_types.h>
#import "structs.h"
#import "server_structs.h"
#import "diphone_module.h"

static char file_id[] = "@(#)Delta Calculation Engine. Author: Craig-Richard Schock. (C) Trillium, 1991, 1992.";

float current_values[14];
float current_deltas[14];

struct _calc_info calc_info;
struct _pitch_movement pitch_movements[MAX_PMOVEMENTS];

float intonation_random;
float total_time;
float *tg_parameters[5];
int tg_count[5];

int demoFlag;
int demoCount;

#define WAT_PAGES 6
int watermark;

int utterance_type;

extern int SYSPrefill;

extern int cur_event, cur_foot, cur_phone, cur_pevent;
extern struct _event events[MAX_EVENTS];
extern struct _foot feet[MAX_FEET];
extern struct _phone phones[MAX_PHONES];
extern struct _pevent pevents[MAX_PEVENTS];
extern FILE *fp_um, *fp_mk;
extern float gaussian();

extern int buffer_pages[PAGES];
extern int buffer_page_usable[PAGES];
extern int cur_page_in, cur_page_out, *cur_index_in;

extern struct _speak_messages speak_messages[MAX_SPEAK_MESSAGES];
extern int in_speak_message, out_speak_message, message_queue_empty;

extern struct _user users[50];
extern unsigned char users_list[50];

init_utterance()
{
int i;
int identifier = speak_messages[out_speak_message].ident;

	bzero(current_values,sizeof(float)*14);

	for(i = 0;i<PAGES;i++)
		buffer_page_usable[i] = TRUE;

	init_events();
	current_values[0] = targetValue("^","ax");
	current_values[1] = targetValue("^","f1");
	current_values[2] = targetValue("^","f2");
	current_values[3] = targetValue("^","f3");
	current_values[4] = targetValue("^","f4");
	current_values[5] = targetValue("^","ah1");
	current_values[6] = targetValue("^","ah2");
	current_values[7] = targetValue("^","fh2");
	current_values[8] = targetValue("^","bwh2");
	current_values[9] = targetValue("^","fnnf");
	current_values[10] = targetValue("^","nb");
	current_values[11] = targetValue("^","micro");
	current_values[12] = 0.0;
	current_values[13] = 0.0;


	current_deltas[12] = 0.0;
	current_deltas[13] = 0.0;

	utterance_type = 0;

	cur_index_in = (int *)buffer_pages[cur_page_in];

	calc_info.identifier = identifier;
	calc_info.status = speak_messages[out_speak_message].status;
	calc_info.volume = users[identifier].volume;
	calc_info.speed = users[identifier].speed;
	calc_info.balance = users[identifier].balance;
	calc_info.elasticity = users[identifier].elasticity;
	calc_info.intonation = users[identifier].intonation;
	calc_info.pitch_offset = users[identifier].pitch_offset;
	calc_info.block = users[identifier].block;
	calc_info.block_port = users[identifier].block_port;
	calc_info.random = calc_info.intonation & TTS_INTONATION_RANDOMIZE;
	calc_info.uid = speak_messages[out_speak_message].uid;
	calc_info.gid = speak_messages[out_speak_message].gid;
	calc_info.filePath = speak_messages[out_speak_message].filePath;

}


do_calc()
{
register int cur_pev_value = 0, cur_ev_value = 0;
int i;
int time = 0;
float temp;
float last_targets[12];

//	printf("Do Calc\n");
//	thread_priority(thread_self(), 24, FALSE);

	cur_page_out = cur_page_in;			/* This prevents a click at the beginning of speaking */
	watermark = (cur_page_in+WAT_PAGES)%PAGES;
	if (cur_event>0)
	bcopy(current_values, last_targets, sizeof(float)*12);
	while(cur_ev_value<cur_event+1)
	{
		if (time>=events[cur_ev_value].time)
		{
			bcopy(events[cur_ev_value].deltas,current_deltas,sizeof(float)*12);

/*			if (events[cur_ev_value].targets[0]!=(-1.0))
				bcopy(events[cur_ev_value].targets, current_values, sizeof(float)*12);*/

			cur_ev_value++;
		}
		if ((time>=pevents[cur_pev_value].time) && (cur_pev_value<=cur_pevent))
		{
			current_deltas[13] = pevents[cur_pev_value++].delta;
		}


		current_values_to_table();	/* Convert parameters to table entries */

		for(i = 0;i<14;i++) current_values[i]+=current_deltas[i];

		memory_man();			/* Do memory management */
//		thread_priority(thread_self(), 24, FALSE);
		if (calc_info.status == ERASED) return(0);

		time++;
	}
	finished_calculations();
}

void update_synth_ptr(void)
{
int next_page;
static count;

	synth_read_ptr = buffer_pages[cur_page_out];

	next_page = (cur_page_out+1)%PAGES;
	if(buffer_page_usable[next_page]==FALSE)
	{
		count = 0;
		buffer_page_usable[cur_page_out] = TRUE;
		cur_page_out = next_page;
	}
	else count++;
	if (count>2)
	{
		calc_info.status = TO_BE_ERASED;
		count = 0;
	}
//	printf("\t\tConsumed:%d\n", cur_page_out);
}

memory_man()
{
int temp;

	if ( ((int)cur_index_in - (int)buffer_pages[cur_page_in]) >= (int) vm_page_size)
	{
//		printf("Produced:%d\n", cur_page_in);
		buffer_page_usable[cur_page_in] = FALSE;	/* Mark page as Not Usable (by the calc engine) */
		cur_page_in = (cur_page_in+1)%PAGES;		/* Next Page */
		cur_index_in = (int *) buffer_pages[cur_page_in];/* Make sure pointer is page aligned */
		poll_port(FALSE);				/* Check for new messages, no blocking */
		thread_priority(thread_self(), 24, FALSE);
		if (calc_info.status != PAUSED) feed_synthesizer(FALSE,FALSE);
		if (calc_info.status == ERASED) return(0);
		if (buffer_page_usable[cur_page_in] == FALSE) pause_calculation();
	}
	if (watermark == cur_page_in) 
	{
		watermark = (-1);
		if(calc_info.status==IDLE)
			if(start_synthesizer()==ST_NO_ERROR)
			{
				calc_info.status = RUNNING;
				feed_synthesizer(FALSE,FALSE);
			}
	}
}


finished_calculations()
{
	/* This function is called after all tables have been calculated by the
	   calc_engine.  Here is where all remaining pages are sent to the synth
	   and new_messages are processed */
int temp, last_page;
int i;
//DSPFix24 zero;

	temp = ((int) vm_page_size + (int) buffer_pages[cur_page_in]) - (int)cur_index_in;
	bzero(cur_index_in,temp);

	last_page = cur_page_in;
	buffer_page_usable[cur_page_in] = FALSE;
	cur_page_in = (cur_page_in+1)%PAGES;
	cur_index_in = (int *) buffer_pages[cur_page_in];

	if (calc_info.status == IDLE)
		if (start_synthesizer()==ST_NO_ERROR) 
		{
			calc_info.status = RUNNING;
		}
	while(cur_page_out!=last_page)
	{
		feed_synthesizer(FALSE,FALSE);
		if (calc_info.status == ERASED) break;
		poll_port(FALSE);
	}
	feed_synthesizer(FALSE, TRUE);

	cur_page_out = cur_page_in;
}


pause_calculation()
{
	/* Currently a stub function (i.e. do nothing) */
	/* This function is called when all vm pages are full.  Here, even
	   though the calculation engine is paused, messages and synth
	   stuff can still be processed */
	while (buffer_page_usable[cur_page_in] == FALSE)
	{
		feed_synthesizer(FALSE,FALSE);
		if (calc_info.status == ERASED) break;

		/* NOTE: This command put in to prevent Synthesizer lock-ups.
			 May not work properly  *** */
/*		poll_port(FALSE);*/
	}
}
continue_synth()
{
	switch(calc_info.status)
	{
		case IDLE:
		case PAUSED:
				if (start_synthesizer()==ST_NO_ERROR) 
				{
					calc_info.status = RUNNING;
				}
				break;
		case TO_BE_PAUSED:
				calc_info.status = RUNNING;
				break;
		default:
				break;
	}
}

feed_synthesizer(block, last)
int block, last;
{

	while(1)
	{
		switch(calc_info.status)
		{
			case PAUSED: poll_port(FALSE);
			case IDLE:
					if (!block) return(0);
					break;

			case TO_BE_PAUSED:
					pause_synth();
					if (!block) return(0);
					break;
			case TO_BE_ERASED:
					pause_synth();
					calc_info.status = ERASED;
					return(0);
			case ERASED: return(0);
			case RUNNING:
			default:
					if (last) await_request_new_page(ST_YES, ST_YES, update_synth_ptr);
					else await_request_new_page(ST_NO, ST_NO, update_synth_ptr);
					if (!block) return(0);
		}
		poll_port(FALSE);
	}
}

pause_synth()
{
/*	if (calc_info.status == TO_BE_ERASED)
	{
		await_request_new_page(ST_NO, ST_YES, update_synth_ptr);
		return(0);
	}
	else
	{*/
		await_request_new_page(ST_YES, ST_YES, update_synth_ptr);
		calc_info.status = PAUSED;
/*	}*/
}

phone_string(string)
char *string;
{
byte syllable,word,salient,marked, final;
int length, index, phone_index, continue_index, tone_group_boundary, tone_groups;
int i;
char temp[10], last_phone[10];

//	printf("%s\n", string);
	tone_groups = index = 0;
	length = strlen(string);
	bzero(last_phone,10);

	final = syllable = salient = marked = (byte)0;
	word = (byte)1;

	for(i = 0; i<SYSPrefill; i++)
	{
		new_phone("^",(byte)0, (byte)0, (byte)0, (byte)0);
	}

	while(index<length)
	{

		if (string[index] == '\n') index++;
		if (index>=length) break;

		tone_group_boundary = (-1);
		phone_index = next_phone(string, index, length, &continue_index, &tone_group_boundary);
		if (tone_group_boundary !=(-1)) tone_groups++;

		if (tone_groups >1)
		{
			rewrite("^", word);
			index = tone_group_boundary;
			break;
		}

		if (phone_index == (-1))
		{
			rewrite("^", word);
			break;
		}
		bzero(temp,10);
		syllable = salient = word = (byte)0;
		parse_up_to(string, index, phone_index, &syllable, &word, &salient, &marked, &final);
		strncpy(temp, &string[phone_index], continue_index-phone_index);

		rewrite(temp, word);
		index = continue_index;

		/* This next if statement is a KLUDGE! for the "OI" problem */
		if (strcmp(temp, "oi")==0)
		{
			if (salient)
			{
				new_foot(marked, utterance_type);
				new_phone("o", (byte)1, (byte)syllable, (byte)word, (byte)final);
				new_phone("i", (byte)0, (byte)0, (byte)0, (byte)final);
				strcpy(temp,"i");
			}
			else
			{
				new_phone("o", (byte)0, (byte)syllable, (byte)word, (byte)final);
				new_phone("i", (byte)0, (byte)0, (byte)0, (byte)final);
				strcpy(temp,"i");
			}
		}
		else 
		/* KLUDGE ends here */
		if (temp[0] != '\000')
			if (salient)
			{
				new_foot(marked, utterance_type);
				new_phone(temp, (byte)1, (byte)syllable, (byte)word, (byte)final);
			}
			else
				new_phone(temp, (byte)0, (byte)syllable, (byte)word, (byte)final);

	}
	new_phone("^", (byte)0, (byte)0, (byte)0, (byte)0);
	new_phone("^", (byte)0, (byte)0, (byte)0, (byte)0);
	finish_structs();

	return(index);
}

next_phone(string, index, length, continue_index, tone_group)
char *string;
int index, length, *continue_index, *tone_group;
{
int new_index;

	while( ((string[index]<'a') || (string[index]>'z')) && (index<length))
	{
		if ((string[index]=='^') || ( (string[index]=='*') && (string[index-1]!='/'))) 	/* Special case for * and ^ */
		{
			*continue_index = index+1;
			return(index);
		}
		if ((string[index] == '/') && (string[index+1] == 'c'))
		{
			*tone_group = index;
			index++;
		}
		if ((string[index] == '/') && (string[index+1] == 'l')) index++;
		index++;
	}
	if (index>=length) return(-1);
	new_index = index;
	while( (string[new_index]>='a') && (string[new_index]<='z') && (new_index<length)) new_index++;
	*continue_index = new_index;

	return(index);
}

parse_up_to(string, index, high_index, syllable, word, salient, marked, final)
char *string;
int index;
byte *syllable, *word, *salient, *marked, *final;
{

	while(index<high_index)
	{
		switch(string[index])
		{
			case '/':
				switch(string[index+1])
				{
					case '*': index +=2;
						  *salient = (byte) 1;
						  *marked = (byte)1;
						  break;
					case '/': index +=2;
						  *marked = (byte)0;
						  break;
					case '_': index +=2;
						  *salient = (byte) 1;
						  *marked = (byte)0;
						  break;
					case 'l': index +=2;
						  *final = (byte) 1;
						  break;
					case '0': index +=2;
						  utterance_type = TYPE_STATEMENT;
						  break;
					case '1': index +=2;
						  utterance_type = TYPE_EXCLAIMATION;
						  break;
					case '2': index +=2;
						  utterance_type = TYPE_QUESTION;
						  break;
					case '3': index +=2;
						  utterance_type = TYPE_CONTINUATION;
						  break;
					default:  index++;
						  break;
				}
				 break;

			case ',': /*new_phone("^",(byte)0, (byte)0, (byte)0, (byte)0);*/
				  index++;
				  break;

			case '.': *syllable = (byte)1;
				  index++;
				  break;

			case ' ': *word = (byte)1;
				  *syllable = (byte)1;
				  index++;
				  break;

			case '\'': *salient = (byte)1;
				  index++;
				  break;

			default: index++;
				 break;
		}
	}
}

rewrite(temp, word)
char *temp;
byte word;
{
	if (cur_phone == 0) return;
	switch(phones[cur_phone-1].token[0])
	{
		case 'h': switch(phones[cur_phone-1].token[1])
			  {
				case '\000': if (phoneInCategory(temp, "vocoid"))
						strcat(phones[cur_phone-1].token, temp);
					     else if (temp[0] == 'w') strcat(phones[cur_phone-1].token, "w");
					     else if (temp[0] == 'y') strcat(phones[cur_phone-1].token, "y");
//					     printf("rewriting h -> %s\n", phones[cur_phone-1].token);
					     break;
				default: break;
			  }

			  break;

		case 'r':
		case 'l': 
/*			  printf("rewriting %s -> ", phones[cur_phone-1].token);*/
			  if (!phoneInCategory(temp, "vocoid"))
				strcat(phones[cur_phone-1].token, "-");
/*			  printf("%s\n", phones[cur_phone-1].token);*/
			  break;

		default: if (word == (byte)1)
				if ((phones[cur_phone-1].vocallic == (byte) 1) &&
				    (phoneInCategory(temp, "vocoid")))
				{
					new_phone("gs", (byte)0, (byte)0, (byte)0, (byte)0);
/*					printf("Adding gs between %s and %s\n", phones[cur_phone-2].token,
						 temp);*/
				}

			 break;
	}

}

build_events()
{
register int i;
int time = 0;
float delta;

	for (i = 0;i<cur_foot+1;i++)
	{
		build_foot(&time,i);
		/* more to come */
	}
	delta = (-11.0/((float)((time*2)/1000)+1.5))/1000.0;
/*	if (utterance_type == TYPE_QUESTION) delta = -delta;*/
	current_deltas[12] = delta;
	total_time = (float) time;
}


build_foot(time, foot_number)
int *time;
int foot_number;
{
int i, j, k, event_time, to, temp_dur, maj_ev;
char *x,*y;
struct _diphoneHeader *header;
struct _intervalHeader *intHeader;
float duration, stretched_dur, temp_time, samples, percent, interval, temp_rhythm_mult;
float deltas[12], targets[12];
float no_targets[12] = {-1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0 };
vm_address_t diphone_page;

	i = feet[foot_number].index1;
	to = feet[foot_number].index2;

	temp_time = 0.0;
	temp_rhythm_mult = 1.0/0.9;
	while(i<=to)
	{
		/* If an unmarked phone is in a marked foot, make the phone marked */
		if (feet[foot_number].marked == (byte)1)
			if (!rindex(phones[i].token, '\''))
				strcat(phones[i].token, "'");

		x = phones[i].token;			/* Construct diphone */
		y = phones[i+1].token;
		if (y[0] == '\000') break;

		diphone_page = paged_diphone(x,y);
		header = (struct _diphoneHeader *) diphone_page;
		intHeader = (struct _intervalHeader *) ((int)diphone_page + sizeof(struct _diphoneHeader));

		phones[i].time = (*time)+temp_time;


		if ((phones[i].syllable==(byte)1) || (phones[i].word==(byte)1)) temp_rhythm_mult = 1.0;
		/* Rhythm calculations */
		samples = (float)(feet[foot_number].duration);
		samples *= (phones[i].regression - 1.0) * temp_rhythm_mult;
		percent = (float) phones[i].duration / (float) feet[foot_number].duration;
		samples *=percent;

		maj_ev = 0;

		for (j = 0;j<header->intervals;j++)		/* Loop through events */
		{
			temp_dur = (intHeader->coded_duration&0x80000000);
			if (!temp_dur) maj_ev++;

			duration = (float)(intHeader->coded_duration&0x0000FFFF);

			if (calc_info.elasticity == TTS_ELASTICITY_UNIFORM)
			{
				interval = (float) floor( (double)(samples*(1.0/header->intervals))+0.5);
				stretched_dur = duration + interval;
				if (stretched_dur<1.0) stretched_dur = 1.0;
			}
			else
			{
				if (intHeader->stretch_factor == 0.0)
					stretched_dur = duration;
				else
				{
					interval = (float) floor( (double)(samples*intHeader->stretch_factor)+0.5);
					stretched_dur = duration + interval;
					if (stretched_dur<1.0) stretched_dur = 1.0;
				}
			}

			event_time =(*time) + (int)(temp_time);

			if (maj_ev==2) phones[i+1].onset = event_time;

			for (k = 0;k<12;k++)
			{
				deltas[k] = intHeader->parm[k]/stretched_dur;
//				printf("%f ", intHeader->parm[k]);
			}
//			printf("\n");
			if (event_time>=0) 
				if (j == 0)
					insert_event(event_time, deltas, phones[i].foot, phones[i].syllable, 
						phones[i].word);
/*					insert_event(event_time, deltas,targets, phones[i].foot, phones[i].syllable, 
						phones[i].word);*/
				else
					insert_event(event_time, deltas, phones[i].foot, phones[i].syllable, 
						phones[i].word);
/*					insert_event(event_time, deltas,no_targets, phones[i].foot, phones[i].syllable, 
						phones[i].word);*/

			intHeader =  (struct _intervalHeader *)((int)intHeader+sizeof(struct _intervalHeader));

			temp_time+=stretched_dur;
		}
/*		printf("Phone: %d  time: %d  onset:%d\n", i, phones[i].time, phones[i].onset);*/
		i++;
	}
	(*time) += temp_time;
}


speak_next_message()
{
char *text, *phones, *rhythmData = NULL;
int ident, chunks, index = 0, first = 1;
struct timeval tp, tp1, tp2, tp3, tp4, tp5;
struct timezone tzp;


	if (message_queue_empty == FALSE)
	{
		if (speak_messages[out_speak_message].status!=ERASED)
		{
			text = speak_messages[out_speak_message].text;
			chunks = calc_chunks(text);

//			printf("|%s|%d:%d:%d\n|%s|\n", speak_messages[out_speak_message].filePath,
//				speak_messages[out_speak_message].uid,speak_messages[out_speak_message].gid, chunks, text);

			while(chunks>0)
			{
				init_utterance();

				index += phone_string(&text[index]);
				regression();
				build_events();
				intonation();
				if (speak_messages[out_speak_message].rhythm)
				{
					if (!rhythmData)
					{
						rhythmData = (char *) malloc(64*1024);
						bzero(rhythmData, 64*1024);
					}
					buffer_rhythm_data(rhythmData);
				}
				else
				{
					if (first == 1)
					{
						while(synth_status==ST_RUN);
						set_synthesizer_output(speak_messages[out_speak_message].filePath, 
							speak_messages[out_speak_message].uid,
							speak_messages[out_speak_message].gid, chunks);
						first = 0;
					}
//					while(synth_status==ST_RUN);
					do_calc();
				}
				chunks--;
				if (calc_info.status == ERASED) break;
			}
		}
/*		printf("init: %d\n", (tp1.tv_sec*1000000 + tp1.tv_usec) - (tp.tv_sec*1000000 + tp.tv_usec));
		printf("phone_string: %d\n", (tp2.tv_sec*1000000 + tp2.tv_usec) - (tp1.tv_sec*1000000 + tp1.tv_usec));
		printf("rhythm: %d\n", (tp3.tv_sec*1000000 + tp3.tv_usec) - (tp2.tv_sec*1000000 + tp2.tv_usec));
		printf("build_events: %d\n", (tp4.tv_sec*1000000 + tp4.tv_usec) - (tp3.tv_sec*1000000 + tp3.tv_usec));
		printf("intonation: %d\n", (tp5.tv_sec*1000000 + tp5.tv_usec) - (tp4.tv_sec*1000000 + tp4.tv_usec));
		printf("Total: %d\n", (tp5.tv_sec*1000000 + tp5.tv_usec) - (tp.tv_sec*1000000 + tp.tv_usec));
*/

		if (speak_messages[out_speak_message].rhythm)	/* Send rhythm data message */
		{
			send_string_message(calc_info.rhythm_port, PORT_NULL, 0, ident, rhythmData);
//			printf("%s\n", rhythmData);
			free(rhythmData);
		}
		if (speak_messages[out_speak_message].filePath) 
			free(speak_messages[out_speak_message].filePath);

		if (calc_info.block) send_int_message(calc_info.block_port, PORT_NULL, 0, ident, TTS_OK);
		calc_info.status = NONE;
		calc_info.identifier = (-1);
		free(speak_messages[out_speak_message].text);
		speak_messages[out_speak_message].ident = (-1);
		speak_messages[out_speak_message].text = NULL;
		out_speak_message = (out_speak_message+1)%MAX_SPEAK_MESSAGES;
		if (out_speak_message == in_speak_message) message_queue_empty = TRUE;
	}

}

find_next_speak_message(ident)
int ident;
{
int temp;

	temp = (out_speak_message+1)%MAX_SPEAK_MESSAGES;
	while(speak_messages[temp].ident!=ident)
	{
		if (temp==in_speak_message) return(-1);
		temp = (temp+1)%MAX_SPEAK_MESSAGES;
	}
	return(temp);
}

erase_all_utterances(ident)
int ident;
{
int temp;

	temp = (out_speak_message+1)%MAX_SPEAK_MESSAGES;
	while(temp!=in_speak_message)
	{
		if (speak_messages[temp].ident == ident) speak_messages[temp].status = ERASED;
		temp = (temp+1)%MAX_SPEAK_MESSAGES;
	}
	return(0);
}

calc_chunks(string)
char *string;
{
int temp = 0, index = 0;

	while(string[index]!='\000')
	{
		if ((string[index] == '/') && (string[index+1] == 'c'))
		{
			temp++;
			index+=2;
		}
		else index++;		
	}
	temp--;
	if (temp<0) temp = 0;
	return(temp);
}

float *parse_groups(number, fp)
int number;
FILE *fp;
{
float *temp;
char line[256];
int index;

	index = 0;
	temp = (float *) malloc(sizeof(float)*10*number);
	while(number)
	{
		fgets(line, 256, fp);
		sscanf(line, " %f %f %f %f %f %f %f %f %f %f", 
			&temp[index], &temp[index+1], &temp[index+2], &temp[index+3], &temp[index+4], 
			&temp[index+5], &temp[index+6], &temp[index+7], &temp[index+8], &temp[index+9]);
		index+=10;
		number--;
	}
	return(temp);

}

init_tone_groups(systemPath)
const char *systemPath;
{
FILE *fp;
float temp;
char line[256];
int tgparms, count = 0;
#define intonation_name "/intonation"
char tempPath[256];

        strcpy(tempPath, systemPath);
        strcat(tempPath, intonation_name);
	fp = fopen(tempPath, "r");
	if (fp == NULL) 
	{
		NXLogError("TTS_Server: Cannot open Intonation file.");
		return(-1);
	}
	while(fgets(line, 256, fp)!=NULL)
	{
		if ((line[0] == '#') || (line[0] == ' '));
		else if (strncmp(line,"TG",2)==0)
		{
			sscanf(&line[2]," %d", &tg_count[count]);
			tg_parameters[count] = parse_groups(tg_count[count], fp);
			count++;
		}
		else if (strncmp(line,"RANDOM",6)==0)
		{
			sscanf(&line[6]," %f", &intonation_random);
		}
	}
	fclose(fp);
/*	print_tone_groups();*/
}

print_tone_groups()
{
int i, j, k;
float *temp;

	printf("Intonation random = %f\n", intonation_random);
	printf("Tone groups: %d %d %d %d %d\n", tg_count[0], tg_count[1], tg_count[2],
		tg_count[3], tg_count[4]);

	for(i = 0; i<5; i++)
	{
		temp = tg_parameters[i];
		printf("Temp [%d] = %d\n", i, temp);
		j = 0;
		for(k = 0;k<tg_count[i];k++)
		{
			printf("%f %f %f %f %f %f %f %f %f %f\n", 
				temp[j], temp[j+1], temp[j+2], temp[j+3], temp[j+4], 
				temp[j+5], temp[j+6], temp[j+7], temp[j+8], temp[j+9]);
			j+=10;
		}
	}

}

intonation()
{
int tonics, nexttonic;
int pindex, pfoot;
float ptargets[250], ptime[250], tonic_delta;
float *pitch_parameters;
int select;

	calc_onsets_for_feet();
	bzero(ptargets,sizeof(float)*250);
	bzero(ptime,sizeof(float)*250);
	pfoot = pindex = 0;
	tonics = find_tonics();

	ptargets[0] = 0.0;
	ptime[0] = 0.0;
	pindex = 1;

	while(tonics)
	{
		nexttonic = find_next_tonic(pfoot);

		switch((int)feet[nexttonic].tone_group)
		{
			case TYPE_STATEMENT:
				if (calc_info.intonation & TTS_INTONATION_RANDOMIZE) select = random()%tg_count[0];
				else select = 0;
//				printf("Tone Group 1: Select = %d\n", select);
				pitch_parameters = (float *) ((int)tg_parameters[0] + select*40);
				break;

			case TYPE_QUESTION:
				if (calc_info.intonation & TTS_INTONATION_RANDOMIZE) select = random()%tg_count[1];
				else select = 0;
//				printf("Tone Group 2: Select = %d\n", select);
				pitch_parameters = (float *) ((int)tg_parameters[1] + select*40);
				break;

			case TYPE_EXCLAIMATION:
				if (calc_info.intonation & TTS_INTONATION_RANDOMIZE) select = random()%tg_count[0];
				else select = 0;
				select = random()%tg_count[0];
//				printf("Tone Group 1: Select = %d\n", select);
				pitch_parameters = (float *) ((int)tg_parameters[0] + select*40);
				break;

			case TYPE_CONTINUATION:
				if (calc_info.intonation & TTS_INTONATION_RANDOMIZE) select = random()%tg_count[2];
				else select = 0;
//				printf("Tone Group 3: Select = %d\n", select);
				pitch_parameters = (float *) ((int)tg_parameters[2] + select*40);
				break;
			default:
//				printf("Tone Group undefined.\n");
				break;
		}
		calc_pre_tonic(pitch_parameters, nexttonic, &pfoot, &pindex, ptargets, ptime);

		calc_tonic(pitch_parameters, &pfoot, &pindex, ptargets, ptime, tonics);

		tonics--;
	}
	convert_targets_to_deltas(ptargets, ptime, pindex);
}

#ifdef DEBUG
old_calc_pre_tonic(pitch_parameters, nexttonic, pfoot, pindex, ptargets, ptime)
float *pitch_parameters, *ptargets, *ptime;
int nexttonic;
int *pfoot, *pindex;
{
float pretonic_delta, notional_pitch;
int time1,time2, x,y;
int base_time, tonic_time;

	base_time = phones[feet[*pfoot].index1].time;
	tonic_time = phones[feet[nexttonic].index1].time;

	pretonic_delta =  (pitch_parameters[2]) / (float)(tonic_time-base_time);
	notional_pitch = pitch_parameters[1];


	while(*pfoot<nexttonic)			/* Deal with pre-tonics */
	{

		x = feet[*pfoot].index1;
		y = feet[*pfoot].index2;
		time1 = phones[x].time;
		time2 = phones[y+1].time;
		if (time2<=time1) time2 = phones[y].time;

		ptime[*pindex] = ( ((float)(time2-time1))*pitch_parameters[8])+(float)time1;
		ptargets[*pindex] = (pretonic_delta*ptime[*pindex])+pitch_parameters[3] + notional_pitch;
		if (calc_info.random) ptargets[*pindex] += intonation_random*gaussian();
		(*pindex)++;

		ptime[*pindex] = (float)time2;
		ptargets[*pindex] = (pretonic_delta*(float)time2)+ notional_pitch;
		if (calc_info.random) ptargets[*pindex] += intonation_random*gaussian();

		(*pindex)++;
		(*pfoot)++;
	}
}

old_calc_tonic(pitch_parameters, pfoot, pindex, ptargets, ptime)
float *pitch_parameters, *ptargets, *ptime;
int *pfoot, *pindex;
{
float tonic_delta, notional_pitch;
int time1,time2, x,y;

	x = feet[*pfoot].index1;
	y = feet[*pfoot].index2;
	time1 = phones[x].time;
	time2 = phones[y+1].time;
	if (time2<=time1) time2 = phones[y].time;

	tonic_delta =  (pitch_parameters[5]) / (float)(time2-time1);
	notional_pitch = pitch_parameters[1]+pitch_parameters[2]+pitch_parameters[4];

	if (pitch_parameters[4]!=0.0)
	{
		ptime[*pindex] = (float)(time1+1);
		ptargets[*pindex] = notional_pitch;
		(*pindex)++;
	}
	ptime[*pindex] = ( ((float)(time2-time1))*pitch_parameters[9])+(float)time1;
	ptargets[*pindex] = (tonic_delta*(ptime[*pindex]-(float)time1))+pitch_parameters[6]+ notional_pitch;
	if (calc_info.random) ptargets[*pindex] += intonation_random*gaussian();

	(*pindex)++;

	ptime[*pindex] = (float)time2;
	ptargets[*pindex] = (tonic_delta*(float)(time2-time1))+ notional_pitch;
	if (calc_info.random) ptargets[*pindex] += intonation_random*gaussian();

	(*pindex)++;
	(*pfoot)++;

}
#endif

calc_pre_tonic(pitch_parameters, nexttonic, pfoot, pindex, ptargets, ptime)
float *pitch_parameters, *ptargets, *ptime;
int nexttonic;
int *pfoot, *pindex;
{
float pretonic_delta, notional_pitch;
int time1,time2, x,y;
int base_time, tonic_time;

	base_time = feet[*pfoot].onset1;
	tonic_time =feet[nexttonic].onset1;

	pretonic_delta =  (pitch_parameters[2]) / (float)(tonic_time-base_time);
	notional_pitch = pitch_parameters[1];


	while(*pfoot<nexttonic)			/* Deal with pre-tonics */
	{

		time1 = feet[*pfoot].onset1;
		time2 = feet[*pfoot].onset2;

		ptime[*pindex] = (float)time1;
		ptargets[*pindex] = (pretonic_delta*time1)+pitch_parameters[3] + notional_pitch;
		if (calc_info.random) ptargets[*pindex] += intonation_random*gaussian();
		(*pindex)++;

		if ((time2>0) && (*pfoot!=0))
		{
			ptime[*pindex] = (float)time2;
			ptargets[*pindex] = (pretonic_delta*(float)time2)+ notional_pitch;
			if (calc_info.random) ptargets[*pindex] += intonation_random*gaussian();
			(*pindex)++;
		}

		(*pfoot)++;
	}
}

calc_tonic(pitch_parameters, pfoot, pindex, ptargets, ptime, tonic_number)
float *pitch_parameters, *ptargets, *ptime;
int *pfoot, *pindex, tonic_number;
{
float tonic_delta, notional_pitch;
int time1,time2, x,y, offset1;

/*	printf("Tonic number %d  pfoot: %d   cur_foot: %d\n", tonic_number, *pfoot, cur_foot);*/
	time1 = feet[*pfoot].onset1;
	offset1 = feet[*pfoot].offset1;
	if (tonic_number>1)
		time2 = feet[*pfoot].onset2;
	else
		time2 = phones[feet[cur_foot].index2].time;
	y = feet[*pfoot].index2;

	if (time2!=(-1)) tonic_delta =  (pitch_parameters[5]) / (float)(time2-time1);
	else 
	{
		if (time1> phones[feet[*pfoot].index1].time)
			time1 = phones[feet[*pfoot].index1].time;
		tonic_delta =  (pitch_parameters[5]) / (float)(phones[y].time-time1);
	}
	notional_pitch = pitch_parameters[1]+pitch_parameters[2]+pitch_parameters[4];

	ptime[*pindex] = (float)time1;
	ptargets[*pindex] = notional_pitch;
	if (calc_info.random) ptargets[*pindex] += intonation_random*gaussian();

	(*pindex)++;

	ptime[*pindex] = offset1;
	ptargets[*pindex] = (tonic_delta*(float)(ptime[*pindex]-time1))+ notional_pitch + pitch_parameters[6];

	(*pindex)++;

	if (time2>0)
		ptime[*pindex] = (float)time2;
	else
		ptime[*pindex] = (float) phones[y].time;
	ptargets[*pindex] = (tonic_delta*(float)(ptime[*pindex]-time1))+ notional_pitch;

	if (calc_info.random) ptargets[*pindex] += intonation_random*gaussian();

	(*pindex)++;
	(*pfoot)++;

}

convert_targets_to_deltas(ptargets, ptime, pindex)
float *ptargets, *ptime;
int pindex;
{
int i = 0;
float rise, run, delta;

/*	printf("Convert_to_deltas:%d\n", pindex);*/
	while(i<pindex)
	{
//		printf("%f [+1]%f\n", ptime[i], ptime[i+1]);
		if ((ptime[i]>=0.0) && (ptime[i]!=ptime[i+1]))
		{
			if (ptime[i] == 0.0)
				current_values[13] = ptargets[i];
			if (ptargets[i+1]>10.0) ptargets[i+1] = 10.0;
			if (ptargets[i+1]<-7.0) ptargets[i+1] = -7.0;
			rise = ptargets[i+1] - ptargets[i];
			run = ptime[i+1] - ptime[i];
			delta = rise/run;
/*			printf("[%d] = %f\n", i, ptargets[i]);*/
/*			printf("Time[%d] = %f   target[%d] = %f  rise = %f  run = %f  delta = %f ptime+1 = %f\n", 
				i, ptime[i], i, ptargets[i], rise, run, delta, ptime[i+1]);*/
			insert_pevent((int)ptime[i],delta);
		}
		i++;
	}
/*	printf("\n\n");*/
}

find_tonics()
{
int i, temp = 0;

	for (i = 0 ; i<=cur_foot; i++)
		if (feet[i].marked == (byte)1)
		{
/*			printf("Foot[%d] = tonic\n", i);*/
			temp++;
		}

	return(temp);
}

find_next_tonic(pfoot)
int pfoot;
{
int i;

	for (i = pfoot ; i<=cur_foot; i++)
		if (feet[i].marked == (byte)1) return(i);

	return(cur_foot);
}

calc_onsets_for_feet()
{
int i;
	for (i = 0 ; i<=cur_foot; i++)
		calc_onsets_for_foot(i);

}

calc_onsets_for_foot(foot)
int foot;
{
int i;
int first = (-1), second = (-1), offset1 = (-1), offset2 = (-1) ;

	for (i=feet[foot].index1; i<=feet[foot].index2;i++)
	{
/*		printf("Phone: %s  vocallic: %d  onset: %d\n", phones[i].token, (int) phones[i].vocallic, 
			phones[i].onset);*/
		if (phones[i].vocallic == (byte) 1)
		{
			if (first == (-1))
			{
				first = phones[i].onset;
				i++;
				while(phones[i].syllable||phones[i].word) 
				{
					if ( (offset1 == (-1)) && (phones[i].vocallic == (byte)0))
						offset1 = phones[i].onset;
					i++;
				}
				if (offset1 == (-1)) offset1 = phones[i].onset;
				if (i>feet[foot].index2) break;
			}
			else 
			{
				second = phones[i].onset;
				i++;
				while(phones[i].syllable||phones[i].word) 
				{
					if ( (offset2 == (-1)) && (phones[i].vocallic == (byte)0))
						offset2 = phones[i].onset;
					i++;
				}
				if (offset2 == (-1)) offset2 = phones[i].onset;
				if (i>feet[foot].index2) break;
				break;
			}
		}
	}
	if (first == (-1)) first = phones[feet[foot].index2].time;
	feet[foot].onset1 = first;
	feet[foot].onset2 = second;
	feet[foot].offset1 = offset1;
	feet[foot].offset2 = offset2;

/*	printf("Foot: %d  first: %d  offset1: %d  second:%d  offset2: %d\n", foot, first, offset1, second, offset2);*/
}


/* 
printf("cd: %d  st:%f 1:%2.2f 2:%2.2f 3:%2.2f 4:%2.2f 5:%2.2f 6:%2.2f 7:%2.2f 8:%2.2f 9:%2.2f 10:%2.2f 11:%2.2f 12:%2.2f\n", 
		intHeader->coded_duration, intHeader->stretch_factor, intHeader->parm[0], intHeader->parm[1],
		intHeader->parm[2], intHeader->parm[3], intHeader->parm[4], intHeader->parm[5], intHeader->parm[6],
		intHeader->parm[7], intHeader->parm[8], intHeader->parm[9], intHeader->parm[10], intHeader->parm[11]);
*/

buffer_rhythm_data(rhythmData)
char *rhythmData;
{
int i, j, nextTime;
char temp[256], temp1[10];

	for (i = 0; i<cur_phone; i++)
	{
		sprintf(temp,"%s : " ,phones[i].token);
		nextTime = phones[i+1].time;
		if (nextTime == 0) nextTime = phones[i].time+100;
		while(j<cur_event)
		{
			if (events[j].time<nextTime)
			{
				sprintf(temp1, "%d ", events[j].time);
				strcat(temp, temp1);
				j++;
			}
			else
			{
				strcat(temp,"\n");
				break;
			}
		}
		if (j>=cur_event) strcat(temp,"\n");
		strcat(rhythmData, temp);

	}
}

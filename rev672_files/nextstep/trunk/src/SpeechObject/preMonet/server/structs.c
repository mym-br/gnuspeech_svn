#include <stdio.h>
#ifdef V2
#import <mach.h>
#endif
#ifdef V3
#import <mach/mach.h>
#endif
#include "diphone_module.h"
#include "structs.h"

static char file_id[] = "@(#)Structure Control. Author: Craig-Richard Schock. (C) Trillium, 1991, 1992, 1993.";

struct _event events[MAX_EVENTS];
int cur_event;

struct _pevent pevents[MAX_PEVENTS];
int cur_pevent;

struct _phone phones[MAX_PHONES];
int cur_phone;

struct _foot feet[MAX_FEET];
int cur_foot;

struct _pitch_movement pm[MAX_PMOVEMENTS];
int cur_pm;

int current_event;

struct _speak_messages speak_messages[MAX_SPEAK_MESSAGES];
int in_speak_message, out_speak_message, message_queue_empty;

int *buffer;
int buffer_pages[PAGES];
int buffer_page_usable[PAGES];
int cur_page_in, *cur_index_in, cur_page_out;

float regress_phones();

extern struct _calc_info calc_info;

init_all(systemPath)
const char *systemPath;
{
thread_t temp;
kern_return_t error;

	init_server();
	init_databases(systemPath);	/* Needs path */
	init_parser_module();
	init_tables();
	init_users();
	init_messages();
	init_tone_groups(systemPath);	/* Needs path */
	init_mainDict(systemPath);	/* Needs path */
	initialize_synthesizer_module();
//	spawn_synthesizer_thread(&temp);
//	error = thread_priority(temp, 20, FALSE);
//        if (error != KERN_SUCCESS)
//                mach_error("thread_priority() call failed", error);

}

init_messages()
{
int i;
	bzero(speak_messages, sizeof(struct _speak_messages)*MAX_SPEAK_MESSAGES);
	in_speak_message = out_speak_message = 0;
	message_queue_empty = TRUE;
	for (i = 0;i<MAX_SPEAK_MESSAGES;i++) speak_messages[i].ident = (-1);
}

init_tables()
{
kern_return_t ret;
int i;

	ret = vm_allocate(task_self(), (vm_address_t *)&buffer,vm_page_size*PAGES, TRUE);
	if (ret != KERN_SUCCESS)
	{
/*		fprintf(stderr,"structs.c: Cannot Allocate Memory for Buffer\n");*/
		exit(1);
	}

	/* Setup a quick page lookup table and flag each table as usable*/

	buffer_pages[0] = (int) buffer;
	buffer_page_usable[0] = TRUE;

	for(i = 1;i<PAGES;i++) 
	{
		buffer_pages[i] = buffer_pages[i-1]+(int)vm_page_size;
		buffer_page_usable[i] = TRUE;
	}

	cur_page_in = cur_page_out = 0;
	cur_index_in = buffer;

}

init_databases(systemPath)
const char *systemPath;
{
char *parameters[] = {"ax","f1","f2","f3","f4","ah1","ah2",
			"fh2","bwh2","fnnf","nb","micro",NULL};
#define degas_name "/diphones.degas"
#define degas_preload "/diphones.preload"
char tempPath[256];
char tempPath2[256];

	strcpy(tempPath, systemPath);
	strcat(tempPath, degas_name);

	strcpy(tempPath2, systemPath);
	strcat(tempPath2, degas_preload);

	if (init_diphone_module(tempPath,parameters,tempPath2) != 0)
	{
		NXLogError("TTS_Server: Cannot Open degas File");
		exit(-1);
	}
}

init_events()
{

	bzero(events,MAX_EVENTS*sizeof(struct _event));
	bzero(pevents,MAX_PEVENTS*sizeof(struct _pevent));
	bzero(phones,MAX_PHONES*sizeof(struct _phone));
	bzero(feet,MAX_FEET*sizeof(struct _foot));
	bzero(pm,MAX_PMOVEMENTS*sizeof(struct _pitch_movement));
	cur_pm = cur_pevent = cur_foot = cur_phone = cur_event = 0;

}

//insert_event(time,deltas,targets, foot,syllable,word)
insert_event(time,deltas, foot,syllable,word)
int time;
float *deltas;
//float *targets;
byte foot,syllable,word;
{
register int i = cur_event;

/*printf("Time: %d d1: %2.2f d2: %2.2f d3: %2.2f d4: %2.2f d5: %2.2f d6: %2.2f d7: %2.2f d8: %2.2f d9: %2.2f d10: %2.2f d11: %2.2f d12: %2.2f\n",
		time, deltas[0], deltas[1], deltas[2], deltas[3], deltas[4], deltas[5], deltas[6], deltas[7], deltas[8], deltas[9], 
		deltas[10], deltas[11]);*/
	events[i].time = time;
	bcopy(deltas,&events[i].deltas,sizeof(float)*12);
//	bcopy(targets,&events[i].targets,sizeof(float)*12);
	events[i].foot = foot;
	events[i].syllable = syllable;
	events[i].word = word;
	events[++cur_event].time = (-1);
/*	printf("Current_event = %d\n", cur_event);*/
}

insert_pevent(time,delta)
int time;
float delta;
{
register int i = cur_pevent;

/*	printf("Time: %d  Pevent: %f cur_pevent = %d\n", time, delta, cur_pevent);*/
	pevents[i].time = time;
	pevents[i].delta = delta;
	cur_pevent++;
	pevents[cur_pevent].time = 99999999;
}

finish_structs()
{
	feet[cur_foot].index2 = cur_phone-2;
/*	feet[cur_foot].marked = (byte)1;*/
}

new_foot(marked, utterance_type)
byte marked;
int utterance_type;
{
	feet[cur_foot].index2 = cur_phone-1;
	cur_foot++;
	feet[cur_foot].index1 = cur_phone;
	feet[cur_foot].marked = marked;
	feet[cur_foot].tone_group = (byte)utterance_type;
/*	printf("Feet = %d\n", cur_foot);*/
	if (cur_foot>MAX_FEET)
	{
		NXLogError("TTS_Server: Too many feet.");
		return(0);
	}
}

new_phone(token,foot,syllable,word, final)
char *token;
byte foot, syllable, word, final;
{
	strncpy(phones[cur_phone].token, token, 8);
	phones[cur_phone].foot = foot;
	phones[cur_phone].syllable = syllable;
	phones[cur_phone].word = word;
	phones[cur_phone].word = final;
	phones[cur_phone].vocallic = (byte)phoneInCategory(token, "vocoid");
/*	printf("Phone: %s  vocoid: %d\n", token, phones[cur_phone].vocallic);*/
	feet[cur_foot].num_items++;
	cur_phone++;
	if (cur_phone>MAX_PHONES)
	{
		NXLogError("TTS_Server: Too many phones.");
		return(0);
	}
	else
	phones[cur_phone].token[0] = '\000';
/*	printf("Phone = %d\n", cur_phone);*/
}

previous_phone_cat(token)
char *token;
{
int temp;
	temp = cur_phone-1;
	if (temp<0) temp = 0;
	strcat(phones[temp].token, token);

}

regression()
{
int current_foot,index1,index2;
float regression_foot;

	current_foot = 0;
	while(current_foot<cur_foot+1)
	{
		index1 = feet[current_foot].index1;
		index2 = feet[current_foot].index2;
		regression_foot = regress_phones(index1,index2,feet[current_foot].duration = 
			calc_duration(index1,index2,feet[current_foot].marked, current_foot),
			(int) feet[current_foot].num_items,feet[current_foot].marked);
		current_foot++;
	}
}

int calc_duration(from,to,marked, current_foot)
int from,to, current_foot;
byte marked;
{
int i;
char *x,*y;
int sum = 0;

	for(i = from;i<=to;i++)
	{

		x = phones[i].token;
		y = phones[i+1].token;
		if (y[0] == '\000') break;
		if (feet[current_foot].marked == (byte)1)
		{
			if (!rindex(x, '\''))
				strcat(phones[i].token, "'");
			if (!rindex(y, '\''))
				strcat(phones[i+1].token, "'");
		}

		phones[i].duration = diphone_duration(x,y);
		sum += phones[i].duration;
	}
	return(sum);
}

float regress_phones(from,to,total_duration,num_items,marked)
int from,to,total_duration,num_items;
byte marked;
{
int i, new_dur;
float percent,temp, temp_duration;
int sum = 0;

	if (marked == (byte)1)
	{
		temp = (117.7 - (19.36 * (float) num_items))/2.0;
		percent = (temp / (float)(total_duration))*100.0;
		for(i = from;i<=to;i++)
		{
			temp = (100.0+percent)/100.0;
			temp*=calc_info.speed;
			temp_duration = ((float)phones[i].duration * temp);
			new_dur = (int)temp_duration;
			sum+=(int)temp_duration;
			phones[i].regression = temp;
		}
	}
	else
	{
		temp = (18.5 - (2.08 * (float) num_items))/2.0;
		percent = (temp / (float)(total_duration))*100.0;
		for(i = from;i<=to;i++)
		{
			temp = (100.0+percent)/100.0;
			temp*=calc_info.speed;
			temp_duration = ((float)phones[i].duration * temp);
			sum+=(int)temp_duration;
			phones[i].regression = temp;
		}
	}
	temp = (float)total_duration/(float)sum;
	return(temp);
}

new_pm(time, index)
int time, index;
{
	pm[cur_pm].time = time;
	pm[cur_pm++].index = index;
}

print_pm()
{
int i;
	for(i = 0;i<cur_pm;i++)
		printf("Time = %d index = %d\n",pm[i].time,pm[i].index);
}


/* Currently Obsolete, Mar. 26, 1992 */
/*
print_data_structure()
{
register int i,temp,j;

	printf("Feet = %d  Phone = %d\n",cur_foot, cur_phone);
	for (i = 0;i<cur_phone;i++)
	{
		temp = phones[i].token;
		if ((temp<0) || (temp>88)) break;
		printf("Token: %3d  %3s  ", temp,post[temp]);
		printf("Word: %d  Syllable: %d  Foot: %d Regression: %f Duration: %d\n",(int)phones[i].word,
			(int)phones[i].syllable, (int)phones[i].foot, phones[i].regression, (int) phones[i].duration);
	}

	for (i = 0;i<cur_foot+1;i++)
	{
		printf("Foot #%d  Index1 = %d index2 = %d duration = %d marked = %d Num_items = %d\n", i,
			feet[i].index1, feet[i].index2, feet[i].duration,
			(int) feet[i].marked, (int) feet[i].num_items);
		for(j = feet[i].index1;j<=feet[i].index2;j++)
		{
			temp = phones[j].token;
			if ((temp<0) || (temp>88)) break;
			if (phones[j].syllable == (byte)1) printf(" | ");
			if (phones[j].word == (byte)1) printf(" ] [ ");
			if (phones[j].foot == (byte)1) printf(" / ");
			printf("%3s ",post[temp]);
		}
		printf("\n");
	}
	for(i = 0;i<cur_event;i++)
	{
		printf("Event #%3d : time: %4d deltas %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f\n", i,events[i].time,
			events[i].deltas[0],events[i].deltas[1],events[i].deltas[2],events[i].deltas[3],
			events[i].deltas[4],events[i].deltas[5],events[i].deltas[6],events[i].deltas[7],
			events[i].deltas[8],events[i].deltas[9]);
	}

}
*/

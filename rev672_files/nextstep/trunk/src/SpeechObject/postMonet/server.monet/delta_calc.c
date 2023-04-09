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

#import "RealTimeController.h"
#import "synthesizer_module.h"

static char file_id[] = "@(#)Delta Calculation Engine. Author: Craig-Richard Schock. (C) Trillium, 1991, 1992.";
static float silencePage[16] = {0.0, 0.0, 0.0, 0.0, 5.5, 2500.0, 500.0, 0.8, 0.89, 0.99, 0.81, 0.76, 1.05, 1.23, 0.01, 0.0};

struct _calc_info calc_info;

float intonation_random;
float *tg_parameters[5];
int tg_count[5];

struct _voiceConfig voices[MAX_VOICES];
float minBlack, minWhite;

int demoFlag;
int demoCount;

int setSoftware;

int vowelTransitions[13][13];

#define WAT_PAGES 6

extern int SYSPrefill;

extern float gaussian();

extern struct _speak_messages speak_messages[MAX_SPEAK_MESSAGES];
extern int in_speak_message, out_speak_message, message_queue_empty;

extern struct _user users[50];
extern unsigned char users_list[50];

extern RealTimeController *realTime;

init_utterance()
{
int identifier = speak_messages[out_speak_message].ident;
int voice;
FILE *fp;


	calc_info.identifier = identifier;
	calc_info.volume = users[identifier].volume;
	calc_info.speed = users[identifier].speed;
	calc_info.balance = users[identifier].balance;
	calc_info.intonation = users[identifier].intonation;
	calc_info.pitch_offset = users[identifier].pitch_offset;
	calc_info.block = users[identifier].block;
	calc_info.block_port = users[identifier].block_port;
	calc_info.voice_type = users[identifier].voice_type;
	calc_info.channels = users[identifier].channels;
	calc_info.vtlOffset = users[identifier].vtlOffset;
	calc_info.breathiness = users[identifier].breathiness;
	calc_info.samplingRate = users[identifier].samplingRate;
	calc_info.random = calc_info.intonation & 0x00000010;


	voice = calc_info.voice_type;

	if ((calc_info.samplingRate!=22050) && (calc_info.samplingRate!=44100))
		calc_info.samplingRate=22050;

//	printf("Tube Length = %f\n", calc_info.vtlOffset+voices[voice].meanLength);

	if ((calc_info.vtlOffset+voices[voice].meanLength) < 15.9)
		calc_info.samplingRate = 44100;

	calc_info.random = calc_info.intonation & TTS_INTONATION_RANDOMIZE;
	calc_info.uid = speak_messages[out_speak_message].uid;
	calc_info.gid = speak_messages[out_speak_message].gid;
	calc_info.filePath = speak_messages[out_speak_message].filePath;


//	printf("Voice: %d L: %f  tp: %f  tnMin: %f  tnMax: %f  glotPitch: %f\n", voice,
//		voices[voice].meanLength, voices[voice].tp, voices[voice].tnMin, 
//		voices[voice].tnMax, voices[voice].glotPitchMean);

//	printf("sampling Rate: %f\n", calc_info.samplingRate);

	[realTime setPitchMean:(double) users[identifier].pitch_offset+voices[voice].glotPitchMean];
	[realTime setGlobalTempo:(double) 1.0/ (double)users[identifier].speed];
	[realTime setIntonation:users[identifier].intonation];

	if ( (calc_info.filePath )&& (users[identifier].softwareSynthesis) )
	{
		setSoftware = 1;

		[realTime setSoftwareSynthesis: users[identifier].softwareSynthesis];

		fp = fopen("/tmp/Monet.parameters", "w");
		fprintf(fp,"%f\n%f\n%f\n%d\n%f\n%d\n%f\n%f\n%f\n%f\n%f\n32.0\n0.8\n3.05\n5000.0\n5000.0\n1.35\n1.96\n1.91\n1.3\n0.73\n1500.0\n6.0\n1\n48.0\n",
		calc_info.samplingRate, 250.0, 
		calc_info.volume,
		calc_info.channels,
		calc_info.balance, 
		0, 		/* Waveform */
		voices[voice].tp*100.0,		/* tp */
		voices[voice].tnMin*100.0,	/* tn Min */
		voices[voice].tnMax*100.0,	/* tn Max */
		calc_info.breathiness,
		calc_info.vtlOffset+voices[voice].meanLength, 
		32.0,	/* Temperature */
		0.8, 	/* Loss Factor */
		3.05,	/* Ap scaling */
		5000.0, 5000.0, 	/* Mouth and nose coef */
		1.35, 1.96, 1.91, 	/* n1, n2, n3 */
		1.3, 0.73,		/* n4, n5 */
		1500.0, 6.0,		/* Throat cutoff and volume */
		1, 48.0			/* Noise Modulation, mixOffset */
		);

		fclose(fp);
	}
	else
	{
		setSoftware = 0;
		[realTime setSoftwareSynthesis: 0 ];
		set_utterance_rate_parameters(calc_info.samplingRate, 250.0, 
			calc_info.volume,	/* Master Volume */
			calc_info.channels, 	/* Stereo/Mono */
			calc_info.balance,	/* Balance */
			0, 	/* WaveForm */
			voices[voice].tp*100.0,	/* tp */
			voices[voice].tnMin*100.0,	/* tn Min */
			voices[voice].tnMax*100.0,	/* tn Max */
			calc_info.breathiness,
			calc_info.vtlOffset+voices[voice].meanLength, 
			32.0,	/* Temperature */
			0.8, 	/* Loss Factor */
			3.05,	/* Ap scaling */
			5000.0, 5000.0, 	/* Mouth and nose coef */
			1.35, 1.96, 1.91, 	/* n1, n2, n3 */
			1.3, 0.73,		/* n4, n5 */
			1500.0, 6.0,		/* Throat cutoff and volume */
			1, 48.0,		/* Noise Modulation, mixOffset */
			users[identifier].pitch_offset+voices[voice].glotPitchMean,
			silencePage);

	}
}

speak_next_message()
{
char *text, *phones, *rhythmData = NULL;
int ident, chunks, index = 0, first = 1;
struct timeval tp, tp1, tp2, tp3, tp4, tp5;
struct timezone tzp;
char commandLine[1024];

	if (message_queue_empty == FALSE)
	{
		if (speak_messages[out_speak_message].status!=ERASED)
		{
			text = speak_messages[out_speak_message].text;
			chunks = calc_chunks(text);
			set_synthesizer_output(speak_messages[out_speak_message].filePath,
				speak_messages[out_speak_message].uid,
				speak_messages[out_speak_message].gid, chunks);

			calc_info.status = speak_messages[out_speak_message].status;
			while(chunks>0)
			{
				init_utterance();

//				printf("Speaking \"%s\"\n", &text[index]);
				[realTime synthesizeString: &text[index]];
//				printf("Calc Info Status = %d\n", calc_info.status);
				index+= next_chunk(&text[index+2])+2;
				chunks--;

				if ( (calc_info.status == ERASED) || (calc_info.status == TO_BE_ERASED))
					break;
				switch(calc_info.status)
				{
					case TO_BE_PAUSED:
					case PAUSED:
							calc_info.status = PAUSED;
							break;
					default:
							calc_info.status = IDLE;
				}

			}
		}

		if (speak_messages[out_speak_message].rhythm)	/* Send rhythm data message */
		{
			send_string_message(calc_info.rhythm_port, PORT_NULL, 0, ident, rhythmData);
			free(rhythmData);
		}
		if (setSoftware)
		{
			if (!calc_info.block)
			{
				sprintf(commandLine, "/usr/local/bin/tube /tmp/Monet.parameters %s &", 
				speak_messages[out_speak_message].filePath);
				system(commandLine);
			}
			else
			{
				sprintf(commandLine, "/usr/local/bin/tube /tmp/Monet.parameters %s", 
				speak_messages[out_speak_message].filePath);
				system(commandLine);
			}
		}

		if (calc_info.block) send_int_message(calc_info.block_port, PORT_NULL, 0, ident, TTS_OK);

		if (speak_messages[out_speak_message].filePath) 
			free(speak_messages[out_speak_message].filePath);
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

next_chunk(string)
char *string;
{
int temp = 0, index = 0;

	while(string[index]!='\000')
	{
		if ((string[index] == '/') && (string[index+1] == 'c'))
		{
			return index;
		}
		else index++;		
	}
	return(0);
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



void init_vowel_transitions(systemPath)
const char *systemPath;
{
char tempPath[256];
#define vowelTransPath "/vowelTransitions"
char dummy[24], line[256];
int i = 0, temp;
FILE *fp;

	bzero(vowelTransitions, 13*13*sizeof(int));
	strcpy(tempPath, systemPath);
	strcat(tempPath, vowelTransPath);
	fp = fopen(tempPath, "r");
	if (fp == NULL) 
	{
		NXLogError("TTS_Server: Cannot open vowel transitions file.");
		return;
	}
	while(fgets(line, 256, fp))
	{
		if (i==13) break;

		if ((line[0] == '#') || (line[0] == ' '));
		else
		{
			sscanf(line, "%s %d %d %d %d %d %d %d %d %d %d %d %d %d", dummy,
				&vowelTransitions[i][0], &vowelTransitions[i][1], &vowelTransitions[i][2], 
				&vowelTransitions[i][3], &vowelTransitions[i][4], &vowelTransitions[i][5], 
				&vowelTransitions[i][6], &vowelTransitions[i][7], &vowelTransitions[i][8], 
				&vowelTransitions[i][9], &vowelTransitions[i][10], &vowelTransitions[i][11], 
				&vowelTransitions[i][12]);
			i++;

			temp = (int)dummy[0];
			if (dummy[1]!='\'')
				temp+= (int)dummy[1];
//			printf("%d %d\n", i, temp);
		}
	}	

	return;
}

print_vowel_transitions()
{
int i;
	for (i = 0; i<13; i++)
	{
		printf("Transition %d: %d %d %d %d %d %d %d %d %d %d %d %d %d\n", i, 
				vowelTransitions[i][0], vowelTransitions[i][1], vowelTransitions[i][2], 
				vowelTransitions[i][3], vowelTransitions[i][4], vowelTransitions[i][5], 
				vowelTransitions[i][6], vowelTransitions[i][7], vowelTransitions[i][8], 
				vowelTransitions[i][9], vowelTransitions[i][10], vowelTransitions[i][11], 
				vowelTransitions[i][12]);
	}
}

init_voices(systemPath)
const char *systemPath;
{
FILE *fp;
char line[256];
#define voiceConfig_name "/voices.config"
char tempPath[256];
int currentVoice = 0, i;

	bzero(voices, sizeof(struct _voiceConfig)*MAX_VOICES);
	strcpy(tempPath, systemPath);
	strcat(tempPath, voiceConfig_name);
	fp = fopen(tempPath, "r");
	if (fp == NULL) 
	{
		NXLogError("TTS_Server: Cannot open voice configuration file.");
		return(-1);
	}
	while(fgets(line, 256, fp))
	{
		if ((line[0] == '#') || (line[0] == ' '));
		else
		{
			if (!strncmp(line, "MinBlack", 8))
				minBlack = atof(&line[8]);
			else
			if (!strncmp(line, "MinWhite", 8))
				minWhite = atof(&line[8]);
			else
			if (!strncmp(line, "Male", 4))
				currentVoice = 0;
			else
			if (!strncmp(line, "Female", 6))
				currentVoice = 1;
			else
			if (!strncmp(line, "LgChild", 7))
				currentVoice = 2;
			else
			if (!strncmp(line, "SmChild", 7))
				currentVoice = 3;
			else
			if (!strncmp(line, "Baby", 4))
				currentVoice = 4;
			else
			if (!strncmp(line, "length", 6))
				voices[currentVoice].meanLength = atof(&line[6]);
			else
			if (!strncmp(line, "tp", 2))
				voices[currentVoice].tp = atof(&line[2]);
			else
			if (!strncmp(line, "tnMin", 5))
				voices[currentVoice].tnMin = atof(&line[5]);
			else
			if (!strncmp(line, "tnMax", 5))
				voices[currentVoice].tnMax = atof(&line[5]);
			else
			if (!strncmp(line, "glotPitch", 9))
				voices[currentVoice].glotPitchMean = atof(&line[9]);

		}
	}
	fclose(fp);

//	printf("MinBlack = %f MinWhite = %f\n", minBlack, minWhite);
//	for (i = 0; i<MAX_VOICES; i++)
//	{
//		printf("L: %f  tp: %f  tnMin: %f  tnMax: %f  glotPitch: %f\n", 
//			voices[i].meanLength, voices[i].tp, voices[i].tnMin, 
//			voices[i].tnMax, voices[i].glotPitchMean);
//	}

}
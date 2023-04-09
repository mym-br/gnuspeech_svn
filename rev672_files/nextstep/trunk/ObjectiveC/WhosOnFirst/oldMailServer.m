#import <stdio.h>
#import <sys/dir.h>
#import <TextToSpeech/TextToSpeech.h>

/*===========================================================================

	File: mailServer.c
	Author: Craig-Richard Schock

	Purpose: This file holds the mail functions for the mailServer 
		 program.  

	Date: February 22, 1993.
	Last Modified: February 25, 1993.

===========================================================================*/

struct _messageInfo {
	int number;
	char *user;
	char **subjects;
};


struct _messageInfo messageInfo[512];

char mailPath[256];
char *mailFile;
char noneString[15] = {"No Subject"};
int bytes, messageTotal, messageUsers = 0;

char *next_message();

doMail()
{
int i;
FILE *fp;

	if (configure() == (-1)) exit(-1);

	parseMail();
	speak_summary();

	exit(0);
}

configure()
{
	messageTotal = 0;

	sprintf(mailPath, "/usr/spool/mail/%s", getlogin());

	bytes = get_size(mailPath);
	if (bytes<=0) 
		return (-1);

	return(0);
}

parseMail()
{
char *mailFile, *temp;
int begin = 0, end = 1, length;
FILE *fp;

	fp = fopen(mailPath, "r");
	if (fp == NULL) return(-1);

	mailFile = (char *) malloc(bytes+1);
	if (mailFile == NULL)
		exit(-1);
	bzero(mailFile, bytes+1);

	fread(mailFile, bytes, 1, fp);
	fclose(fp);

	while(begin<bytes)
	{
		temp = next_message(mailFile, &begin, &end, &length);
		parse_message(temp);
		free(temp);
		begin = end;
		messageTotal++;
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

char *next_message(mailFile, begin, end, length)
char *mailFile;
int *begin, *end, *length;
{
char *temp, *temp1;

	temp = dindex(&mailFile[(*begin)+1], "From ");

	if (temp)
		*end = (int)(temp - mailFile);
	else
		*end = (int)(bytes);

	*length = ((*end)-(*begin));
	temp1 = (char *) malloc( (*length)+1);
	bzero(temp1, (*length)+1);
	bcopy(&mailFile[(*begin)], temp1, *length);
	
	return(temp1);
}

parse_message(message)
char *message;
{
char *from = NULL, *sender = NULL, *subject = NULL;
char *temp;
char buffer[256];
int i;

	get_message_info(message, &from, &sender, &subject);

	figure_out_from_line(from, buffer);
//	printf("%d From:|%s|\nSubject:|%s|\n\n", messageTotal, buffer, subject);

	enter_user(buffer, subject);

	if (from) free(from);
	if (sender) free(sender);
	if (subject) free(subject);
}

get_message_info(message, from, sender, subject)
char *message, **from, **sender, **subject;
{
char *temp, line[256];

	bzero(line, 256);
	temp = dindex(message, "From:");
	if (temp)
	{
		get_address_line(&temp[5], line);
		*from = (char *) malloc(strlen(line)+1);
		strcpy(*from, line);
	}

	bzero(line, 256);
	temp = dindex(message, "Sender:");
	if (temp)
	{
		get_line(&temp[7], line);
		*sender = (char *) malloc(strlen(line)+1);
		strcpy(*sender, line);
	}

	bzero(line, 256);
	temp = dindex(message, "Subject:");
	if (temp)
	{
		get_line(&temp[8], line);
		*subject = (char *) malloc(strlen(line)+1);
		strcpy(*subject, line);
	}


}

get_line(buffer, output)
char *buffer, *output;
{
	while(*buffer == ' ') (buffer++);
	while(*buffer!='\n')
	{
		if (isupper(*buffer))
			*(output++) = tolower(*(buffer++));
		else
			*(output++) = *(buffer++);

	}
}

get_address_line(buffer, output)
char *buffer, *output;
{

	while((*buffer!='\n') && (*buffer != '\000'))
	{
		if (isupper(*buffer))
			*(output++) = tolower(*(buffer++));
		else
			*(output++) = *(buffer++);

	}
}

figure_out_from_line(string, buffer)
char *string, *buffer;
{
int i;
char *temp;

	if (!string) return;

	bzero(buffer,256);

	if (temp = index(string, '"'))
	{
		temp++;
		i = 0;
		while( (*temp!='\n') && (*temp!='"'))
		{
			buffer[i++] = *(temp++);
		}
//		printf("Found Quotes (%s)\n\n", buffer);
	}
	else
	if (temp = index(string, '('))
	{
		temp++;
		i = 0;
		while( (*temp!='\n') && (*temp!=')'))
		{
			buffer[i++] = *(temp++);
		}
//		printf("Found Brackets (%s)\n", buffer);

	}
	else
	if (temp = index(string, '<'))
	{
		while(string<temp)
		{
			while((*string==' ') && (string<temp)) string++;
			i = 0;
			while(string<temp)
				buffer[i++] = *(string++);
		}

//		printf("Found less-than sign(%s)\n", buffer);

	}
	else
	{
//		printf("Using:|%s|\n", string);
	}
}

enter_user(string, subject)
char *string, *subject;
{
int i, temp;
char *tempString;

//	printf("|%s| |%s|\n", string, subject);

	if (!string) return(0);
	for (i= 0; i<messageUsers; i++)
	{
		if (messageInfo[i].user==NULL) break;
		if (strcmp(messageInfo[i].user, string)==0)
		{
			temp = messageInfo[i].number;
			if (!subject)
			{
				tempString = noneString;
			}
			else
			{
				tempString = (char *) malloc(strlen(subject)+1);
				bzero(tempString, strlen(subject)+1);
				strcpy(tempString, subject);
			}
			messageInfo[i].subjects[temp] = tempString;
			messageInfo[i].number++;
			return(0);
		}
	}

//	printf("Entering User into Database\n");
	temp = messageUsers++;

	tempString = (char *) malloc(strlen(string)+1);
	bzero(tempString, strlen(string)+1);
	strcpy(tempString, string);

	messageInfo[temp].user = tempString;
	messageInfo[temp].number = 0;

	messageInfo[temp].subjects = (char **) malloc(sizeof (char *) * 512);

	if (!subject)
	{
		tempString = noneString;
	}
	else
	{
		tempString = (char *) malloc(strlen(subject)+1);
		bzero(tempString, strlen(subject)+1);
		strcpy(tempString, subject);
	}

	messageInfo[temp].subjects[0] = tempString;
	messageInfo[temp].number++;

	return(0);
}

print_users()
{
int i, j;

	printf("Writers: %d\n", messageUsers);
	for(i = 0; i<messageUsers; i++)
	{
		printf("Writer: %s (%d)\n", messageInfo[i].user, messageInfo[i].number);
		for(j = 0; j<messageInfo[i].number; j++)
			printf("\tSubject: %s\n", messageInfo[i].subjects[j]);

	}
}

speak_summary()
{
TextToSpeech *mySpeech;
int i, j;
char temp[1024];

	mySpeech = [[TextToSpeech alloc] init];
	if (!mySpeech)
	{
		sleep(6);
		mySpeech = [[TextToSpeech alloc] init];
	}

	if (!mySpeech)
	{
		sleep(5);
		mySpeech = [[TextToSpeech alloc] init];
	}
	if (!mySpeech) return (0);

	if (messageTotal<6)
	{
		bzero(temp, 1024);
		sprintf(temp, "You have %d mail messages.", messageTotal);
		[mySpeech speakText:temp];
		for (i = 0; i< messageUsers; i++)
		{
			if (messageInfo[i].number>1)
			{
				sprintf(temp, "%d messages from %s,", messageInfo[i].number, messageInfo[i].user);
				[mySpeech speakText:temp];
				for(j = 0; j< messageInfo[i].number; j++)
					[mySpeech speakText:messageInfo[i].subjects[j]];
			}
			else
			{
				sprintf(temp, "From %s,", messageInfo[i].user);
				[mySpeech speakText: temp];
				[mySpeech speakText:messageInfo[i].subjects[0]];
			}

		}
	}
	else
	if (messageUsers<6)
	{
                bzero(temp, 1024);
                sprintf(temp, "You have %d mail messages.", messageTotal);
                [mySpeech speakText:temp];
		for (i = 0; i<messageUsers; i++)
		{
			bzero(temp, 1024);
			if (messageInfo[i].number>1)
			{
				sprintf(temp, "%d messages from %s.", messageInfo[i].number, messageInfo[i].user);
				[mySpeech speakText:temp];
			}
			else
			{
				sprintf(temp, "%d message from %s.", messageInfo[i].number, messageInfo[i].user);
				[mySpeech speakText: temp];
			}


		}


	}
	else
	{
		bzero(temp, 1024);
		sprintf(temp, "You have %d messages in your mailbox", messageTotal);
		[mySpeech speakText:temp];
	}
	[mySpeech free];

}

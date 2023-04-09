#import <stdio.h>
#import <objc/objc.h>
#import <sys/param.h>
#import <appkit/nextstd.h>
#import <streams/streams.h>
#import <TextToSpeech/TextToSpeech.h>
#import <TextToSpeech/TextToSpeechPlus.h>

/* Test to see if C-code can communicate with the server. */
/*
main()
{
char line[256], *temp;
TextToSpeech *mySpeech;
short dict;

	mySpeech = [[TextToSpeech alloc] init];

	if (mySpeech == nil) 
	{
		printf("Cannot connect to speech server\n");
		exit(1);
	}

	strcpy(line,"hello");

	temp = [mySpeech pronunciation:(const char *)line :&dict:(int)0xDEAFBABE];
	if (temp == NULL)
		printf("Cannot get pron\n");
	else
		printf("|%s| dict = %d\n", temp, (int)dict);

}

*/

TextToSpeech *mySpeech;
static NXStream *fp;

main(argc, argv)
int argc;
char *argv[];
{
const short order[4] = {4,0,0,0};

	if (argc !=2)
	{
		printf("Usage: %s Filename\n", argv[0]);
		exit(1);
	}

	fp = NXMapFile(argv[1], NX_READONLY);
	if (fp == NULL)
	{
		printf("Cannot open file \"%s\"\n", argv[1]);
		exit(1);
	}

	mySpeech = [[TextToSpeech alloc] init];
	[mySpeech setDictionaryOrder:&order];
	if (mySpeech == nil) 
	{
		printf("Cannot connect to speech server\n");
		exit(1);
	}

	check_file();

	NXClose(fp);
	exit(0);
}

check_file()
{
char line[256], *temp;
int i, value, j;
short dict;

	j = 0;
	while(1)
	{
		bzero(line, 256);
		while((value = NXGetc(fp))!=EOF)
		{
/*			printf("Value = %d   %c\n", value, (char) value);*/
			j++;
			if (!(j%10000)) fprintf(stderr,"%d bytes\n", j);
			if ((value>='a' && value<='z') || (value>='A' && value<='Z')) 
			{
				NXUngetc(fp);
				j--;
				break;
			}
		}

		if (value == EOF) break;

		i = 0;
		while((value = NXGetc(fp))!=EOF)
		{
/*			printf("Value = %d   %c\n", value, (char) value);*/
			j++;
			if (!(j%10000)) fprintf(stderr,"%d bytes\n", j);
			if ((value>='a' && value<='z') || (value>='A' && value<='Z'))
			{
				line[i] = (char)value;
				if (isupper(line[i])) line[i] = tolower(line[i]);
				i++;
			}
			else break;

		}
		line[i] = '\000';
		temp = [mySpeech pronunciation:(const char *)line :&dict:(int)0xDEAFBABE];
		if (dict!=4) printf("%s %s\n", line, temp);
		if (value == EOF) break;

	}


}
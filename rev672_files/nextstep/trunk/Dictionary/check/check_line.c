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
	[mySpeech setDictionaryOrder:(const short *) &order];
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
char line[256], word[256],  *temp;
int i, value, j;
short dict;

	j = 0;
	while(1)
	{
		bzero(line, 256);
		value = getLine(line);
		getWord(line, word);

		j++;
		if (j%10000 == 0) fprintf(stderr, "%d bytes\n", j);
//		printf("|%s|\n |%s|\n", line, word);

		temp = [mySpeech pronunciation:(const char *) word :&dict:(int)0xDEAFBABE];
		if (dict!=4) printf("%s\n", line);

		if (value == EOF) break;
	}


}

getLine(line)
char *line;
{
int i = 0, value;

	value = NXGetc(fp);
	do
	{
		if (value!=(int)'\n') line[i++] = (char) value;
		value = NXGetc(fp);

	} while ((value !=EOF) && (value!=(int)'\n'));

	return(value);
}

getWord(line, word)
char *line, *word;
{
int i = 0;

	bzero(word, 256);
	while((line[i]!=' ')&&(i<256))	word[i] = line[i++];

}

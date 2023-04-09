#import <stdio.h>
#import <objc/objc.h>
#import <sys/param.h>
#import <appkit/nextstd.h>
#import <streams/streams.h>

static NXStream *fp;

main(argc, argv)
int argc;
char *argv[];
{
const short order[4] = {4,0,0,0};

	if (argc !=3)
	{
		printf("Usage: %s Filename MainDictionary\n", argv[0]);
		exit(1);
	}

	fp = NXMapFile(argv[1], NX_READONLY);
	if (fp == NULL)
	{
		printf("Cannot open file \"%s\"\n", argv[1]);
		exit(1);
	}

	if (init_dict(argv[2]))
	{
		printf("Cannot open file called \"%s\"\n", argv[2]);
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
		temp = search(line);
		if (temp)
			printf("%s %s\n", line, temp);
		if (value == EOF) break;

	}


}

#import <stdio.h>
#import <sys/param.h>
#import <appkit/nextstd.h>
#import <streams/streams.h>

/* Test to see if C-code can communicate with the server. */

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


	check_file();

	NXClose(fp);
	exit(0);
}

check_file()
{
char line[256], *temp;
char phone[10];
int i, value, j;
short dict;

	j = 0;
	while(1)
	{
		bzero(line, 256);
		while((value = NXGetc(fp))!=EOF)
		{
			j++;
			if (!(j%10000)) fprintf(stderr,"%d bytes\n", j);
			if (value == (int)' ') break;
		}

		if (value == EOF) break;

		bzero(phone, 10);
		i=0;
		while((value = NXGetc(fp))!=EOF)
		{
			j++;
			if (!(j%10000)) fprintf(stderr,"%d bytes\n", j);

			if ((value>='a' && value<='z') || (value=='\'') )
			{
				phone[i] = (char)value;
				i++;
				phone[i] = '\000';
			}
			else 
			{

				if (phone[0] == '\000') break;
				printf("%s\n", phone);
				i = 0;
				bzero(phone, 10);
			}
			if (value == (int)'\n') break;
			if (value == (int)'%') break;
			
		}

		if (value == EOF) break;

	}


}
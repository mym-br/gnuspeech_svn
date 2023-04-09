#include <stdio.h>
#include <strings.h>

FILE *fp, *hifile, *lofile;
int lowerbound;

main(argc, argv)
int argc;
char *argv[];
{
	if (argc != 5)
	{
		printf("Usage: %s filename lowerbound lofilename hifilename \n", argv[0]);
		exit(1);
	}

	fp = fopen(argv[1], "r");
	if (fp == NULL)
	{
		printf("Cannot open file named \"%s\"\n", argv[1]);
		exit(1);
	}

	hifile = fopen(argv[3], "w");
	if (hifile == NULL)
	{
		printf("Cannot open file named \"%s\"\n", argv[3]);
		exit(1);
	}

	lofile = fopen(argv[4], "w");
	if (lofile == NULL)
	{
		printf("Cannot open file named \"%s\"\n", argv[4]);
		exit(1);
	}

	sscanf(argv[2], "%d", &lowerbound);
	if (lowerbound<0)
	{
		printf("Error in lowerbound: %d\n", lowerbound);
		exit(1);
	}

	doit();
	exit(0);
}

doit()
{
char line[256];

	while(fgets(line, 256, fp) !=0)
	{
/*		printf("%s : %d\n", line, myindex(line,' '));*/
		if (myindex(line,' ')>lowerbound) fprintf(hifile, "%s", line);
		else fprintf(lofile, "%s", line);
	}

}

myindex(line, character)
char *line;
char character;
{
int length, i = 0;

	length = strlen(line);
	while(i<length)
	{
		if (line[i] == ' ') break;
		i++;
	}
	return(i);
}

#include <stdio.h>

#define dictionary "./MainDictionary"
#define EQUAL	1
#define L1	2
#define L2	3


FILE *fp1,*fp2;

int done = 0;
char line1[256],line2[256];

main(argc,argv)
int argc;
char *argv[];
{
	if (argc !=2) usage(argv[0]);

	fp1 = fopen(dictionary,"r");
	if (fp1 == NULL) file_error(dictionary);

	fp2 = fopen(argv[1],"r");
	if (fp1 == NULL) file_error(argv[1]);

	fix();
	fclose(fp1);
	fclose(fp2);
	exit(0);
}

usage(string)
char *string;
{
	fprintf(stderr,"Usage: %s fix_filename \n",string);
	exit(1);
}

file_error(string)
char *string;
{
	fprintf(stderr,"Cannot open file: %s\n",string);
	exit(1);
}

fix()
{

	if (fgets(line1,256,fp1) == NULL) line1_empty();
	if (fgets(line2,256,fp2) == NULL) line2_empty();
	while(done == 0)
		insert(line1,line2);
}

insert(line1,line2)		/* Line 2 has priority */
char *line1,*line2;
{

	switch(compare(line1,line2))
	{
		case EQUAL: advance(line1,1);
			    printf("%s",line2);
			    advance(line2,2);
			    break;
		case L1:    printf("%s",line1);
			    advance(line1,1);
			    break;
		case L2:    printf("%s",line2);
			    advance(line2,2);
			    break;
		default:    break;
	}
}

compare(line1,line2)
char *line1,*line2;
{

	while(*line1==*line2)
	{
		if ((*line1)==' ') return(EQUAL);
		line1++;
		line2++;
	}
	if ((*line1) < (*line2)) return(L1);
	else return(L2);
}

advance(line,number)
char *line;
int number;
{
	switch(number)
	{
		case 1: if (fgets(line,256,fp1)== NULL) line1_empty();
			break;
		case 2: if (fgets(line,256,fp2)== NULL) line2_empty();
			break;
	}
}

line1_empty()
{
	done = 1;
	printf("%s",line2);
	while(fgets(line2,256,fp2)!=NULL)
		printf("%s",line2);
	
}

line2_empty()
{
	done = 1;
	printf("%s",line1);
	while(fgets(line1,256,fp1)!=NULL)
		printf("%s",line1);
	
}


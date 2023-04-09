#include <stdio.h>
#include "buffer.h"

FILE *fp, *fpo;

main(argc, argv)
int argc;
char *argv[];
{

	if (argc!=3) usage(argv[0]);
	fp = fopen(argv[1], "r");
	fpo = fopen(argv[2], "w");
	if ( (fp == NULL)||(fpo==NULL)) 
	{
		printf("Cannot open files.\n");
		exit(0);
	}
	encrypt_file();
	fclose(fp);
	fclose(fpo);
	exit(0);
}

usage(string)
char *string;
{
	printf("Usage: %s input_filename output_filename\n", string);
	exit(1);
}

encrypt_file()
{
char in_buf[256], out_buf[256];
int i, bytes;
unsigned int temp;

	while( (bytes = fread(in_buf, 1, 256, fp))!=0)
	{
		for (i = 0;i<256;i++)
		{
			temp = (int) (in_buf[i]-buffer[i]);
			if (temp<0) temp += 256;
			out_buf[i] = (char) temp;
		}
		fwrite(out_buf, 1, bytes, fpo);
	}
}

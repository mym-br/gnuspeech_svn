#include <stdio.h>

extern unsigned int getSeed();

main(argc, argv)
int argc;
char *argv[];
{
FILE *fpin, *fpout;
unsigned int password;
unsigned int seed;

	if (argc != 4) usage(argv[0]);

	sscanf(argv[1], "%x", &password);

	seed = getSeed(password);

	fpin = fopen(argv[2], "r");
	if (fpin == NULL)
		fileerror(argv[2]);

	fpout = fopen(argv[3], "w");
	if (fpout == NULL)
		fileerror(argv[3]);

	decrypt(seed, fpin, fpout);
	fclose(fpin);
	fclose(fpout);
	exit(0);

}

usage(string)
char *string;
{
	printf("Usage: %s seed input_file output_file\n", string);
	exit(1);
}

fileerror(string)
char *string;
{
	printf("Could not open file named \"%s\".\n", string);
	exit(1);
}

decrypt(seed, input, output)
unsigned int seed;
FILE *input, *output;
{
unsigned int buffer[256];
unsigned int in_buf[256], out_buf[256];
int i, bytes;

	genBuffer(seed, buffer);

	while( (bytes = fread(in_buf, 1, 1024, input))!=0)
	{
		bcopy(in_buf, out_buf, 1024);
		for (i = 0;i<bytes/4;i++)
		{
			out_buf[i] = (int) (in_buf[i]-buffer[i]);
		}
		fwrite(out_buf, 1, bytes, output);
	}
}

#include <stdio.h>
#include "structs.h"

main(argc, argv)
int argc;
char *argv[];
{
FILE *fp;
struct _FFTheader fftHeader;

	if (argc == 1)
	{
		printf("Usage: %s filename\n", argv[0]);
		exit(1);
	}

	fp = fopen(argv[1], "r");
	if (fp == NULL)
	{
		printf("Cannot open file named \"%s\".\n", argv[1]);
		exit(1);
	}

	fread(&fftHeader, 1, sizeof(struct _FFTheader), fp);
	if (fftHeader.anaMagic != ANA_MAGIC)
	{
		printf("This file is not an fft output file\n");
		exit(1);
	}

	print_windows(fp, &fftHeader);

	fclose(fp);
	exit(0);

}

print_windows(fp, fftHeader)
FILE *fp;
struct _FFTheader *fftHeader;
{
int i, j;
struct _data512 data;

	printf("Total number of windows:%d\n", fftHeader->num_windows);
	printf("Window slide: %d samples\n", fftHeader->slide);
	printf("Window size: %d samples\n", fftHeader->bin_size);

	if (fftHeader->hanning)
		printf("Hanning window used.\n");
	else
		printf("Hanning window not used.\n");

	for(i = 0;i<fftHeader->num_windows; i++)
	{
		printf("*** Window %d ***\n\n", i);
		switch(fftHeader->bin_size)
		{
			case 128:fread(&data, 1, sizeof(struct _data128), fp);
				 break;
			case 256:fread(&data, 1, sizeof(struct _data256), fp);
				 break;
			case 512:fread(&data, 1, sizeof(struct _data512), fp);
				 break;
		}
		
		for(j = 0; j<fftHeader->bin_size/2; j++)
		{
			printf("%d: %f\n", j, data.data[j]); 
		}
	}
}
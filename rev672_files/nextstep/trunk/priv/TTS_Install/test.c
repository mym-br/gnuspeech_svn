#include <stdio.h>



main()
{
FILE *myPipe, *fp;
int bytes, i;
char inbuf[4096], outbuf[4096];

	myPipe = popen("/usr/ucb/zcat | (cd /tmp; tar -xf -)", "w");
	if (myPipe == NULL)
	{
		printf("Cannot open pipe\n");
		exit(1);
	}

	fp = fopen("test.tar.Z", "r");
	if (fp == NULL)
	{
		printf("Cannot open input file\n");
		exit(1);
	}

	while( (bytes = fread(inbuf, 1, 4096, fp))!=0)
	{
		bcopy(inbuf, outbuf, 4096);
		fwrite(outbuf, 1, bytes, myPipe);
	}
	fclose(fp);
	pclose(myPipe);
	exit(0);
}

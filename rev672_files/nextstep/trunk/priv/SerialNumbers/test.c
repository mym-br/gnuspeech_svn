#include <stdio.h>

main(argc, argv)
int argc;
char *argv[];
{
int x[32], y[32];
int i,j, temp;

	if (argc>1)
	{
		temp = atoi(argv[1]);
		srandom(temp);
	}

	bzero(x,32*sizeof(int));
	bzero(y,32*sizeof(int));
	for (i = 0;i<32;i++)
	{
		j = random()%32;
		while(y[j])
			j = random()%32;
		x[i] = j;
		y[j] = 1;
	}
	for(i = 0;i<32;i++)
		printf("%d  %d\n", i, x[i]);

}

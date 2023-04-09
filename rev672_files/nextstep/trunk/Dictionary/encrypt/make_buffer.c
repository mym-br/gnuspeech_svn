#include <stdio.h>

long random();

main()
{
int i, number = 0;
unsigned char temp;

	printf("static char buffer[256] = {\n");
	for (i = 0;i<256;i++)
	{
		temp = (char) (random()%255);
		printf("%d, ", (int) temp );
		number++;
		if (number>=25)
		{
			number = 0;
			printf("\n");
		}
	}
	printf("};\n");
}
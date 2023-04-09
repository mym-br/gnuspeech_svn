#include <stdio.h>

main()
{
FILE *fp;

	fp = popen("MyNewServer", "r");
	exit(0);
}
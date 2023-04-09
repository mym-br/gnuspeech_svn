#include "number_parser.h"
#include <stdio.h>


void main(void)
{
    char            word[124], *ptr;
    int             i, mode;

    mode = NP_NORMAL;

    while (1) {
	i = 0;
	printf("\nEnter number string to be parsed:  ");

	while ((word[i++] = getchar()) != '\n')
	  ;
	word[--i] = '\0';

	if ((ptr = number_parser(word, mode)) == NULL)
	    printf("The word contains no numbers.\n");
	else
	    printf("%s\n", ptr);
    }
}

#import "reserved_symbol.h"
#import <string.h>

#define NO  0
#define YES 1

int reserved_symbol(current_symbol)
     char *current_symbol;
{
int i;
static char *symbol[NUMBER_RESERVED_SYMBOLS] = {LEFT_PAREN_STRING,
						  RIGHT_PAREN_STRING,
						  NOT_STRING,
						  AND_STRING,
						  OR_STRING,
						  XOR_STRING,
						  PHONE_STRING};
for (i = 0; i < NUMBER_RESERVED_SYMBOLS; i++) {
  if (!strcmp(current_symbol,symbol[i]))
      return(YES);
}

return(NO);
}










#include <stdio.h>
#include <string.h>

#define  EMPTY_TOKEN    0
#define  NOT_SYM        1
#define  AND_SYM        2
#define  OR_SYM         3
#define  XOR_SYM        4
#define  CATEGORY_SYM   5
#define  OPENPAREN_SYM  6
#define  CLOSEPAREN_SYM 7
#define  PAREN_MISMATCH 8
#define  NULL_INPUT     9
#define  UNKNOWN_CAT    10

#define  EMPTY_TOKEN_MESSAGE    "Too much input."
#define  NOT_SYM_MESSAGE        "Expected a not symbol."
#define  AND_SYM_MESSAGE        "Expected an and symbol."
#define  OR_SYM_MESSAGE         "Expected an or symbol."
#define  XOR_SYM_MESSAGE        "Expected an xor symbol."
#define  CATEGORY_SYM_MESSAGE   "Expected a category symbol."
#define  OPENPAREN_SYM_MESSAGE  "Expected a ( symbol."
#define  CLOSEPAREN_SYM_MESSAGE "Expected a ) symbol."
#define  PAREN_MISMATCH_MESSAGE "Parentheses do not match."
#define  NULL_INPUT_MESSAGE     "No input entered."
#define  UNKNOWN_CAT_MESSAGE    "Unrecognized category:  "

#define  NO             0
#define  YES            1


/*  GLOBALS  */
char c_char, *input_string, op_cat_string[256];
int c_pos, last_char_pos;
int token, token_available;
int end_of_input;

int paren_stack, errors;
static char *message_buffer = NULL;
int message_length;

char *parse(char *input);


main()
{
char input[256];
char *message;

printf("Enter input:  ");
if (fgets(input,256,stdin) != input) {
  printf("fgets error\n");
  exit(1);
}
input[strlen(input)-1] = '\0';
printf("Input = %s\n",input);

if ((message = parse(input)) == NULL)
  printf("\nparsed with no errors\n");
else
  printf("\nerror message:\n%s",message);
}



char *parse(input)
     char *input;
{
  scan_init(input);
  while (!end_of_input)
    check_input();
  if (paren_stack != 0)
    error(PAREN_MISMATCH);

  list_number_errors();
  return(message_buffer);
}



scan_init(input)
     char *input;
{
c_pos = 0;
token_available = NO;
end_of_input = NO;
token = EMPTY_TOKEN;
paren_stack = errors = 0;
free_message_buffer();

input_string = input;
if ((last_char_pos = strlen(input_string)) == 0)
  error(NULL_INPUT);

advance();
}



check_input()
{
  token = next_token();

  check_line();
  match_tokens(EMPTY_TOKEN);
}



check_line()
{
  token = next_token();

  check_negation();
  check_expression();
}



check_expression()
{
  token = next_token();

  if (token == OPENPAREN_SYM) {
    match_tokens(OPENPAREN_SYM);
    check_line();
    match_tokens(CLOSEPAREN_SYM);
    check_expression_tail();
  }
  else {
    check_category_name();
    check_expression_tail();
  }
}



check_expression_tail()
{
  token = next_token();

  if ( (token == AND_SYM) || (token == OR_SYM) || (token == XOR_SYM) ) {
    match_tokens(token);
    check_line();
  }
}
    


check_negation()
{
  token = next_token();

  if (token == NOT_SYM)
    match_tokens(token);
}



check_category_name()
{
  token = next_token();
  match_category(token);
}



int next_token()
{
  if (!token_available) {
    token = EMPTY_TOKEN;
    skip_white();
    if (!end_of_input) {
      token = get_a_token();
      token_available = YES;
    }
  }
/*  print_token();  */
  return(token);
}



skip_white()
{
  while ((!end_of_input) && 
	 ((c_char == ' ') || (c_char == '\t') || (c_char == '\n'))) {
    advance();
  }
}



advance()
{
  c_char = input_string[c_pos++];

  if (c_pos > last_char_pos)
    end_of_input = YES;
}



int get_a_token()
{
  skip_white();

  if (c_char == '(') {
    token = OPENPAREN_SYM;
    paren_stack++;
    advance();
  }
  else if (c_char == ')') {
    token = CLOSEPAREN_SYM;
    paren_stack--;
    advance();
  }
  else
    token = get_operator_or_category();

  return(token);
}



int get_operator_or_category()
{
  int string_index = 0;

  while((!end_of_input) && (c_char != '(') && (c_char != ')') && (c_char != ' ')) {
    op_cat_string[string_index++] = c_char;
    advance();
  }
  op_cat_string[string_index] = '\0';

  if (string_index == 0)
    return(EMPTY_TOKEN);
  else if (!strcmp(op_cat_string,"not"))
    return(NOT_SYM);
  else if (!strcmp(op_cat_string,"and"))
    return(AND_SYM);
  else if (!strcmp(op_cat_string,"or"))
    return(OR_SYM);
  else if (!strcmp(op_cat_string,"xor"))
    return(XOR_SYM);
  else
    return(CATEGORY_SYM);
}



match_tokens(expected_token)
     int expected_token;
{
  token = next_token();

  token_available = 0;
  if (expected_token != token)
    error(expected_token);
  else {
    if (token == OPENPAREN_SYM)
      printf("*****match_tokens;  token = (\n");
    else if (token == CLOSEPAREN_SYM)
      printf("*****match_tokens;  token = )\n");
    else if (token == EMPTY_TOKEN)
      printf("*****match_tokens;  end of input\n");
    else
      printf("*****match_tokens;  token = %s\n",op_cat_string);
  }
}



match_category(expected_token)
     int expected_token;
{

  token_available = 0;

  if (expected_token == CATEGORY_SYM) {
    printf("*****match_category;  category = %s\n",op_cat_string);
/*    error(UNKNOWN_CAT);  */
  }
  else
    error(CATEGORY_SYM);
}



error(error_code)
     int error_code;
{
static char *error_message[] = {EMPTY_TOKEN_MESSAGE,
				NOT_SYM_MESSAGE,
				AND_SYM_MESSAGE,
				OR_SYM_MESSAGE,
				XOR_SYM_MESSAGE,
				CATEGORY_SYM_MESSAGE,
				OPENPAREN_SYM_MESSAGE,
				CLOSEPAREN_SYM_MESSAGE,
				PAREN_MISMATCH_MESSAGE,
				NULL_INPUT_MESSAGE,
				UNKNOWN_CAT_MESSAGE};

  errors++;

  message_length += strlen(error_message[error_code])+1;
  message_buffer = (char *)realloc(message_buffer,message_length);
  if (errors == 1)
    message_buffer[0] = '\0';
  strcat(message_buffer,error_message[error_code]);
  if (error_code == UNKNOWN_CAT) {
    message_length += strlen(op_cat_string);
    message_buffer = (char *)realloc(message_buffer,message_length);
    strcat(message_buffer,op_cat_string);
  }
  message_length += 2;
  message_buffer = (char *)realloc(message_buffer,message_length);
  strcat(message_buffer,"\n");
}



list_number_errors()
{
  if (errors) {
    char message[32];

    sprintf(message,"\nNumber of Parse errors: %-d\n",errors);
    message_length += strlen(message);
    message_buffer = (char *)realloc(message_buffer,message_length);
    strcat(message_buffer,message);
  }
}



free_message_buffer()
{
  free(message_buffer);
  message_buffer = NULL;
  message_length = 0;
}


print_token()
{
static char *token_string[] = {"EMPTY_TOKEN","not","and",
				"or","xor","CATEGORY_SYM","(",")"};

printf("**print_token();  token = %-d = %s\n",token,token_string[token]);
}




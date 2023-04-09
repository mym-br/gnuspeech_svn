#import <stdio.h>
#import <string.h>
#import <stdlib.h>
#import "Rule.h"
#import "parse.h"

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
#define  NOT_SYM_MESSAGE        "Expected a \"not\" symbol."
#define  AND_SYM_MESSAGE        "Expected an \"and\" symbol."
#define  OR_SYM_MESSAGE         "Expected an \"or\" symbol."
#define  XOR_SYM_MESSAGE        "Expected an \"xor\" symbol."
#define  CATEGORY_SYM_MESSAGE   "Expected a category symbol."
#define  OPENPAREN_SYM_MESSAGE  "Expected a \"(\" symbol."
#define  CLOSEPAREN_SYM_MESSAGE "Expected a \")\" symbol."
#define  PAREN_MISMATCH_MESSAGE "Parentheses do not match."
#define  NULL_INPUT_MESSAGE     "No input."
#define  UNKNOWN_CAT_MESSAGE    "Unrecognized category:  "


static void scan_init(char *input);
static void check_input(void);
static void check_line(void);
static void check_expression(void);
static void check_expression_tail(void);
static void check_negation(void);
static void check_category_name(void);
static int next_token(void);
static void skip_white(void);
static void advance(void);
static int get_a_token(void);
static int get_operator_or_category(void);
static void match_tokens(int expected_token);
static void match_category(int expected_token);
static void error(int error_code);
static void list_number_errors(void);
static void free_message_buffer(void);
static void print_token(void);

/*  GLOBALS -- LOCAL TO THIS FILE  */
static char c_char, *input_string, op_cat_string[256];
static int c_pos, last_char_pos;
static int token, token_available;
static int end_of_input;

static int paren_stack, errors;
static char *message_buffer = NULL;
static int message_length;

id ruleObj;



char *parse(input,sender)
     char *input;
     id sender;
{
  ruleObj = sender;

  scan_init(input);
  while (!end_of_input)
    check_input();
  if (paren_stack != 0)
    error(PAREN_MISMATCH);

  list_number_errors();
  return(message_buffer);
}



void scan_init(input)
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



void check_input()
{
  token = next_token();

  check_line();
  match_tokens(EMPTY_TOKEN);
}



void check_line()
{
  token = next_token();

  check_negation();
  check_expression();
}



void check_expression()
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



void check_expression_tail()
{
  token = next_token();

  if ( (token == AND_SYM) || (token == OR_SYM) || (token == XOR_SYM) ) {
    match_tokens(token);
    check_line();
  }
}
    


void check_negation()
{
  token = next_token();

  if (token == NOT_SYM)
    match_tokens(token);
}



void check_category_name()
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



void skip_white()
{
  while ((!end_of_input) && 
	 ((c_char == ' ') || (c_char == '\t') || (c_char == '\n'))) {
    advance();
  }
}



void advance()
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



void match_tokens(expected_token)
     int expected_token;
{
  token = next_token();

  token_available = 0;
  if (expected_token != token)
    error(expected_token);
/*
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
*/
}



void match_category(expected_token)
     int expected_token;
{

  token_available = 0;

  if (expected_token == CATEGORY_SYM) {
/*
    printf("*****match_category;  category = %s\n",op_cat_string);
*/
    if (![ruleObj validCategory:op_cat_string])
      error(UNKNOWN_CAT);
  }
  else
    error(CATEGORY_SYM);
}



void error(error_code)
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
    message_length += strlen(op_cat_string)+4;
    message_buffer = (char *)realloc(message_buffer,message_length);
    strcat(message_buffer,"\"");
    strcat(message_buffer,op_cat_string);
    strcat(message_buffer,"\"");
  }
  message_length += 2;
  message_buffer = (char *)realloc(message_buffer,message_length);
  strcat(message_buffer,"\n");
}



void list_number_errors()
{
  if (errors) {
    char message[32];

    sprintf(message,"\nNumber of parse errors:  %-d\n",errors);
    message_length += strlen(message);
    message_buffer = (char *)realloc(message_buffer,message_length);
    strcat(message_buffer,message);
  }
}



void free_message_buffer()
{
  free(message_buffer);
  message_buffer = NULL;
  message_length = 0;
}


void print_token()
{
static char *token_string[] = {"EMPTY_TOKEN","not","and",
				"or","xor","CATEGORY_SYM","(",")"};

printf("**print_token();  token = %-d = %s\n",token,token_string[token]);
}




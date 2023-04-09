#import <stdio.h>
#import <string.h>
#import <stdlib.h>
#import "Rule.h"
#import "evaluate.h"

#define  NO_OP          0
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


/*  GLOBALS  */
char c_char, *input_string, *current_phone, op_cat_string[256];
int c_pos, last_char_pos, token, token_available, end_of_input;
id ruleObj;



int evaluate(char *rule, char *phone, id sender)
{
  /*  SET GLOBALS  */
  current_phone = phone;
  ruleObj = sender;
  
  /*  INITIALIZE THE SCAN OF THE RULE  */
  scan_init(rule);

  /*  EVALUATE THE INPUT  */
  return(check_input());
}



void scan_init(char *input)
{
  c_pos = 0;
  token_available = end_of_input = NO;
  token = EMPTY_TOKEN;
  input_string = input;
  
  advance();
}



int check_input(void)
{
  int value_line;

  /*  GET THE NEXT TOKEN  */
  token = next_token();

  /*  <INPUT> ::= <LINE> <EMPTY_TOKEN>  */
  value_line = check_line();
  match_tokens(EMPTY_TOKEN);

  /*  RETURN VALUE OF THE LINE  */
  return(value_line);
}



int check_line(void)
{
  int negative, value_expression;
  
  /*  GET THE NEXT TOKEN  */
  token = next_token();

  /*  <LINE> ::= <NEGATIVE> <EXPRESSION>  */
  negative = check_negation();
  value_expression = check_expression();

  /*  NEGATE THE EXPRESSION IF NECESSARY  */
  if (negative)
    return(!value_expression);
  else
    return(value_expression);
}



int check_expression(void)
{
  int value_line, value_category_name, expression_tail;

  /*  GET THE NEXT TOKEN  */
  token = next_token();

  /*  <EXPRESSION> ::=  ( <LINE> ) <EXPRESSION_TAIL> | 
                        <CATEGORY_NAME> <EXPRESSION_TAIL>  */
  if (token == OPENPAREN_SYM) {
    match_tokens(OPENPAREN_SYM);
    value_line = check_line();
    match_tokens(CLOSEPAREN_SYM);
    expression_tail = check_expression_tail();

    /*  EVALUATE ACCORDING TO OPERATOR  */
    if (operator(expression_tail) == NO_OP)
      return(value_line);
    else if (operator(expression_tail) == AND_SYM)
      return(value_line && value(expression_tail));
    else if (operator(expression_tail) == OR_SYM)
      return(value_line || value(expression_tail));
    else if (operator(expression_tail) == XOR_SYM) {
      if ( (value_line && !value(expression_tail)) ||
	   (!value_line && value(expression_tail)) )
	return(1);
      else
	return(0);
    }
  }
  else {
    value_category_name = check_category_name();
    expression_tail = check_expression_tail();

    /*  EVALUATE ACCORDING TO OPERATOR  */
    if (operator(expression_tail) == NO_OP)
      return(value_category_name);
    else if (operator(expression_tail) == AND_SYM)
      return(value_category_name && value(expression_tail));
    else if (operator(expression_tail) == OR_SYM)
      return(value_category_name || value(expression_tail));
    else if (operator(expression_tail) == XOR_SYM) {
      if ( (value_category_name && !value(expression_tail)) ||
	   (!value_category_name && value(expression_tail)) )
	return(1);
      else
	return(0);
    }
  }
}



int operator(int code)
{
  if (code < 0)
    return(code * (-1));
  else
    return(code);
}



int value(int code)
{
  if (value < 0)
    return(1);
  else
    return(0);
}



int check_expression_tail(void)
{
  int value_line;

  /*  GET NEXT TOKEN  */
  token = next_token();

  /*  <EXPRESSION_TAIL> ::= <"and" | "or" | "xor"> <LINE>  |  " "  */
  if ( (token == AND_SYM) || (token == OR_SYM) || (token == XOR_SYM) ) {
    match_tokens(token);
    value_line = check_line();

    /*  RETURN OPERATOR AND VALUE AS ONE CODED INT  */
    if (value_line)
      return(token * (-1));
    return(token);
  }
  else
    return(NO_OP);
}
    


int check_negation(void)
{
  /*  GET NEXT TOKEN  */
  token = next_token();

  /*  <NEGATION> ::= <"not">  |  " "   */
  if (token == NOT_SYM) {
    match_tokens(token);
    return(1);
  }
  else
    return(0);
}



void check_category_name(void)
{
  /*  GET A TOKEN  */
  token = next_token();
  token_available = 0;

  /*  <CATEGORY_NAME> ::= any valid category for current_phone  */
  return([ruleObj matchPhone:current_phone ToCategory:op_cat_string]);
}



int next_token(void)
{
  if (!token_available) {
    token = EMPTY_TOKEN;
    skip_white();
    if (!end_of_input) {
      token = get_a_token();
      token_available = YES;
    }
  }
  return(token);
}



void skip_white(void)
{
  while ((!end_of_input) && 
	 ((c_char == ' ') || (c_char == '\t') || (c_char == '\n'))) {
    advance();
  }
}



void advance(void)
{
  c_char = input_string[c_pos++];

  if (c_pos > last_char_pos)
    end_of_input = YES;
}



int get_a_token(void)
{
  skip_white();

  if (c_char == '(') {
    token = OPENPAREN_SYM;
    advance();
  }
  else if (c_char == ')') {
    token = CLOSEPAREN_SYM;
    advance();
  }
  else
    token = get_operator_or_category();

  return(token);
}



int get_operator_or_category(void)
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



void match_tokens(int expected_token)
{
  token = next_token();
  token_available = 0;
}

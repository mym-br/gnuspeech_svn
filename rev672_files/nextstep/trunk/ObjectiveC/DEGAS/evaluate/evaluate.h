int evaluate(char *rule, char *phone, id sender);
void scan_init(char *input);
int check_input(void);
int check_line(void);
int check_expression(void);
int operator(int code)
int value(int code);
int check_expression_tail(void);
int check_negation(void);
int check_category_name(void);
int next_token(void);
void skip_white(void);
void advance(void);
int get_a_token(void);
int get_operator_or_category(void);
void match_tokens(int expected_token);

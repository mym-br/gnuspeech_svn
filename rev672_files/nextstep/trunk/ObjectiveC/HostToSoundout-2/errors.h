#import <sound/sounderror.h>

void check_mach_error(int error_code, char *error_message);
char *snd_error_string(int error);
void check_snddriver_error (int error_code, char *error_message);
void check_snd_error (int error_code, char *error_message);


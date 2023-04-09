#import <appkit/nextstd.h>
#import <mach/mach.h>

typedef unsigned char byte;

#define TYPE_STATEMENT 0
#define TYPE_QUESTION 1
#define TYPE_EXCLAIMATION 2
#define TYPE_CONTINUATION 3


/*============================ Database Stuff =============================*/

/*========================= Calculation Specifics =========================*/
#define IDLE 0
#define RUNNING 1
#define TO_BE_PAUSED 2
#define PAUSED 3
#define TO_BE_ERASED 4
#define ERASED 5
#define NONE 6

struct _calc_info {
	int identifier;
	int status;
	int intonation;
	int random;
	int block;
	int voice_type;
	int channels;
	int uid;
	int gid;
	port_t block_port;
	port_t rhythm_port;
	float volume;
	float speed;
	float balance;
	float pitch_offset;
	float vtlOffset;
	float breathiness;
	float samplingRate;

	char *filePath;
};

struct _speak_messages {
	int ident;
	int status;
	char *text;
	int rhythm;
	int uid;
	int gid;
	char *filePath;
};

#define MAX_SPEAK_MESSAGES	50


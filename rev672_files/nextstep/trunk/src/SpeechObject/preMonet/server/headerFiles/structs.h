#import <appkit/nextstd.h>

/* 	Buffer parameters 
	Note: Each page = 0.1 second of speech.  Length of buffer in seconds = 
	Pages * 0.1 s.
*/
#define TABLES 32
#define PAGESIZE 8192
#define PAGES 16
#define SMALLPAGES PAGES*2

typedef unsigned char byte;

struct _event {
	int time;
	float deltas[12];
//	float targets[12];
	byte foot;
	byte syllable;
	byte word;
};

struct _pevent {
	int time;
	float delta;
};

#define MAX_EVENTS	4500
#define MAX_PEVENTS	750

/* TO BE MODIFIED */
struct _phone {
	int time;
	int onset;
	float regression;
	char token[8];
	byte duration;
	byte syllable;
	byte word;
	byte foot;
	byte final;
	byte vocallic;
};

#define MAX_PHONES 1500

struct _foot {
	int index1;
	int index2;
	int duration;
	int onset1;
	int onset2;
	int offset1;
	int offset2;
	byte marked;
	byte num_items;
	byte tone_group;
};

#define MAX_FEET 200

struct _pitch_movement {
	int time;
	int index;
};

#define	MAX_PMOVEMENTS	150

#define TYPE_STATEMENT 0
#define TYPE_QUESTION 1
#define TYPE_EXCLAIMATION 2
#define TYPE_CONTINUATION 3


/*============================ Database Stuff =============================*/

struct _diphoneHeader {
	int 	intervals;
	int 	total_duration;
};

struct _intervalHeader
{
	int 	coded_duration;
	float	stretch_factor;
	float parm[12];
};

/* TO BE MODIFIED  (NOW OBSOLETE) */
struct _header {
	int duration;
	int events;
};

/* TO BE MODIFIED  (NOW OBSOLETE) */
struct _data {
	int time;
	float value[8];
};

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
	int elasticity;
	int random;
	int block;
	int uid;
	int gid;
	port_t block_port;
	port_t rhythm_port;
	float volume;
	float speed;
	float balance;
	float pitch_offset;
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

/* ================ */


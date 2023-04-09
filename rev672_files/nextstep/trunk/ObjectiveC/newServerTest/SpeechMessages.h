/* Open, Close, and Set Messages.  Not seen by user */

#define NEW_SPEAKER	 0
#define CLOSE_SPEAKER	 1
#define SET_TASK_PORTS   2
#define DIAGNOSIS        3

/* Set attribute messages */
#define SET_APP_DICT	 100
#define SET_USER_DICT	 101
#define SET_SPEED	 102
#define SET_VOLUME	 103
#define SET_ERROR_PORT	 104
#define SET_DICT_ORDER	 105
#define SET_ESCAPE_CHAR  106
#define SET_ELASTICITY   107
#define SET_INTONATION   108
#define SET_PITCH_OFFSET 109
#define SET_BALANCE      110
#define SET_BLOCK        111

/* Attribute query messages */
#define GET_APP_DICT	 200
#define GET_USER_DICT	 201
#define GET_SPEED	 202
#define GET_VOLUME	 203
#define GET_DICT_ORDER	 204
#define GET_PRON	 205	/* Hidden Message */
#define GET_ESCAPE_CHAR  206
#define GET_LINE_PRON	 207	/* Hidden Message */
#define GET_ELASTICITY   208
#define GET_INTONATION   209
#define GET_PITCH_OFFSET 210
#define GET_BALANCE      211
#define GET_BLOCK        212

/* Synth control messages */
#define PAUSEIMMED	 300
#define PAUSEAFTERWORD	 301
#define PAUSEAFTERUTT	 302
#define CONTINUE	 303
#define ERASEALLSOUND	 304
#define SPEAKTEXT	 305
#define ERASECURUTT	 306
#define ERASEALLWORDS    307

/* Misc. Messages */
#define VERSION		 400
#define DICTVERSION      401

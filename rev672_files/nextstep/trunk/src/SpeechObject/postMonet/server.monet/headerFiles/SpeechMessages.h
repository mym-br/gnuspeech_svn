/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:53 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/SpeechObject/postMonet/server.monet/headerFiles/SpeechMessages.h,v $
$State: Exp $


$Log: not supported by cvs2svn $

******************************************************************************/

/* Open, Close, and Set Messages.  Not seen by user */
#define NEW_SPEAKER	 0
#define CLOSE_SPEAKER	 1
#define SET_TASK_PORTS   2
#define DIAGNOSIS        3
#define SERVER_HUP	 4

/* Set attribute messages */
#define SET_APP_DICT	 100
#define SET_USER_DICT	 101
#define SET_SPEED	 102
#define SET_VOLUME	 103
#define SET_ERROR_PORT	 104
#define SET_DICT_ORDER	 105
#define SET_ESCAPE_CHAR  106
#define SET_ELASTICITY   107    /* Obsolete Message */
#define SET_INTONATION   108
#define SET_PITCH_OFFSET 109
#define SET_BALANCE      110
#define SET_BLOCK        111
#define SET_VOICE_TYPE   112
#define SET_VTL_OFFSET   113
#define SET_BREATHINESS  114
#define SET_CHANNELS     115
#define SET_SAMPLE_RATE  116
#define SET_SOFT_SYNTH   117

/* Attribute query messages */
#define GET_APP_DICT	 200
#define GET_USER_DICT	 201
#define GET_SPEED	 202
#define GET_VOLUME	 203
#define GET_DICT_ORDER	 204
#define GET_PRON	 205	/* Hidden Message */
#define GET_ESCAPE_CHAR  206
#define GET_LINE_PRON	 207	/* Hidden Message */
#define GET_ELASTICITY   208    /* Obsolete Message */
#define GET_INTONATION   209
#define GET_PITCH_OFFSET 210
#define GET_BALANCE      211
#define GET_BLOCK        212
#define	GET_RHYTHM	 213	/* Hidden Message */
#define GET_REGHOST	 214	/* Hidden Message */
#define GET_DEMOMODE	 215	/* Hidden Message */
#define GET_EXPIRYDATE	 216	/* Hidden Message */
#define GET_VOICE_TYPE   217
#define GET_VTL_OFFSET   218
#define GET_BREATHINESS  219
#define GET_CHANNELS     220
#define GET_SAMPLE_RATE  221
#define GET_SOFT_SYNTH   222

/* Synth control messages */
#define PAUSEIMMED	 300
#define PAUSEAFTERWORD	 301
#define PAUSEAFTERUTT	 302
#define CONTINUE	 303
#define ERASEALLSOUND	 304
#define SPEAKTEXT	 305
#define ERASECURUTT	 306
#define ERASEALLWORDS    307
#define SPEAKTEXTTOFILE	 308

/* Misc. Messages */
#define VERSION		 400
#define DICTVERSION      401

/* Misc Messages which may affect system security */
#define GETPRIORITY      1001
#define SETPRIORITY      1002
#define GETQUANTUM       1003
#define SETQUANTUM       1004
#define GETPOLICY        1005
#define SETPOLICY        1006
#define GETPREFILL       1007
#define SETPREFILL       1008

#define SERVERPID        1100
#define INACTIVEKILL     1101
#define KILLQUERY        1102
#define RESTARTSERVER    1103

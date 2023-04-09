/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:52 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/SpeechObject/postMonet/objC.monet/MessageStructs.h,v $
$State: Exp $


$Log: not supported by cvs2svn $

******************************************************************************/


/*  HEADER FILES  ************************************************************/
#import <mach/mach.h>
#import <mach/message.h>


/*  LOCAL DEFINES  ***********************************************************/
#define SPEECH_PORT_NAME "SpeechPort"



/****************************************************************************
*
*       Structure:  float_msg
*
*       Created:    May 8, 1991 by Craig Schock
*
*       Purpose:    This is the basic structure for a message sent to the 
*                   speech daemon which has 1 float parameter.
*
*       NOTE:       Since float and unsigned int are both 32 bits long, the 
*                   float parameter is stored in an int dataspace because the
*                   message overhead will be much less.  The float is NOT 
*                   cast to an int;  it is only stored in the same 32 bit 
*                   dataspace.
*
****************************************************************************/

struct float_msg {
        msg_header_t    h;      /* message header */
        msg_type_t      t;      /* type descriptor */
        float           data;   /* data */
}; 
typedef struct float_msg float_msg_t;



/****************************************************************************
*
*       Structure:  int_msg
*
*       Created:    July 12, 1991 by Craig Schock
*
*       Purpose:    This is the basic structure for a message sent to the 
*                   speech daemon which has 1 int parameter.
*
****************************************************************************/

struct int_msg {
        msg_header_t    h;      /* message header */
        msg_type_t      t;      /* type descriptor */
        int             data;   /* data */
}; 
typedef struct int_msg int_msg_t;



/****************************************************************************
*
*       Structure:  string_msg
*
*       Created:    May 8, 1991 by Craig Schock
*
*       Purpose:    This is the basic structure for a message sent to the 
*                   speech daemon which has 1 parameter which is a pointer to 
*                   a null terminated string of characters.
*
*       NOTE:       Don't forget to set message_simple to FALSE.
*
*       April 24, 1992:  changed data to const char * (LM).
*
****************************************************************************/

struct string_msg {
        msg_header_t    h;      /* message header */
	msg_type_long_t t1;     /* Type descriptor */
        const char *    data;   /* pointer to string */
}; 
typedef struct string_msg string_msg_t;



/****************************************************************************
*
*       Structure:  simple_msg
*
*       Created:    May 8, 1991 by Craig Schock
*
*       Purpose:    This is the basic structure for a message sent to the 
*                   speech daemon which has no parameters.
*
*       NOTE:       Since a speech identifier has to be sent to the speech 
*                   daemon with every message, simply sending a header was
*                   not sufficient. 
*
****************************************************************************/

struct simple_msg {
        msg_header_t    h;      /* message header */
}; 
typedef struct simple_msg simple_msg_t;

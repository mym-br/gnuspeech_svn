#ifdef V2
#import <mach.h>
#import <sys/message.h>
#endif
#ifdef V3
#import <mach/mach.h>
#import <mach/message.h>
#endif
#import <servers/netname.h>

#define SPEECH_PORT_NAME "SpeechPort"

/****************************************************************************
*
*	Structure: float_msg
*	Created: May 8, 1991 by Craig Schock
*	Purpose: This is the basic structure for a message sent to the 
*		speech daemon which has 1 float parameter.
*	NOTE:  	Since float and unsigned int are both 32 bits long, the 
*		float parameter is stored in an (int) dataspace because the
*		message overhead will be much less.  The float is NOT 
*		casted to an int;  it is only stored in the same 32 bit 
*		dataspace
*
****************************************************************************/

struct float_msg {
	msg_header_t	h;	/* message header */
	msg_type_t	t;	/* type descriptor */
	float 		data;	/* Data */
}; 

/****************************************************************************
*
*	Structure: int_msg
*	Created: July 12, 1991 by Craig Schock
*	Purpose: This is the basic structure for a message sent to the 
*		speech daemon which has 1 int parameter.
*
****************************************************************************/

struct int_msg {
	msg_header_t	h;	/* message header */
	msg_type_t	t;	/* type descriptor */
	int 		data;	/* Data */
}; 

/****************************************************************************
*
*	Structure: string_msg
*	Created: May 8, 1991 by Craig Schock
*	Purpose: This is the basic structure for a message sent to the 
*		speech daemon which has 1 parameter which is a pointer to 
*		a null terminated string of characters.
*	NOTE:  	Don't forget to set message_simple to FALSE.
*
*	July 10, 1992: Changed to allow for long messages
*
****************************************************************************/
struct string_msg {
	msg_header_t	h;	/* message header */
	msg_type_long_t t1;	/* Type descriptor */
	char * 		data;	/* Pointer to string */
}; 
//	msg_type_t	t1;	/* type descriptor */

/****************************************************************************
*
*	Structure: simple_msg
*	Created: May 8, 1991 by Craig Schock
*	Purpose: This is the basic structure for a message sent to the 
*		speech daemon which has no parameters.
*	NOTE:	Since a speech identifier has to be sent to the speech 
*		daemon with every message, simply sending a header was
*		not sufficient. 
*
****************************************************************************/

struct simple_msg {
	msg_header_t	h;	/* message header */
}; 

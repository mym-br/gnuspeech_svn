#include <stdio.h>
#include "MessageStructs.h"

extern void gethostname();
extern void mach_error();

/*===========================================================================

	This file was created on June 22, 1991.  It is the integration of 
	several test files.  Each function has been tested in at least 1 other
	context.

	This file contains low-level messaging functions for both the speech
	server and the User-SpeechObject.  In order to avoid any undue
	overhead, messages are constructed by hand and not with MiG.

	The following is a list of supported functions:

	send_string_message(port_t outPort, port_t replyPort, int msg_id,
		int ident, char *value);
	send_simple_message(port_t outPort, port_t replyPort, int msg_id,
		int ident);
	send_float_message(port_t outPort, port_t replyPort, int msg_id,
		int ident, double value);
	receive_float_message(port_t inPort, struct float_msg *message);
	receive_string_message(port_t inPort, struct float_msg *message);

	All functions are described below.

===========================================================================*/

/*===========================================================================

	Function: send_string_message

	Purpose: This function sets-up and sends a message with two data 
		items value and ident to the port specified in the outPort
		parameter.  

	Parameters:	outPort: The port to which the message is sent.
			replyPort: The reply port where the reply (if any)
					is expected.
			msg_id: should be set to STRING_MESSAGE.
			ident: Identity of the SpeechObject Instance.
			value: pointer to null-terminated string.

	Returns: (kern_return_t) This function returns the value returned
		 by the function msg_send.

	Algorithm: This function sets up the message header.  This simply
		involves setting up data fields in the msg_header_t struct.
		Then the data header and data item for the instance 
		identifier is set up.  Then the data header and character 
		pointer structures are set up.  See the digital librarian
		for documentation on setting up these system data structs.

===========================================================================*/

kern_return_t send_string_message(outPort, replyPort, msg_id, ident, value)
port_t outPort, replyPort;
unsigned int msg_id, ident;
char *value;
{
struct string_msg message;
msg_return_t ret_value;
unsigned short send_msg_id[2];
int *temp;

	/* Set up message header.  Be sure to include a reply port! */
	message.h.msg_simple = FALSE;
	message.h.msg_size = sizeof(struct string_msg);
	message.h.msg_type = MSG_TYPE_NORMAL;
	message.h.msg_local_port = replyPort;		/* Reply port */
	message.h.msg_remote_port = outPort;

	send_msg_id[0] =(unsigned short) msg_id;
	send_msg_id[1] =(unsigned short) ident;
	temp = (int *) send_msg_id;
	message.h.msg_id = (*temp);			/* STRING_MESSAGE */

	/* Set up message data header */
	message.t1.msg_type_header.msg_type_name = MSG_TYPE_STRING;	/* String message sent */
	message.t1.msg_type_header.msg_type_size = 8;			/* Pointer is 32 bits */
	message.t1.msg_type_header.msg_type_number = strlen(value)+1;	/* there is 1 pointer */
	message.t1.msg_type_header.msg_type_inline = FALSE;		/* Out-of-line */
	message.t1.msg_type_header.msg_type_longform = TRUE;
	message.t1.msg_type_header.msg_type_deallocate = FALSE;		/* User must deallocate */

	message.t1.msg_type_long_name = (short) MSG_TYPE_STRING;/* String message sent */
	message.t1.msg_type_long_size = (short) 8;		/* Pointer is 32 bits */
	message.t1.msg_type_long_number = strlen(value)+1;	/* there is 1 pointer */

	message.data = value;				/* Pointer to buffer */

	/* Send message */
	ret_value = msg_send((void *) &message,MSG_OPTION_NONE, (msg_timeout_t) 0);

	return(ret_value);
}


/*===========================================================================

	Function: send_simple_message

	Purpose: This function sends a simple message to the port specified
		in the outPort parameter.  The message has 1 data item called
		"ident". 

	Parameters:	outPort: The port to which the message is sent.
			replyPort: The reply port where the reply (if any)
					is expected.
			msg_id: See SpeechMessages.h
			ident: Identity of the SpeechObject Instance.

	Returns: (kern_return_t) This function returns the value returned
		 by the function msg_send.

===========================================================================*/

kern_return_t send_simple_message(outPort, replyPort, msg_id, ident)
port_t outPort, replyPort;
int msg_id, ident;
{
struct simple_msg message;
msg_return_t ret_value;
unsigned short send_msg_id[2];
int *temp;

	/* Set up message header.  Be sure to include a reply port! */
	message.h.msg_simple = TRUE;
	message.h.msg_size = sizeof(struct simple_msg);
	message.h.msg_type = MSG_TYPE_NORMAL;
	message.h.msg_local_port = replyPort;		/* Reply port */
	message.h.msg_remote_port = outPort;

	send_msg_id[0] =(unsigned short) msg_id;
	send_msg_id[1] =(unsigned short) ident;
	temp = (int *) send_msg_id;
	message.h.msg_id = (*temp);			/* STRING_MESSAGE */


	/* Send message */
	ret_value = msg_send((void *) &message,MSG_OPTION_NONE, (msg_timeout_t) 0);

	return(ret_value);
}

/*===========================================================================

	Function: send_float_message

	Purpose: This function sends a float message to the port specified
		in the outPort parameter.  The message has 2 data items called
		"ident" and "value".

	Parameters:	outPort: The port to which the message is sent.
			replyPort: The reply port where the reply (if any)
					is expected.
			msg_id: See SpeechMessages.h
			ident: Identity of the SpeechObject Instance.
			value: The float parameter to be sent.

	Returns: (kern_return_t) This function returns the value returned
		 by the function msg_send.

	NOTE: Very Important.  In order to reduce programming and overhead,
		a small hack has been made in this function.  Since both 
		floats and ints are 32 bits long, they are treated as equals
		in the message data structure.  Although ident is defined as
		an int and data is defined as a float (see MessageStructs.h)
		they are only covered by 1 data header item.

===========================================================================*/

kern_return_t send_float_message(outPort, replyPort, msg_id, ident, value)
port_t outPort, replyPort;
int msg_id, ident;
float value;
{
struct float_msg message;
msg_return_t ret_value;
unsigned short send_msg_id[2];
int *temp;

	/* Set up message header.  Be sure to include a reply port! */
	message.h.msg_simple = TRUE;
	message.h.msg_size = sizeof(struct float_msg);
	message.h.msg_type = MSG_TYPE_NORMAL;
	message.h.msg_local_port = replyPort;		/* Reply port */
	message.h.msg_remote_port = outPort;
	send_msg_id[0] =(unsigned short) msg_id;
	send_msg_id[1] =(unsigned short) ident;
	temp = (int *) send_msg_id;
	message.h.msg_id = (*temp);			/* STRING_MESSAGE */


	/* Set up message data header */
	message.t.msg_type_name = MSG_TYPE_INTEGER_32;	/* Integer data */
	message.t.msg_type_size = 32;			/* integer is 32 bits */
	message.t.msg_type_number = 1;			/* there is 1 int and 1 float*/
	message.t.msg_type_inline = TRUE;		/* in-line */
	message.t.msg_type_longform = FALSE;
	message.t.msg_type_deallocate = FALSE;		

	message.data = value;				/* The actual Data */

	/* Send message */
	ret_value = msg_send((void *) &message,MSG_OPTION_NONE, (msg_timeout_t) 0);

	return(ret_value);
}

/*===========================================================================

	Function: send_int_message

	Purpose: This function sends a float message to the port specified
		in the outPort parameter.  The message has 2 data items called
		"ident" and "value".

	Parameters:	outPort: The port to which the message is sent.
			replyPort: The reply port where the reply (if any)
					is expected.
			msg_id: See SpeechMessages.h
			ident: Identity of the SpeechObject Instance.
			value: The float parameter to be sent.

	Returns: (kern_return_t) This function returns the value returned
		 by the function msg_send.

===========================================================================*/

kern_return_t send_int_message(outPort, replyPort, msg_id, ident, value)
port_t outPort, replyPort;
int msg_id, ident;
int value;
{
struct int_msg message;
msg_return_t ret_value;
unsigned short send_msg_id[2];
int *temp;

	/* Set up message header.  Be sure to include a reply port! */
	message.h.msg_simple = TRUE;
	message.h.msg_size = sizeof(struct int_msg);
	message.h.msg_type = MSG_TYPE_NORMAL;
	message.h.msg_local_port = replyPort;		/* Reply port */
	message.h.msg_remote_port = outPort;
	send_msg_id[0] =(unsigned short) msg_id;
	send_msg_id[1] =(unsigned short) ident;
	temp = (int *) send_msg_id;
	message.h.msg_id = (*temp);			/* STRING_MESSAGE */

	/* Set up message data header */
	message.t.msg_type_name = MSG_TYPE_INTEGER_32;	/* Integer data */
	message.t.msg_type_size = 32;			/* integer is 32 bits */
	message.t.msg_type_number = 1;			/* there is 1 int and 1 float*/
	message.t.msg_type_inline = TRUE;		/* in-line */
	message.t.msg_type_longform = FALSE;
	message.t.msg_type_deallocate = FALSE;		

	message.data = value;				/* The actual Data */

	/* Send message */
	ret_value = msg_send((void *) &message,MSG_OPTION_NONE, (msg_timeout_t) 0);

	return(ret_value);
}

/*===========================================================================

	Function: receive_simple_message

	Purpose: This function receives a simple message from the port 
		specified in inPort.

	Parameters:	inPort: The incoming port.
			message: Pointer to where the incoming message is
				to be put.

	Returns: The value returned by msg_send is returned.
		The message itself is returned in the buffer pointed to 
		by the "message" parameter.

===========================================================================*/

kern_return_t receive_simple_message(inPort, message)
port_t inPort;
struct simple_msg *message;
{
msg_return_t ret_value;
	message->h.msg_local_port = inPort;
	message->h.msg_size = sizeof(struct simple_msg);
	ret_value = msg_receive((msg_header_t *) message, MSG_OPTION_NONE, (msg_timeout_t) 0);
	return(ret_value);
}


/*===========================================================================

	Function: receive_float_message

	Purpose: This function receives a float message from the port 
		specified in inPort.

	Parameters:	inPort: The incoming port.
			message: Pointer to where the incoming message is
				to be put.

	Returns: The value returned by msg_send is returned.
		The message itself is returned in the buffer pointed to 
		by the "message" parameter.

===========================================================================*/

kern_return_t receive_float_message(inPort, message)
port_t inPort;
struct float_msg *message;
{
msg_return_t ret_value;
	message->h.msg_local_port = inPort;
	message->h.msg_size = sizeof(struct float_msg);
	ret_value = msg_receive((msg_header_t *)message, MSG_OPTION_NONE, (msg_timeout_t) 0);
	return(ret_value);
}

/*===========================================================================

	Function: receive_string_message

	Purpose: This function receives a string message and deallocates the 
		out-of-line data buffer.

	Parameters:	inPort: The incoming port.
			message: Pointer to where the incoming message is
				to be put.

	Returns: The value returned by msg_send is returned.
		The message itself is returned in the buffer pointed to 
		by the "message" parameter.

	NOTE: Very important.  This function returns a message which contains
		a pointer to out-of-line data.  It MUST be deallocated
		with the vm_deallocate call:
		vm_deallocate(task_self(), (vm_address_t)message.data,
			strlen(message.data+2));

		vm_deallocate automatically defaults to a multiple of the
		system constant PAGESIZE;  therefore, an accurate measure
		of memory size is not necessary.

===========================================================================*/
kern_return_t receive_string_message(inPort, message)
port_t inPort;
struct float_msg *message;
{
msg_return_t ret_value;
	message->h.msg_local_port = inPort;
	message->h.msg_size = sizeof(struct string_msg);
	ret_value = msg_receive((msg_header_t *)message, MSG_OPTION_NONE, (msg_timeout_t) 0);
	return(ret_value);
}


/*===========================================================================

	Function: receive_int_message

	Purpose: This function receives a int message from the port 
		specified in inPort.

	Parameters:	inPort: The incoming port.
			message: Pointer to where the incoming message is
				to be put.

	Returns: The value returned by msg_send is returned.
		The message itself is returned in the buffer pointed to 
		by the "message" parameter.

===========================================================================*/

kern_return_t receive_int_message(inPort, message)
port_t inPort;
struct  int_msg *message;
{
msg_return_t ret_value;
	message->h.msg_local_port = inPort;
	message->h.msg_size = sizeof(struct int_msg);
	ret_value = msg_receive((msg_header_t *)message, MSG_OPTION_NONE, (msg_timeout_t) 0);
	return(ret_value);
}

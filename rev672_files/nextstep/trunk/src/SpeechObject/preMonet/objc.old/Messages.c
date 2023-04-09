/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:53 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/SpeechObject/preMonet/objc.old/Messages.c,v $
$State: Exp $


$Log: not supported by cvs2svn $

******************************************************************************/

/**************************************************************************************
*
*       This file was created on June 22, 1991.  It is the integration of 
*       several test files.  Each function has been tested in at least 1 other
*       context.
*
*       Revised April 23, 1992 (LM):  added message timeouts, function prototypes.
*               May 25, 1992 (LM):    added receive_int_message_block().
*               July 8, 1992 (LM):    changed message time-out to 3 seconds.
*
*       This file contains low-level messaging functions for both the speech
*       server and the User-SpeechObject.  In order to avoid any undue
*       overhead, messages are constructed by hand and not with MiG.
*
*       The following is a list of supported functions:
*
*           send_simple_message(port_t outPort, port_t replyPort,
*                               int msg_id, int ident);
*           send_int_message(port_t outPort, port_t replyPort,
*                            int msg_id, int ident, int value)
*           send_float_message(port_t outPort, port_t replyPort,
*                              int msg_id, int ident, float value);
*           send_string_message(port_t outPort, port_t replyPort,
*                               int msg_id, int ident, char *value);
*
*           receive_simple_message(port_t inPort, simple_msg_t *message);
*           receive_int_message(port_t inPort, int_msg_t *message);
*           receive_int_message_block(port_t inPort, int_msg_t *message);
*           receive_int_message_long(port_t inPort, int_msg_t *message);
*           receive_float_message(port_t inPort, float_msg_t *message);
*           receive_string_message(port_t inPort, string_msg_t *message);
*           receive_string_message_long(port_t inPort, string_msg_t *message);
*
*       All functions are described below.
*
**************************************************************************************/


/*  HEADER FILES  ************************************************************/
#import <stdio.h>
#import "Messages.h"
#import "MessageStructs.h"


/*  LOCAL DEFINES  ***********************************************************/
#define TTS_TIMEOUT           3000     /*  EQUALS 3 SECONDS  */
#define TTS_LONG_TIMEOUT      30000    /*  EQUALS 30 SECONDS  */


/**************************************************************************************
*
*       Function:    send_simple_message
*
*       Purpose:     This function sends a simple message to the port specified
*                    in the outPort parameter.  The message has 1 data item called
*                    "ident". 
*
*       Parameters:  outPort:    The port to which the message is sent.
*                    replyPort:  The reply port where the reply (if any)
*                                is expected.
*                    msg_id:     See SpeechMessages.h
*                    ident:      Identity of the SpeechObject Instance.
*
*       Returns:     (msg_return_t) This function returns the value returned
*                    by the function msg_send.
*
**************************************************************************************/

msg_return_t send_simple_message(port_t outPort, port_t replyPort, int msg_id, int ident)
{
  simple_msg_t message;
  unsigned short send_msg_id[2];

  /*  SET UP MESSAGE HEADER.  BE SURE TO INCLUDE A REPLY PORT!  */
  message.h.msg_simple = TRUE;
  message.h.msg_size = sizeof(simple_msg_t);
  message.h.msg_type = MSG_TYPE_NORMAL;
  message.h.msg_local_port = replyPort;
  message.h.msg_remote_port = outPort;
  
  send_msg_id[0] = (unsigned short)msg_id;
  send_msg_id[1] = (unsigned short)ident;
  message.h.msg_id = *((int *)send_msg_id);
  
  /*  SEND MESSAGE  */
  return(msg_send((void *)&message, SEND_TIMEOUT, (msg_timeout_t)TTS_TIMEOUT));
}



/**************************************************************************************
*
*       Function:    send_int_message
*
*       Purpose:     This function sends a float message to the port specified
*                    in the outPort parameter.  The message has 2 data items called
*                    "ident" and "value".
*
*       Parameters:  outPort:    The port to which the message is sent.
*                    replyPort:  The reply port where the reply (if any)
*                                is expected.
*                    msg_id:     See SpeechMessages.h
*                    ident:      Identity of the SpeechObject Instance.
*                    value:      The float parameter to be sent.
*
*       Returns:     (msg_return_t) This function returns the value returned
*                    by the function msg_send.
*
**************************************************************************************/

msg_return_t send_int_message(port_t outPort, port_t replyPort,
			      int msg_id, int ident, int value)
{
  int_msg_t message;
  unsigned short send_msg_id[2];
  
  /*  SET UP MESSAGE HEADER.  BE SURE TO INCLUDE A REPLY PORT!  */
  message.h.msg_simple = TRUE;
  message.h.msg_size = sizeof(int_msg_t);
  message.h.msg_type = MSG_TYPE_NORMAL;
  message.h.msg_local_port = replyPort;
  message.h.msg_remote_port = outPort;

  send_msg_id[0] = (unsigned short)msg_id;
  send_msg_id[1] = (unsigned short)ident;
  message.h.msg_id = *((int *)send_msg_id);
  
  /*  SET UP MESSAGE DATA HEADER  */
  message.t.msg_type_name = MSG_TYPE_INTEGER_32;  /* Integer data */
  message.t.msg_type_size = 32;			  /* integer is 32 bits */
  message.t.msg_type_number = 1;		  /* there is 1 int and 1 float */
  message.t.msg_type_inline = TRUE;		  /* in-line */
  message.t.msg_type_longform = FALSE;
  message.t.msg_type_deallocate = FALSE;		
  
  message.data = value;				  /* The actual Data */
  
  /*  SEND MESSAGE  */
  return(msg_send((void *)&message, SEND_TIMEOUT, (msg_timeout_t)TTS_TIMEOUT));
}



/**************************************************************************************
*
*       Function:    send_float_message
*
*       Purpose:     This function sends a float message to the port specified
*                    in the outPort parameter.  The message has 2 data items called
*                    "ident" and "value".
*
*       Parameters:  outPort:    The port to which the message is sent.
*                    replyPort:  The reply port where the reply (if any)
*                                is expected.
*                    msg_id:     See SpeechMessages.h
*                    ident:      Identity of the SpeechObject Instance.
*                    value:      The float parameter to be sent.
*
*       Returns:     (msg_return_t) This function returns the value returned
*                    by the function msg_send.
*
*       NOTE: Very Important.  In order to reduce programming and overhead,
*       a small hack has been made in this function.  Since both 
*       floats and ints are 32 bits long, they are treated as equals
*       in the message data structure.  Although ident is defined as
*       an int and data is defined as a float (see MessageStructs.h)
*       they are only covered by 1 data header item.
*
**************************************************************************************/

msg_return_t send_float_message(port_t outPort, port_t replyPort,
				int msg_id, int ident, float value)
{
  float_msg_t message;
  unsigned short send_msg_id[2];

  /*  SET UP MESSAGE HEADER.  BE SURE TO INCLUDE A REPLY PORT!  */
  message.h.msg_simple = TRUE;
  message.h.msg_size = sizeof(float_msg_t);
  message.h.msg_type = MSG_TYPE_NORMAL;
  message.h.msg_local_port = replyPort;
  message.h.msg_remote_port = outPort;

  send_msg_id[0] = (unsigned short)msg_id;
  send_msg_id[1] = (unsigned short)ident;
  message.h.msg_id = *((int *)send_msg_id);
  
  /*  SET UP MESSAGE DATA HEADER  */
  message.t.msg_type_name = MSG_TYPE_INTEGER_32;  /* Integer data */
  message.t.msg_type_size = 32;			  /* integer is 32 bits */
  message.t.msg_type_number = 1;		  /* there is 1 int and 1 float*/
  message.t.msg_type_inline = TRUE;		  /* in-line */
  message.t.msg_type_longform = FALSE;
  message.t.msg_type_deallocate = FALSE;		
  
  message.data = value;				  /* The actual Data */
  
  /*  SEND MESSAGE  */
  return(msg_send((void *)&message, SEND_TIMEOUT, (msg_timeout_t)TTS_TIMEOUT));
}



/**************************************************************************************
*
*       Function:    send_string_message
*
*       Purpose:     This function sets-up and sends a message with two data 
*                    items value and ident to the port specified in the outPort
*                    parameter.  
*
*       Parameters:  outPort:    The port to which the message is sent.
*                    replyPort:  The reply port where the reply (if any)
*                    is expected.
*                    msg_id:     Should be set to STRING_MESSAGE.
*                    ident:      Identity of the SpeechObject Instance.
*                    value:      Pointer to null-terminated string.
*
*       Returns:     (msg_return_t) This function returns the value returned
*                    by the function msg_send.
*
*       Algorithm:   This function sets up the message header.  This simply
*                    involves setting up data fields in the msg_header_t struct.
*                    Then the data header and data item for the instance 
*                    identifier is set up.  Then the data header and character 
*                    pointer structures are set up.  See the digital librarian
*                    for documentation on setting up these system data structs.
*
**************************************************************************************/

msg_return_t send_string_message(port_t outPort, port_t replyPort, 
				 int msg_id, int ident, const char *value)
{
  string_msg_t message;
  unsigned short send_msg_id[2];
  
  /*  SET UP MESSAGE HEADER.  BE SURE TO INCLUDE A REPLY PORT!  */
  message.h.msg_simple = FALSE;
  message.h.msg_size = sizeof(string_msg_t);
  message.h.msg_type = MSG_TYPE_NORMAL;
  message.h.msg_local_port = replyPort;
  message.h.msg_remote_port = outPort;
  
  send_msg_id[0] = (unsigned short)msg_id;
  send_msg_id[1] = (unsigned short)ident;
  message.h.msg_id = *((int *)send_msg_id);
  
  /* Set up message data header */
  message.t1.msg_type_header.msg_type_name = MSG_TYPE_STRING;     /* String message sent */
  message.t1.msg_type_header.msg_type_size = 8;                   /* 8bits/Char */
  message.t1.msg_type_header.msg_type_number = strlen(value)+1;   /* Strlength + NULL char */
  message.t1.msg_type_header.msg_type_inline = FALSE;             /* Out-of-line */
  message.t1.msg_type_header.msg_type_longform = TRUE;
  message.t1.msg_type_header.msg_type_deallocate = FALSE;         /* User must deallocate */

  message.t1.msg_type_long_name = (short) MSG_TYPE_STRING;       /* String message sent */
  message.t1.msg_type_long_size = (short) 8;             	 /* 8bits/Char */
  message.t1.msg_type_long_number = strlen(value)+1;     	 /* Strlength + NULL char */
  
  message.data = value;			        /* Pointer to buffer */

/*	printf("Value = |%s|\n Strlen = %d\n", value, strlen(value));*/
  
  /*  SEND MESSAGE  */
  return(msg_send((void *)&message, SEND_TIMEOUT, (msg_timeout_t)TTS_TIMEOUT));
}



/**************************************************************************************
*
*       Function:    receive_simple_message
*
*       Purpose:     This function receives a simple message from the port 
*                    specified in inPort.
*
*       Parameters:  inPort:   The incoming port.
*                    message:  Pointer to where the incoming message is
*                              to be put.
*
*       Returns:     The value returned by msg_send is returned.
*                    The message itself is returned in the buffer pointed to 
*                    by the "message" parameter.
*
**************************************************************************************/

msg_return_t receive_simple_message(port_t inPort, simple_msg_t *message)
{
  message->h.msg_local_port = inPort;
  message->h.msg_size = sizeof(simple_msg_t);
  return(msg_receive((msg_header_t *)message, RCV_TIMEOUT, (msg_timeout_t)TTS_TIMEOUT));
}



/**************************************************************************************
*
*       Function:    receive_int_message
*
*       Purpose:     This function receives a int message from the port 
*                    specified in inPort.
*
*       Parameters:  inPort:   The incoming port.
*                    message:  Pointer to where the incoming message is
*                              to be put.
*
*       Returns:     The value returned by msg_send is returned.
*                    The message itself is returned in the buffer pointed to 
*                    by the "message" parameter.
*
**************************************************************************************/

msg_return_t receive_int_message(port_t inPort, int_msg_t *message)
{
  message->h.msg_local_port = inPort;
  message->h.msg_size = sizeof(int_msg_t);
  return(msg_receive((msg_header_t *)message, RCV_TIMEOUT, (msg_timeout_t)TTS_TIMEOUT));
}



/**************************************************************************************
*
*       Function:    receive_int_message_block
*
*       Purpose:     This function receives a int message from the port 
*                    specified in inPort, and blocks until it is received.
*
*       Parameters:  inPort:   The incoming port.
*                    message:  Pointer to where the incoming message is
*                              to be put.
*
*       Returns:     The value returned by msg_send is returned.
*                    The message itself is returned in the buffer pointed to 
*                    by the "message" parameter.
*
**************************************************************************************/

msg_return_t receive_int_message_block(port_t inPort, int_msg_t *message)
{
  message->h.msg_local_port = inPort;
  message->h.msg_size = sizeof(int_msg_t);
  return(msg_receive((msg_header_t *)message, MSG_OPTION_NONE, 0));
}



/**************************************************************************************
*
*       Function:    receive_int_message_long
*
*       Purpose:     This function receives a int message from the port 
*                    specified in inPort, and uses a long time out.
*
*       Parameters:  inPort:   The incoming port.
*                    message:  Pointer to where the incoming message is
*                              to be put.
*
*       Returns:     The value returned by msg_send is returned.
*                    The message itself is returned in the buffer pointed to 
*                    by the "message" parameter.
*
**************************************************************************************/

msg_return_t receive_int_message_long(port_t inPort, int_msg_t *message)
{
  message->h.msg_local_port = inPort;
  message->h.msg_size = sizeof(int_msg_t);
  return(msg_receive((msg_header_t *)message, RCV_TIMEOUT, (msg_timeout_t)TTS_LONG_TIMEOUT));
}



/**************************************************************************************
*
*       Function:    receive_float_message
*
*       Purpose:     This function receives a float message from the port 
*                    specified in inPort.
*
*       Parameters:  inPort:   The incoming port.
*                    message:  Pointer to where the incoming message is
*                              to be put.
*
*       Returns:     The value returned by msg_send is returned.
*                    The message itself is returned in the buffer pointed to 
*                    by the "message" parameter.
*
**************************************************************************************/

msg_return_t receive_float_message(port_t inPort, float_msg_t *message)
{
  message->h.msg_local_port = inPort;
  message->h.msg_size = sizeof(float_msg_t);
  return(msg_receive((msg_header_t *)message, RCV_TIMEOUT, (msg_timeout_t)TTS_TIMEOUT));
}



/**************************************************************************************
*
*       Function:    receive_string_message
*
*	Purpose:     This function receives a string message and deallocates the 
*                    out-of-line data buffer.
*
*       Parameters:  inPort:   The incoming port.
*                    message:  Pointer to where the incoming message is
*                              to be put.
*
*       Returns:     The value returned by msg_send is returned.
*                    The message itself is returned in the buffer pointed to 
*                    by the "message" parameter.
*
*       NOTE:        Very important.  This function returns a message which contains
*                    a pointer to out-of-line data.  It MUST be deallocated
*                    with the vm_deallocate call:
*
*                    vm_deallocate(task_self(), (vm_address_t)message.data,
*                                  strlen(message.data+2));
*
*                    vm_deallocate automatically defaults to a multiple of the
*                    system constant PAGESIZE;  therefore, an accurate measure
*                    of memory size is not necessary.
*
**************************************************************************************/

msg_return_t receive_string_message(port_t inPort, string_msg_t *message)
{
  message->h.msg_local_port = inPort;
  message->h.msg_size = sizeof(string_msg_t);
  return(msg_receive((msg_header_t *)message, RCV_TIMEOUT, (msg_timeout_t)TTS_TIMEOUT));
}



/**************************************************************************************
*
*       Function:    receive_string_message_long
*
*	Purpose:     This function receives a string message and deallocates the 
*                    out-of-line data buffer.  A long time out is used.
*
*       Parameters:  inPort:   The incoming port.
*                    message:  Pointer to where the incoming message is
*                              to be put.
*
*       Returns:     The value returned by msg_send is returned.
*                    The message itself is returned in the buffer pointed to 
*                    by the "message" parameter.
*
*       NOTE:        Very important.  This function returns a message which contains
*                    a pointer to out-of-line data.  It MUST be deallocated
*                    with the vm_deallocate call:
*
*                    vm_deallocate(task_self(), (vm_address_t)message.data,
*                                  strlen(message.data+2));
*
*                    vm_deallocate automatically defaults to a multiple of the
*                    system constant PAGESIZE;  therefore, an accurate measure
*                    of memory size is not necessary.
*
**************************************************************************************/

msg_return_t receive_string_message_long(port_t inPort, string_msg_t *message)
{
  message->h.msg_local_port = inPort;
  message->h.msg_size = sizeof(string_msg_t);
  return(msg_receive((msg_header_t *)message, RCV_TIMEOUT, (msg_timeout_t)TTS_LONG_TIMEOUT));
}

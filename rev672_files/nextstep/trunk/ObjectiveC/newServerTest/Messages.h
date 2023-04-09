#import "MessageStructs.h"

extern msg_return_t send_simple_message(port_t outPort, port_t replyPort,
					int msg_id, int ident);
extern msg_return_t send_int_message(port_t outPort, port_t replyPort,
				     int msg_id, int ident, int value);
extern msg_return_t send_float_message(port_t outPort, port_t replyPort,
				       int msg_id, int ident, float value);
extern msg_return_t send_string_message(port_t outPort, port_t replyPort, 
					int msg_id, int ident, const char *value);
extern msg_return_t receive_simple_message(port_t inPort, simple_msg_t *message);
extern msg_return_t receive_int_message(port_t inPort, int_msg_t *message);
extern msg_return_t receive_int_message_block(port_t inPort, int_msg_t *message);
extern msg_return_t receive_int_message_long(port_t inPort, int_msg_t *message);
extern msg_return_t receive_float_message(port_t inPort, float_msg_t *message);
extern msg_return_t receive_string_message(port_t inPort, string_msg_t *message);
extern msg_return_t receive_string_message_long(port_t inPort, string_msg_t *message);

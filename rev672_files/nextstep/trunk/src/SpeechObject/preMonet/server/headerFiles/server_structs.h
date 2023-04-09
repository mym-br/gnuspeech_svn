//#import <ndbm.h>
#import "preditorDict.h"

/*===========================================================================

	Notes: 

	identifier:  The speaker ident (identifier) of is used to determine
		which speaker object is making a request of the server.  When
		an instance of the SpeechObject is created, it immediately
		attempts to communicate with the speech daemon.  With its 
		initial contact, it receives an unique identifier which it 
		must always send to the speech daemon when it makes a 
		request.  In this way, a small database can be kept which 
		keeps track of the speaker attributes of each instance of 
		the SpeechObject.  In this way, multi-user access to the 
		speech daemon will be transparent to the user/programmer.

===========================================================================*/


struct _user {
	float	speed;
	float	volume;
	float	pitch_offset;
	float	balance;
	int 	voice_type;
	int	elasticity;
	int	intonation;
	int	escape_character;
	int	user_task;
	int	block;
	port_t	block_port;
	port_t	error_port;
	char	app_dict[256];
	char	user_dict[256];
	preditorDict user;
	preditorDict app;
	short	order[5];
};


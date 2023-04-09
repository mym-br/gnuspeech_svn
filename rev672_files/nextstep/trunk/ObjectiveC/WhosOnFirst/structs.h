struct record {
	char name[10];		/* User name */
	char tty[10];		/* TTY name */
	char hostname[64];	/* Host Name */
	int marked;		/* Referenced */
	id windowPointer;	/* Pointer to window */
	float x,y;		/* x,y position of icon (screen coords) */
	struct record *next;	/* Pointer to next record in list */

};

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

/*================================================================================

	File: stat.c
	Author: Craig-Richard Schock

	Purpose: This file contains the function which returns the size in bytes
		 of the specified file.

	Parameters: 

	Filename:  The name of the file to be checked.

	Last Modified: February 25, 1993.

================================================================================*/

long get_size(filename)
char filename[256];
{
struct stat buf;

	if (stat(filename,&buf)== (-1)) return(0);
	return(buf.st_size);
}

/*
 *    Filename:	objc-debug.h 
 *    Created :	Tue Mar 24 19:21:43 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *
 * LastEditDate "Tue Apr  7 21:38:21 1992"
 *
 * $Log: not supported by cvs2svn $
 * Revision 2.0  1992/04/08  03:43:23  vince
 * Initial-Release
 *
 *
 */

/* Macros for debugging */

#ifdef DEBUG
#import <stdio.h>
#import <objc/objc.h>  /* not necessary because this file will only be imported into
			* Objectiv C code
			*/

#define DEBUG_FILE_VERSION   \
        fprintf(stderr,"Source file %s last compiled on %s at %s\n", __FILE__, __DATE__, __TIME__ )

#define DEBUG_PUTS(string)  \
        fputs(string, stderr)

#define DEBUG_ASSERT(x)	    \
         if (!(x))          \
            fprintf(stderr,"Assertion: %s failed in source file: %s line: %i\n", #x,__FILE__,__LINE__)

#define DEBUG_METHOD        \
        fprintf(stderr,"In class: %s, %s is called\n", __FILE__,sel_getName(_cmd))

#else
#define DEBUG_FILE_VERSION
#define DEBUG_PUTS(string)
#define DEBUG_ASSERT(x)
#define DEBUG_METHOD
#endif

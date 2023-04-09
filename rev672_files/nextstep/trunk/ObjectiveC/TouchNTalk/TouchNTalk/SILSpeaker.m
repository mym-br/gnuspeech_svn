/*
 *    Filename:	SILSpeaker.m 
 *    Created :	Sun Jul  4 22:51:03 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Mon Jun  6 20:18:09 1994"
 *
 * $Id: SILSpeaker.m,v 1.5 1994/06/10 20:18:28 dale Exp $
 *
 * $Log: SILSpeaker.m,v $
 * Revision 1.5  1994/06/10  20:18:28  dale
 * Modified lines/columns holophrast to use tab or 3 spaces as separator between nodes.
 *
 * Revision 1.4  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.3  1993/08/27  03:51:06  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/07/23  07:33:00  dale
 * *** empty log message ***
 *
 * Revision 1.1  1993/07/06  00:34:26  dale
 * Initial revision
 *
 */

#import <appkit/Application.h>
#import <appkit/Panel.h>
#import <appkit/nextstd.h>
#import <appkit/publicWraps.h>
#import "SILSpeaker.h"

/* CLASS VARIABLES */
static id speechInstance;   // allow only one instance of class to allocated and initialized
static int reference;       // keep track of all references to the shared instance

@implementation SILSpeaker

+ initialize
{
    speechInstance = nil;
    reference = 0;
    return self;
}

/* Returns the shared instance to a SILSpeaker object. Note that initializing the speechInstance
 * with [[super alloc] init] causes the local -init method to be invoked rather than the superclasses.
 * In addition, the -alloc method invoked is actually the one residing in the superclass, but within
 * our own execution context. Therefore the return type of [super alloc] is infact an instance of the
 * local class! So it seems that super actually acts ONLY as a pointer to where to look for a 
 * particular method, but the instance returned is that of the working class -- that is, an instance 
 * of the current working class context. Here is an explanatory note from Len,
 *
 *     "When you do a [super alloc], I think what is returned is the id of the class in which 
 *      you are working (not the superclass). I say this because the usual way to allocate 
 *      memory for an instance of a class is to do:
 *
 *          self = [super alloc];
 *
 *      Since this is done in the context of the +alloc method, the compiler is smart enough 
 *      to know that you are allocating memory for the class's instance variables plus all 
 *      inherited instance variables."
 */
+ new
{
    if (!speechInstance) {
	speechInstance = [[super alloc] init];   // this invokes the local -init, but super's -alloc,
	if (speechInstance == nil) {             // all within our own execution context
	    NXBeep();
	    NXRunAlertPanel("TextToSpeech Server", "Too many clients, or server cannot be started.", 
			    "OK", NULL, NULL);
	    [NXApp terminate:self];
	}
    }
    reference++;
    return speechInstance;
}

+ alloc
{
    NXLogError("Attempt to +alloc shared instance of SILSpeaker class.");
    return nil;
}

+ allocFromZone:(NXZone *)zone
{
    NXLogError("Attempt to +allocFromZone: shared instance of SILSpeaker class.");
    return nil;
}

- init
{
    [super init];
    return self;
}

/* Actually frees the shared instance only if there are no more references to it. If there are
 * references, then we just return self (the shared instance). Make sure we set the shared instance 
 * to nil after sending [super free]. Returns self.
 */
- free
{
    if (--reference <= 0) {
	[super free];
	speechInstance = nil;
	reference = 0;          // just in case
    }
    return self;
}

@end

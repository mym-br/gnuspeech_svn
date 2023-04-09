/*
 *    Filename:	SILSpeaker.h 
 *    Created :	Sun Jul  4 22:49:44 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Wed Aug 25 16:29:01 1993"
 *
 * $Id: SILSpeaker.h,v 1.3 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: SILSpeaker.h,v $
 * Revision 1.3  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.2  1993/08/27  03:51:06  dale
 * *** empty log message ***
 *
 * Revision 1.1  1993/07/06  00:34:26  dale
 * Initial revision
 *
 */

#import <TextToSpeech/TextToSpeech.h>

@interface SILSpeaker:TextToSpeech
{
}

/* CLASS METHODS */
+ initialize;
+ new;
+ alloc;
+ allocFromZone:(NXZone *)zone;

/* GENERAL METHODS */
- init;
- free;

@end

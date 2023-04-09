/*
 *    Filename:	Queue.h 
 *    Created :	Wed May 12 22:20:03 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Wed May 19 14:37:32 1993"
 *
 * $Id: Queue.h,v 1.2 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: Queue.h,v $
 * Revision 1.2  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.1  1993/05/20  06:03:35  dale
 * Initial revision
 *
 */

#import <appkit/appkit.h>
#import <objc/Object.h>

/* Typedef's */
typedef struct _QStruct {
    void            *object;
    struct _QStruct *nNode;
} QNode;

@interface Queue:Object
{
    QNode        *qHead;
    QNode        *qTail;
    unsigned int  qLength;
}

- init;
- (void *)dequeueObject;
- enqueueObject:(void *)object;
- (unsigned int)lengthOfQueue;
- free;

@end

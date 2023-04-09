/*
 *    Filename:	Queue.m 
 *    Created :	Wed May 12 22:20:15 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Wed May 19 14:37:38 1993"
 *
 * $Id: Queue.m,v 1.2 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: Queue.m,v $
 * Revision 1.2  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.1  1993/05/20  06:03:35  dale
 * Initial revision
 *
 */

#import <stdlib.h>
#import "Queue.h"

@implementation Queue


- init
{
    [super init];
    qHead = qTail = (QNode *)NULL;
    qLength = 0;
    return self;
}


/* Adds a pointer to some object to the tail of the queue.  If a pointer to NULL is passed as the 
 * object, it is simply ignored, and the Q length remains the same.  Self is always returned.
 */
- enqueueObject:(void *)object
{
    QNode *qNode;

    if (object == (void *)NULL)
        return self;

    if (!(qNode = (QNode *)malloc((size_t)sizeof(QNode)))) {
        NXLogError("Unable to allocate memory.");
	return self;
    }

    qNode->object = object;
    qNode->nNode  = (QNode *)NULL;

    if (qHead != qTail) {                  // More than one element in Q
	qTail->nNode = qNode;
	qTail = qNode;
    } else if (qHead != (QNode *)NULL) {   // Only one element in Q
	qTail = qNode;
	qHead->nNode = qNode;
    } else {                               // Q is empty
	qHead = qTail = qNode;
    }
    qLength++;
    return self;
}


/* Removes a pointer to some object from the head of the queue.  If there is nothing to remove, a NULL
 * pointer is returned, else a pointer to the object is returned.
 */
- (void *)dequeueObject
{
    void   *object;
    QNode *cNode;

    if (qHead != qTail) {                  // More than one element in Q
	cNode = qHead;
	qHead = cNode->nNode;
	cNode->nNode = (QNode *)NULL;
	object = cNode->object;
	cNode->object = (void *)NULL;
	free((char *)cNode);
	qLength--;
    } else if (qHead != (QNode *)NULL) {   // Only one element in Q
	cNode = qHead;
	qHead = qTail = (QNode *)NULL;
	object = cNode->object;
	cNode->object = (void *)NULL;
	free((char *)cNode);
	qLength = 0;
    } else {                               // Q is empty
	object = (void *)NULL;
    }
    return object;
}


- (unsigned int)lengthOfQueue
{
    return qLength;
}


- free
{
    QNode *cNode;

    while (qHead != (QNode *)NULL) {
	cNode = qHead->nNode;
	qHead->nNode = (QNode *)NULL;
	free((char *)qHead);
	qHead = cNode;
    }
    return [super free];
}

@end

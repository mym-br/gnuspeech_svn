/*
 *    Filename:	TabletReader.h 
 *    Created :	Thu Aug  5 14:21:07 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Mon Jan  9 12:13:41 1995"
 *    Copyright (c) 1995, Dale Brisinda. All rights reserved.
 */

@protocol TabletReader

- convertDataAtTabletFD:(int)tabletFD 
    location:(NXPoint *)location
    identifier:(short *)identifier
    proximity:(short *)proximity
    pressure:(short *)pressure
    angle:(short *)angle
    button:(short *)button;

@end

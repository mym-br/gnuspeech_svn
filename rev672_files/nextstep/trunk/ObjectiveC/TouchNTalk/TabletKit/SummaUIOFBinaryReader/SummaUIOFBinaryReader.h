/*
 *    Filename:	SummaUIOFBinaryReader.h
 *    Created :	Fri Aug  6 12:38:09 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Mon Jan  9 12:21:32 1995"
 *    Copyright (c) 1995, Dale Brisinda. All rights reserved.
 */

#import <objc/Object.h>
#import <tabletkit/tabletkit.h>

@interface SummaUIOFBinaryReader:Object <TabletReader>

/* DATA CONVERSION METHODS */
- (NXCoord)convertToCoord:(char)c1 :(char)c2 :(char)c3;

@end

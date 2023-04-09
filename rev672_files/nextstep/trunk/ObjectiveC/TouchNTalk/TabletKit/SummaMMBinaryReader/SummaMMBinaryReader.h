/*
 *    Filename:	SummaMMBinaryReader.h
 *    Created :	Fri Aug  6 01:04:32 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Mon Jan  9 12:20:08 1995"
 *    Copyright (c) 1995, Dale Brisinda. All rights reserved.
 */

#import <objc/Object.h>
#import <tabletkit/tabletkit.h>

@interface SummaMMBinaryReader:Object <TabletReader>

/* DATA CONVERSION METHODS */
- (NXCoord)convertToCoord:(char)c1 :(char)c2;

@end

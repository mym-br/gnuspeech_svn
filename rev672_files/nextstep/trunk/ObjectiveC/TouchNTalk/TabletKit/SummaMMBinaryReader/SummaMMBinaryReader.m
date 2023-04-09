/*
 *    Filename:	SummaMMBinaryReader.m 
 *    Created :	Fri Aug  6 01:11:56 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Mon Jan  9 12:20:16 1995"
 *    Copyright (c) 1995, Dale Brisinda. All rights reserved.
 */

#import <libc.h>
#import "SummaMMBinaryReader.h"

#define PACKET_SIZE 5

@implementation SummaMMBinaryReader

/* The key item to note here is the read call. The tablet manager sets read 
 * calls to the tablet file descriptor to be non-blocking. Therefore, the read 
 * function call returns immediately. If data was read, then we continue 
 * processing, otherwise we immediately return nil. A nil return value does not
 * signify an error but indicates to the tablet manager that no more events can
 * be generated since there is no more data at the tablet file descriptor.
 *
 * If multiple buttons are pressed, then only the first button inspected is 
 * recognized. Buttons are inspected in the order cursor button 1, cursor 
 * button 2, cursor button 3, and cursor button 4. If the 16 button cursor is
 * used with the mm/SummaSketch format (after setting the tablet for this
 * configuration) then buttons 1-7 map to buttons 8-15, and button 16 is 
 * ignored. The stylus tip button, lower barrel button, and up per barrel 
 * button are equal to cursor button 1, cursor button 2, and cursor button 3 
 * respectively. 
 *
 * If the first byte does not have the phase bit set, we throw out the byte, 
 * and continue reading until a byte with a set phase bit is encountered. If a
 * byte is encountered with the MSB (bit 7) set in the middle of the packet, we
 * make this byte the header of the packet and begin reading the rest of the 
 * packet again. We ignore the pressure, and stylus angle parameters since the
 * mm/SummaSketch format does not support them. Returns self.
 */
- convertDataAtTabletFD:(int)tabletFD 
    location:(NXPoint *)location
    identifier:(short *)identifier
    proximity:(short *)proximity
    pressure:(short *)pressure
    angle:(short *)angle
    button:(short *)button
{
    char buffer[PACKET_SIZE];
    int i;

    for (i = 0; i < PACKET_SIZE; i++) {
	if (read(tabletFD, &buffer[i], 1) != 1) {   // no more data at tablet file descriptor
	    return nil;
	}
	if (i == 0 && !(buffer[i] & 0x80)) {   // bad phase bit; throw out byte
	    i--;
	} else if (i > 0 && (buffer[i] & 0x80)) {   // MSB not clear; make byte header of new packet
            buffer[0] = buffer[i];
            i = 0;
        }
    }
    *proximity = (buffer[0] & 0x40 ? 0 : 1);
    *identifier = (buffer[0] & 0x20 ? 1 : 0);
    location->x = [self convertToCoord:buffer[1] :buffer[2]];
    location->y = [self convertToCoord:buffer[3] :buffer[4]];

    if (!(buffer[0] & 0x10)) {   // negative x coord
	location->x *= -1;
    }
    if (!(buffer[0] & 0x08)) {   // negative y coord
	location->y *= -1;
    }
    switch (buffer[0] & 0x07) {
      case 0x00:
	*button = TK_NOBUTTON;   // no button down
	break;
      case 0x01:
	*button = TK_BUTTON1;    // equal to stylus tip button
	break;
      case 0x02:
	*button = TK_BUTTON2;    // equal to lower stylus barrel button
	break;
      case 0x03:
	*button = TK_BUTTON3;    // equal to upper stylus barrel button; includes (1+2)
	break;
      case 0x04:
	*button = TK_BUTTON4;
	break;
      case 0x05:
	*button = TK_BUTTON5;
	break;
      case 0x06:
	*button = TK_BUTTON6;
	break;
      case 0x07:
	*button = TK_BUTTON7;
	break;
      default:
	*button = TK_NOBUTTON;   // ignore anything else
	break;
    }
    return self;
}

- (NXCoord)convertToCoord:(char)c1 :(char)c2
{
    int r;

    c1 &= 0x7f;
    r = (int)c1;
    c2 &= 0x7f;
    r |= (int)(c2 << 7);
    return (NXCoord)r;
}

@end

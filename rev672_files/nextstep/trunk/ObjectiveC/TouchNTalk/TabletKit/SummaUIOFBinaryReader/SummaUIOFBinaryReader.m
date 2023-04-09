/*
 *    Filename:	SummaUIOFBinaryReader.m
 *    Created :	Fri Aug  6 12:38:54 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Mon Jan  9 12:21:38 1995"
 *    Copyright (c) 1995, Dale Brisinda. All rights reserved.
 */

#import <libc.h>
#import "SummaUIOFBinaryReader.h"

#define PACKET_SIZE 8

@implementation SummaUIOFBinaryReader

/* The key item to note here is the read call. The tablet manager sets read 
 * calls to the tablet file descriptor to be non-blocking. Therefore, the read 
 * function call returns immediately. If data was read, then we continue 
 * processing, otherwise we immediately return nil. A nil return value does not
 * signify an error but indicates to the tablet manager that no more events can
 * be generated since there is no more data at the tablet file descriptor.
 *
 * If the first byte does not have the phase bit set, we throw out the byte,
 * and continue reading until a byte with a set phase bit is encountered. If
 * a byte is encountered with the MSB (bit 6) set in the middle of the packet,
 * we make this byte the header of the packet and begin reading the rest of the
 * packet again. We ignore the pressure, and stylus angle parameters since the 
 * UIOF/Microgrid format does not support them. Returns self.
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
	if (i == 0 && !(buffer[i] & 0x40)) {   // bad phase bit; throw out byte
	    i--;
	} else if (i > 0 && (buffer[i] & 0x40)) {   // MSB not clear; make byte header of new packet
            buffer[0] = buffer[i];
            i = 0;
        }
    }
    *proximity = (buffer[0] & 0x01 ? 0 : 1);
    *identifier = (buffer[0] & 0x02 ? 1 : 0);
    location->x = [self convertToCoord:buffer[2] :buffer[3] :buffer[4]];
    location->y = [self convertToCoord:buffer[5] :buffer[6] :buffer[7]];

    switch (buffer[1] & 0x1f) {
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
	*button = TK_BUTTON3;    // equal to upper stylus barrel button
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
      case 0x08:
	*button = TK_BUTTON8;
	break;
      case 0x09:
	*button = TK_BUTTON9;
	break;
      case 0x0A:
	*button = TK_BUTTON10;
	break;
      case 0x0B:
	*button = TK_BUTTON11;
	break;
      case 0x0C:
	*button = TK_BUTTON12;
	break;
      case 0x0D:
	*button = TK_BUTTON13;
	break;
      case 0x0E:
	*button = TK_BUTTON14;
	break;
      case 0x0F:
	*button = TK_BUTTON15;
	break;
      case 0x10:
	*button = TK_BUTTON16;
	break;
      default:
	*button = TK_NOBUTTON;   // ignore anything else
	break;
    }
    return self;
}

- (NXCoord)convertToCoord:(char)c1 :(char)c2 :(char)c3;
{
    int r, sign;

    sign = (c3 & 0x10) ? -1 : 1;

    c1 &= 0x3f;
    r = (int)c1;
    c2 &= 0x3f;
    r |= (int)(c2 << 6);
    c3 &= 0x0f;
    r |= (int)(c3 << 12);
    return (NXCoord)(r * sign);
}

@end

////////////////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2004 Steve Nygard.  All rights reserved.
//
//  Contributors: Steve Nygard
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
////////////////////////////////////////////////////////////////////////////////
//
//  This file is part of SNFoundation, a personal collection of Foundation
//  extensions. Copyright (C) 2004 Steve Nygard.  All rights reserved.
//
//  NSBezierPath-Extensions.m
//  Monet
//
//  Created by Steve Nygard in 2004
//
//  Version: 0.9.7
//
////////////////////////////////////////////////////////////////////////////////

#import "NSBezierPath-Extensions.h"
#import <AppKit/AppKit.h>

#ifdef GNUSTEP
#define M_PI 3.1415927
#endif

@implementation NSBezierPath (Extensions)

+ (void)drawCircleMarkerAtPoint:(NSPoint)aPoint;
{
    int radius = 3;
    NSBezierPath *bezierPath;

    //NSLog(@"->%s, point: %@", _cmd, NSStringFromPoint(aPoint));
    aPoint.x = rint(aPoint.x);
    aPoint.y = rint(aPoint.y);
    //NSLog(@"-->%s, point: %@", _cmd, NSStringFromPoint(aPoint));

    bezierPath = [[NSBezierPath alloc] init];
    [bezierPath appendBezierPathWithArcWithCenter:aPoint radius:radius startAngle:0 endAngle:360];
    [bezierPath closePath];
    [bezierPath fill];
    //[bezierPath stroke];
    [bezierPath release];
}

+ (void)drawTriangleMarkerAtPoint:(NSPoint)aPoint;
{
    int radius = 5;
    NSBezierPath *bezierPath;
    float angle;

    //NSLog(@"->%s, point: %@", _cmd, NSStringFromPoint(aPoint));
    aPoint.x = rint(aPoint.x);
    aPoint.y = rint(aPoint.y);
    //NSLog(@"-->%s, point: %@", _cmd, NSStringFromPoint(aPoint));

    bezierPath = [[NSBezierPath alloc] init];
    //[bezierPath moveToPoint:NSMakePoint(aPoint.x, aPoint.y + radius)];
    angle = 90.0 * (2 * M_PI) / 360.0;
    //NSLog(@"angle: %f, cos(angle): %f, sin(angle): %f", angle, cos(angle), sin(angle));
    [bezierPath moveToPoint:NSMakePoint(aPoint.x + cos(angle) * radius, aPoint.y + sin(angle) * radius)];
    angle = 210.0 * (2 * M_PI) / 360.0;
    //NSLog(@"angle: %f, cos(angle): %f, sin(angle): %f", angle, cos(angle), sin(angle));
    [bezierPath lineToPoint:NSMakePoint(aPoint.x + cos(angle) * radius, aPoint.y + sin(angle) * radius)];
    angle = 330.0 * (2 * M_PI) / 360.0;
    //NSLog(@"angle: %f, cos(angle): %f, sin(angle): %f", angle, cos(angle), sin(angle));
    [bezierPath lineToPoint:NSMakePoint(aPoint.x + cos(angle) * radius, aPoint.y + sin(angle) * radius)];
    [bezierPath closePath];
    [bezierPath fill];
    //[bezierPath stroke];
    [bezierPath release];
}

+ (void)drawSquareMarkerAtPoint:(NSPoint)aPoint;
{
    NSRect rect;

    //NSLog(@"->%s, point: %@", _cmd, NSStringFromPoint(aPoint));
    aPoint.x = rint(aPoint.x);
    aPoint.y = rint(aPoint.y);
    //NSLog(@"-->%s, point: %@", _cmd, NSStringFromPoint(aPoint));

    rect = NSIntegralRect(NSMakeRect(aPoint.x - 3, aPoint.y - 3, 1, 1));
    rect.size = NSMakeSize(6, 6);
    //NSLog(@"%s, rect: %@", _cmd, NSStringFromRect(rect));
    [NSBezierPath fillRect:rect];
    //[NSBezierPath strokeRect:rect];
    //NSRectFill(rect);
    //NSFrameRect(rect);
}

+ (void)highlightMarkerAtPoint:(NSPoint)aPoint;
{
    NSRect rect;

    //NSLog(@"->%s, point: %@", _cmd, NSStringFromPoint(aPoint));
    aPoint.x = rint(aPoint.x);
    aPoint.y = rint(aPoint.y);
    //NSLog(@"-->%s, point: %@", _cmd, NSStringFromPoint(aPoint));


    rect = NSIntegralRect(NSMakeRect(aPoint.x - 5, aPoint.y - 5, 10, 10));
    //NSLog(@"%s, rect: %@", _cmd, NSStringFromRect(rect));
    NSFrameRect(rect);
}

@end

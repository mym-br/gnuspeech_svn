/***************************************************************************
 *  Copyright 1991, 1992, 1993, 1994, 1995, 1996, 2001, 2002, 2004, 2005   *
 *    David R. Hill, Leonard Manzara, Craig Schock,                        *
 *    Steve Nygard, Gregory John Casamento                                 *
 *                                                                         *
 *  This program is free software: you can redistribute it and/or modify   *
 *  it under the terms of the GNU General Public License as published by   *
 *  the Free Software Foundation, either version 3 of the License, or      *
 *  (at your option) any later version.                                    *
 *                                                                         *
 *  This program is distributed in the hope that it will be useful,        *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of         *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *
 *  GNU General Public License for more details.                           *
 *                                                                         *
 *  You should have received a copy of the GNU General Public License      *
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.  *
 ***************************************************************************/

#import "MReleaseNotesController.h"
#import <Foundation/NSBundle.h>

#ifndef GNUSTEP
#import <WebKit/WebKit.h>
#endif

@implementation MReleaseNotesController

- (id)init;
{
    if ([super initWithWindowNibName:@"ReleaseNotes"] == nil)
        return nil;

    [self setWindowFrameAutosaveName:@"ReleaseNotes"];

    return self;
}

- (void)windowDidLoad;
{
    NSString *path;

    path = [[NSBundle mainBundle] pathForResource:@"ReleaseNotes" ofType:@"html"];
#ifndef GNUSTEP
    [[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
#endif
}

@end

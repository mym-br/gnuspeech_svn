/***************************************************************************
 *  Copyright 1991, 1992, 1993, 1994, 1995, 1996, 2001, 2002, 2004, 2005,  *
 *            2007                                                         *
 *    David R. Hill, Leonard Manzara, Craig Schock,                        *
 *    Steve Nygard                                                         *
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

#import <AppKit/NSControl.h>

#import <AppKit/NSNibDeclarations.h> // For IBAction, IBOutlet
#import <GnuSpeech/GnuSpeech.h> // For MMFRuleSymbols

@class NSMutableArray;
@class MonetList, MModel, MMPoint, MMSlope, MMTransition;
@class TransitionView, NSTextFieldCell;

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/


@protocol TransitionViewNotifications
- (void)transitionViewSelectionDidChange:(NSNotification *)aNotification;
@end

@protocol TransitionViewDelegate
- (BOOL)transitionView:(TransitionView *)aTransitionView shouldAddPoint:(MMPoint *)aPoint;
@end

extern NSString *TransitionViewSelectionDidChangeNotification;

// TODO (2004-03-22): Make this an NSControl subclass.
@interface TransitionView : NSControl
{
    MMFRuleSymbols _parameters;

    NSFont *timesFont;

    MMTransition *transition;

    NSMutableArray *samplePostures;
    NSMutableArray *displayPoints;
    NSMutableArray *displaySlopes;
    NSMutableArray *selectedPoints;

    NSPoint selectionPoint1;
    NSPoint selectionPoint2;

    MMSlope *editingSlope;
    NSTextFieldCell *textFieldCell;
    NSText *nonretained_fieldEditor;

    int zeroIndex;
    int sectionAmount;

    MModel *model;

    struct {
        unsigned int shouldDrawSelection:1;
        unsigned int shouldDrawSlopes:1;
    } flags;

    id nonretained_delegate;
}

- (id)initWithFrame:(NSRect)frameRect;
- (void)dealloc;

- (int)zeroIndex;
- (void)setZeroIndex:(int)newZeroIndex;

- (int)sectionAmount;
- (void)setSectionAmount:(int)newSectionAmount;

- (MModel *)model;
- (void)setModel:(MModel *)newModel;

- (void)_updateFromModel;
- (void)updateTransitionType;

- (double)ruleDuration;
- (void)setRuleDuration:(double)newValue;

- (double)beatLocation;
- (void)setBeatLocation:(double)newValue;

- (double)mark1;
- (void)setMark1:(double)newValue;

- (double)mark2;
- (void)setMark2:(double)newValue;

- (double)mark3;
- (void)setMark3:(double)newValue;

- (IBAction)takeRuleDurationFrom:(id)sender;
- (IBAction)takeBeatLocationFrom:(id)sender;
- (IBAction)takeMark1From:(id)sender;
- (IBAction)takeMark2From:(id)sender;
- (IBAction)takeMark3From:(id)sender;

- (BOOL)shouldDrawSelection;
- (void)setShouldDrawSelection:(BOOL)newFlag;

- (BOOL)shouldDrawSlopes;
- (void)setShouldDrawSlopes:(BOOL)newFlag;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

// Drawing
- (void)drawRect:(NSRect)rect;

- (void)clearView;
- (void)drawGrid;
- (void)drawEquations;
- (void)drawPhones;
- (void)drawTransition;
- (void)updateDisplayPoints;
- (void)highlightSelectedPoints;

// Event handling
- (BOOL)acceptsFirstResponder;
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;
- (void)mouseDown:(NSEvent *)mouseEvent;
- (void)mouseDragged:(NSEvent *)mouseEvent;
- (void)mouseUp:(NSEvent *)mouseEvent;
- (void)keyDown:(NSEvent *)keyEvent;

// View geometry
- (int)sectionHeight;
- (NSPoint)graphOrigin;
- (float)timeScale;
- (NSRect)rectFormedByPoint:(NSPoint)point1 andPoint:(NSPoint)point2;
- (float)slopeMarkerYPosition;
- (NSRect)slopeMarkerRect;

// Slopes
- (void)drawSlopes;
- (void)_setEditingSlope:(MMSlope *)newSlope;
- (void)editSlope:(MMSlope *)aSlope startTime:(float)startTime endTime:(float)endTime;
- (MMSlope *)getSlopeMarkerAtPoint:(NSPoint)aPoint startTime:(float *)startTime endTime:(float *)endTime;

// NSTextView delegate method, used for editing slopes
- (void)textDidEndEditing:(NSNotification *)notification;

// Selection
- (MMPoint *)selectedPoint;
- (void)selectGraphPointsBetweenPoint:(NSPoint)point1 andPoint:(NSPoint)point2;
- (void)_selectionDidChange;

// Actions
- (IBAction)deleteBackward:(id)sender;
- (IBAction)groupInSlopeRatio:(id)sender;

// Publicly used API
- (MMTransition *)transition;
- (void)setTransition:(MMTransition *)newTransition;

@end

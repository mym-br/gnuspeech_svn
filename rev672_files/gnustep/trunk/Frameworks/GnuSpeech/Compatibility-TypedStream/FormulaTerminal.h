/***************************************************************************
 *  Copyright 1991, 1992, 1993, 1994, 1995, 1996, 2001, 2002, 2007         *
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

#import "MMOldFormulaNode.h"

@class MMSymbol;

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

#define RULEDURATION    (-2)
#define BEAT		(-3)
#define MARK1		(-4)
#define MARK2		(-5)
#define MARK3		(-6)
#define TEMPO0		(-7)
#define TEMPO1		(-8)
#define TEMPO2		(-9)
#define TEMPO3		(-10)


@interface FormulaTerminal : MMOldFormulaNode
{
    MMSymbol *symbol;
    double value;
    int whichPhone; // TODO (2004-03-10): Rename this
}

- (id)init;
- (void)dealloc;

- (MMSymbol *)symbol;
- (void)setSymbol:(MMSymbol *)newSymbol;

- (double)value;
- (void)setValue:(double)newValue;

- (int)whichPhone;
- (void)setWhichPhone:(int)newValue;

// Methods common to "FormulaNode" -- for both FormulaExpression, FormulaTerminal
- (void)expressionString:(NSMutableString *)resultString;

// Archiving
- (id)initWithCoder:(NSCoder *)aDecoder;

@end

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
//  MXMLParser.h
//  GnuSpeech
//
//  Created by Steve Nygard in 2004
//
//  Version: 0.9.1
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/NSXMLParser.h>

@class NSMutableArray, NSData;

@protocol MXMLParserGenericInit
+ (id)objectWithXMLAttributes:(NSDictionary *)attributes context:(id)context;
- (id)initWithXMLAttributes:(NSDictionary *)attributes context:(id)context;
@end

@interface MXMLParser : NSXMLParser
{
    NSMutableArray *delegateStack;
    id context;
}

- (id)initWithData:(NSData *)data;
- (void)dealloc;

- (id)context;
- (void)setContext:(id)newContext;

- (void)pushDelegate:(id)newDelegate;
- (void)popDelegate;

- (void)skipTree;

@end
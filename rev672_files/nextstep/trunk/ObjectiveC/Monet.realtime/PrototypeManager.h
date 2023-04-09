
#import <objc/Object.h>
#import <objc/List.h>
#import <appkit/NXBrowser.h>
#import <appkit/NXBrowserCell.h>
#import <appkit/Form.h>
#import "NamedList.h"
#import <appkit/Font.h>

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

@interface PrototypeManager:Object
{
	id	controller;

	List *protoEquations;
	List *protoTemplates;
	List *protoSpecial;

	id	delegateResponder;

}

- init;
- appDidInit:sender;

- findEquationList: (const char *) list named: (const char *) name;
- findList: (int *) listIndex andIndex: (int *) index ofEquation: equation;
- findEquation: (int) listIndex andIndex: (int) index;

- findTransitionList: (const char *) list named: (const char *) name;
- findList: (int *) listIndex andIndex: (int *) index ofTransition: transition;
- findTransition: (int) listIndex andIndex: (int) index;

- findSpecialList: (const char *) list named: (const char *) name;
- findList: (int *) listIndex andIndex: (int *) index ofSpecial: transition;
- findSpecial: (int) listIndex andIndex: (int) index;

- equationList;
- transitionList;
- specialList;

- (BOOL) isEquationUsed: anEquation;

- readPrototypesFrom:(NXTypedStream *)stream;
- writePrototypesTo:(NXTypedStream *)stream;

@end

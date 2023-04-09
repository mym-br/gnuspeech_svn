/*
 *    Filename:	KeyboardText.m 
 *    Created :	Thu Feb  6 21:44:20 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *
 * LastEditDate "Sat Jun  6 14:03:33 1992"
 *
 * $Log: not supported by cvs2svn $
# Revision 2.1  1992/06/10  14:02:11  vince
# KeyboardTextCell is no longer in use.
# a Custom TextObject (MyText) with new delegation
# methods is being used to handle the filter
# functions.
# The bug involving the Charfilter function not being
# properly installed has been fixed, by reinstalling
# it each time there is a keyDown or a mouseDown event.
# This Object will now also shift the keyboard if the
# shift key is pressed, as long as NX_SHIFTMASK has been
# added to the windows event mask
#
# Revision 2.0  1992/04/08  03:43:23  vince
# Initial-Release
#
 *
 */


/* Generated by Interface Builder */
#import "KeyboardText.h"
#import <appkit/TextField.h>
#import <appkit/NXCType.h>
#import "KeyboardController.h"
#import "MyText.h"
#import "PrEditorApp.h"

@implementation KeyboardText

/* Default charFilter function is NXFieldFilter() */
#define UPKEY       0xAD
#define DOWNKEY     0xAF
#define LEFTKEY     0xAC
#define RIGHTKEY    0xAE
#define DOUBLEQUOTE 0x22
#define QUOTE       0x27
#define PERIOD      0x2e

unsigned short keyboardCharFilter(unsigned short charCode, int flags, unsigned short charSet)
{
    if (flags & NX_COMMANDMASK)
	return NXFieldFilter(charCode,flags,charSet); /* Return whatever the default is */

    switch (charCode) {
        case UPKEY        :
        case DOWNKEY      :
        case LEFTKEY      :
        case RIGHTKEY     :
        case NX_BTAB      :
        case NX_TAB       :
        case NX_DELETE    :
        case NX_BACKSPACE :
        case NX_CR        :     
             return NXFieldFilter(charCode,flags,charSet); /* Return whatever the default is */
             break;
	 }
    
    if ((charCode == QUOTE) || (charCode == DOUBLEQUOTE) || (charCode == PERIOD)){
        return charCode;
    }
    if (NXIsAlpha(charCode)){ /* Only AlphaNumeric keys and the ' and " keys are allowed */ 
        return charCode;
    }else{
        return NX_ILLEGAL; /* if the value is illegal */
    }
}

- insertKey:(const char)character
{

    id textObj;
    char string[2];

    string[0] = character;
    string[1] = '\000';

    textObj = [[NXApp mainWindow] getFieldEditor:YES for:self];
    [textObj replaceSel:string length:1];
    [textObj scrollSelToVisible];
    return self;
}

- delete
{
    id textObj;
    char *string = NULL;

    if ([textField stringValue]){
        textObj = [[NXApp mainWindow] getFieldEditor:YES for:textField];
        [textObj replaceSel:string length:0];
        [textObj scrollSelToVisible];
    }
    return self;
}

- textDidGetKey:textObject charCode:(unsigned short int) charCode
{
    [keyboard pressKey:charCode];
    return self;
}

- textFlagsDidChange:textObject flags:(int) theflags keyCode:(unsigned int)keyCode
{
    if (theflags & NX_ALPHASHIFTMASK){
	[keyboard shiftDown:self];
	return self;
    }
    if ((keyCode == 82) || (keyCode == 87))
	[keyboard toggleShift:self];
    return self;
}

- (BOOL)textWillChange:textObject
{
    if ([textObject charFilter] != (NXCharFilterFunc)keyboardCharFilter){
	oldCharFilter = [textObject charFilter];
	[textObject setCharFilter: (NXCharFilterFunc)keyboardCharFilter ];
    }
    [keyboard enableKeyboard];
    return NO;
}

- textDidEnd:textObject endChar:(unsigned short)whyEnd
{
    [keyboard disableKeyboard];
    return self;
}

- textDidMouseDown:textObject
{
    if ([textObject charFilter] != (NXCharFilterFunc)keyboardCharFilter){
	oldCharFilter = [textObject charFilter];
	[textObject setCharFilter: (NXCharFilterFunc)keyboardCharFilter ];
    }
    [keyboard enableKeyboard];
    return self;
}

@end
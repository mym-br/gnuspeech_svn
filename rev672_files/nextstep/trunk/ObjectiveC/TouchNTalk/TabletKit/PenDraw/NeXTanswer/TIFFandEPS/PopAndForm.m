/* PopAndForm.m
 *  Purpose: A small Object that controls a Popup connected to a Form
 *
 *  You may freely copy, distribute, and reuse the code in this example.
 *  NeXT disclaims any warranty of any kind, expressed or  implied, as to its
 *  fitness for any particular use.
 *
 */
#import "PopAndForm.h"

@implementation PopAndForm : Object

- newValue:sender
{
    char *enteredValue = (char *)[formcell stringValue];
    if  ([[popup target] indexOfItem:enteredValue] == -1)
	[[popup target] addItem:enteredValue];
    [popup setTitle:enteredValue];
    [formcell setEnabled:NO];		
    return self;
}

- enableForm:sender
{
    [formcell setEnabled:YES];
    [formcell selectTextAt:0];
    return self;
}


@end

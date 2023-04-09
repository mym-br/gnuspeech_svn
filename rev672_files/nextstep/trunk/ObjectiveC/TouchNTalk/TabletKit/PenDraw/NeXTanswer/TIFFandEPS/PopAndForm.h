/* PopAndForm.h
 *  Purpose: A small Object that controls a Popup connected to a Form
 *
 *  You may freely copy, distribute, and reuse the code in this example.
 *  NeXT disclaims any warranty of any kind, expressed or  implied, as to its
 *  fitness for any particular use.
 *
 */

#import <appkit/appkit.h>

@interface PopAndForm : Object
{
    id	popup;
    id	formcell;
}

- newValue:sender;
- enableForm:sender;

@end

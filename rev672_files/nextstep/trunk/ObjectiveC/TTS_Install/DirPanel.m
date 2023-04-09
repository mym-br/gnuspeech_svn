/*
 *    Filename:	DirPanel.m 
 *    Created :	Mon Jun  1 18:52:17 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *    LastEditDate was "Mon Jun  1 19:51:50 1992"
 *
 *    $Id: DirPanel.m,v 1.1 2002-03-21 16:49:48 rao Exp $
 *
 *    $Log: not supported by cvs2svn $
# Revision 1.0  1992/06/09  05:22:41  vince
# Initial revision
#
 */


#import "DirPanel.h"
#import <appkit/Button.h>
#import <appkit/OpenPanel.h>

@implementation SavePanel (DirPanel)

- sendEvent:(NXEvent *)e
{
    /* When the user types, SavePanel is going to try to disable
     * the okButton.  Make sure that doesn't happen.  I fix
     * that here since I can override this method (while I
     * can't override what's defined in SavePanel). 
     */

    if( e->type==NX_KEYDOWN){
	[self disableFlushWindow];
	[super sendEvent:e];
	[okButton setEnabled:YES];
	[self reenableFlushWindow];
	[self flushWindowIfNeeded];
	NXPing();
    }else
	[super sendEvent:e];
  return self;
}
/* Global flag indicating that this is a return from okButton
 * press, not a real cancel. 
 */
static BOOL notCancel=NO;

-(int)dirPanelRunModal
{
    int ret;
    id okaybut = okButton;
    /* Store the okButton target/action. */
    id okt=[okButton target];
    SEL oka=[okButton action];
    /* Enable the button, and redirect it at realOk:. */
    [okButton setEnabled:YES];
    [okButton setTarget:self];
    [okButton setAction:@selector( realOk:)];
    okButton = nil;
    /* Make sure we don't misfire on this. */
    notCancel=NO;
	/* OpenPanel doesn't seem to pay attention to setRequiredFileType,
	   so I have to do things differently for it.  Actually, I
	   would tend to recommend just using SavePanels, but that's
	   just me.
	   
	   The idea, here, is that not many people are going to
	   have files named *.abcdefghijklmnop, so the SavePanel
	   can't find any, so it can only show directories, that
	   you can move around in and look for stuff.  Since we're
	   chosing directories, this is the right behaviour. */
    if( [self isMemberOf:[SavePanel class]]){
	[self setRequiredFileType:"abcdefghijklmnop"];
	ret=[self runModal];
    }else{
	const char *types[]={ "abcdefghijklmnop", NULL};
      	/* I cast to OpenPanel to remove the warning on compile. */
	ret=[(OpenPanel *)self runModalForTypes:types];
    }
    /* If SavePanel thinks we canceled, check to see if _we_
       think so, too. */
    if( !ret && notCancel){
	notCancel=NO;
	ret=1;
    }
    	/* Restore the okButton's target/action. */
    okButton = okaybut;
    [okButton setTarget:okt];
    [okButton setAction:oka];
    return ret;
}

- realOk:sender
{
	/* Mark this as a fake Cancel. */
    notCancel=YES;
  	/* Use the ok: method to pull out any data from the form. */
    [self ok:sender];
  	/* Use cancel: to get out of the modal loop. */
    return [self cancel:sender];
}
@end

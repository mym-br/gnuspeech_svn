/*
 *    Filename:	PrEditorApp.m 
 *    Created :	Tue Jan 14 21:47:15 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *
 * LastEditDate "Wed Jun  3 23:20:50 1992"
 *
 * $Log: not supported by cvs2svn $
# Revision 2.2  92/08/16  10:59:30  len
# Fixed "Canel" and "Anyways"
# 
# Revision 2.1  1992/06/10  14:22:17  vince
# Methods to return:
# - wordList -> Return a pointer to the wordList
# (aka PrDictViewer object)
#
# - mainDocument -> Return a pointer to PrEditorDocument Object
# currently being edited (mainWindow)
#
# Revision 2.0  1992/04/08  03:43:23  vince
# Initial-Release
#
 *
 */


/* Generated by Interface Builder */

#import "PrEditorApp.h"

#import <appkit/Window.h>
#import <appkit/Panel.h>
#import <appkit/OpenPanel.h>
#import <appkit/Menu.h>
#import <appkit/MenuCell.h>
#import <appkit/Matrix.h>
#import <objc/List.h>
#import <defaults/defaults.h>

#import <stdlib.h>
#import <stdio.h>
#import <objc/zone.h>
#import <mach/mach.h>
#import <strings.h>

#import "PrEditorDocument.h"
#import "MyText.h"

@implementation PrEditorApp

/* Private C functions used to implement methods in this class. */

static void initMenu(id menu)
/*
 * Sets the updateAction for every menu item which sends to the
 * First Responder (i.e. their target is nil).  When autoupdate is on,
 * every event will be followed by an update of each of the menu items
 * which is visible.  This keep all unavailable menu items dimmed out
 * so that the user knows what options are available at any given time.
 * Returns the activate menu if is found in this menu.
 */ 
{
    int count;
    id matrix, cell;
    id matrixTarget, cellTarget;

    matrix = [menu itemList];
    matrixTarget = [matrix target];

    count = [matrix cellCount];
    while (count--) {
        cell = [matrix cellAt:count :0];
        cellTarget = [cell target];
        if (!matrixTarget && !cellTarget) {
            [cell setUpdateAction:@selector(menuItemUpdate:) forMenu:menu];
        } else if ([cell hasSubmenu]) {
            initMenu(cellTarget);
        }
    }
}

static id documentInWindow(id window)
/*
 * Checks to see if the passed window's delegate is a PrEditorDocument.
 * If it is, it returns that document, otherwise it returns nil.
 */
{
    id document = [window delegate];
    return [document isKindOf:[PrEditorDocument class]] ? document : nil;
}

static id findDocument(const char *name)
/*
 * Searches the window list looking for a PrEditorDocument with the specified name.
 * Returns the window containing the document if found.
 * If name == NULL then the first document found is returned.
 */
{
    int count;
    static id document;
    static id window;
    static id windowList;

    windowList = [NXApp windowList];
    count = [windowList count];
    while (count--) {
        window = [windowList objectAt:count];
        document = documentInWindow(window);
        if (document && (!name || !strcmp([document filename], name))) {
            return window;
        }
    }
    return nil;
}

+ new
{
    self = [super new];
    [MyText poseAs:[Text class]];
    [self setDelegate:self];
    return self;
}

- free
{
    [self setDelegate:nil];
    [prefMgrObject free];
    return [super free];
}

- appDidInit:sender
{

/*
 * Initialize the menus.
 */
    initMenu([NXApp mainMenu]);
    [self setAutoupdate:YES];
/* 
 *
 * Check the default values for NXOpen== NULL NXAutoLaunch== "NO" if they either one of them
 * Has a value ie NXGetDefault doesn't return 0 then call new document
 * 
 * If there are no open documents, then open a blank one
 *
 *   if (!NXGetDefaultValue([NXApp appName],"NXOpen"))
 *    	&& strcmp(NXGetDefaultValue([NXApp appName],"NXAutoLaunch"),"NO")){
 *
 */
    if (!NXGetDefaultValue([NXApp appName],"NXOpen")){
	[self newDocument:sender];
    }
    return self;
}

- newDocument:sender
{
    [[PrEditorDocument allocFromZone:[self newZone]] initFromFile:NULL];
    return self;
}

- open:sender
{
    char                     completePath[1024];
    const  char             *directory;
    const  char *const      *files;
    static const char *const dictType[3] = {"preditor","preditor+", NULL};
    id                       openpanel   = [[OpenPanel new] allowMultipleFiles:YES];

    if ([openpanel runModalForTypes:dictType]) {
        files = [openpanel filenames];
        directory = [openpanel directory];
        while (files && *files) {
	    sprintf(completePath,"%s/%s",directory,*files);
		[[PrEditorDocument allocFromZone:[self newZone]] initFromFile:completePath];
		files++;
        }
    }

    return self;
}

- (int)openFile:(const char *)fullPath ok:(int *)flag
{
    if ([[PrEditorDocument allocFromZone:[self newZone]] initFromFile:fullPath]){
	*flag = YES;
    }else{
	*flag = NO;
    }
    return 0;
}

- (BOOL)appAcceptsAnotherFile:sender
{
    return YES;
}

- saveAll:sender
{
    int count;
    id window;

    count = [windowList count];
    while (count--) {
        window = documentInWindow([windowList objectAt:count]);
	if (window)
	    if (![window save:self])
		break;
    }

    return self;
}


- appWillTerminate:sender
{
    int count;
    id window;
    int dirtycount = 0;

    count = [windowList count];
    while (count--) {
        window = [windowList objectAt:count];
        if ([documentInWindow(window) isDirty]){
	    dirtycount++;
	}else{
	    [documentInWindow(window) free];
	}
    }

    if (dirtycount) {
	switch (NXRunAlertPanel("Quit","There are unsaved Documents","Review Unsaved","Quit Anyway","Cancel")){

	case NX_ALERTDEFAULT:  /* Save file */
	    count = [windowList count];
	    while (count--) {
		window = [windowList objectAt:count];
		if ([documentInWindow(window) isDirty]){
		    switch (NXRunAlertPanel("Review",
					    "Save changed to %s",
					    "Save","Don't Save","Cancel",[documentInWindow(window) filename])){

		    case NX_ALERTDEFAULT:   /* Save file */
			if (![documentInWindow(window) save:sender]){
			    [documentInWindow(window) free];
			    return nil;
			}
			break;
		    case NX_ALERTALTERNATE: /* Don't Save file */
			[documentInWindow(window) free];
			break;
		    case NX_ALERTOTHER:     /* Cancel Quit Application */
			return nil;
		    case NX_ALERTERROR:
			break;
		    }
		}
	    }
	    break;
	case NX_ALERTALTERNATE: /* Quit Anyways */
	    return self;
	    break;
	case NX_ALERTOTHER:     /* Cancel Quit Application */
	    return nil;
	    break;
	case NX_ALERTERROR:
	    break;
	}
    }
    return self;
}     

- (char *) untitled
{
    static int  count = 1;
    static char buffer[1024];

    sprintf(buffer,"%s-%d","Untitled",count++);
    return (char *)buffer;
}



/* WordList methods */

- wordList
{
  return wordList;
}

- mainDocument;
{
  return documentInWindow([self mainWindow]);
}

/* Automatic update methods */

- (BOOL)menuItemUpdate:menuCell
/*
 * Method called by all menu items which send their actions to the
 * First Responder.  First, if the object which would respond were the
 * action sent down the responder chain also responds to the message
 * validateCommand:, then it is sent validateCommand: to determine
 * whether that command is valid now, otherwise, if there is a responder
 * to the message, then it is assumed that the item is valid.
 * The method returns YES if the cell has changed its appearance (so that
 * the caller (a Menu) knows to redraw it).
 */
{
    SEL action;
    id responder, target;
    BOOL enable;

    target = [menuCell target];
    enable = [menuCell isEnabled];

    if (!target) {
        action = [menuCell action];
        responder = [self calcTargetForAction:action];
        if ([responder respondsTo:@selector(validateCommand:)]) {
            enable = [responder validateCommand:menuCell];
        } else {
            enable = responder ? YES : NO;
        }
    }

    if ([menuCell isEnabled] != enable) {
        [menuCell setEnabled:enable];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)validateCommand:menuCell
{
    SEL action = [menuCell action];

    if (action == @selector(saveAll:)) {
        return (findDocument(NULL) ? YES : NO);
    }

    return YES;
}


- inspectorPanel
{
    return inspectorObject;
}


/* Reusing Zones All objects in the application call these two methods
 * when a new Zone is required and is freed back to the system
 */
- (NXZone *)newZone
{
    NXZone *zone;

    if (!zoneList || ![zoneList count]) {
        zone = NXCreateZone(vm_page_size, vm_page_size, YES);
	NXNameZone(zone,"Zone Created By PrEditorApp");
	return zone;
    } else {
        return (NXZone *)[zoneList removeLastObject];
    }
}

- (void)reuseZone:(NXZone *)aZone
{
    if (!zoneList) {
	zoneList = [List new];
    }
    [zoneList addObject:(id)aZone];
}


@end
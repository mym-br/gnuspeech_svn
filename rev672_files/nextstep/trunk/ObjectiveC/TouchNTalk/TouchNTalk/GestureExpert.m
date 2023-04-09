/*
 *    Filename:	GestureExpert.m 
 *    Created :	Wed Sep  1 13:03:35 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Tue Jul 26 11:02:24 1994"
 *
 * The name "Gesture Expert" is a bit misleading although this was the original intent. The current
 * system has the tablet and stylus DRIVING the graphical display. Thus we are really not performing
 * any gesture recognition of any kind but mapping stylus movements to graphical controls on the
 * display which inturn invoke the required functionality as if the user had physically manipulated
 * the graphical controls with the mouse.
 *
 * Note: Because of the inadequate single/double click model outlined in the original paper we have
 * mapped the barrel button to what would be a double click. The double click cannot adequately be
 * used in the current model because a system wide response time delay in the realization of single
 * clicks would then result. We need a more unified model that allows processing of single clicks
 * even when they subsequently become double clicks -- as in the NEXTSTEP single/double/triple click
 * model. This would require a re-evaluation of which grooves perform which functions.
 *
 * $Id: GestureExpert.m,v 1.9 1994/07/26 20:11:02 dale Exp $
 *
 * $Log: GestureExpert.m,v $
 * Revision 1.9  1994/07/26  20:11:02  dale
 * *** empty log message ***
 *
 * Revision 1.8  1994/06/29  22:39:07  dale
 * Added column cursor locator support.
 *
 * Revision 1.7  1994/06/15  19:32:35  dale
 * *** empty log message ***
 *
 * Revision 1.6  1994/06/10  20:18:28  dale
 * *** empty log message ***
 *
 * Revision 1.5  1994/06/03  08:03:28  dale
 * Added code to allow barrel button click to act as double stylus click.
 *
 * Revision 1.4  1994/06/01  19:13:28  dale
 * *** empty log message ***
 *
 * Revision 1.3  1994/05/28  21:24:37  dale
 * Added backward and forward page turns.
 *
 * Revision 1.2  1993/10/10  20:58:14  dale
 * Added soft function and left holo "gesture" recognition.
 *
 * Revision 1.1  1993/09/04  17:49:02  dale
 * Initial revision
 *
 */

#import "Publisher.tproj.h"
#import "TouchNTalk.h"
#import "TNTControl.h"
#import "TabletSurface.h"
#import "TabletRegion.h"
#import "GestureExpert.h"

/* Page turns for barrel depression in page next or page previous area. */
#define TNT_BARREL_PAGE_TURNS  10

@implementation GestureExpert


/* INITIALIZING AND FREEING *************************************************************************/


- init
{
    [super init];
    ttServer = [NXApp delegate];
    tabletSurface = [ttServer tabletSurface];    
    return self;
}

- free
{
    return [super free];
}


/* DISPATCH EVENT ***********************************************************************************/


- pandemonium:(NXEvent *)theEvent
{
    static id ttControl;

    // DEBUG
    // [self showContents:theEvent];

    ttControl = [[NXApp delegate] tntControl];
    if ([ttControl operationMode] == TNT_LOCATE && 
	[(id)theEvent->TNT_REGION tag] != TNT_TACTILEAREA && 
	[(id)theEvent->TNT_REGION tag] != TNT_DEADZONE && 
	theEvent->TNT_GROOVE != TNT_CURSOR_LOCATOR) {

	// cancel cursor location since not in tactile area, deadzone, or cursor locator groove
	[ttControl setOperationMode:TNT_NORMAL];
    }

    // check the most likely to least likely
    switch ([(id)theEvent->TNT_REGION tag]) {
      case TNT_TACTILEAREA:
	// we can incorporate velocity later (slow means spell etc.)
	[self tactileAreaGesture:theEvent];
	break;

      case TNT_LEFTHOLO:
	[self leftHoloGesture:theEvent];
	break;

      case TNT_SOFTAREA:
	[self softFunctionGesture:theEvent];
	break;

      case TNT_TOPHOLO:
	if (theEvent->TNT_GROOVE == TNT_PAGE_LOCATOR) {
	    [self pageLocatorGesture:theEvent];
	} else if (theEvent->TNT_GROOVE == TNT_BOOKMARK_HOLO) {
	    [self bookmarkLocatorGesture:theEvent];
	} else if (theEvent->TNT_GROOVE == TNT_HORIZ_PAGESCROLL) {
	    [self horizontalScrollGesture:theEvent];
	}
	break;

      case TNT_RIGHTAREA:
	if (theEvent->TNT_GROOVE == TNT_CURSOR_LOCATOR) {
	    [self cursorLocatorGesture:theEvent];
	} else if (theEvent->TNT_GROOVE == TNT_VERT_PAGESCROLL) {
	    [self verticalScrollGesture:theEvent];
	}
	break;

      case TNT_NEXTAREA:
	[self pageNextGesture:theEvent];
	break;

      case TNT_PREVAREA:
	[self pagePrevGesture:theEvent];
	break;

      case TNT_SILAREA:
	// we can incorporate velocity later (slow means spell etc.)
	[self silAreaGesture:theEvent];
	break;

      default:
	break;
    }
    return self;
}


/* PRIVATE EXPERTS **********************************************************************************/


- softFunctionGesture:(NXEvent *)theEvent
{
    NXRect boundingRect = [(id)theEvent->TNT_REGION boundingRect];
    float fraction =  ABS(theEvent->location.y - boundingRect.origin.y) / boundingRect.size.height;

    switch (theEvent->TNT_SUBTYPE) {
      case TNT_STYLUSMOVED:
        [ttServer softFunctionDragTo:fraction];
	break;
      case TNT_STYLUSTIPDOWN:
	if (theEvent->TNT_CLICKS == 1) {
	    [ttServer softFunctionSingleClickAt:fraction];
	}
	break;
      case TNT_STYLUSDOWN:
	[ttServer softFunctionDownAt:fraction];
	break;
      case TNT_STYLUSUP:
	[ttServer softFunctionUpAt:fraction];
	break;
      default:
	break;
    }
    return self;
}

- leftHoloGesture:(NXEvent *)theEvent
{
    NXRect boundingRect = [(id)theEvent->TNT_REGION boundingRect];
    float fraction =  ABS(theEvent->location.y - boundingRect.origin.y) / boundingRect.size.height;

    switch (theEvent->TNT_SUBTYPE) {
      case TNT_STYLUSMOVED:
        [ttServer leftHolo:theEvent->TNT_GROOVE dragTo:fraction];
	break;
      case TNT_STYLUSTIPDOWN:
	if (theEvent->TNT_CLICKS == 1) {
	    [ttServer leftHolo:theEvent->TNT_GROOVE singleClickAt:fraction];
	} else if (theEvent->TNT_CLICKS == 2) {
	    [ttServer leftHolo:theEvent->TNT_GROOVE doubleClickAt:fraction];
	}
	break;
      case TNT_STYLUSBARRELDOWN:
	if (theEvent->TNT_CLICKS == 1) {
	    [ttServer leftHolo:theEvent->TNT_GROOVE doubleClickAt:fraction];
	}	
	break;
      case TNT_STYLUSDOWN:
	[ttServer leftHolo:theEvent->TNT_GROOVE downAt:fraction];
	break;
      case TNT_STYLUSUP:
	[ttServer leftHolo:theEvent->TNT_GROOVE upAt:fraction];
	break;
      default:
	break;
    }
    return self;
}

- pageLocatorGesture:(NXEvent *)theEvent
{
    NXRect boundingRect = [(id)theEvent->TNT_REGION boundingRect];
    float fraction =  ABS(theEvent->location.x - boundingRect.origin.x) / boundingRect.size.width;

    switch (theEvent->TNT_SUBTYPE) {
      case TNT_STYLUSMOVED:
        [ttServer pageLocatorDragTo:fraction];
	break;
      case TNT_STYLUSTIPDOWN:
	if (theEvent->TNT_CLICKS == 1) {
	    [ttServer pageLocatorSingleClickAt:fraction];
	} else if (theEvent->TNT_CLICKS == 2) {
	    [ttServer pageLocatorDoubleClickAt:fraction];
	}
	break;
      case TNT_STYLUSBARRELDOWN:
	if (theEvent->TNT_CLICKS == 1) {
	    [ttServer pageLocatorDoubleClickAt:fraction];
	}
	break;
      case TNT_STYLUSDOWN:
	[ttServer pageLocatorDownAt:fraction];
	break;
      case TNT_STYLUSUP:
	[ttServer pageLocatorUpAt:fraction];
	break;
      default:
	break;
    }
    return self;
}

- bookmarkLocatorGesture:(NXEvent *)theEvent
{
    NXRect boundingRect = [(id)theEvent->TNT_REGION boundingRect];
    float fraction =  ABS(theEvent->location.x - boundingRect.origin.x) / boundingRect.size.width;

    switch (theEvent->TNT_SUBTYPE) {
      case TNT_STYLUSMOVED:
        [ttServer bookmarkLocatorDragTo:fraction];
	break;
      case TNT_STYLUSTIPDOWN:
	if (theEvent->TNT_CLICKS == 1) {
	    [ttServer bookmarkLocatorSingleClickAt:fraction];
	} else if (theEvent->TNT_CLICKS == 2) {
	    [ttServer bookmarkLocatorDoubleClickAt:fraction];
	}
	break;
      case TNT_STYLUSBARRELDOWN:
	if (theEvent->TNT_CLICKS == 1) {
	    [ttServer bookmarkLocatorDoubleClickAt:fraction];
	}
	break;
      case TNT_STYLUSDOWN:
	[ttServer bookmarkLocatorDownAt:fraction];
	break;
      case TNT_STYLUSUP:
	[ttServer bookmarkLocatorUpAt:fraction];
	break;
      default:
	break;
    }
    return self;
}

- horizontalScrollGesture:(NXEvent *)theEvent
{
    NXRect boundingRect = [(id)theEvent->TNT_REGION boundingRect];
    float fraction =  ABS(theEvent->location.x - boundingRect.origin.x) / boundingRect.size.width;

    switch (theEvent->TNT_SUBTYPE) {
      case TNT_STYLUSMOVED:
        [ttServer horizPageScrollDragTo:fraction];
	break;
      case TNT_STYLUSTIPDOWN:
	if (theEvent->TNT_CLICKS == 1) {
	    [ttServer horizPageScrollSingleClickAt:fraction];
	}
	break;
      case TNT_STYLUSDOWN:
	[ttServer horizPageScrollDownAt:fraction];
	break;
      case TNT_STYLUSUP:
	[ttServer horizPageScrollUpAt:fraction];
	break;
      default:
	break;
    }
    return self;
}

- cursorLocatorGesture:(NXEvent *)theEvent
{
    NXRect boundingRect = [(id)theEvent->TNT_REGION boundingRect];
    float fraction =  ABS(theEvent->location.y - boundingRect.origin.y) / boundingRect.size.height;

    switch (theEvent->TNT_SUBTYPE) {
      case TNT_STYLUSMOVED:
        [ttServer cursorLocatorDragTo:fraction];
	break;
      case TNT_STYLUSTIPDOWN:
	if (theEvent->TNT_CLICKS == 1) {
	    [ttServer cursorLocatorSingleClickAt:fraction];
	} else if (theEvent->TNT_CLICKS == 2) {
	    [ttServer cursorLocatorDoubleClickAt:fraction];
	}
	break;
      case TNT_STYLUSBARRELDOWN:
	if (theEvent->TNT_CLICKS == 1) {
	    [ttServer cursorLocatorDoubleClickAt:fraction];
	}
      case TNT_STYLUSDOWN:
	[ttServer cursorLocatorDownAt:fraction];
	break;
      case TNT_STYLUSUP:
	[ttServer cursorLocatorUpAt:fraction];
	break;
      default:
	break;
    }
    return self;
}

- verticalScrollGesture:(NXEvent *)theEvent
{
    NXRect boundingRect = [(id)theEvent->TNT_REGION boundingRect];
    float fraction =  ABS(theEvent->location.y - boundingRect.origin.y) / boundingRect.size.height;

    switch (theEvent->TNT_SUBTYPE) {
      case TNT_STYLUSMOVED:
        [ttServer vertPageScrollDragTo:fraction];
	break;
      case TNT_STYLUSTIPDOWN:
	if (theEvent->TNT_CLICKS == 1) {
	    [ttServer vertPageScrollSingleClickAt:fraction];
	}
	break;
      case TNT_STYLUSDOWN:
	[ttServer vertPageScrollDownAt:fraction];
	break;
      case TNT_STYLUSUP:
	[ttServer vertPageScrollUpAt:fraction];
	break;
      default:
	break;
    }
    return self;
}

- pageNextGesture:(NXEvent *)theEvent
{
    switch (theEvent->TNT_SUBTYPE) {
      case TNT_STYLUSTIPDOWN:
	[ttServer pageNextClicks:theEvent->TNT_CLICKS];
	break;
      case TNT_STYLUSBARRELDOWN:
	if (theEvent->TNT_CLICKS == 1) {
	    [ttServer pageNextClicks:TNT_BARREL_PAGE_TURNS];
	}
	break;
      default:
	break;
    }
    return self;
}

- pagePrevGesture:(NXEvent *)theEvent
{
    switch (theEvent->TNT_SUBTYPE) {
      case TNT_STYLUSTIPDOWN:
	[ttServer pagePreviousClicks:theEvent->TNT_CLICKS];
	break;
      case TNT_STYLUSBARRELDOWN:
	if (theEvent->TNT_CLICKS == 1) {
	    [ttServer pagePreviousClicks:TNT_BARREL_PAGE_TURNS];
	}
	break;
      default:
	break;
    }
    return self;
}

- tactileAreaGesture:(NXEvent *)theEvent
{
    NXRect boundingRect = [(id)theEvent->TNT_REGION boundingRect];
    float fraction =  ABS(theEvent->location.x - boundingRect.origin.x) / boundingRect.size.width;

    switch (theEvent->TNT_SUBTYPE) {
      case TNT_STYLUSMOVED:
        [ttServer tactileGroove:theEvent->TNT_GROOVE dragTo:fraction];
	break;
      case TNT_STYLUSTIPDOWN:
	if (theEvent->TNT_CLICKS == 1) {
	    [ttServer tactileGroove:theEvent->TNT_GROOVE singleClickAt:fraction];
	} else if (theEvent->TNT_CLICKS == 2) {
	    [ttServer tactileGroove:theEvent->TNT_GROOVE doubleClickAt:fraction];
	}
	break;
      case TNT_STYLUSBARRELDOWN:
	if (theEvent->TNT_CLICKS == 1) {
	    [ttServer tactileGroove:theEvent->TNT_GROOVE doubleClickAt:fraction];
	}
	break;
      case TNT_STYLUSDOWN:
	[ttServer tactileGroove:theEvent->TNT_GROOVE downAt:fraction];
	break;
      case TNT_STYLUSUP:
	[ttServer tactileGroove:theEvent->TNT_GROOVE upAt:fraction];
	break;
      default:
	break;
    }
    return self;
}

- silAreaGesture:(NXEvent *)theEvent
{
    NXRect boundingRect = [(id)theEvent->TNT_REGION boundingRect];
    float fraction =  ABS(theEvent->location.x - boundingRect.origin.x) / boundingRect.size.width;

    switch (theEvent->TNT_SUBTYPE) {
      case TNT_STYLUSMOVED:
        [ttServer silDragTo:fraction];
	break;
      case TNT_STYLUSTIPDOWN:
	if (theEvent->TNT_CLICKS == 1) {
	    [ttServer silSingleClickAt:fraction];
	} else if (theEvent->TNT_CLICKS == 2) {
	    [ttServer silDoubleClickAt:fraction];
	}
	break;
      case TNT_STYLUSBARRELDOWN:
	if (theEvent->TNT_CLICKS == 1) {
	    [ttServer silDoubleClickAt:fraction];
	}
	break;
      case TNT_STYLUSDOWN:
	[ttServer silDownAt:fraction];
	break;
      case TNT_STYLUSUP:
	[ttServer silUpAt:fraction];
	break;
      default:
	break;
    }
    return self;
}


/* DEBUGGING ****************************************************************************************/


- showContents:(NXEvent *)theEvent
{
    printf("\nEvent type: %d", theEvent->TNT_SUBTYPE);
    printf("\nRegion: %d ", [(id)theEvent->TNT_REGION tag]);
    printf("Groove: %d ", theEvent->TNT_GROOVE);
    printf("Partition: %d\n", theEvent->TNT_PARTITION);
    return self;
}

@end

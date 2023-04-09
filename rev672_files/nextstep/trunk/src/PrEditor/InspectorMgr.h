/*
 *    Filename:	InspectorMgr.h 
 *    Created :	Wed Jan  8 23:34:29 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *
 * LastEditDate "Tue May 26 22:18:26 1992"
 *
 * $Log: not supported by cvs2svn $
 * Revision 2.1  1992/06/10  13:59:25  vince
 * Code to enable and disable the InspectorPanel has been
 * added. When the panel is disabled, it will simply contain
 * the words No Inspector and the popup menu will be disabled.
 *
 * Revision 2.0  1992/04/08  03:43:23  vince
 * Initial-Release
 *
 *
 */


/* Generated by Interface Builder */

#import <objc/Object.h>
#import <objc/zone.h>

#define CURRENT_DICTIONARY 99

@interface InspectorMgr:Object
{
    NXZone *inspectorZone;    /* Zone where all objects related to the inspector
			       * panel are created
			       */
    id	alphabetView;         /* View containing the phonetic Alphabet selection */
    id	dictionaryView;       /* View containing the current dictionary search order */
    id	currentView;          /* View currently being displayed to the user */

    id  emptyView;            /* View containing simply "No Inspector" */
    id  popUp;                /* To popUp list in InspectorPanel */
    
    id	inspectorPanel;       /* THe inspectorPanel itself */

    id  scrollView;           /* ScrollView containing the dictionary Search order stuff */
    id  directoryMatrix;      /* NiftyMatrix Object containing the dictionary Search order stuff */
    id  fontMatrix;           /* Matrix of radio buttons to select the current font/or phonetic
			       * Alphabet
			       */

    short int order[4];       /* Current dictionary Search Order */

}

+ initialize;
- init;
- free;

/* Display inspector Panel on screen
 * If panel isn't already loading into memory load the 
 * nib file in and display it
 */
- inspector:sender;


/* Create the NiftyMatrix inside the ScrollView */
- createScrollView;


- revertToDefaultSearchOrder:sender;

/* This method will send an action down the responder chain when
 * the user clicks in the NiftyMatrix
 */
- dictionaryOrderChanged:sender;
- (const short int *) dictionaryOrder;

/* Enable and Disble the Inspector Panel */
- enableInspector:sender;
- disableInspector:sender;

/* PopUp menu action to swith views in inspector */
- switchViews:sender;

- (const char *)fontName;

/* Window Delegation Methods */
- windowDidMove:sender;

@end
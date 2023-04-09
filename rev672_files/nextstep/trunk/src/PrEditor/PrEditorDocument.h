/*
 *    Filename:	PrEditorDocument.h 
 *    Created :	Thu Jan  9 21:31:43 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *
 * LastEditDate "Tue May 26 21:34:35 1992"
 *
 * $Log: not supported by cvs2svn $
 * Revision 2.1  1992/06/10  14:34:54  vince
 * newLocation function is gone, instead the tileing is done by
 * looking at what is currently on the screen instead.
 *
 * Support for the Contents viewer Object has been added.
 *
 * Bugs in the updateFont method have been fixed the font is
 * now properly set.
 *
 * The disabled scrollers have been removed from the word type
 * display.
 *
 * The entered pronunciation is checked by the Speech object
 * if an error occurs this object will put up a panel notifying
 * the user, which character position is wrong. (On the To Do list
 * is to add a textfilter to the Phone Field to ensure that the
 * user can only type in correct things.)
 *
 * Revision 2.0  1992/04/08  03:43:23  vince
 * Initial-Release
 *
 *
 */

#import <objc/Object.h>
#import <objc/hashtable.h>

typedef struct _entry {
    char element[1024];
    BOOL gray;
} entry;

@interface PrEditorDocument: Object
{
    id     documentWindow;
    id     scrollView;
    id     partsOfSpeechMatrix;
    BOOL   dirty;
    char   filename[1024];
    char   directory[1024];
    id     target;            /* Target for partsOfSpeechChanged */
    id     keyBoardControl;
    BOOL   nameEqualsUntitiled;
    NXAtom currentFont;       /* Current font that is in use */

    id     englishField;
    id     phonField;
    id     speechObject;
    id     prDictionary;     /* Dictionary Object */
    id     messageField;     /* Field to indicate in which knowledge base the pronunciation
			      * was found in, and where messages (not error messages)
			      * get presented to the user.
			      */
    short int dictOrder[4];
}

/* Load a file from disk, if fileName == NULL then a new document will be created */
- initFromFile:(const char *)fileName;
- free;

- (const char *)filename;
- (const char *)directory;
- (BOOL) isDirty;

/* Return prDictionary object */
- dictionary;

/* Return wordField */
- wordField;

/* Dealing with the PartsOfSpeech NifyMatrix */
- createScrollView;
- matrix;

/* Get and Set the parts of speech Nifty Matrix */
- setPartsOfSpeech:(entry *)list;
- getPartsOfSpeech:(entry *)list;

/* Document handling methods */

- saveDocument; /* Actually save the file to disk under name in directory/filename above */
/* Target/Action methods */
- partsOfSpeechChanged:sender;
- save:sender;
- saveAs:sender;

- dictionaryOrderChanged:sender;
- changeFont:sender;              /* Called when the user changes the font in the inspector panel */

/* Word editing methods */
- deleteWord:sender;
- storeWord:sender;
- speakWord:sender;
- getPronounciation:sender;
- getPronounciationCurrentDict:sender;

/* Window Delegations Methods */
- windowWillClose:sender;
- windowDidBecomeMain:sender;
- windowDidMiniaturize:sender;

/* main menu updating stuff */
- (BOOL)validateCommand:menuCell;

- updateFont;

@end

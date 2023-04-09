/*
 *    Filename:	PrEditorDocument.m 
 *    Created :	Thu Jan  9 21:31:35 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *
 * LastEditDate "Mon Jun  8 13:00:23 1992"
 *
 * $Log: not supported by cvs2svn $
# Revision 2.1  1992/06/10  14:34:54  vince
# newLocation function is gone, instead the tileing is done by
# looking at what is currently on the screen instead.
#
# Support for the Contents viewer Object has been added.
#
# Bugs in the updateFont method have been fixed the font is
# now properly set.
#
# The disabled scrollers have been removed from the word type
# display.
#
# The entered pronunciation is checked by the Speech object
# if an error occurs this object will put up a panel notifying
# the user, which character position is wrong. (On the To Do list
# is to add a textfilter to the Phone Field to ensure that the
# user can only type in correct things.)
#
# Revision 2.0  1992/04/08  03:43:23  vince
# Initial-Release
#
 *
 */


#import "PrEditorDocument.h"
#import "PrEditorApp.h"

#import <appkit/Window.h>
#import <appkit/ScrollView.h>
#import <appkit/SavePanel.h>
#import <appkit/MenuCell.h>
#import <appkit/Font.h>
#import <objc/List.h>
#import <objc/error.h>
#import <objc/typedstream.h>
#import <objc/zone.h>
#import <string.h>
#import <objc/typedstream.h>
#import <appkit/nextstd.h>
#import <appkit/publicWraps.h>

#import "Speech.h"
#import "conversion.h"
#import "NiftyMatrix.h"
#import "NiftyMatrixCat.h"
#import "NiftyMatrixCell.h"
#import "KeyboardController.h"
#import "InspectorMgr.h"
#import "PrDict.h"
#import "word_types.h"
#import "hash.h"
#import "PrDictViewer.h"

#import "objc-debug.h"


/************************* Defines for Document Window Positions  *****************************/
#define XOFFSET        (20.0)  /* X-Offset of subsequent windows */
#define YOFFSET        (25.0)  /* Y-Offset of subsequent windows */
#define XREPOSITION    (150.0) /* Amount to reposition the windows to the left, X coord only  */
#define XMAXPOS        (300.0) /* Maximum X coordinate to place a window before repositioning */
#define YMINPOS        (16.0)  /* Minimum Y coordinate to place a window before repositioning */
/**********************************************************************************************/


@implementation PrEditorDocument

/* set list according to contents of word_type */
static inline void setList(const char *word_type, entry list[9])
{
    int i=0;
    int j=0;

    BOOL used[9] = {NO,NO,NO,NO,NO,NO,NO,NO,NO};
    /* Noun, Verb, Adjective, Adverb, Pronoun, Article, Preposition, Conjunction, Interjection */

    if (word_type && ((word_type[i] != UNKNOWN) && (word_type[i] != UNKNOWN2))){
	while(word_type[i]){
	    switch (word_type[i]){
	    case NOUN:
		strcpy(list[i].element,"Noun");
		list[i].gray = NO;
		used[0]      = YES;
		break;
	    case VERB:
		strcpy(list[i].element,"Verb");
		list[i].gray = NO;
		used[1]      = YES;
		break;
	    case ADJECTIVE:
		strcpy(list[i].element,"Adjective");
		list[i].gray = NO;
		used[2]      = YES;
		break;
	    case ADVERB:
		strcpy(list[i].element,"Adverb");
		list[i].gray = NO;
		used[3]      = YES;
		break;
	    case PRONOUN:
		strcpy(list[i].element,"Pronoun");
		list[i].gray = NO;
		used[4]      = YES;
		break;
	    case ARTICLE:
		strcpy(list[i].element,"Article");
		list[i].gray = NO;
		used[5]      = YES;
		break;
	    case PREPOSITION:
		strcpy(list[i].element,"Preposition");
		list[i].gray = NO;
		used[6]      = YES;
		break;
	    case CONJUNCTION:
		strcpy(list[i].element,"Conjunction");
		list[i].gray = NO;
		used[7]      = YES;
		break;
	    case INTERJECTION:
		strcpy(list[i].element,"Interjection");
		list[i].gray = NO;
		used[8]      = YES;
		break;
		/* case 'i': */
		/* case '?': */
	    } /* switch */
	    i++;
	} /* while */

	for(j=0;j < 9; j++){
	    if (!used[j]){
		switch(j){
		case 0:
		    strcpy(list[i].element,"Noun");
		    list[i++].gray = YES;
		    break;
		case 1:
		    strcpy(list[i].element,"Verb");
		    list[i++].gray = YES;
		    break;
		case 2:
		    strcpy(list[i].element,"Adjective");
		    list[i++].gray = YES;
		    break;
		case 3:
		    strcpy(list[i].element,"Adverb");
		    list[i++].gray = YES;
		    break;
		case 4:
		    strcpy(list[i].element,"Pronoun");
		    list[i++].gray = YES;
		    break;
		case 5:
		    strcpy(list[i].element,"Article");
		    list[i++].gray = YES;
		    break;
		case 6:
		    strcpy(list[i].element,"Preposition");
		    list[i++].gray = YES;
		    break;
		case 7:
		    strcpy(list[i].element,"Conjunction");
		    list[i++].gray = YES;
		    break;
		case 8:
		    strcpy(list[i].element,"Interjection");
		    list[i++].gray = YES;
		    break;
		} /* switch */
	    } /* if */
	} /* for */

    } else {
	strcpy(list[0].element,"Noun");
	list[0].gray = YES;
	strcpy(list[1].element,"Verb");
	list[1].gray = YES;
	strcpy(list[2].element,"Adjective");
	list[2].gray = YES;
	strcpy(list[3].element,"Adverb");
	list[3].gray = YES;
	strcpy(list[4].element,"Pronoun");
	list[4].gray = YES;
	strcpy(list[5].element,"Article");
	list[5].gray = YES;
	strcpy(list[6].element,"Preposition");
	list[6].gray = YES;
	strcpy(list[7].element,"Conjunction");
	list[7].gray = YES;
	strcpy(list[8].element,"Interjection");
	list[8].gray = YES;
    }
}

/* Returns a pointer to char of each word types
 * See word_types.h
 */
static inline char *setWordtype(entry list[9])
{
    int i;
    int j=0;
    char word_type[9];
    BOOL emptyList = YES;

    bzero(word_type,9*sizeof(char));

    for (i=0; i < 9 ; i++){
	if (list[i].gray){
	    emptyList = NO;
	    word_type[j++] = typecode(list[i].element,strlen(list[i].element));
	}
    }
    if (emptyList == NO){
	return word_type;
    }else{
	/* bzero(word_type,9*sizeof(char)); */
	word_type[0] = UNKNOWN;
	word_type[1] = '\000';
	return word_type;
    }
	
}

- initFromFile:(const char*)fileName
{
    char  name[1024];
    char *untitled;
    NXTypedStream *volatile stream = NULL; /* declared volatile because it is used
					    * within the exception handling code
					    * Which is essentually a setjmp and longjmp
					    */

    DEBUG_METHOD;


    [NXApp loadNibSection:"Document.nib" owner:self withNames:NO fromZone:[self zone]];

    [documentWindow addToEventMask:NX_SHIFTMASK];
    [documentWindow setMiniwindowIcon:"dict"];
    [documentWindow useOptimizedDrawing:YES];


    currentFont = NULL;
    
    if (!fileName){   /* Create a new document */
	untitled = [NXApp untitled];  /* Ask the application Object for a name */
	sprintf(name,"%s/%s",NXHomeDirectory(),untitled);
	strcpy(filename,untitled);
	strcpy(directory,NXHomeDirectory()); /* set the default directory to the users
					      * home directory
					      */
	[documentWindow setTitleAsFilename:name];
	nameEqualsUntitiled = YES;
	/* alloc And init hashTable object */
	prDictionary = [[PrDict allocFromZone:[self zone]] init]; /* alloc a PrDict Object */
    }else{                                                        /* Load a file from disk */
	strcpy(name,fileName);
	[documentWindow setTitleAsFilename:fileName];
	strcpy(filename,rindex(name,'/')+1);
	*(rindex(name,'/')) = '\000';
	strcpy(directory,name);
	nameEqualsUntitiled = NO;

	/* Exception handling code, to ensure that the file read from the typed
	 * Stream doesn't contain garbage
	 * and really is a preditor dictionary.
	 * if you attempt to open a non preditor dictionary
	 * either it will work but you will get an empty file or
	 * an exception will be generated and the user will see an AlertPanel
	 */
	NX_DURING

	/* Load the file from disk from file: fileName */
	/* Load hashTable from disk */
	    stream = NXOpenTypedStreamForFile(fileName,NX_READONLY);
	    if (stream){
		NXSetTypedStreamZone(stream,[self zone]);
		prDictionary = NXReadObject(stream);
		NXCloseTypedStream(stream);
	    }

	NX_HANDLER
	
	    if ( (NXLocalHandler.code >= TYPEDSTREAM_ERROR_RBASE) &&  
		 (NXLocalHandler.code < TYPEDSTREAM_ERROR_RBASE +1000)) {

		/* code for custom handling of TYPEDSTREAM Exceptions exceptions 
		 * Close the typedStream and put up a panel telling the user that the file
		 * that they wanted to open was not a dictionary 
		 * And free this object
		 *
		 */
		NXLogError("File %s isn't a PrEditor Dictionary\n",fileName);
		NXRunAlertPanel("Open",
				"%s file isn't a PrEditor Dictionary",
				"Okay",NULL,NULL,fileName);
	    } else {
		NXLogError("FATAL ERROR Uncaught Exception while opening %s\n",fileName);
		NXRunAlertPanel("FATAL ERROR",
				"Uncaught Exception occured while opening %s, contact Trillium Research",
				"Okay",NULL,NULL,fileName);
		NX_RERAISE();
	    }

	    if (stream){
		NXCloseTypedStream(stream);
	    }
	    [self free];
   	    return nil;

	NX_ENDHANDLER
	    
    } /* if (!fileName) */
    if (!(speechObject = [[TextToSpeech allocFromZone:[self zone]] init])){  /* Check if able to connect
									      * to the server
									      * if not possible put up
									      * a panel and don't open
									      * up a window
									      */
	NXRunAlertPanel((fileName ? "Open" : "New"),
			"Unable to connect to Speech Server",
			"Okay",NULL,NULL);

	[self free];
	NXLogError("Unable to connect to Speech Server\n");
	return nil;
    }

    dirty = NO;
    [self createScrollView];

    /* This is the code that tiles the windows
     *
     * It works like this:
     * 1. Check if there are any other mainWindows if there are then
     * 2. Get the position of that main window
     * 3. Check if the window if off the screen, if ((NX_X(&winLoc) + XOFFSET) <= 300.0), in the
     *    X direction if it is then reposition it to the left of the current window XREPOSITION
     *    pixels.
     * 4. Check if the window is too low, (the Y coord) if it is just place it at the
     *    default location.
     */
    if ([NXApp mainWindow]) {
        NXRect winFrame, winLoc;
        [[NXApp mainWindow] getFrame:&winFrame];
        [[documentWindow class] getContentRect:&winLoc forFrameRect:&winFrame style:[documentWindow style]];
	if ((NX_X(&winLoc) + XOFFSET) <= XMAXPOS){
	    if ( (NX_Y(&winLoc) - YOFFSET) >= YMINPOS )
		[documentWindow moveTo:NX_X(&winLoc) + XOFFSET :NX_Y(&winLoc) - YOFFSET];
	}else{
	    if ( (NX_Y(&winLoc) - YOFFSET) >= YMINPOS )
		[documentWindow moveTo:NX_X(&winLoc) + XOFFSET - XREPOSITION :NX_Y(&winLoc) - YOFFSET];
	}
    }

    [keyBoardControl disableKeyboard];

    [documentWindow useOptimizedDrawing:YES];
    [englishField selectText:self];
    [self updateFont];
    [documentWindow makeKeyAndOrderFront:self];

    [[NXApp inspectorPanel] enableInspector:self];

    return self;
}

/* Free everything that the Object has allocated */
- free
{
    DEBUG_METHOD;

    [documentWindow setDelegate:nil];  /* This is important to prevent segfaulting */
    [partsOfSpeechMatrix free];
    [keyBoardControl free];
    [speechObject free];
    [prDictionary free];
    [NXApp reuseZone:[self zone]];     /* Reuse the current zone */
    [super free];

    return nil;
}

/* Current filename */
- (const char *)filename
{
    return filename;
}

/* directory where file will be stored */
- (const char *)directory
{
    return directory;
}

/* is the copy of the dictionary in memory dirty, ie has it been modified and
 * not saved to disk??
 */
- (BOOL)isDirty
{
    return dirty;
}

/* Return a pointer to the current dictionary */
- dictionary
{
  return prDictionary;
}

/* Return wordField */
- wordField
{
  return englishField;
}

- createScrollView
{
    NXRect      scrollRect, matrixRect;
    NXSize      interCellSpacing = {0.0, 0.0};
    NXSize      cellSize;

    DEBUG_METHOD;

    /* set the scrollView's attributes */
    [scrollView setBorderType:NX_BEZEL];
    [scrollView setVertScrollerRequired:NO];
    [scrollView setHorizScrollerRequired:NO];
                
    /* get the scrollView's dimensions */
    [scrollView getFrame:&scrollRect];

    /* determine the matrix bounds */
    [ScrollView getContentSize:&(matrixRect.size)
                forFrameSize:&(scrollRect.size)
                horizScroller:NO
                vertScroller:NO
                borderType:NX_BEZEL];
    
    /* prepare a matrix to go inside our scrollView */
    partsOfSpeechMatrix = [[NiftyMatrix allocFromZone:[self zone]] initFrame:&matrixRect 
                                  mode:NX_RADIOMODE
                                  cellClass:[NiftyMatrixCell class]
                                  numRows:0
                                  numCols:1];

    /* we don't want any space between the matrix's cells  */
    [partsOfSpeechMatrix setIntercell:&interCellSpacing];

    /* resize the matrix's cells and size the matrix to contain them */
    [partsOfSpeechMatrix getCellSize:&cellSize];
    cellSize.width = NX_WIDTH(&matrixRect) + 0.1;
    [partsOfSpeechMatrix setCellSize:&cellSize];
    [partsOfSpeechMatrix sizeToCells];
    [partsOfSpeechMatrix setAutosizeCells:YES];
    
    /*
     * when the user clicks in the matrix and then drags the mouse out of
     * scrollView's contentView, we want the matrix to scroll
     */
    [partsOfSpeechMatrix setAutoscroll:YES];
    
    /* stick the matrix in our scrollView */
    [scrollView setDocView:partsOfSpeechMatrix];
    
    /* set things up so that the matrix will resize properly */
    [[partsOfSpeechMatrix superview] setAutoresizeSubviews:YES];
    [partsOfSpeechMatrix setAutosizing:NX_WIDTHSIZABLE];
    
    /* set the matrix's single-click actions */
    [partsOfSpeechMatrix setTarget:self];
    [partsOfSpeechMatrix setAction:@selector(partsOfSpeechChanged:)];
//    [partsOfSpeechMatrix allowEmptySel:YES];

    [partsOfSpeechMatrix insertCellWithStringValue: "Noun"  ];
    [partsOfSpeechMatrix insertCellWithStringValue: "Verb"];
    [partsOfSpeechMatrix insertCellWithStringValue: "Adjective"];
    [partsOfSpeechMatrix insertCellWithStringValue: "Adverb"];
    [partsOfSpeechMatrix insertCellWithStringValue: "Pronoun"];
    [partsOfSpeechMatrix insertCellWithStringValue: "Article"];
    [partsOfSpeechMatrix insertCellWithStringValue: "Preposition"];
    [partsOfSpeechMatrix insertCellWithStringValue: "Conjunction"];
    [partsOfSpeechMatrix insertCellWithStringValue: "Interjection"];
    [partsOfSpeechMatrix grayAllCells];

    return self;
}

- matrix
{
    return partsOfSpeechMatrix;
}

- setPartsOfSpeech:(entry *)list
{
    int i = 0;
    id speechMatrix = [self matrix];

    DEBUG_METHOD;

    [speechMatrix  unlockAllCells];    
    [speechMatrix  removeAllCells];
    [speechMatrix  insertCellWithStringValue: "PrEditor by"]; /* Junk values that seem to fix a
								* strange bug
								* This will stay for now
								* until i can figure out why
								*/
    [speechMatrix  insertCellWithStringValue: "Vince DeMarco"];
    [speechMatrix  insertCellWithStringValue: "for"];
    [speechMatrix  insertCellWithStringValue: "Trillium"];
    [speechMatrix  insertCellWithStringValue: "Sound"];


    [speechMatrix  ungrayAllCells];
    [speechMatrix  removeAllCells];

    for(i=0;i<9;i++){
	[speechMatrix insertCellWithStringValue: (const char *)list[i].element];
    }
    [speechMatrix  ungrayAllCells];    
    for(i=0;i<9;i++){
	if (list[i].gray){
	    [speechMatrix toggleCellWithStringValue: (const char *)list[i].element];
	}
    }
    [speechMatrix  display];

    return self;
}

- getPartsOfSpeech:(entry *)list
{
    id thelist = [[self matrix] cellList];
    id cellAt;
    int count;
    int i = 0;

    DEBUG_METHOD;

    count = [thelist count];
    while (i < count){
	cellAt = [thelist objectAt:i];
	strcpy(list[i].element,[cellAt stringValue]);
	list[i].gray = [cellAt toggleValue]? YES : NO;
	i++;
    }
    return self;
}

/* Target/Action methods ******************************************************************************/

/* Parts of speech have changed this is currently being ignored
 * but it might get used latter on 
 */
- partsOfSpeechChanged:sender
{
    DEBUG_METHOD;

    /* dirty = YES; 
     * [documentWindow setDocEdited: dirty];
     */

    return self;
}

- saveDocument /* Actually save the file to disk */
{
    char completePath[1024];
    NXTypedStream *volatile stream = NULL;

    sprintf(completePath,"%s/%s",[self directory],[self filename]);     
                                              /* Save file undername: directory/filename */

    dirty = NO;
    [documentWindow setDocEdited: dirty];

    NX_DURING

	stream = NXOpenTypedStreamForFile(completePath,NX_WRITEONLY);
        if (stream){
	    NXSetTypedStreamZone(stream,[self zone]);
	    /* NXWriteObject(stream,prDictionary); */
	    NXWriteRootObject(stream,prDictionary);
	    NXCloseTypedStream(stream);
	}else{
	    NXRunAlertPanel("Save","Can't create file","Okay",NULL,NULL);
	    return nil;
	}

    NX_HANDLER

	if (NXLocalHandler.code == TYPEDSTREAM_WRITE_REFERENCE_ERROR) {

	    NXLogError("TYPEDSTREAM WRITE REFERENCE ERROR occured while saving %s\n",[self filename]);
	    NXRunAlertPanel("ERROR",
			    "TYPEDSTREAM WRITE REF ERROR occured while saving %s, contact Trillium Research",
			    "Okay",NULL,NULL,[self filename]);
	}else{
	    NXLogError("FATAL ERROR - Uncaught exeception occured while saving %s\n",[self filename]);
	    NXRunAlertPanel("FATAL ERROR",
			    "Uncaught Exception occured while saving %s, contact Trillium Research",
			    "Okay",NULL,NULL,[self filename]);
	    NX_RERAISE();
	}
        return nil;

    NX_ENDHANDLER

    return self;
}

/* Save Target from main menu */
- save:sender
{
    const char *name;
    id savepanel;

    if (nameEqualsUntitiled){
	savepanel = [[SavePanel new] setTitle:"Save Document"];
	[savepanel setRequiredFileType:"preditor"];

	if ([savepanel runModalForDirectory:[self directory] file:[self filename]]){
	    nameEqualsUntitiled = NO;	
	    name = [savepanel filename];
	    [documentWindow setTitleAsFilename:name];
	    strcpy(filename,rindex(name,'/')+1);
	    *(rindex(name,'/')) = '\000';
	    strcpy(directory,name);
	}else{
	    return nil;
	}

    }
    /* Save file undername: directory/filename */
    /* fprintf(stderr,"Save:%s / %s\n",directory,filename); */
    [self saveDocument];
    return self;
}

/* SaveAs Target from main menu */
- saveAs:sender
{
    const char *name;

    id savepanel = [[SavePanel new] setTitle: "Save Document As"];
    [savepanel setRequiredFileType:"preditor"];

    if ([savepanel runModalForDirectory:[self directory] file:[self filename]]){
	name = [savepanel filename];
	[documentWindow setTitleAsFilename:name];
	strcpy(filename,rindex(name,'/')+1);
	*(rindex(name,'/')) = '\000';
	strcpy(directory,name);
    }else{
	return self;
    }

    /* fprintf(stderr,"SaveAs:%s / %s\n",directory,filename); */
    [self saveDocument];
    return self;
}


/* Change the currently selected font */
- changeFont:sender
{
    DEBUG_METHOD;

    [self updateFont];
    return self;
}

- updateFont
{
    id fontObj;
    const char *newFont      = [[NXApp inspectorPanel] fontName];
    const char *current_word = [phonField stringValue];
    NXAtom theNewFont        = NXUniqueString(newFont);

    if (currentFont != theNewFont) {
	currentFont = theNewFont;
	if (fontObj = [Font newFont: newFont  size: 16.0])
	    [[keyBoardControl setFont:fontObj] disableKeyboard];
	if (fontObj = [Font newFont: newFont  size: 23.0])
	    [phonField setFont:fontObj];
	[phonField setStringValue:current_word];
    }
    return self;
}

/* The dictionary Order has changed so take note of it */

- dictionaryOrderChanged:sender
{
    const short int *ord;
    int i;

    DEBUG_METHOD;

    ord = [[NXApp inspectorPanel] dictionaryOrder];
    for (i=0;i<4;i++){
	dictOrder[i] = ord[i];
    }

    switch([speechObject setDictOrder: dictOrder]){
      case TTS_OK:
	return self;
      case TTS_SERVER_HUNG:
      case TTS_SERVER_RESTARTED:
	return self;
      default:
	NXLogError("Could not set Dictionary Order");
	NXRunAlertPanel("ERROR",
			"Could not set Dictionary Order contact Trillium Research",
			"Okay",NULL,NULL);
	return self;
    }
    return self;
}

/* DICTIONARY EDITING METHODS ***************************************************************/

/* Delete the currently selected word */
- deleteWord:sender
{
    const char *word = [englishField stringValue];
    char  message[1024];

    DEBUG_METHOD;
    if (word && word[0]){
	if ([prDictionary isMember: word]){
	    [prDictionary deleteKey: word];

	    sprintf(message,"\"%s\" Deleted from Current Dictionary",word);
	    [messageField setStringValue:message];

	    dirty = YES;
	    [[NXApp wordList] loadDict: prDictionary];
	    [documentWindow setDocEdited: dirty];
	}else{
	    sprintf(message,"\"%s\" is not in the Current Dictionary",word);
	    [messageField setStringValue:message];
	    NXBeep();
	}
    }else{
	NXBeep();
    }
    return self;
}

/* Store the currently selected word in the dictionary */
- storeWord:sender
{
    BOOL  inList = NO;
    entry list[9];
    char  *wordtype;
    char  dictentry[1024];
    char  message[1024];
    const char *phone = [phonField stringValue];
    const char *word = [englishField stringValue];

    DEBUG_METHOD;

    if ((phone && word) && (phone[0] && word[0])){ /* Make sure the word and the pronounciation have been
						    * entered by the user before trying to save it
						    */
	[self getPartsOfSpeech:list];
	wordtype = setWordtype(list);
	sprintf(dictentry,"%s%%%s",phone,wordtype);
#ifdef DEBUG	
	fprintf(stderr,"storeWord: word = %s dictentry = %s\n",word,dictentry);
#endif
	if ([prDictionary isMember: word]){
	    sprintf(message,"\"%s\" is already in the Current Dictionary, replacing old entry",word);
	    [messageField setStringValue:message];
	    NXBeep();
	    inList = YES;
	}else{
	    
	    sprintf(message,"\"%s\" Stored in Current Dictionary",word);
	    [messageField setStringValue:message];
	}

	[prDictionary insertKey: word data:(const char *)dictentry];

	dirty = YES;
	if (inList == NO)
	  [[NXApp wordList] loadDict: prDictionary]; /* Update Contents inspector (PrDictViewer) 
						      * only if a new word has been added to the 
						      * dictionary, ie inList == NO
						      */

	[documentWindow setDocEdited: dirty];
    }else{
	NXBeep();
    }
    return self;
}

/* Speak the current phoneme string to the user, if the speechObject returns an negative number
 * this indicates that a parse error has occured at -1 * the return value
 */
- speakWord:sender
{
    int retval;
    const char *phone = [phonField stringValue];

    DEBUG_METHOD;

    if (phone && phone[0]){
	if ((retval = [speechObject speakLiteralMode:phone]) != TTS_OK){
	    switch (retval) {
	        case TTS_PARSE_ERROR:
		     NXLogError("Could not parse phoneme string %s",phone);
		     NXRunAlertPanel("Speech Current Word","Could not parse phoneme string",
				     "Okay",NULL,NULL);
		     break;
		case TTS_SPEAK_QUEUE_FULL:
		     NXLogError("Speech Server Queue is full");
		     NXRunAlertPanel("Speech Current Word","Speech Server Queue is full",
				     "Okay",NULL,NULL);
		     break;
		default:
		     /* This will probably change in the future
		      * But this is okay for now
		      */
		     NXLogError("Could not parse phoneme string %s: error at pos %d",phone,-retval);
		     NXRunAlertPanel("Speech Current Word",
				     "Could not parse phoneme string:\nError at position %d",
				     "Okay",NULL,NULL,-retval);
		     break;
	    }
	}
    }else{
	NXBeep();
    }
    
    return self;
}

/* Query the speech Object for the pronunciation of the currently entered word */
- getPronounciation:sender
{
    char        word[1024];
    const char *result;
    const char *lookup = [englishField stringValue];
    int         i;
    int         currentDict = -1;
    int         found = -1;
    short int   dict;
    BOOL        wordfound = NO;
    entry       list[9];
    BOOL        error = NO;

    DEBUG_METHOD;

    if (lookup && lookup[0]){

	strcpy(word,lookup);

	result = [speechObject getPronunciation: lookup dict: &dict];

	for (i = 0; i < 4; i++){
	    if (dictOrder[i] == CURRENT_DICTIONARY)
		currentDict = i;
	    if (dictOrder[i] == dict)
		found = i;
	}
	
	if ((found > currentDict) && (currentDict != -1)){	
	    /* Word might be in the current dictionary
	     * Check prDictionary first
	     */
	    if (wordfound = [prDictionary isMember: word]){
		[messageField setStringValue:"Pronunciation found in the Current Dictionary"];
		result = (char *)[prDictionary valueForKey:word];
	    }
	}
	if (!wordfound){
	    switch(dict){
	    case TTS_NUMBER_PARSER:
		[messageField setStringValue:"Pronunciation found by The Number Parser"];
		break;
	    case TTS_USER_DICTIONARY:
		[messageField setStringValue:"Pronunciation found in the User Dictionary"];
		break;
	    case TTS_MAIN_DICTIONARY:
		[messageField setStringValue:"Pronunciation found in the Main Dictionary"];
		break;
	    case TTS_LETTER_TO_SOUND:
		[messageField setStringValue:"Pronunciation found by The Letter To Sound Rules"];
		break;
	    default:
		error = YES;
		NXLogError("getPronunciation:dict: returned a garbage dicitonary");
                NXRunAlertPanel("ERROR",
                                "Server Returned garbage while looking up %s, contact Trillium Research",
                                "Okay",NULL,NULL,lookup);

		break;
	    }
	}
#ifdef DEBUG
	fprintf(stderr,"getPro: result = %s in dictionary = %d\n",result,dict);
#endif
	if (error != YES){
	    [phonField setStringValue: (const char *)pronunciation(result)];
	    setList(word_type(result),list);
	    [self setPartsOfSpeech: list];
	}
    }else{
	NXBeep();
    }
    return self;
}

/* Same as above except only the CurrentDictionary is searched this is used by the Contents
 * Inspector (PrDictViewer) when the user clicks on a word
 */
- getPronounciationCurrentDict:sender
{
  const char *result;
  entry       list[9];
  const char *word = [englishField stringValue];

  DEBUG_METHOD;
  
  if (word && word[0]){
      result = [prDictionary valueForKey:word];
      if (result && result[0]){
	  [phonField setStringValue: pronunciation(result)];
	  [messageField setStringValue:"Pronunciation found in the Current Dictionary"];
	  [phonField selectText:sender];
	  [keyBoardControl enableKeyboard];
	  setList(word_type(result),list);
	  [self setPartsOfSpeech: list];
      }
  }
  return self;
}


/* Window Delegations Methods ************************************************************************/
- windowWillClose:sender
{
    DEBUG_METHOD;

    if ([self isDirty]){
	/* Localize this in the .nib file */
	switch (NXRunAlertPanel("Close","%s has changed. Save?","Save","Don't Save","Cancel",[self filename])){
	case NX_ALERTDEFAULT:   /* Save file */
	    [self save:sender];
	    break;
	case NX_ALERTALTERNATE: /* Don't Save */
	    break;
	case NX_ALERTOTHER:     /* Cancel window Close */
	    return nil;
	    break;
	case NX_ALERTERROR:
	    break;
	}
    }
    [self free];
    if ([documentWindow isMainWindow]){ /* Only do this if the window is the MainWindow
					 * if it isn't then something else
					 * already has the inspector and the wordList
					 * (contents view) already set up correctly
					 */
	[[NXApp wordList] documentChanged];
	[[NXApp inspectorPanel] disableInspector:sender];
    }
    return sender;
}

- windowDidBecomeMain:sender
{
    DEBUG_METHOD;

    [self dictionaryOrderChanged:sender];
    [self updateFont];
    [[NXApp wordList] loadDict: prDictionary];
    [[NXApp inspectorPanel] enableInspector:sender];
    return self;
}

- windowDidMiniaturize:sender
{
    [[NXApp wordList] documentChanged];
    [[NXApp inspectorPanel] disableInspector:sender];
    return sender;
}

/* main menu updating stuff ****************************************************************************/

- (BOOL)validateCommand:menuCell
/*
 * Validates whether a menu command that PrEditorDocument responds to
 * is valid at the current time.
 */
{
    SEL         action = [menuCell action];
    const char *phone  = [phonField stringValue];
    const char *word   = [englishField stringValue];


    if (action == @selector(save:)){                 /* If action is sav */
      return (nameEqualsUntitiled ? YES : [self isDirty]);  /* Return the saved state of the file
	                                                     * unless the files name is Untitiled-??
							     * Then return YES, enabling the save
							     * menu option
							     */
    }
    if (action == @selector(deleteWord:)){           /* If action is deleteWord */
      return ((word && word[0]) ? YES : NO);   /* Enable Menu option if word has been entered */      
	                                       
    }
    if (action == @selector(getPronounciation:)){    /* If action is getPronunciation */
      return ((word && word[0]) ? YES : NO);   /* Enable Menu option if word has been entered */      
	                                       
    }
    if (action == @selector(speakWord:)){            /* If action is speakWord */
      return ((phone && phone[0]) ? YES : NO); /* Enable Menu option if pronunciation have been entered */      
                                               
    }
    if (action == @selector(storeWord:)){            /* If action is storeWord in dictionary */
      return (((phone && word) && (phone[0] && word[0])) ? YES : NO); /* if word and pron have been entered */
                                               
    }
    return YES;
}


@end

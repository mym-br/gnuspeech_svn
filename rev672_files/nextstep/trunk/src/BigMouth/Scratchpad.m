/*  HEADER FILES  ************************************************************/
#import "Scratchpad.h"
#import "BigMouth.h"
#import <TextToSpeech/TextToSpeech.h>
#import <appkit/appkit.h>


/*  LOCAL DEFINES  ***********************************************************/
#define SCRATCHPAD_WIDTH_MIN    300.0
#define SCRATCHPAD_HEIGHT_MIN   300.0

#define MODE_NONE               0
#define MODE_TEXTBUFFER         1
#define MODE_FILESTREAM         2
#define MODE_FILENAME           3




@implementation Scratchpad

- awakeFromNib
{
    NXSize minimumSize;

    /*  GET THE CONNECTION TO THE TTS OBJECT  */
    mySpeaker = [NXApp ttsInstance];

    /*  GET THE ID OF THE TEXT OBJECT IN THE SCRATCHPAD  */
    textObject = [scratchpad docView];

    /*  SET MINIWINDOW ICONS  */
    [scratchpadWindow setMiniwindowIcon:"mouth.tiff"];

    /*  SET MINIMUM SIZE FOR THE WINDOW  */
    minimumSize.width = SCRATCHPAD_WIDTH_MIN;
    minimumSize.height = SCRATCHPAD_HEIGHT_MIN;
    [scratchpadWindow setMinSize:&minimumSize];

    /*  INITIALIZE THE SAVE PANEL  */
    savePanel = [SavePanel new];
    [savePanel setRequiredFileType:"snd"];

    return self;
}



- free
{
    /*  BE SURE TO FREE THE CONTENTS OF THE SCRATCHPAD BUFFER  */
    if (textBuffer)
	free(textBuffer);

    /*  CLOSE OLD MEMORY STREAM, INCLUDING ALL MEMORY IT USES  */
    if (fileStream)
	NXCloseMemory(fileStream, NX_FREEBUFFER);
    
    /*  FREE FILENAME MEMORY, IF NECESSARY  */
    if (filename)
	free(filename);

    /*  FREE OBJECT AS USUAL  */
    return [super free];
}



- warnUser
{
    /*  WARN THE USER IF THE VOCAL TRACT LENGTH TOO SHORT  */
    NXBeep();
    NXRunAlertPanel("DSP hardware is too slow",
	"Choose a larger voice type and/or a longer vocal tract length offset.",
	"OK", NULL, NULL);

    return self;
}



- speakAll:sender
{
    int documentLength;
    NXStream *textStream;

    /*  FIND LENGTH OF TEXT IN THE SCROLLVIEW  */
    documentLength = [textObject byteLength];

    /*  BEEP AND RETURN IF NO TEXT  */
    if (documentLength <= 0) {
	NXBeep();

	/*  SET THE MODE SO THAT REPEAT HAS NO EFFECT  */
	mode = MODE_NONE;
	[NXApp setModeToScratchpad];

	return self;
    }

    /*  FREE THE CONTENTS OF THE OLD BUFFER, IF NECESSARY  */
    if (textBuffer)
	free(textBuffer);

    /*  ALLOCATE TEMPORARY MEMORY TO HOLD A COPY OF THE TEXT  */
    textBuffer = (char *)malloc(documentLength+1);

    /*  FIND THE STREAM WHICH CONTAINS THE TEXT  */
    textStream = [textObject stream];

    /*  REWIND THE STREAM TO THE BEGINNING  */
    NXSeek(textStream, 0, NX_FROMSTART);

    /*  COPY THE CONTENTS OF THE STREAM INTO THE TEMPORARY BUFFER  */
    NXRead(textStream, textBuffer, documentLength);

    /*  BE SURE TO APPEND A NULL TO THE STRING  */
    textBuffer[documentLength] = '\0';

    /*  SPEAK THE CONTENTS OF THE TEMPORARY BUFFER  */
    if (toFile) {
	/*  RUN THE SAVE PANEL, TO GET THE FILE NAME  */
	if ([savePanel runModal] == NX_OKTAG) {
	    /*  IF OK, SYNTHESIZE TO THE SPECIFIED FILE  */
	    [mySpeaker speakText:textBuffer toFile:[savePanel filename]];
	}
    }
    else {
	if ([mySpeaker speakText:textBuffer] == TTS_DSP_TOO_SLOW) {
	    /*  WARN THE USER IF THE VOCAL TRACT LENGTH TOO SHORT  */
	    [self warnUser];
	}
    }
    /*  SET THE MODE, IN CASE WE WANT TO SPEAK THE BUFFER AGAIN  */
    mode = MODE_TEXTBUFFER;
    [NXApp setModeToScratchpad];

    /*  Note:  we cannot use the speakStream: method since the Text
	object does not use a memory stream.  The speakStream: method
	can only handle memory streams since it relies on the
	NXGetMemoryBuffer() function.  */

    return self;
}



- speakSelection:sender
{
    NXSelPt begin, end;
    int length;

    /*  GET THE BEGIN AND END POINTS OF THE SELECTION  */
    [textObject getSel:&begin :&end];

    /*  CALCULATE LENGTH OF SELECTION  */
    length = end.cp - begin.cp;

    /*  BEEP AND RETURN IF NO SELECTION MADE  */
    if (([textObject byteLength] <= 0) || (length <= 0)) {
	NXBeep();

	/*  SET THE MODE SO THAT REPEAT HAS NO EFFECT  */
	mode = MODE_NONE;
	[NXApp setModeToScratchpad];
	
	return self;
    }

    /*  FREE THE CONTENTS OF THE OLD BUFFER, IF NECESSARY  */
    if (textBuffer)
	free(textBuffer);

    /*  ALLOCATE TEMPORARY MEMORY TO HOLD A COPY OF THE TEXT  */
    textBuffer = (char *)malloc(length+1);

    /*  COPY SELECTION INTO TEMPORARY BUFFER  */
    [textObject getSubstring:textBuffer start:begin.cp length:length];

    /*  BE SURE TO APPEND A NULL TO THE END OF THE STRING  */
    textBuffer[length] = '\0';

    /*  SPEAK THE SELECTION  */
    if (toFile) {
	/*  RUN THE SAVE PANEL, TO GET THE FILE NAME  */
	if ([savePanel runModal] == NX_OKTAG) {
	    /*  IF OK, SYNTHESIZE TO THE SPECIFIED FILE  */
	    [mySpeaker speakText:textBuffer toFile:[savePanel filename]];
	}
    }
    else {
	if ([mySpeaker speakText:textBuffer] == TTS_DSP_TOO_SLOW) {
	    /*  WARN THE USER IF THE VOCAL TRACT LENGTH TOO SHORT  */
	    [self warnUser];
	}
    }

    /*  SET THE MODE, IN CASE WE WANT TO SPEAK THE BUFFER AGAIN  */
    mode = MODE_TEXTBUFFER;
    [NXApp setModeToScratchpad];

    return self;
}



- speakFileOnPasteboard:pasteboard
{
    char *path;
    int pathLength;
    
    /*  CLOSE OLD MEMORY STREAM, INCLUDING ALL MEMORY IT USES  */
    if (fileStream) {
	NXCloseMemory(fileStream, NX_FREEBUFFER);
	fileStream = NULL;
    }
    
    /*  PUSH THE SPEAKFILE BUTTON  */
    [speakFileButton highlight:YES];

    /*  GET THE PATH FROM THE PASTEBOARD  */
    if ([pasteboard readType:NXFilenamePboardType data:&path length:&pathLength]) {
	/*  MAKE SURE PATH NAME IS NULL TERMINATED  */
	path[pathLength] = '\0';
	
	/*  MEMORY MAP SPECIFIED INPUT FILE TO MEMORY STREAM  */
	if (fileStream = NXMapFile(path, NX_READONLY)) {
	    if (toFile) {
		/*  RUN THE SAVE PANEL, TO GET THE FILE NAME  */
		if ([savePanel runModal] == NX_OKTAG) {
		    /*  IF OK, SYNTHESIZE TO THE SPECIFIED FILE  */
		    [mySpeaker speakStream:fileStream toFile:[savePanel filename]];
		}
	    }
	    else {
		/*  SPEAK MEMORY STREAM  */
		if ([mySpeaker speakStream:fileStream] == TTS_DSP_TOO_SLOW) {
		    /*  WARN THE USER IF THE VOCAL TRACT LENGTH TOO SHORT  */
		    [self warnUser];
		}
	    }	    
	    /*  SET THE MODE, IN CASE WE WANT TO SPEAK THE BUFFER AGAIN  */
	    mode = MODE_FILESTREAM;
	    [NXApp setModeToScratchpad];
	}
	else {
	    /*  IF WE CAN'T READ THE CONTENTS OF THE FILE, THEN READ FILENAME  */
	    char *ptr;
	    
	    /*  FREE FILENAME MEMORY, IF NECESSARY  */
	    if (filename) {
		free(filename);
		filename = NULL;
	    }
	    
	    /*  FIND FILENAME IN PATH  */
	    ptr = strrchr(path,'/') + 1;
	    
	    /*  IF THE FILENAME EXISTS, STORE IT AND SPEAK IT  */
	    if (ptr && (strlen(ptr) > 0)) {
		/*  ALLOCATE MEMORY AND STORE THE FILENAME (FOR REPEAT)  */
		filename = (char *)malloc(strlen(ptr)+1);
		strcpy(filename,ptr);

		/*  SPEAK THE FILENAME  */		
		if (toFile) {
		    /*  RUN THE SAVE PANEL, TO GET THE FILE NAME  */
		    if ([savePanel runModal] == NX_OKTAG) {
			/*  IF OK, SYNTHESIZE TO THE SPECIFIED FILE  */
			[mySpeaker speakText:filename
				   toFile:[savePanel filename]];
		    }
		}
		else {
		    if ([mySpeaker speakText:filename] == TTS_DSP_TOO_SLOW) {
			/*  WARN THE USER IF THE VOCAL TRACT LENGTH TOO SHORT  */
			[self warnUser];
		    }
		}

		/*  SET THE MODE, IN CASE WE WANT TO SPEAK THE BUFFER AGAIN  */
		mode = MODE_FILENAME;
		[NXApp setModeToScratchpad];
	    }
	    else {
		/*  THE FILENAME IS NOT SPEAKABLE, SO MERELY BEEP  */
		NXBeep();
		
		/*  SET THE MODE SO THAT REPEAT HAS NO EFFECT  */
		mode = MODE_NONE;
		[NXApp setModeToScratchpad];
	    }
	}
	
	/*  DEALLOCATE OLD PATH BUFFER MEMORY IF NECESSARY  */
	if (path)
	    vm_deallocate(task_self(),(vm_address_t)path,(vm_size_t)pathLength);
    }

    /*  RELEASE THE SPEAKFILE BUTTON  */
    [speakFileButton highlight:NO];

    return self;
}



- speakFile:sender
{
    if (fileStream) {
	if (toFile) {
	    /*  RUN THE SAVE PANEL, TO GET THE FILE NAME  */
	    if ([savePanel runModal] == NX_OKTAG) {
		/*  IF OK, SYNTHESIZE TO THE SPECIFIED FILE  */
		[mySpeaker speakStream:fileStream toFile:[savePanel filename]];
	    }
	}
	else {
	    if ([mySpeaker speakStream:fileStream] == TTS_DSP_TOO_SLOW) {
		/*  WARN THE USER IF THE VOCAL TRACT LENGTH TOO SHORT  */
		[self warnUser];
	    }
	}

	mode = MODE_FILESTREAM;
    }
    else if (filename) {
	if (toFile) {
	    /*  RUN THE SAVE PANEL, TO GET THE FILE NAME  */
	    if ([savePanel runModal] == NX_OKTAG) {
		/*  IF OK, SYNTHESIZE TO THE SPECIFIED FILE  */
		[mySpeaker speakText:filename
			   toFile:[savePanel filename]];
	    }
	}
	else {
	    if ([mySpeaker speakText:filename] == TTS_DSP_TOO_SLOW) {
		/*  WARN THE USER IF THE VOCAL TRACT LENGTH TOO SHORT  */
		[self warnUser];
	    }
	}

	mode = MODE_FILENAME;
    }
    else {
	NXBeep();
	mode = MODE_NONE;
    }

    [NXApp setModeToScratchpad];
    return self;
}



- toFileButtonPushed:sender
{
    toFile = [sender state];
    return self;
}



- repeat
{
    tts_error_t returnCode = TTS_OK;


    if ((mode == MODE_TEXTBUFFER) && textBuffer) {
	if (toFile) {
	    /*  RUN THE SAVE PANEL, TO GET THE FILE NAME  */
	    if ([savePanel runModal] == NX_OKTAG) {
		/*  IF OK, SYNTHESIZE TO THE SPECIFIED FILE  */
		[mySpeaker speakText:textBuffer toFile:[savePanel filename]];
	    }
	}
	else {
	    returnCode = [mySpeaker speakText:textBuffer];
	}
    }
    else if ((mode == MODE_FILESTREAM) && fileStream) {
	if (toFile) {
	    /*  RUN THE SAVE PANEL, TO GET THE FILE NAME  */
	    if ([savePanel runModal] == NX_OKTAG) {
		/*  IF OK, SYNTHESIZE TO THE SPECIFIED FILE  */
		[mySpeaker speakStream:fileStream toFile:[savePanel filename]];
	    }
	}
	else {
	    returnCode = [mySpeaker speakStream:fileStream];
	}
    }
    else if ((mode == MODE_FILENAME) && filename) {
	if (toFile) {
	    /*  RUN THE SAVE PANEL, TO GET THE FILE NAME  */
	    if ([savePanel runModal] == NX_OKTAG) {
		/*  IF OK, SYNTHESIZE TO THE SPECIFIED FILE  */
		[mySpeaker speakText:filename
			   toFile:[savePanel filename]];
	    }
	}
	else {
	    returnCode = [mySpeaker speakText:filename];
	}
    }
    else
	NXBeep();

    /*  WARN THE USER IF THE VOCAL TRACT LENGTH TOO SHORT  */
    if (returnCode == TTS_DSP_TOO_SLOW)
	[self warnUser];

    return self;
}

@end

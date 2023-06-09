/* Generated by Interface Builder */

/*  HEADER FILES  ************************************************************/
#import "BigMouth.h"
#import "Scratchpad.h"
#import <TextToSpeech/TextToSpeech.h>
#import <appkit/appkit.h>


/*  LOCAL DEFINES  ***********************************************************/
#define MODE_NONE               0
#define MODE_TEXTBUFFER         1
#define MODE_FILESTREAM         2
#define MODE_FILENAME           3
#define MODE_SCRATCHPAD         4




@implementation BigMouth

- appDidInit:sender
{
    /*  CONNECT TO THE TEXT-TO-SPEECH SERVER  */
    [self connectToTTSServer];

    /*  SET THIS OBJECT AS THE SERVICES DELEGATE  */
    [[NXApp appListener] setServicesDelegate:self];

    return self;
}



- connectToTTSServer
{
    /*  CONNECT TO THE TEXT-TO-SPEECH SERVER, IF NOT ALREADY CONNECTED  */
    if (!mySpeaker) {
	mySpeaker = [[TextToSpeech alloc] init];
	if (mySpeaker == nil) {
	    NXRunAlertPanel("No Connection Possible",
			    "Too many clients, or server cannot be started.",
			    "OK", NULL, NULL);
	    [NXApp terminate:self];
	}
    }

    return self;
}



- free
{
    /*  STOP ANY SPEAKING BEFORE QUITTING  */
    [mySpeaker eraseAllSound];

    /*  BE SURE TO SEVER CONNECTION WITH TEXT-TO-SPEECH SERVER  */
    [mySpeaker free];

    /*  BE SURE TO FREE MEMORY USED FOR PASTEBOARD  */
    if (textBuffer)
	vm_deallocate(task_self(),(vm_address_t)textBuffer, (vm_size_t)textLength);
    
    /*  CLOSE OLD MEMORY STREAM, INCLUDING ALL MEMORY IT USES  */
    if (fileStream)
	NXCloseMemory(fileStream, NX_FREEBUFFER);
    
    /*  FREE FILENAME MEMORY, IF NECESSARY  */
    if (filename)
	free(filename);

    /*  FREE SCRATCHPAD MEMORY, IF IT EXISTS  */
    if (scratchpad)
	[scratchpad free];

    /*  FREE OBJECT AS USUAL  */
    return [super free];
}



- ttsInstance
{
    return mySpeaker;
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



- (BOOL)appAcceptsAnotherFile:sender
{
    /*  THIS METHOD ENABLES COMMAND-DRAG OPENING OF A FILE OVER THE APP ICON  */
    return YES;
}



- (int)app:sender openFile:(const char *)pathname type:(const char *)aType
{
    /*  THIS METHOD SPEAKS THE COMMAND-DRAGGED FILE  */
    /*  UNHIDE THE APPLICATION, SO WE HAVE ACCESS TO REAL-TIME CONTROLS  */
    [self unhide:self];

    /*  MAKE SURE WE ARE CONNECTED TO THE TEXT-TO-SPEECH SERVER  */
    [self connectToTTSServer];

    /*  SPEAK THE FILE IF POSSIBLE, OR FILENAME  */
    [self speakFile:pathname];

    return YES;
}



- speak:pasteboard userData:(const char*)userData error:(char**)message
{
    /*  THIS METHOD SPEAKS DATA ENTERED VIA THE SERVICES PASTEBOARD  */
    const NXAtom *pasteboardType;
    
    /*  GET THE PASTEBOARD TYPE  */
    pasteboardType = [pasteboard types];
    
    /*  IF ASCII TEXT, READ THE TEXT INTO BUFFER FROM THE PASTEBOARD AND SPEAK IT  */
    if (*pasteboardType == NXAsciiPboardType) {
	/*  DEALLOCATE OLD TEXT BUFFER MEMORY IF NECESSARY  */
	if (textBuffer) {
	    vm_deallocate(task_self(),(vm_address_t)textBuffer,
			  (vm_size_t)textLength);
	    textBuffer = NULL;
	    textLength = 0;
	}
	
	/*  FILL THE BUFFER WITH THE CONTENTS OF THE PASTEBOARD  */
	if ([pasteboard readType:NXAsciiPboardType data:&textBuffer
			length:&textLength]) {
	    /*  MAKE SURE THE BUFFER IS NULL TERMINATED  */
	    textBuffer[textLength] = '\0';
	    
	    /*  SPEAK THE CONTENTS OF THE BUFFER  */
	    if ([mySpeaker speakText:textBuffer] == TTS_DSP_TOO_SLOW) {
		/*  WARN THE USER IF THE VOCAL TRACT LENGTH TOO SHORT  */
		[self warnUser];
	    }
	    
	    /*  SET THE MODE, IN CASE WE WANT TO SPEAK THE BUFFER AGAIN  */
	    mode = MODE_TEXTBUFFER;
	}
    }
    /*  IF FILENAME, SPEAK THE FILE'S CONTENTS  */
    else if (*pasteboardType == NXFilenamePboardType) {
	char *path;
	int pathLength;

	/*  GET THE PATH FROM THE PASTEBOARD  */
	if ([pasteboard readType:NXFilenamePboardType data:&path
			length:&pathLength]) {
	    /*  MAKE SURE PATH NAME IS NULL TERMINATED  */
	    path[pathLength] = '\0';

	    /*  SPEAK THE FILE IF POSSIBLE, OR FILENAME  */
	    [self speakFile:path];
	    
	    /*  DEALLOCATE OLD PATH BUFFER MEMORY IF NECESSARY  */
	    if (path)
		vm_deallocate(task_self(),(vm_address_t)path,(vm_size_t)pathLength);
	}
    }
    
    return self;
}



- speakFile:(const char *)pathname
{
    /*  CLOSE OLD MEMORY STREAM, INCLUDING ALL MEMORY IT USES  */
    if (fileStream) {
	NXCloseMemory(fileStream, NX_FREEBUFFER);
	fileStream = NULL;
    }
    
    /*  MEMORY MAP SPECIFIED INPUT FILE TO MEMORY STREAM  */
    if (fileStream = NXMapFile(pathname, NX_READONLY)) {
	/*  SPEAK MEMORY STREAM  */
	if ([mySpeaker speakStream:fileStream] == TTS_DSP_TOO_SLOW) {
	    /*  WARN THE USER IF THE VOCAL TRACT LENGTH TOO SHORT  */
	    [self warnUser];
	}
	
	/*  SET THE MODE, IN CASE WE WANT TO SPEAK THE BUFFER AGAIN  */
	mode = MODE_FILESTREAM;
    }
    else {
	/*  IF WE CAN'T READ THE CONTENTS OF THE FILE, THEN READ FILENAME  */
	char *ptr;
	
	/*  FREE FILENAME MEMORY, IF NECESSARY  */
	if (filename) {
	    free(filename);
	    filename = NULL;
	}
	
	/*  FIND FILENAME IN PATHNAME  */
	ptr = strrchr(pathname,'/') + 1;
	
	/*  IF THE FILENAME EXISTS, STORE IT AND SPEAK IT  */
	if (ptr && (strlen(ptr) > 0)) {
	    /*  ALLOCATE MEMORY AND STORE THE FILENAME (FOR REPEAT)  */
	    filename = (char *)malloc(strlen(ptr)+1);
	    strcpy(filename,ptr);
	    
	    /*  SPEAK THE FILENAME  */
	    if ([mySpeaker speakText:filename] == TTS_DSP_TOO_SLOW) {
		/*  WARN THE USER IF THE VOCAL TRACT LENGTH TOO SHORT  */
		[self warnUser];
	    }
	    
	    /*  SET THE MODE, IN CASE WE WANT TO SPEAK THE BUFFER AGAIN  */
	    mode = MODE_FILENAME;
	}
	else {
	    /*  THE FILENAME IS NOT SPEAKABLE, SO MERELY BEEP  */
	    NXBeep();
	    
	    /*  SET THE MODE SO THAT REPEAT HAS NO EFFECT  */
	    mode = MODE_NONE;
	}
    }

    return self;
}



- pause:sender
{
    [mySpeaker pauseImmediately];
    return self;
}


- continue:sender
{
    [mySpeaker continue];
    return self;
}


- stopSpeaking:sender
{
    [mySpeaker eraseAllSound];
    return self;
}



- repeat:sender
{
    tts_error_t returnCode = TTS_OK;


    /*  REPEATS PREVIOUSLY SPOKEN BUFFER, IF POSSIBLE  */
    if ((mode == MODE_TEXTBUFFER) && textBuffer)
	returnCode = [mySpeaker speakText:textBuffer];
    else if ((mode == MODE_FILESTREAM) && fileStream)
	returnCode = [mySpeaker speakStream:fileStream];
    else if ((mode == MODE_FILENAME) && filename)
	returnCode = [mySpeaker speakText:filename];
    else if (mode == MODE_SCRATCHPAD)
	[scratchpad repeat];
    else
	NXBeep();

    /*  WARN THE USER IF THE VOCAL TRACT LENGTH TOO SHORT  */
    if (returnCode == TTS_DSP_TOO_SLOW)
	[self warnUser];

    return self;
}



- setModeToScratchpad
{
    mode = MODE_SCRATCHPAD;
    return self;
}



- showInfo:sender
{
    /*  LOAD THE NIB CONTAINING THE INFO PANEL, IF NECESSARY  */
    if (infoPanel == nil) {
	if (![NXApp loadNibSection:"info.nib" owner:self withNames:NO])
	    return nil;
    }

    /*  MAKE THE INFO PANEL VISIBLE  */
    [infoPanel makeKeyAndOrderFront:nil];

    return self;
}



- showPreferences:sender
{
    /*  LOAD THE NIB CONTAINING THE PREFERENCES WINDOW, IF NECESSARY  */
    if (preferencesWindow == nil) {
	if (![NXApp loadNibSection:"preferences.nib" owner:self withNames:NO])
	    return nil;
    }

    /*  MAKE THE WINDOW VISIBLE  */
    [preferencesWindow makeKeyAndOrderFront:nil];

    return self;
}



- showScratchpadWindow:sender
{
    /*  LOAD THE NIB CONTAINING THE PREFERENCES WINDOW, IF NECESSARY  */
    if (scratchpadWindow == nil) {
	if (![NXApp loadNibSection:"scratchpad.nib" owner:self withNames:NO])
	    return nil;
    }

    /*  MAKE THE WINDOW VISIBLE  */
    [scratchpadWindow makeKeyAndOrderFront:nil];

    return self;
}

@end

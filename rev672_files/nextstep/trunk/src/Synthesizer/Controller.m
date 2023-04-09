/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/Controller.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

# Revision 1.2  1994/07/13  03:39:54  len
# Added Mono/Stereo sound output option and changed file format.
#
# Revision 1.1.1.1  1994/05/20  00:21:53  len
# Initial archive of TRM interactive Synthesizer.
#

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "Controller.h"
#import "GlottalSource.h"
#import "NoiseSource.h"
#import "Throat.h"
#import "ResonantSystem.h"
#import "Synthesizer.h"
#import "Analysis.h"
#import <stdlib.h>
#import <stdio.h>
#include <math.h>


/*  LOCAL DEFINES  ***********************************************************/
#define FILENAME_DEF @"Untitled.trm"
#define FILETYPE @"trm"

#define VOLUME_MIN            0
#define VOLUME_MAX            60
#define VOLUME_DEF            VOLUME_MAX

#define BALANCE_MIN           (-1.0)
#define BALANCE_MAX           (+1.0)
#define BALANCE_DEF           0.0

#define CHANNELS_MIN          1
#define CHANNELS_MAX          2
#define CHANNELS_DEF          CHANNELS_MAX

#define CONTROL_RATE_MIN      1
#define CONTROL_RATE_MAX      1000
#define CONTROL_RATE_DEF      500

#define ANALYSIS_ENABLED_DEF  NO

#define SUCCESS               1
#define FAILURE               0

#define CURRENT_FILE_VERSION  2



@implementation Controller

- init
{
    /*  DO REGULAR INITIALIZATION  */
    [super init];

    /*  SET DEFAULT INSTANCE VARIABLES  */
    [self defaultInstanceVariables];

    /*  SOME IVARS ARE SET ONLY AT INIT TIME  */
    analysisEnabled = ANALYSIS_ENABLED_DEF;

    /*  CREATE SAVE PANEL  */
    savePanel = [NSSavePanel savePanel];
    [savePanel setRequiredFileType:FILETYPE];
    [savePanel setTitle:@"Save As"];

    /*  CREATE OPEN PANEL  */
    openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];

    /*  CREATE MEMORY FOR PATH NAME  */
    path = (char *)malloc(MAXPATHLEN+1);

    /*  LOAD PATHNAME WITH DEFAULT   */
    sprintf(path, "%s/%s", [NSHomeDirectory() cString], [FILENAME_DEF cString]);

    /*  SET FLAG INDICATING NO VALID FILE TO SAVE TO  */
    validPath = NO;

    return self;
}



- (void)dealloc
{
    /*  FREE THE SAVE PANEL  */
    [savePanel release];

    /*  FREE THE OPEN PANEL  */
    [openPanel release];

    /*  FREE MEMORY FOR PATH NAME  */
    free(path);

    /*  DO REGULAR FREE  */
    [super dealloc];
}



- (void)defaultInstanceVariables
{
    /*  SET DEFAULTS  */
    volume = VOLUME_DEF;
    balance = BALANCE_DEF;
    channels = CHANNELS_DEF;
    controlRate = CONTROL_RATE_DEF; 
}



- (void)awakeFromNib
{
    /*  USE OPTIMIZED DRAWING IN THE WINDOW  */
    [controlWindow useOptimizedDrawing:YES];

    /*  SAVE THE FRAME FOR THE WINDOW  */
    [controlWindow setFrameAutosaveName:@"controlWindow"];

    /*  SET MINIMUM AND MAXIMUM VALUES OF SLIDERS  */
    [volumeSlider setMinValue:VOLUME_MIN];
    [volumeSlider setMaxValue:VOLUME_MAX];
    [balanceSlider setMinValue:BALANCE_MIN];
    [balanceSlider setMaxValue:BALANCE_MAX];

    /*  SET FORMAT OF FIELDS AND SLIDERS  */
    [balanceField setFloatingPointFormat:NO left:2 right:2];

    /*  DISPLAY ANALYSIS BUTTON  */
    [analysisEnabledButton setState:analysisEnabled];
    [analysis setAnalysisEnabled:analysisEnabled];
}



- (void)displayAndSynthesizeIvars
{
    /*  DISPLAY MASTER VOLUME AND SEND TO SYNTHESIZER  */
    [volumeField setIntValue:volume];
    [volumeSlider setIntValue:volume];
    [synthesizer setMasterVolume:volume];

    /*  DISPLAY BALANCE AND SEND TO SYNTHESIZER  */
    [balanceField setDoubleValue:balance];
    [balanceSlider setDoubleValue:balance];
    [synthesizer setBalance:balance];

    /*  DISPLAY NUMBER OF CHANNELS, AND SEND TO SYNTHESIZER  */
    [channelsPopUp selectItemAtIndex:[channelsPopUp indexOfItemWithTag: channels]];
    [channelsPopUp setTitle: [channelsPopUp titleOfSelectedItem]];
    [self setBalanceControls:channels];
    [synthesizer setChannels:channels];

    /*  DISPLAY CHANGES TO SUBVIEWS OF WINDOW  */
    [controlWindow displayIfNeeded]; 
}



- (void)saveToStream:(NSArchiver *)typedStream
{
    /*  WRITE INSTANCE VARIABLES TO TYPED STREAM  */
    [typedStream encodeValuesOfObjCTypes:"idii", &volume, &balance, &channels, &controlRate]; 
}

- (void)openFromStream:(NSArchiver *)typedStream
{
    /*  READ INSTANCE VARIABLES FROM TYPED STREAM  */
    [typedStream decodeValuesOfObjCTypes:"idii", &volume, &balance, &channels, &controlRate];

    /*  DISPLAY THE NEW VALUES  */
    [self displayAndSynthesizeIvars]; 
}

#ifdef NeXT
- (void)_openFromStream:(NXTypedStream *)typedStream
{
    /*  READ INSTANCE VARIABLES FROM TYPED STREAM  */
    NXReadTypes(typedStream, "idii", &volume, &balance, &channels, &controlRate);

    /*  DISPLAY THE NEW VALUES  */
    [self displayAndSynthesizeIvars]; 
}
#endif



- (void)volumeFieldEntered:sender
{
    BOOL rangeError = NO;

    /*  GET THE CURRENT ROUNDED VALUE  */
    int currentValue = (int)rint([sender doubleValue]);

    /*  MAKE SURE VALUE IS IN RANGE  */
    if (currentValue < VOLUME_MIN) {
	rangeError = YES;
	currentValue = VOLUME_MIN;
    }
    else if (currentValue > VOLUME_MAX) {
	rangeError = YES;
	currentValue = VOLUME_MAX;
    }

    /*  SET THE FIELD TO THE ROUNDED, CORRECTED VALUE  */
    [sender setIntValue:currentValue];

    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != volume) {
	/*  SET INSTANCE VARIABLE  */
	volume = currentValue;

	/*  SET SLIDER TO NEW VALUE  */
	[volumeSlider setIntValue:volume];

	/*  SEND VOLUME TO SYNTHESIZER  */
	[synthesizer setMasterVolume:volume];

	/*  SET DIRTY BIT  */
	[self setDirtyBit];
    }

    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
	NSBeep();
	[sender selectText:self];
    } 
}

- (void)volumeSliderMoved:sender
{
    /*  GET CURRENT VALUE  */
    int currentValue = [sender intValue];

    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != volume) {
	/*  SET INSTANCE VARIABLE  */
	volume = currentValue;

	/*  SET FIELD DISPLAY  */
	[volumeField setIntValue:volume];

	/*  SEND VOLUME TO SYNTHESIZER  */
	[synthesizer setMasterVolume:volume];

	/*  SET DIRTY BIT  */
	[self setDirtyBit];
    } 
}



- (void)balanceFieldEntered:sender
{
    BOOL rangeError = NO;

    /*  GET THE CURRENT VALUE  */
    double currentValue = [sender doubleValue];

    /*  MAKE SURE VALUE IS IN RANGE  */
    if (currentValue < BALANCE_MIN) {
	rangeError = YES;
	currentValue = BALANCE_MIN;
    }
    else if (currentValue > BALANCE_MAX) {
	rangeError = YES;
	currentValue = BALANCE_MAX;
    }

    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != balance) {
	/*  SET INSTANCE VARIABLE  */
	balance = currentValue;
	
	/*  SET SLIDER TO NEW VALUE  */
	[balanceSlider setDoubleValue:balance];

	/*  SEND BALANCE TO SYNTHESIZER  */
	[synthesizer setBalance:balance];

	/*  SET DIRTY BIT  */
	[self setDirtyBit];
    }

    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
	NSBeep();
	[sender setDoubleValue:currentValue];
	[sender selectText:self];
    } 
}

- (void)balanceSliderMoved:sender
{
    double currentValue;

    /*  SET FIELD DISPLAY  */
    [balanceField setDoubleValue:[sender doubleValue]];
    
    /*  GET CURRENT VALUE (FIELD USES FIXED FORMAT)  */
    currentValue = [balanceField doubleValue];

    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != balance) {
	/*  SET INSTANCE VARIABLE  */
	balance = currentValue;

	/*  SEND BALANCE TO SYNTHESIZER  */
	[synthesizer setBalance:balance];

	/*  SET DIRTY BIT  */
	[self setDirtyBit];
    } 
}



- (void)setBalanceControls:(int)numberChannels
{
    /*  ENABLE OR DISABLE STEREO BALANCE CONTROLS  */
    if (numberChannels == 1) {
	[balanceField setEnabled:NO];
	[balanceSlider setEnabled:NO];
	[balanceLabelLeft setTextColor:[NSColor darkGrayColor]];
	[balanceLabelRight setTextColor:[NSColor darkGrayColor]];
    }
    else {
	[balanceField setEnabled:YES];
	[balanceSlider setEnabled:YES];
	[balanceLabelLeft setTextColor:[NSColor blackColor]];
	[balanceLabelRight setTextColor:[NSColor blackColor]];
    } 
}



- (void)channelsSelected:sender
{
    /*  RECORD THE NUMBER OF CHANNELS  */
    int currentValue = [[sender selectedCell] tag];

    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != channels) {
	/*  SET INSTANCE VARIABLE  */
	channels = currentValue;

	/*  SEND CHANNELS TO SYNTHESIZER  */
	[synthesizer setChannels:channels];

	/*  ENABLE OR DISABLE STEREO BALANCE CONTROLS  */
	[self setBalanceControls:channels];

	/*  SET DIRTY BIT  */
	[self setDirtyBit];

	/*  DISPLAY CHANGES TO SUBVIEWS OF WINDOW  */
	[controlWindow displayIfNeeded];
    } 
}



- (void)resetToDefault:sender
{
    /*  TELL SYNTHESIZER WE ARE LOADING COMPLETE SET OF PARAMETERS  */
    [synthesizer beginLoading];

    /*  SET IVARS TO DEFAULT IN EACH OBJECT  */
    [glottalSource defaultInstanceVariables];
    [noiseSource defaultInstanceVariables];
    [throat defaultInstanceVariables];
    [resonantSystem defaultInstanceVariables];
    [analysis defaultInstanceVariables];
    [estimation defaultInstanceVariables];
    [self defaultInstanceVariables];

    /*  DISPLAY AND SEND THE NEW PARAMETERS TO THE SYNTHESIZER  */
    [glottalSource displayAndSynthesizeIvars];
    [noiseSource displayAndSynthesizeIvars];
    [throat displayAndSynthesizeIvars];
    [resonantSystem displayAndSynthesizeIvars];
    [analysis displayAndSynthesizeIvars];
    [estimation displayAndSynthesizeIvars];
    [self displayAndSynthesizeIvars];

    /*  TELL THE SYNTHESIZER WE ARE FINISHED LOADING PARAMETERS  */
    [synthesizer endLoading];

    /*  SET OR CLEAR DIRTY BIT, DEPENDING ON CURRENT STATE  */
    if (validPath)
	[self setDirtyBit];
    else
	[self clearDirtyBit]; 
}



- (void)resetToFile:sender
{
    [self openFromFile:[NSString stringWithCString:path]];

    /*  CLEAR DIRTY BIT  */
    [self clearDirtyBit]; 
}



- (void)runButtonPushed:sender
{
    /*  TOGGLE SYNTHESIZER OFF OR ON  */
    if ([sender state]) {
	[synthesizer beginRunning:sender :analysisEnabled];
	/*  DON'T ALLOW CHANGE OF ANALYSIS ENABLED WHILE RUNNING  */
	[analysisEnabledButton setEnabled:NO];
	/*  SIGNAL RUNNING STATUS TO ANALYSIS OBJECT  */
	[analysis setRunning:YES];
	/*  SIGNAL RUNNING STATUS TO ESTIMATION OBJECT  */
	[estimation setRunning:YES];
    }
    else {
	[synthesizer endRunning:sender];
	/*  ALLOW CHANGE OF ANALYSIS ENABLED WHEN STOPPED  */
	[analysisEnabledButton setEnabled:YES];
	/*  SIGNAL RUNNING STATUS TO ANALYSIS OBJECT  */
	[analysis setRunning:NO];
	/*  SIGNAL RUNNING STATUS TO ESTIMATION OBJECT  */
	[estimation setRunning:NO];
    } 
}



- (void)analysisEnabledButtonPushed:sender
{
    /*  RECORD STATE  */
    analysisEnabled = [sender state];

    /*  ENABLE OR DISABLE ANALYSIS CONTROL  */
    [analysis setAnalysisEnabled:analysisEnabled]; 
}



- (void)open:sender
{
    NSArray *fileTypes = [NSArray arrayWithObject: FILETYPE];

    /*  IF DIRTY BIT SET, ASK TO SAVE CURRENT STATE TO FILE?  */
    if ([controlWindow isDocumentEdited]) {
	int returnValue;
	if (validPath) {
	    returnValue = NSRunAlertPanel(@"", @"Save changes to %s?", @"Yes", @"No", @"Cancel", path);
	    /*  SAVE TO CURRENT PATH, IF YES BUTTON PUSHED  */
	    if (returnValue == NSAlertDefaultReturn)
		[self saveToFile:[NSString stringWithCString:path]];
	    /*  CANCEL APPLICATION TERMINATION, IF CANCEL BUTTON PUSHED  */
	    else if (returnValue == NSAlertOtherReturn)
		return;
	}
	else {
	    returnValue = NSRunAlertPanel(@"", @"Save changes to File?", @"Yes", @"No", @"Cancel");
	    /*  BRING UP "SAVE AS" PANEL, IF YES BUTTON PUSHED  */
	    if (returnValue == NSAlertDefaultReturn) {
	      [self saveAs:self];
	    }
	    /*  CANCEL APPLICATION TERMINATION, IF CANCEL BUTTON PUSHED  */
	    else if (returnValue == NSAlertOtherReturn)
		return;
	}
    }

    /*  RUN OPEN PANEL  */
    if ([openPanel runModalForTypes:fileTypes] == NSOKButton) {
	if ([self openFromFile:[openPanel filename]] == SUCCESS) {
	    /*  SAVE NEW PATH  */
	    strcpy(path, [[openPanel filename] cString]);

	    /*  INDICATE WE HAVE A VALID PATH TO SAVE TO  */
	    validPath = YES;

	    /*  ENABLE "RESET TO FILE" BUTTON  */
	    [resetToFileButton setEnabled:YES];
	    
	    /*  PUT NEW PATH INTO WINDOW TITLE BAR  */
	    [resonantSystem setTitle:[NSString stringWithCString:path]];

	    /*  CLEAR DIRTY BIT  */
	    [self clearDirtyBit];
	}
    } 
}



- (void)save:sender
{
    /*  SAVE IMMEDIATELY, IF WE HAVE A VALID FILE TO SAVE TO  */
    if (validPath)
	[self saveToFile:[NSString stringWithCString:path]];
    /*  ELSE, USE SAVE AS PANEL  */
    else
	[self saveAs:self]; 
}



- (void)saveAs:sender
{
    char directory[MAXPATHLEN], *filename;

    /*  PARSE CURRENT PATH FOR DIRECTORY AND FILENAME  */
    strcpy(directory, path);
    filename = rindex(directory, '/') + 1;
    *(filename-1) = '\0';

    /*  RUN SAVE PANEL, SAVING TO FILE, IF ASKED  */
    if ([savePanel runModalForDirectory:@"" file:@""] == NSOKButton) {
	if ([self saveToFile:[savePanel filename]] == SUCCESS) {
	    /*  SAVE NEW PATH  */
	    strcpy(path, [[savePanel filename] cString]);

	    /*  INDICATE WE HAVE A VALID PATH TO SAVE TO  */
	    validPath = YES;
	    
	    /*  ENABLE "RESET TO FILE" BUTTON  */
	    [resetToFileButton setEnabled:YES];
	    
	    /*  PUT NEW PATH INTO WINDOW TITLE BAR  */
	    [resonantSystem setTitle:[NSString stringWithCString:path]];

	    /*  CLEAR THE DIRTY BIT  */
	    [self clearDirtyBit];
	}
    }
}



- (int)saveToFile:(NSString *)filename
{
    NSMutableData *mdata = [NSMutableData data];
        /*  OPEN STREAM FOR WRITING  */
    NSArchiver *typedStream =
	[[NSArchiver alloc] initForWritingWithMutableData: mdata];
    
    /*  WARN USER IF INVALID FILE FOR WRITING  */
    if (typedStream == NULL) {
	NSRunAlertPanel(@"", @"Unable to open file for writing.", @"", nil, nil);
	return FAILURE;
    }
    
NS_DURING

    /*  WRITE VERSION NUMBER TO STREAM  */
    fileVersion = CURRENT_FILE_VERSION;
    [typedStream encodeValuesOfObjCTypes:"i", &fileVersion];

    /*  WRITE PARAMETERS TO STREAM  */
    [glottalSource saveToStream:typedStream];
    [noiseSource saveToStream:typedStream];
    [throat saveToStream:typedStream];
    [resonantSystem saveToStream:typedStream];
    [self saveToStream:typedStream];
    [analysis saveToStream:typedStream];
    [estimation saveToStream:typedStream];
    
    /*  CLOSE THE TYPED STREAM  */
    [mdata writeToFile: filename atomically: NO]; 
    [typedStream release];

NS_HANDLER    

    /*  WARN USER IF EXCEPTION RAISED WHILE WRITING  */
    NSRunAlertPanel(@"", @"Error while writing file.", @"", nil, nil);
    return FAILURE;

NS_ENDHANDLER

    /*  CLEAR THE DIRTY BIT  */
    [self clearDirtyBit];
	
    /*  INDICATE SUCCESSFUL SAVE  */
    return SUCCESS;
}


- (int)openFromFile:(NSString *)filename
{
    /*  OPEN STREAM FOR WRITING  */
    NSArchiver *typedStream =
	[[NSUnarchiver alloc] initForReadingWithData:[NSData dataWithContentsOfFile:filename]];
    
    /*  WARN USER IF INVALID FILE FOR READING  */
    if (typedStream == NULL) {
	NSRunAlertPanel(@"", @"Unable to open file for reading.", @"", nil, nil);
	return FAILURE;
    }
    
NS_DURING

    /*  TELL SYNTHESIZER WE ARE LOADING COMPLETE SET OF PARAMETERS  */
    [synthesizer beginLoading];

    /*  READ FILE VERSION FROM STREAM  */
    [typedStream decodeValuesOfObjCTypes:"i", &fileVersion];

    /*  READ PARAMETERS FROM STREAM  */
    [glottalSource openFromStream:typedStream];
    [noiseSource openFromStream:typedStream];
    [throat openFromStream:typedStream];
    [resonantSystem openFromStream:typedStream];
    [self openFromStream:typedStream];
    [analysis openFromStream:typedStream];
    /*  ESTIMATION MODULE ADDED IN FILE VERSION 2  */
    if (fileVersion >= 2)
	[estimation openFromStream:typedStream];
    
    /*  CLOSE THE TYPED STREAM  */
    [typedStream release];

    /*  TELL THE SYNTHESIZER WE ARE FINISHED LOADING PARAMETERS  */
    [synthesizer endLoading];

NS_HANDLER    

    /*  WARN USER IF EXCEPTION RAISED WHILE READING  */
    NSRunAlertPanel(@"", @"Error while reading file.", @"", nil, nil);

    /*  TELL THE SYNTHESIZER WE ARE FINISHED LOADING PARAMETERS  */
    [synthesizer endLoading];

    return FAILURE;

NS_ENDHANDLER
	
    /*  INDICATE SUCCESSFUL READ  */
    return SUCCESS;
}

#ifdef NeXT
- (int)_openFromFile:(NSString *)filename
{
    /*  OPEN STREAM FOR WRITING  */
    NXTypedStream *typedStream =
      NXOpenTypedStreamForFile(filename, NX_READONLY);
    
    /*  WARN USER IF INVALID FILE FOR READING  */
    if (typedStream == NULL) {
	NSRunAlertPanel(@"", @"Unable to open file for reading.", @"", nil, nil);
	return FAILURE;
    }
    
NS_DURING

    /*  TELL SYNTHESIZER WE ARE LOADING COMPLETE SET OF PARAMETERS  */
    [synthesizer beginLoading];

    /*  READ FILE VERSION FROM STREAM  */
    NXReadTypes(typedStream, "i", &fileVersion);

    /*  READ PARAMETERS FROM STREAM  */
    [glottalSource _openFromStream:typedStream];
    [noiseSource _openFromStream:typedStream];
    [throat _openFromStream:typedStream];
    [resonantSystem _openFromStream:typedStream];
    [self _openFromStream:typedStream];
    [analysis _openFromStream:typedStream];
    /*  ESTIMATION MODULE ADDED IN FILE VERSION 2  */
    if (fileVersion >= 2)
	[estimation _openFromStream:typedStream];
    
    /*  CLOSE THE TYPED STREAM  */
    NXCloseTypedStream(typedStream);

    /*  TELL THE SYNTHESIZER WE ARE FINISHED LOADING PARAMETERS  */
    [synthesizer endLoading];

NS_HANDLER    

    /*  WARN USER IF EXCEPTION RAISED WHILE READING  */
    NSRunAlertPanel(@"", @"Error while reading file.", @"", nil, nil);

    /*  TELL THE SYNTHESIZER WE ARE FINISHED LOADING PARAMETERS  */
    [synthesizer endLoading];

    return FAILURE;

NS_ENDHANDLER
	
    /*  INDICATE SUCCESSFUL READ  */
    return SUCCESS;
}
#endif



- (void)windowWillMiniaturize:sender
{
    [sender setMiniwindowImage:[NSImage imageNamed:@"Synthesizer.tiff"]];
}



- (int)application:sender openFile:(NSString *)filename
{
    /*  RETURN IMMEDIATELY, IF WRONG FILE TYPE  */
    if (![[filename pathExtension] isEqualToString:FILETYPE])
	return NO;

    /*  TRY TO OPEN THE FILE  */
    if ([self openFromFile:filename] == SUCCESS) {
	/*  SAVE NEW PATH  */
	strcpy(path, [filename cString]);
	
	/*  INDICATE WE HAVE A VALID PATH TO SAVE TO  */
	validPath = YES;
	
	/*  ENABLE "RESET TO FILE" BUTTON  */
	[resetToFileButton setEnabled:YES];
	
	/*  PUT NEW PATH INTO WINDOW TITLE BAR  */
	[resonantSystem setTitle:[NSString stringWithCString:path]];
    }
    /*  RETURN NO, IF FILE CAN'T BE OPENED AND READ FROM  */
    else
	return NO;
    
    return YES;
}



- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    /*  DISPLAY DEFAULT INSTANCE VARIABLES, IF NOT LOADING FROM FILE  */
    if (!validPath) {
	[glottalSource displayAndSynthesizeIvars];
	[noiseSource displayAndSynthesizeIvars];
	[throat displayAndSynthesizeIvars];
	[resonantSystem displayAndSynthesizeIvars];
	[analysis displayAndSynthesizeIvars];
	[estimation displayAndSynthesizeIvars];
	[self displayAndSynthesizeIvars];	
    }

    /*  CLEAR DIRTY BIT  */
    [self clearDirtyBit];
}



- (BOOL)applicationShouldTerminate:(id)sender
{
    /*  STOP SYNTHESIZER IF RUNNING  */
    if ([runButton state])
	[runButton performClick:self];

    /*  IF DIRTY BIT SET, ASK TO SAVE TO FILE?  */
    if ([controlWindow isDocumentEdited]) {
	int returnValue;
	if (validPath) {
	    returnValue = NSRunAlertPanel(@"", @"Save changes to %s?", @"Yes", @"No", @"Cancel", path);
	    /*  SAVE TO CURRENT PATH, IF YES BUTTON PUSHED  */
	    if (returnValue == NSAlertDefaultReturn)
		[self saveToFile:[NSString stringWithCString:path]];
	    /*  CANCEL APPLICATION TERMINATION, IF CANCEL BUTTON PUSHED  */
	    else if (returnValue == NSAlertOtherReturn)
		return NO;
	}
	else {
	    returnValue = NSRunAlertPanel(@"", @"Save changes to File?", @"Yes", @"No", @"Cancel");
	    /*  BRING UP "SAVE AS" PANEL, IF YES BUTTON PUSHED  */
	    if (returnValue == NSAlertDefaultReturn) {
	      [self saveAs:self];
	    }
	    /*  CANCEL APPLICATION TERMINATION, IF CANCEL BUTTON PUSHED  */
	    else if (returnValue == NSAlertOtherReturn)
		return NO;
	}
    }

    /*  ALLOW APP TO TERMINATE  */
    return YES;
}



- (void)showInfo:sender
{
    if (infoPanel == nil) {
	if (![NSBundle loadNibNamed:@"info.nib" owner:self])
	    return;
    }

    [infoPanel makeKeyAndOrderFront:nil]; 
}



- (void)setDirtyBit
{
    /*  SET BIT & REFLECT CHANGE IN WINDOW'S CLOSE BUTTON  */
    [controlWindow setDocumentEdited:YES]; 
}

- (void)clearDirtyBit
{
    /*  CLEAR BIT & REFLECT CHANGE IN WINDOW'S CLOSE BUTTON  */
    [controlWindow setDocumentEdited:NO]; 
}

@end

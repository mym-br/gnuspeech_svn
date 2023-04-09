/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/Controller.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.2  1994/07/13  03:39:52  len
 * Added Mono/Stereo sound output option and changed file format.
 *
 * Revision 1.1.1.1  1994/05/20  00:21:57  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

#import <AppKit/AppKit.h>

@interface Controller:NSObject
{
    id	volumeField;
    id	volumeSlider;
    id	balanceField;
    id	balanceSlider;
    id  balanceLabelLeft;
    id  balanceLabelRight;
    id  resetToFileButton;
    id  runButton;
    id	controlWindow;
    id  analysisEnabledButton;
    id  channelsPopUp;

    id	glottalSource;
    id	noiseSource;
    id	resonantSystem;
    id	synthesizer;
    id	throat;
    id  analysis;
    id  estimation;

    id  savePanel;
    id  openPanel;
    char *path;
    BOOL validPath;

    id infoPanel;

    int volume;
    double balance;
    int channels;
    int controlRate;
    int fileVersion;
    BOOL analysisEnabled;
}

- (void)defaultInstanceVariables;
- (void)awakeFromNib;
- (void)displayAndSynthesizeIvars;

- (void)saveToStream:(NSArchiver *)typedStream;
- (void)openFromStream:(NSArchiver *)typedStream;

- (void)volumeFieldEntered:sender;
- (void)volumeSliderMoved:sender;

- (void)balanceFieldEntered:sender;
- (void)balanceSliderMoved:sender;

- (void)setBalanceControls:(int)numberChannels;
- (void)channelsSelected:sender;

- (void)resetToDefault:sender;
- (void)resetToFile:sender;
- (void)runButtonPushed:sender;

- (void)analysisEnabledButtonPushed:sender;

- (void)open:sender;
- (void)save:sender;
- (void)saveAs:sender;
- (int)saveToFile:(NSString *)filename;
- (int)openFromFile:(NSString *)filename;

- (void)windowWillMiniaturize:sender;
- (int)application:sender openFile:(NSString *)filename;

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (BOOL)applicationShouldTerminate:(id)sender;
- (void)showInfo:sender;

- (void)setDirtyBit;
- (void)clearDirtyBit;
@end

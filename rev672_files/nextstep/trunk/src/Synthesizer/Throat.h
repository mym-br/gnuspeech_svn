/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/Throat.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.1.1.1  1994/05/20  00:21:51  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

#import <AppKit/AppKit.h>

@interface Throat:NSObject
{
    id	cutoffField;
    id	cutoffSlider;
    id	lowpassView;
    id	scaleSwitch;
    id	volumeField;
    id	volumeSlider;
    id  throatWindow;
    id  resonantSystem;
    id  synthesizer;
    id  controller;
    id  throatMenuItem;

    int throatVolume;
    int throatCutoff;
    int responseScale;
}

- (void)defaultInstanceVariables;

- (void)awakeFromNib;
- (void)displayAndSynthesizeIvars;

- (void)saveToStream:(NSArchiver *)typedStream;
- (void)openFromStream:(NSArchiver *)typedStream;

- (void)cutoffEntered:sender;
- (void)cutoffSliderMoved:sender;
- (void)scaleSwitchPushed:sender;
- (void)volumeEntered:sender;
- (void)volumeSliderMoved:sender;

- (void)windowWillMiniaturize:sender;
@end

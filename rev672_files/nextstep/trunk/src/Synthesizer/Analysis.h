/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/Analysis.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.1.1.1  1994/05/20  00:21:52  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

#import <AppKit/AppKit.h>

@interface Analysis:NSObject
{
    id  analysisWindow;
    id	magnitudeForm;
    id	magnitudePopUp;
    id  magnitudeLabel;
    id	binSizeFrequency;
    id	binSizePopUp;
    id	doAnalysisButton;
    id	grayLevelPopUp;
    id  normalizeSwitch;
    id	rateForm;
    id	rateSecond;
    id	spectrograph;
    id	spectrographGridButton;
    id	spectrum;
    id	spectrumGridButton;
    id	updateMatrix;
    id	windowForm;
    id	windowPopUp;
    id  synthesizer;

    id  soundDataObject;
    id  analysisDataObject;

    BOOL normalizeInput;
    int binSize;
    int windowType;
    float alpha;
    float beta;
    int grayLevel;
    int magnitudeScale;
    float linearUpperThreshold;
    float linearLowerThreshold;
    int logUpperThreshold;
    int logLowerThreshold;
    BOOL spectrographGrid;
    BOOL spectrumGrid;

    int updateMode;
    float updateRate;
    BOOL analysisEnabled;
    BOOL running;

    NSTimer *timedEntry;
}

- (void)defaultInstanceVariables;
- (void)awakeFromNib;
- (void)displayAndSynthesizeIvars;

- (void)saveToStream:(NSArchiver *)typedStream;
- (void)openFromStream:(NSArchiver *)typedStream;

- (void)windowWillMiniaturize:sender;

- (void)setAnalysisEnabled:(BOOL)flag;
- (void)setRunning:(BOOL)flag;

- (void)normalizeSwitchPushed:sender;
- (void)magnitudeFormEntered:sender;
- (void)magnitudeScaleSelected:sender;
- (void)binSizeSelected:sender;
- (void)doAnalysisButtonPushed:sender;
- (void)grayLevelSelected:sender;
- (void)rateFormEntered:sender;
- (void)spectrographGridPushed:sender;
- (void)spectrumGridPushed:sender;
- (void)updateMatrixPushed:sender;
- (void)windowFormEntered:sender;
- (void)windowSelected:sender;

- (void)displayAnalysis;

@end

/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/AnalysisData.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.1.1.1  1994/05/20  00:22:00  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

#import <AppKit/AppKit.h>

@interface AnalysisData:NSObject
{
    float *analysisData;
    int   windowSize;
    id    analysisWindow;
}

- init;
- (void)dealloc;
- (void)freeAnalysisData;

- (void)analyzeSoundData:soundDataObj windowSize:(int)size windowType:(int)type alpha:(float)alpha beta:(float)beta normalizeAmplitude:(BOOL)normalize;
- (const float *)analysisData;
- (int)windowSize;
- (int)spectrumSize;
- (BOOL)haveAnalyzedData;

@end

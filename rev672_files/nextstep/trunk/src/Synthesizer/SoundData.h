/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/SoundData.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.1.1.1  1994/05/20  00:22:04  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

#import <AppKit/AppKit.h>

@interface SoundData:NSObject
{
    float *soundData;
    int   soundDataSize;
    float largestMagnitude;
}

- init;
- (void)dealloc;
- (void)freeSoundData;

- (void)fillAndConvertStereoSoundData:(const short int *)data stereoDataSize:(int)size;
- (const float *)soundData;
- (int)soundDataSize;
- (BOOL)haveSoundData;
- (float)largestMagnitude;

@end

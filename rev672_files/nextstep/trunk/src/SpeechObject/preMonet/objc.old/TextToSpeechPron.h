/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:54 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/SpeechObject/preMonet/objc.old/TextToSpeechPron.h,v $
$State: Exp $


$Log: not supported by cvs2svn $

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "TextToSpeech.h"



@interface TextToSpeech(TextToSpeechPron)

/*  HIDDEN METHODS  */
- (const char *)pronunciation:(const char *)word:(short *)dict:(int)password;
- (const char *)linePronunciation:(const char *)line:(int)password;

@end

/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:53 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/SpeechObject/postMonet/objC.monet/headerFiles/TextToSpeechDemo.h,v $
$State: Exp $


$Log: not supported by cvs2svn $

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import <TextToSpeech/TextToSpeech.h>



@interface TextToSpeech(TextToSpeechDemo)

/*  HIDDEN METHODS  */
- (unsigned int) registeredHostId;
- (unsigned int) demoMode;
- (unsigned int) expiryDate;

@end

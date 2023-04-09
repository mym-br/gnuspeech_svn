/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:53 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/SpeechObject/postMonet/objC.monet/headerFiles/TextToSpeechPriority.h,v $
$State: Exp $


$Log: not supported by cvs2svn $

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import <TextToSpeech/TextToSpeech.h>



@interface TextToSpeech(TextToSpeechPriority)

/*  HIDDEN METHODS  */
- (int) getPriority;
- setPriority: (int) newPriority;

- (int) getQuantum;
- setQuantum: (int) newQuantum;

- (int) getPolicy;
- setPolicy: (int) newPolicy;

- (int) getSilencePrefill;
- setSilencePrefill:(int) newPrefill;

- (int) serverPID;

- inactiveServerKill:(BOOL) killFlag;
- (BOOL) inactiveKillQuery;

- requestServerRestart;

@end

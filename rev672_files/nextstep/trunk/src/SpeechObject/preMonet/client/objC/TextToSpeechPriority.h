#import "TextToSpeech.h"
#import <mach/policy.h>

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

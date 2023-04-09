#import <TextToSpeech/TextToSpeech.h>

@interface TextToSpeech(TextToSpeechPlus)

/*  HIDDEN METHODS  */
- (const char *)pronunciation:(const char *)word:(short *)dict:(int)password;
- (const char *)linePronunciation:(const char *)line:(int)password;

@end

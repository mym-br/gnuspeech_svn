
#import <appkit/appkit.h>
#import "FFTBrain.h"

@interface Brain:Object //;
{
  FFTBrain *newFFT;
  float offset;
  int FFTNum;
}

- newFFT:sender;
- loadFFTfile:sender;

- resyncWindows:sender;

@end

@interface Brain(ApplicationDelegate)

- appDidInit:sender;
- (BOOL) appAcceptsAnotherFile:sender;
- (int)app:sender openFile:(const char *)filename type:(const char *)aType;

@end

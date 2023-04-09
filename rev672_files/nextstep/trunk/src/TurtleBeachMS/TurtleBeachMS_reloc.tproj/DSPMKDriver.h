#ifndef __MK_DSPMKDriver_H___
#define __MK_DSPMKDriver_H___
#import <driverkit/i386/directDevice.h>

// added by len
#import "addons.h"
// end addition

#define DSPDRIVER_PAR_MONITOR "Monitor"
#define DSPDRIVER_PAR_SERIALPORTDEVICE "SerialPortDevice"
#define DSPDRIVER_PAR_ORCHESTRA "Orchestra"
#define DSPDRIVER_PAR_WAITSTATES "WaitStates"

@interface DSPMKDriver : IODirectDevice
{
    int baseIO;
    port_t owner;

    // added by len
    unsigned int irq;
    BOOL messagingOn;
    OutputQueueType outputQueue[OUTPUT_QUEUE_SIZE];
    int outputHead;
    int outputTail;
    int dmaOutRegionTag;
    int dmaOutWordCount;
    port_t dmaOutReplyPort;
    // end addition

}

+ (BOOL)probe: deviceDescription;
- initFromDeviceDescription: deviceDescription;

// added by len
- (void)setMessagingOn:(BOOL)flag;
- (BOOL)messagingOn;

- (void)initOutputQueue;
- (void)resetOutputQueue;
- (int)outputQueueFull;
- (void)pushOutputQueue:(DSPPagePtr)pageAddress:(int)regionTag:(BOOL)msgStarted
        :(BOOL)msgCompleted:(port_t)replyPort;
- (OutputQueueType *)popOutputQueue;
- (OutputQueueType *)pendingOutputMessage;

- (void)setDMAOutRegionTag:(int)regionTag wordCount:(int)wordCount
        replyPort:(port_t)replyPort;
- (void)resetDMAOut;

- (void)sendPageToDSP;
- (void)getSwappedShortsFromDSP;
// end addition

@end

#endif


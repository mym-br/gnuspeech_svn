/*  HEADERS  *****************************************************************/
#import <mach/message.h>
#import "dspdriver_types.h"


/*  LOCAL DEFINES  ***********************************************************/
#define NO_MSG                   0x00
#define DMA_IN                   0x04
#define DMA_OUT                  0x05

#define DSP_INT_DMA_IN           100
#define DSP_INT_DMA_OUT          101

#define OUTPUT_QUEUE_SIZE        16                /*  MUST BE A POWER OF 2  */
#define OUTPUT_QUEUE_MOD         (OUTPUT_QUEUE_SIZE-1)

#define WRITE_STARTED            1
#define WRITE_COMPLETED          2
#define READ_COMPLETED           3


/*  LOCAL TYPEDEFS  **********************************************************/
typedef struct {
    vm_address_t pagePtr;
    int regionTag;
    boolean_t msgStarted;
    boolean_t msgCompleted;
    port_t replyPort;
} OutputQueueType;

typedef struct {
    msg_header_t  h;
    msg_type_t    t;
    int           regionTag;
} SimpleMessage;

typedef struct {
    msg_header_t  h;
    msg_type_t    t1;
    int           regionTag;
    int           nbytes;
    msg_type_t    t2;
    short         *data;
} DataMessage;

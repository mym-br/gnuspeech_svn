#import "addons.h"
#import <driverkit/kernelDriver.h>
#import <kernserv/i386/spl.h>



/******************************************************************************
*
*	function:	dsp_put_page
*
*	purpose:	Writes a page of data (2048 DSPFix24s) to the DSP.
*                       A reply message is sent to the reply port, if the
*			started or completed flag is set.  Works like other
*                       "put" driver functions (i.e. doesn't use interrupts).
*
*       arguments:      dspdriver_port
*                       owner_port
*                       pageAddress - vm page address of data
*                       regionTag - tag for the region of data
*                       msgStarted - set on for started message to reply port
*                       msgCompleted - set on for completed message to reply
*                                      port
*                       reply_port - port where reply messages are sent
*                       unit - device unit number
*
*	internal
*	functions:	unitCheck, ownerCheck, sendMessage, writeInt
*
*	library
*	functions:	kern_serv_kernel_task_port, vm_allocate, vm_write,
*                       vm_deallocate
*
******************************************************************************/

EXPORTED kern_return_t
  dsp_put_page(port_t dspdriver_port, port_t owner_port,
	       DSPPagePtr pageAddress, int regionTag, boolean_t msgStarted,
	       boolean_t msgCompleted, port_t reply_port, int unit)
{
    int count = 2048;
    kern_return_t r;
    DSPPagePtr data = NULL, local_data;
    port_t kernel_task;
    void sendMessage();


    /*  DO UNIT AND OWNER CHECK  */
    unitCheck(); ownerCheck();

    /*  GET THE TASK ID FOR THE CURRENT KERNEL TASK  */
    kernel_task = kern_serv_kernel_task_port();

    /*  ALLOCATE VIRTUAL MEMORY FOR THE PAGE OF DATA  */
    r = vm_allocate((vm_task_t)kernel_task, (vm_address_t *)&local_data,
		    8192, TRUE);
    if (r != KERN_SUCCESS)
      return KERN_FAILURE;

    /*  INITIALIZE POINTER TO ALLOCATED PAGE  */
    data = local_data;

    /*  MAP THE USER MEMORY TO THE ALLOCATED PAGE  */
    r = vm_write((vm_task_t)kernel_task, (vm_address_t)local_data, 
		 (pointer_t)pageAddress, 8192);

    /*  SEND STARTED MESSAGE TO REPLY PORT, IF REQUESTED  */
    if (msgStarted)
        sendMessage(WRITE_STARTED, reply_port, regionTag, NULL, 0);

    /*  WRITE THE PAGE TO THE DSP  */
    while (count--)
	writeInt(*data++,unit);

    /*  SEND COMPLETED MESSAGE TO REPLY PORT, IF REQUESTED  */
    if (msgCompleted)
        sendMessage(WRITE_COMPLETED, reply_port, regionTag, NULL, 0);

    /*  DEALLOCATE THE VIRTUAL MEMORY  */
    vm_deallocate((vm_task_t)kernel_task, (vm_address_t)local_data, 8192);

    return KERN_SUCCESS;
}



/******************************************************************************
*
*	function:	dsp_set_messaging
*
*	purpose:	Turns on or off the driver messaging mode.  Messaging
*                       should be turned on after the DSP is booted and loaded.
*			Once messaging is on, pages of data can be queued in
*                       the driver for transfer to the DSP, and data will be
*                       returned to user code using mach messages to the
*                       reply port.
*
*       arguments:      dspdriver_port
*                       owner_port
*                       flag - set on to turn on messaging
*                       unit - device unit number
*
*	internal
*	functions:	unitCheck, ownerCheck, setMessagingOn:
*
*	library
*	functions:	none
*
******************************************************************************/

EXPORTED kern_return_t
  dsp_set_messaging(port_t dspdriver_port, port_t owner_port,
		    boolean_t flag, int unit)
{
    /*  DO UNIT AND OWNER CHECK  */
    unitCheck(); ownerCheck();

    /*  SET THE MESSAGINGON DRIVER INSTANCE VARIABLE  */
    [classVars.driverObjects[unit] setMessagingOn:flag];

    return KERN_SUCCESS;
}



/******************************************************************************
*
*	function:	dsp_queue_page
*
*	purpose:	Queues a page of data (2048 DSPFix24s) for transfer
*                       to the DSP.  A reply message is sent to the reply
*			port if the started or completed flags are set.
*                       Data is transferred by the "DSP-initiated DMA"
*                       protocol (using interrupts).
*
*       arguments:      dspdriver_port
*                       owner_port
*                       pageAddress - vm page address of data
*                       regionTag - tag for the region of data
*                       msgStarted - set on for started message to reply port
*                       msgCompleted - set on for completed message to reply
*                                      port
*                       reply_port - port where reply messages are sent
*                       unit - device unit number
*
*	internal
*	functions:	unitCheck, ownerCheck, pushOutputQueue:::::
*
*	library
*	functions:	none
*
******************************************************************************/

EXPORTED kern_return_t
  dsp_queue_page(port_t dspdriver_port, port_t owner_port,
		 DSPPagePtr pageAddress, int regionTag, boolean_t msgStarted,
		 boolean_t msgCompleted, port_t reply_port, int unit)
{
    /*  DO UNIT AND OWNER CHECK  */
    unitCheck(); ownerCheck();

    /*  PUSH THE PAGE ONTO THE QUEUE  */
    [classVars.driverObjects[unit] pushOutputQueue:pageAddress:regionTag
     :msgStarted:msgCompleted:reply_port];

    return KERN_SUCCESS;
}



/******************************************************************************
*
*	function:	dsp_set_short_swapped_return
*
*	purpose:	Sets up the driver so that data from the DSP is sent
*                       to the reply port in an out-of-line message.  The
*			data is returned in a region of vm (page-aligned)
*                       and consists of swapped short ints (i.e. 16 bit
*                       big-endian sound samples).  Data is transferred by
*                       the "DSP-initiated DMA" protocol (using interrupts).
*
*       arguments:      dspdriver_port
*                       owner_port
*                       regionTag - tag for the region of data
*                       wordCount - transfer buffer size (must agree with DSP)
*                       reply_port - port where reply messages are sent
*                       unit - device unit number
*
*	internal
*	functions:	unitCheck, ownerCheck,
*                       setDMARegionTag:wordCount:replyPort
*	library
*	functions:	none
*
******************************************************************************/

EXPORTED kern_return_t
  dsp_set_short_swapped_return(port_t dspdriver_port, port_t owner_port,
			       int regionTag, int wordCount,
			       port_t reply_port, int unit)
{
    /*  DO UNIT AND OWNER CHECK  */
    unitCheck(); ownerCheck();

    /*  SET DMA OUT VARIABLES  */
    [classVars.driverObjects[unit] setDMAOutRegionTag:regionTag
     wordCount:wordCount replyPort:reply_port];

    return KERN_SUCCESS;
}



/******************************************************************************
*
*	function:	hostCommand
*
*	purpose:	Writes the specified host command to the DSP.
*                       
*       arguments:      command - the command to be sent
*                       unit - device unit number
*
*	internal
*	functions:	DSPDRIVER_CVR
*
*	library
*	functions:	outb
*
******************************************************************************/

static inline void hostCommand(int command, int unit)
{
    outb(DSPDRIVER_CVR(unit), ((unsigned char)command | 0x80) );
}



/******************************************************************************
*
*	function:	sendMessage
*
*	purpose:	Formats and sends the specified reply message to
*                       the reply port.
*			
*       arguments:      messageType - type of message to send
*                       port - port where message is sent
*                       regionTag - tag identifier for the data region
*                       data - a pointer to the returned data (used only for
*                              READ_COMPLETED messages)
*                       nbytes - the number of bytes of returned data (used
*                                only for READ_COMPLETED messages)
*
*	internal
*	functions:	none
*
*	library
*	functions:	msg_send
*
******************************************************************************/

void sendMessage(int messageType, port_t port, int regionTag,
		 short *data, int nbytes)
{
    if ((messageType == WRITE_STARTED) || (messageType == WRITE_COMPLETED)) {
        SimpleMessage msg;

	/*  FILL IN THE MESSAGE HEADER  */
	msg.h.msg_simple = TRUE;
	msg.h.msg_size = sizeof(SimpleMessage);
	msg.h.msg_type = MSG_TYPE_NORMAL;
	msg.h.msg_local_port = PORT_NULL;
	msg.h.msg_remote_port = port;
	msg.h.msg_id = messageType;

	/*  FILL IN THE TYPE DESCRIPTOR  */
	msg.t.msg_type_name = MSG_TYPE_INTEGER_32;
	msg.t.msg_type_size = 32;
	msg.t.msg_type_number = 1;
	msg.t.msg_type_inline = TRUE;
	msg.t.msg_type_longform = FALSE;
	msg.t.msg_type_deallocate = FALSE;

	/*  FILL IN THE DATA  */
	msg.regionTag = regionTag;

	/*  SEND THE MESSAGE  */
	msg_send(&msg.h, MSG_OPTION_NONE, 0);
    }
    else if (messageType == READ_COMPLETED) {
	DataMessage msg;

	/*  FILL IN THE MESSAGE HEADER  */
	msg.h.msg_simple = FALSE;
	msg.h.msg_size = sizeof(DataMessage);
	msg.h.msg_type = MSG_TYPE_NORMAL;
	msg.h.msg_local_port = PORT_NULL;
	msg.h.msg_remote_port = port;
	msg.h.msg_id = messageType;

	/*  FILL IN THE INTEGER TYPE DESCRIPTOR  */
	msg.t1.msg_type_name = MSG_TYPE_INTEGER_32;
	msg.t1.msg_type_size = 32;
	msg.t1.msg_type_number = 2;
	msg.t1.msg_type_inline = TRUE;
	msg.t1.msg_type_longform = FALSE;
	msg.t1.msg_type_deallocate = FALSE;

	/*  FILL IN THE INTEGER VALUES  */
	msg.regionTag = regionTag;
	msg.nbytes = nbytes;

	/*  FILL IN THE OUT-OF-LINE TYPE DESCRIPTOR  */
	msg.t2.msg_type_name = MSG_TYPE_INTEGER_16;
	msg.t2.msg_type_size = 16;
	msg.t2.msg_type_number = nbytes / 2;
	msg.t2.msg_type_inline = FALSE;
	msg.t2.msg_type_longform = FALSE;
	msg.t2.msg_type_deallocate = FALSE;

	/*  FILL IN THE OUT-OF-LINE DATA  */
	msg.data = data;

	/*  SEND THE MESSAGE  */
	msg_send(&msg.h, MSG_OPTION_NONE, 0);
    }
}



/******************************************************************************
*
*	function:	interruptHandler
*
*	purpose:	This function is invoked by the kernel whenever the
*                       DSP interrupts the host.  It checks the ISR to make
*			sure the DSP did indeed cause the interrupt.  It then
*                       checks to make sure that messaging is on, and that
*                       RXDF caused the interrupt.  The DSP message is then
*                       read from RX.  If it is DSP request for DMA in or
*                       out, a message is sent to the IO thread, else the
*                       message is ignored.  The IO thread (the otherOccurred:
*                       method) deals with data transfer.
*
*       arguments:      identity
*                       state 
*                       unit - device unit number
*                       
*	internal
*	functions:	DSPDRIVER_ISR, DSPDRIVER_DATA_HIGH,
*                       DSPDRIVER_DATA_MED, DSPDRIVER_DATA_LOW
*	library
*	functions:	inb, IOSendInterrupt
*
******************************************************************************/

static void interruptHandler(void *identity, void *state, unsigned int unit)
{
    char high, med, low;
    unsigned char isr;
    DSPMKDriver *self = classVars.driverObjects[unit];


    /*  GET THE VALUE OF THE INTERRUPT STATUS REGISTER  */
    isr = inb(DSPDRIVER_ISR(unit));

    /*  IF THE DSP DIDN'T CAUSE THE INTERRUPT, RETURN IMMEDIATELY  */
    if (!(isr & 0x80))
        return;

    /*  IF NOT IN MESSAGING MODE, RETURN IMMEDIATELY  */
    if (!(self->messagingOn))
        return;

    /*  RETURN IMMEDIATELY, IF RXDF DIDN'T CAUSE INTERRUPT  */
    if (!(isr & 0x01))
        return;

    /*  GET THE DSP MESSAGE FROM THE RX REGISTER  */
    high = inb(DSPDRIVER_DATA_HIGH(unit));
    med = inb(DSPDRIVER_DATA_MED(unit));
    low = inb(DSPDRIVER_DATA_LOW(unit));

    /*  SEND DMA_IN OR DMA_OUT INTERRUPT TO IOTHREAD, ACCORDING TO DSP MSG  */
    switch (high) {
      case DMA_IN:  IOSendInterrupt(identity, state, DSP_INT_DMA_IN);  return;
      case DMA_OUT: IOSendInterrupt(identity, state, DSP_INT_DMA_OUT); return;
      default:      return;
    }
}



/******************************************************************************
*
*	method:	        getHandler:level:argument:forInterrupt
*
*	purpose:	Sets the function which handles interrupts from
*                       the DSP.
*			
*       arguments:      handler - pointer for setting the function
*                       ipl - pointer to set the interrupt level
*                       arg - pointer to set the argument sent to the handler
*                       localInterrupt - not used
*
*	internal
*	functions:	unit
*
*	library
*	functions:	none
*
******************************************************************************/

- (BOOL)getHandler:(IOEISAInterruptHandler *)handler
                   level:(unsigned int *)ipl
                   argument:(unsigned int *)arg
                   forInterrupt:(unsigned int)localInterrupt
{
    *handler = interruptHandler;
    *ipl = IPLDEVICE;
    *arg = [self unit];
    return YES;
}



/******************************************************************************
*
*	method:  	otherOccurred:
*
*	purpose:	This method is invoked by the IO thread when it gets
*                       DMA_IN or DMA_OUT messages from the interrupt handler.
*                       If the DSP is requesting DMA data in, a page of data
*			is transferred to the DSP (if available) from the
*                       queue.  If the DSP is requesting DMA data out, that
*                       data is transferred to a page of vm on the host,
*                       where it is then sent on to the user task.
*                       
*       arguments:      msgID - the type of interrupt which occurred
*                       
*	internal
*	functions:	pendingOutputMessage, sendPageToDSP,
*                       getSwappedShortsFromDSP
*
*	library
*	functions:	IOSleep
*
******************************************************************************/

- (void)otherOccurred:(int)msgID
{
    /*  DEAL WITH THE PENDING INTERRUPT  */
    switch (msgID) {
        case DSP_INT_DMA_IN: {
	    /* SLEEP UNTIL THERE IS SOMETHING TO SEND TO THE DSP  */
	    while (![self pendingOutputMessage]) {
	        /*  RESET CAN TURN OFF MESSAGING UNEXPECTEDLY  */
	        if (!messagingOn)
		    return;
		IOSleep(1);
	    }

	    /*  SEND THE PAGE OF DATA TO THE DSP, USING DMA PROTOCOL  */
	    [self sendPageToDSP];

	    return;
	}
        case DSP_INT_DMA_OUT: {
	    /*  GET THE DATA FROM THE DSP, USING DMA PROTOCOL  */
	    [self getSwappedShortsFromDSP];

	    return;
	}
        default: return;
    }
}



/******************************************************************************
*
*	method:  	setMessagingOn
*
*	purpose:	Records whether the driver is in messaging mode, and
*                       and sets the DSP interrupts appropriately.
*			
*       arguments:      flag - set on to turn messaging on
*                       
*	internal
*	functions:	DSPDRIVER_ICR
*
*	library
*	functions:	outb
*
******************************************************************************/

- (void)setMessagingOn:(BOOL)flag
{
    /*  SET THE MESSAGING FLAG IVAR  */
    messagingOn = flag;

    /*  IF MESSAGING, ENABLE INTERRUPT SO THE DSP CAN MESSAGE THE HOST  */
    if (messagingOn)
        outb(DSPDRIVER_ICR([self unit]),0x01);
    else
        outb(DSPDRIVER_ICR([self unit]),0x00);
	
    return;
}



/******************************************************************************
*
*	method:  	messagingOn
*
*	purpose:	Returns TRUE if driver is in messaging mode,
*                       FALSE otherwise.
*			
*       arguments:      none
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

- (BOOL)messagingOn
{
    return messagingOn;
}



/******************************************************************************
*
*	method:  	initOutputQueue
*
*	purpose:	Allocates memory and initializes data structures for
*                       the output queue (for data from host to DSP).
*			
*       arguments:      none
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	kern_serv_kernel_task_port, vm_allocate
*
******************************************************************************/

- (void)initOutputQueue
{
    int i;
    port_t kernel_task;


    /*  SET TAIL AND HEAD POINTERS  */
    outputTail = 0;
    outputHead = 0;

    /*  GET THE TASK ID FOR THE CURRENT KERNEL TASK  */
    kernel_task = kern_serv_kernel_task_port();

    /*  ALLOCATE PAGES OF VIRTUAL MEMORY  */
    for (i = 0; i < OUTPUT_QUEUE_SIZE; i++) {
	vm_allocate((vm_task_t)kernel_task,
		    &(outputQueue[i].pagePtr),
		    8192, TRUE);
//  Use the following instead, if wired vm preferred
//        outputQueue[i].pagePtr = (vm_address_t)kalloc(8192);
    }
}



/******************************************************************************
*
*	method:  	resetOutputQueue
*
*	purpose:	Resets the data structures which control the
*                       output queue.
*			
*       arguments:      none
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

- (void)resetOutputQueue
{
    /*  RESET TAIL AND HEAD POINTERS  */
    outputTail = 0;
    outputHead = 0;
}



/******************************************************************************
*
*	method:  	outputQueueFull
*
*	purpose:	Returns 1 if the output queue is full, 0 otherwise.
*			
*       arguments:      none
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

- (int)outputQueueFull
{
    /*  GET CURRENT TAIL AND HEADER POINTERS FOR THE OUTPUT QUEUE  */
    int tail = outputTail;
    int head = outputHead;

    /*  ADVANCE HEAD BY BUFFER SIZE, IF NECESSARY, TO DO MODULUS COMPARE  */
    if (head <= tail)
        head += OUTPUT_QUEUE_SIZE;

    /*  COMPARE FILL AND EMPTY POINTERS, RETURNING TRUE IF QUEUE FULL  */
    if ((head - tail) <= 1)
        return(1);

    /*  IF HERE, THEN THE QUEUE IS NOT FULL  */
    return(0);
}



/******************************************************************************
*
*	method:  	pushOutputQueue:::::
*
*	purpose:	Takes data from the user process, and pushes it onto
*                       the tail of the output queue.  Note that user data
*			is mapped into queue memory, not copied, so it must
*                       be page-aligned vm.
*
*       arguments:      pageAddress - page-aligned data to be transferred
*                                     to the DSP
*                       regionTag - the tag for the page of data
*                       msgStarted - set on, if started reply message desired
*                       msgCompleted - set on, if completed reply message
*                                      desired
*                       replyPort - port where reply messages are sent to
*
*	internal
*	functions:	outputQueueFull
*
*	library
*	functions:	vm_write, kern_serv_kernel_task_port, IOConvertPort
*
******************************************************************************/

- (void)pushOutputQueue:(DSPPagePtr)pageAddress:(int)regionTag:(BOOL)msgStarted
  :(BOOL)msgCompleted:(port_t)replyPort
{
    /*  MAKE SURE WE DON'T OVERRUN THE BUFFER, BLOCKING IF NECESSARY  */
    while ([self outputQueueFull])
        ;

    /*  PUSH THE DATA ONTO THE TAIL OF THE QUEUE  */
    vm_write(kern_serv_kernel_task_port(), outputQueue[outputTail].pagePtr,
	     (pointer_t)pageAddress, 8192);
    outputQueue[outputTail].regionTag = regionTag;
    outputQueue[outputTail].msgStarted = msgStarted;
    outputQueue[outputTail].msgCompleted = msgCompleted;
    /*  THE IO THREAD SENDS THE MESSAGES BACK TO THE REPLY PORT  */
    outputQueue[outputTail].replyPort =
        IOConvertPort(replyPort,IO_CurrentTask,IO_KernelIOTask);

    /*  DO MODULUS INCREMENT OF TAIL POINTER  */
    outputTail++;
    outputTail &= OUTPUT_QUEUE_MOD;
}



/******************************************************************************
*
*	method:  	popOutputQueue
*
*	purpose:	Removes one item from the head of the output queue.
*			
*       arguments:      none
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

- (OutputQueueType *)popOutputQueue
{
    OutputQueueType *ptr = NULL;

    if (outputHead != outputTail) {
        ptr = &outputQueue[outputHead++];
	outputHead &= OUTPUT_QUEUE_MOD;
    }

    return(ptr);
}



/******************************************************************************
*
*	method:  	pendingOutputMessage
*
*	purpose:	Returns a pointer to the pending output queue item,
*                       if there is one, else returns NULL.
*			
*       arguments:      none
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

- (OutputQueueType *)pendingOutputMessage
{
    if (outputHead != outputTail)
        return(&outputQueue[outputHead]);

    return(NULL);
}



/******************************************************************************
*
*	method:  	setDMAOutRegionTag:wordCount:replyPort
*
*	purpose:	Records where data from the DSP to the host should be
*                       sent, what size buffers are used, and the tag for the
*                       region of data.
*			
*       arguments:      regionTag - tag for the region of data returned
*                       wordCount - the number of words transferred by the
                                    DSP to the host
*                       replyPort - the port where reply messages are sent to
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	IOConvertPort
*
******************************************************************************/

- (void)setDMAOutRegionTag:(int)regionTag wordCount:(int)wordCount
        replyPort:(port_t)replyPort
{
    dmaOutRegionTag = regionTag;
    dmaOutWordCount = wordCount;
    dmaOutReplyPort = IOConvertPort(replyPort,IO_CurrentTask,IO_KernelIOTask);
}



/******************************************************************************
*
*	method:  	resetDMAOut
*
*	purpose:	Resets the driver so that DMA out messages (from DSP
*                       to host) are not sent.
*			
*       arguments:      none
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

- (void)resetDMAOut
{
    dmaOutRegionTag = 0;
    dmaOutWordCount = 0;
    dmaOutReplyPort = PORT_NULL;
}



/******************************************************************************
*
*	method:  	sendPageToDSP
*
*	purpose:	Sends a page of data from the output queue to the DSP
*                       using the "DSP-initiated DMA" protocol.  Started and/or
*                       completed messages are also sent to the reply port, if
*                       requested.  The transferred item is popped from the
*                       output queue.
*			
*       arguments:      none
*                       
*	internal
*	functions:	sendMessage, hostCommand, writeInt, popOutputQueue
*
*	library
*	functions:	none
*
******************************************************************************/

- (void)sendPageToDSP
{
    int i, *data;
    int unit = [self unit];


    /*  SEND STARTED MESSAGE TO REPLY PORT, IF REQUESTED  */
    if (outputQueue[outputHead].msgStarted)
        sendMessage(WRITE_STARTED, outputQueue[outputHead].replyPort,
		    outputQueue[outputHead].regionTag, NULL, 0);


    /*  SEND THE DATA IN THE OUTPUT QUEUE TO THE DSP  */
    /*  SEND DMA_IN_ACCEPTED HOST COMMAND, PLUS A DUMMY VALUE  */
    hostCommand(0x2C>>1, unit);
    writeInt(0, unit);

    /*  SEND THE DMA BUFFER TO THE DSP  */
    data = (int *)(outputQueue[outputHead].pagePtr);
    for (i = 0; i < 2048; i++)
        writeInt(*(data++),unit);

    /*  SEND A DMA_DONE HOST COMMAND  */
    hostCommand(0x28>>1, unit);


    /*  SEND COMPLETED MESSAGE TO REPLY PORT, IF REQUESTED  */
    if (outputQueue[outputHead].msgCompleted)
        sendMessage(WRITE_COMPLETED, outputQueue[outputHead].replyPort,
		    outputQueue[outputHead].regionTag, NULL, 0);

    /*  DISCARD THE LAST ELEMENT OF THE OUTPUT QUEUE  */
    [self popOutputQueue];

}



/******************************************************************************
*
*	method:  	getSwappedShortsFromDSP
*
*	purpose:	Gets a buffer of data from the DSP and copies it to
*                       a region of vm.  The lower 2 bytes of each DSPFix24
*			from the DSP is swapped (i.e. this routine gets right-
*                       justified 16 bit samples from the DSP, and stores them
*                       big-endian).  Each buffer of data is sent to user code
*                       using out-of-line mach messages.
*
*       arguments:      none
*                       
*	internal
*	functions:	unit, DSPDRIVER_ICR, awaitISRMask, DSPDRIVER_DATA_HIGH,
*                       DSPDRIVER_DATA_MED, DSPDRIVER_DATA_LOW, hostCommand,
*                       sendMessage
*	library
*	functions:	vm_allocate, outb, inb
*
******************************************************************************/

- (void)getSwappedShortsFromDSP
{
    int i, unit = [self unit];
    short int *data, *shortPtr;


    /*  RETURN IMMEDIATELY, IF USER HASN'T SET DMA OUT VARIABLES  */
    if (dmaOutReplyPort == PORT_NULL)
        return;

    /*  ALLOCATE MEMORY TO HOLD THE INPUT FROM THE DSP  */
    vm_allocate(task_self(), (vm_address_t *)&data,
		(dmaOutWordCount * 2), TRUE);


    /*  GET THE PENDING DATA FROM THE DSP  */
    /*  SET THE INTERRUPTS OFF, SINCE WE ARE GETTING DATA BY PROGRAMMED	IO,
	AND ACKNOWLEDGE THE DMA REQUEST BY SETTING HOST FLAG1 = 1  */
    outb(DSPDRIVER_ICR(unit),0x10);

    /*  GET THE DMA BUFFER FROM THE DSP (DSPFix24's), IGNORING HIGH
        BYTE, AND SWAPPING LOWER TWO BYTES  */
    for (i = 0, shortPtr = data; i < dmaOutWordCount; i++, shortPtr++) {
        unsigned char low, med, high;
	short int v;

	/*  WAIT UNTIL RXDF IS SET; EXIT LOOP IF WE TIME OUT  */
	if (awaitISRMask(RXDF,unit))
	    break;

	/*  GET THE WORD FROM THE DSP  */
	high = inb(DSPDRIVER_DATA_HIGH(unit));
	med = inb(DSPDRIVER_DATA_MED(unit));
	low = inb(DSPDRIVER_DATA_LOW(unit));

	/*  IGNORE HIGH BYTE, AND SWAP LOWER TWO BYTES  */
	v = low;
	v = (v << 8) | med;

	/*  WRITE THE SWAPPED SHORT INT TO VM  */
	*shortPtr = v;
    }

    /*  SEND A DMA_OUT_DONE HOST COMMAND  */
    hostCommand(0x24>>1, unit);

    /*  STOP THE DMA REQUEST ACKNOWLEDGE BY CLEARING HOST FLAG 1,
        AND RE-ENABLE THE INTERRUPTS  */
    outb(DSPDRIVER_ICR(unit),0x01);


    /*  SEND COMPLETED MESSAGE (WITH DATA) TO REPLY PORT (ALWAYS SENT)  */
    sendMessage(READ_COMPLETED, dmaOutReplyPort, dmaOutRegionTag,
		data, (dmaOutWordCount * 2));
}
